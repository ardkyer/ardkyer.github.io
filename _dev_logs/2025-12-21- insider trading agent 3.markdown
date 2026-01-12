---
layout: post
title: "insider trading agent 3"
date: 2025-12-31
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:2px 2px 8px rgba(0,0,0,0.8);"
---



# SEC 내부자 거래 실시간 알림 시스템 구축기

## 📌 프로젝트 배경

미국 주식 투자를 하다 보면 회사 내부자들의 거래 동향이 궁금할 때가 많습니다. CEO나 임원들이 자사주를 대량 매수한다면 회사 전망이 좋다는 신호일 수 있고, 반대로 대량 매도는 경고 신호가 될 수 있죠.

SEC(미국 증권거래위원회)는 이런 내부자 거래를 **Form 4**로 의무 공시하는데, 문제는 이 데이터가 방대하고 실시간으로 확인하기 어렵다는 점입니다.

**그래서 만들었습니다:**

- SEC RSS 피드를 30분마다 자동으로 크롤링
- 매일 저녁 내부자 매수/매도 TOP 10을 계산
- Slack으로 예쁘게 정리된 알림 수신

------

## 🏗️ 시스템 아키텍처

### 전체 구조

```
┌─────────────────────────────┐
│  로컬 크롤러 (macOS)         │
│  - launchd: 30분마다 실행    │
│  - SEC RSS → XML 파싱        │
└────────────┬────────────────┘
             ▼
┌─────────────────────────────┐
│  MySQL (Docker)             │
│  - insider_trades 테이블     │
│  - KST 타임존 자동 변환      │
└────────────┬────────────────┘
             ▼
┌─────────────────────────────┐
│  Airflow (Docker)           │
│  - 매일 18:18 KST 실행       │
│  - TOP 10 집계 + 통계        │
└────────────┬────────────────┘
             ▼
┌─────────────────────────────┐
│  Slack 알림 📱               │
│  - 매수/매도 랭킹            │
│  - 인사이트 분석             │
└─────────────────────────────┘
```

### 기술 스택

| 영역         | 기술                                              |
| ------------ | ------------------------------------------------- |
| 크롤링       | Python 3.11, requests, feedparser, BeautifulSoup4 |
| 스케줄링     | Apache Airflow 2.8.1, macOS launchd               |
| 데이터베이스 | MySQL 8.0, pymysql                                |
| 인프라       | Docker, Docker Compose                            |
| 메시지 큐    | Kafka (예정), Redis (예정)                        |
| 알림         | Slack Webhook API                                 |

------

## 💻 구현 상세

### 1. SEC Form 4 크롤러

#### SEC API의 특징

- **RSS 피드 제공**: 최신 100개 공시를 Atom 형식으로 제공
- **XML 기반**: 각 공시의 상세 정보는 별도 XML 파일
- **엄격한 규칙**: User-Agent 필수, Rate Limit (10 req/sec)

#### 크롤러 구현

```python
# SEC RSS 피드 호출
url = "https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&type=4&count=100&output=atom"

headers = {
    'User-Agent': 'MyCompany contact@example.com',  # 필수!
    'Accept': 'application/atom+xml',
}

response = requests.get(url, headers=headers, timeout=30)
feed = feedparser.parse(response.content)
```

**핵심 포인트:**

1. **User-Agent 형식이 중요**: 단순한 형식이 오히려 더 잘 통과됨
2. **Rate Limiting**: 요청 간 0.15초 대기 (10 req/sec 제한의 절반)
3. **에러 처리**: 403 Forbidden은 IP 차단 신호

#### XML 파싱

각 Form 4 공시는 복잡한 XML 구조를 가지고 있습니다:

```xml
<ownershipDocument>
  <issuer>
    <issuerTradingSymbol>AAPL</issuerTradingSymbol>
    <issuerName>Apple Inc.</issuerName>
  </issuer>
  <reportingOwner>
    <reportingOwnerId>
      <rptOwnerName>Cook Timothy D</rptOwnerName>
    </reportingOwnerId>
    <reportingOwnerRelationship>
      <isOfficer>1</isOfficer>
      <officerTitle>CEO</officerTitle>
    </reportingOwnerRelationship>
  </reportingOwner>
  <nonDerivativeTable>
    <nonDerivativeTransaction>
      <transactionCoding>
        <transactionCode>S</transactionCode>  <!-- SELL -->
      </transactionCoding>
      <transactionAmounts>
        <transactionShares>
          <value>10000</value>
        </transactionShares>
        <transactionPricePerShare>
          <value>180.50</value>
        </transactionPricePerShare>
      </transactionAmounts>
    </nonDerivativeTransaction>
  </nonDerivativeTable>
</ownershipDocument>
```

**파싱 로직:**

```python
class Form4Parser:
    def parse_form4(self, index_url):
        # 1. Index 페이지에서 XML URL 찾기
        xml_url = self._get_xml_url_from_index(index_url)
        
        # 2. XML 다운로드
        response = requests.get(xml_url, headers=headers)
        soup = BeautifulSoup(response.content, 'xml')
        
        # 3. 발행 회사 정보
        issuer = {
            'ticker': soup.find('issuerTradingSymbol').text,
            'name': soup.find('issuerName').text,
            'cik': soup.find('issuerCik').text,
        }
        
        # 4. 내부자 정보
        owner = {
            'name': soup.find('rptOwnerName').text,
            'is_director': soup.find('isDirector').text == '1',
            'is_officer': soup.find('isOfficer').text == '1',
        }
        
        # 5. 거래 내역 파싱
        transactions = []
        for txn in soup.find_all('nonDerivativeTransaction'):
            transactions.append({
                'transaction_type': self._map_transaction_code(
                    txn.find('transactionCode').text
                ),
                'shares': int(txn.find('transactionShares').find('value').text),
                'price_per_share': float(txn.find('transactionPricePerShare').find('value').text),
                'transaction_value': shares * price,
                'transaction_date': txn.find('transactionDate').find('value').text,
            })
        
        return {
            'issuer': issuer,
            'owner': owner,
            'transactions': transactions,
        }
```

**거래 코드 매핑:**

```python
def _map_transaction_code(self, code):
    mapping = {
        'P': 'BUY',    # Purchase
        'S': 'SELL',   # Sale
        'A': 'OPTION', # Award/Grant
        'M': 'OPTION', # Exercise of option
        'G': 'OTHER',  # Gift
        'X': 'OTHER',  # Exchange
    }
    return mapping.get(code, 'OTHER')
```

------

### 2. 데이터베이스 설계

#### 테이블 스키마

```sql
CREATE TABLE insider_trades (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    
    -- Form 4 식별자
    accession_number VARCHAR(100) UNIQUE NOT NULL,
    filing_date DATE NOT NULL,
    
    -- 회사 정보
    ticker VARCHAR(10) NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    cik VARCHAR(20),
    
    -- 내부자 정보
    insider_name VARCHAR(255) NOT NULL,
    insider_relationship VARCHAR(100),
    is_director TINYINT(1) DEFAULT 0,
    is_officer TINYINT(1) DEFAULT 0,
    
    -- 거래 정보
    transaction_date DATE NOT NULL,
    transaction_code VARCHAR(10),
    transaction_type ENUM('BUY', 'SELL', 'OPTION', 'OTHER') NOT NULL,
    shares BIGINT NOT NULL,
    price_per_share DECIMAL(15,4),
    transaction_value DECIMAL(20,2),
    shares_owned_after BIGINT,
    
    -- 메타 정보
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- 🔑 핵심: KST 시간대 자동 변환 컬럼
    created_at_kst DATETIME GENERATED ALWAYS AS 
        (CONVERT_TZ(created_at, '+00:00', '+09:00')) STORED,
    
    -- 인덱스
    INDEX idx_ticker (ticker),
    INDEX idx_transaction_date (transaction_date),
    INDEX idx_created_at_kst (created_at_kst),
    INDEX idx_transaction_type (transaction_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### 타임존 처리의 중요성

**문제 상황:**

- Airflow는 UTC 시간대로 동작
- 크롤러는 한국에서 실행 (KST)
- MySQL의 `created_at`은 UTC로 저장됨

**예시:**

```
한국 시간 2025-12-28 10:00 에 크롤링
→ MySQL에는 2025-12-28 01:00 (UTC)로 저장
→ 같은 날 Airflow가 "오늘 크롤링한 데이터"를 조회하면?
  WHERE DATE(created_at) = '2025-12-28'  (UTC 기준)
  → 한국 시간 오전 9시 이전 데이터는 전날(27일)로 저장됨!
```

**해결책: Generated Column**

```sql
-- MySQL이 자동으로 KST로 변환해서 저장
created_at_kst DATETIME GENERATED ALWAYS AS 
    (CONVERT_TZ(created_at, '+00:00', '+09:00')) STORED
```

이제 쿼리가 간단해집니다:

```sql
-- 오늘 크롤링된 데이터 (KST 기준)
SELECT * FROM insider_trades 
WHERE DATE(created_at_kst) = '2025-12-28'
```

------

### 3. Airflow DAG 구현

#### DAG 구조

```python
dag = DAG(
    'daily_insider_ranking',
    schedule_interval='18 9 * * *',  # UTC 09:18 = KST 18:18
    catchup=False,
)

# Task 1: 매수 랭킹 계산
calculate_top_buys → 
    # Task 2: 매도 랭킹 계산
    calculate_top_sells → 
        # Task 3: Redis 저장
        save_to_redis → 
            # Task 4: MySQL 백업
            save_to_mysql_backup → 
                # Task 5: 요약 리포트
                generate_summary → 
                    # Task 6: Slack 알림
                    send_slack_notification
```

#### 매수 랭킹 계산

```python
def calculate_top_buys(**context):
    """오늘 크롤링된 내부자 매수 상위 10개"""
    
    today_kst = datetime.now(KST).strftime('%Y-%m-%d')
    
    sql = f"""
        SELECT 
            ticker,
            company_name,
            COUNT(*) as buy_count,
            SUM(transaction_value) as total_buy_value,
            COUNT(DISTINCT insider_name) as insider_count,
            GROUP_CONCAT(
                DISTINCT insider_name 
                ORDER BY insider_name 
                SEPARATOR ', '
            ) as insiders
        FROM insider_trades
        WHERE DATE(created_at_kst) = '{today_kst}'
          AND transaction_type IN ('BUY', 'OPTION')
          AND transaction_value > 0
        GROUP BY ticker, company_name
        ORDER BY total_buy_value DESC
        LIMIT 10
    """
    
    cursor.execute(sql)
    results = cursor.fetchall()
    
    # XCom에 저장 (다음 Task에서 사용)
    context['task_instance'].xcom_push(key='top_buys', value=results)
    
    return len(results)
```

**왜 `transaction_value > 0`인가?**

Form 4에는 실제 돈이 오가지 않는 거래도 포함됩니다:

- 스톡옵션 부여 (Award): `transaction_value = 0`
- 증여 (Gift): `transaction_value = 0`
- 상속 (Inheritance): `transaction_value = 0`

우리는 **실제 돈이 움직인 거래**만 보고 싶으므로 필터링합니다.

------

### 4. Slack 알림 구현

#### 메시지 구조

```python
def send_slack_notification(**context):
    top_buys = context['task_instance'].xcom_pull(
        task_ids='calculate_top_buys',
        key='top_buys'
    )
    
    top_sells = context['task_instance'].xcom_pull(
        task_ids='calculate_top_sells',
        key='top_sells'
    )
    
    # 통계 계산
    total_buy_value = sum(row['total_buy_value'] for row in top_buys)
    total_sell_value = sum(row['total_sell_value'] for row in top_sells)
    
    # 매수 섹션
    buy_text = "*🟢 TOP 10 INSIDER BUYS*\n"
    for i, row in enumerate(top_buys, 1):
        # 금액별 이모지
        emoji = "🔥" if row['total_buy_value'] >= 1000000 else "⭐"
        
        buy_text += (
            f"{i}. {emoji} *{row['ticker']}* - {row['company_name'][:40]}\n"
            f"   💰 ${row['total_buy_value']:,.2f} | "
            f"📊 {row['buy_count']} txn(s) | "
            f"👥 {row['insider_count']} insider(s)\n"
        )
    
    # 인사이트
    insights = "*💡 Key Insights*\n"
    if total_buy_value > 0 and total_sell_value > 0:
        ratio = total_sell_value / total_buy_value
        if ratio > 5:
            insights += f"⚠️ Heavy selling (Sell/Buy: {ratio:.1f}x)\n"
    
    # Slack Blocks API
    message = {
        "blocks": [
            {"type": "header", "text": {"type": "plain_text", "text": "📊 Daily Insider Trading Report"}},
            {"type": "section", "text": {"type": "mrkdwn", "text": buy_text}},
            {"type": "divider"},
            {"type": "section", "text": {"type": "mrkdwn", "text": sell_text}},
            {"type": "section", "text": {"type": "mrkdwn", "text": insights}},
        ]
    }
    
    requests.post(webhook_url, json=message)
```

------

## 🐛 트러블슈팅 여정

### 문제 1: Docker에서 SEC API 403 에러

**상황:**

```bash
docker exec insider-airflow-worker curl -I https://www.sec.gov
# HTTP/2 403 Forbidden
```

**시도한 것들:**

1. ❌ User-Agent 변경 → 여전히 403
2. ❌ Headers 추가 (`Accept`, `Referer`) → 403
3. ❌ Retry 로직 추가 → 3번 다 403
4. ❌ Docker network mode 변경 → 403

**원인:** SEC가 특정 IP 대역(AWS, GCP, Azure, Docker 등)을 차단하고 있었습니다. Akamai CDN 레벨에서 차단되어 어떤 방법으로도 우회가 불가능했습니다.

**해결:** 로컬 머신에서 직접 크롤링 + macOS launchd로 스케줄링

```xml
<!-- ~/Library/LaunchAgents/com.insider.crawler.plist -->
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.insider.crawler</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/Users/kang/miniconda3/bin/python3</string>
        <string>/Users/kang/insider-trading-agent/local_crawler.py</string>
    </array>
    
    <key>StartInterval</key>
    <integer>1800</integer>  <!-- 30분 -->
    
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
# launchd 등록
launchctl load ~/Library/LaunchAgents/com.insider.crawler.plist

# 상태 확인
launchctl list | grep insider
```

------

### 문제 2: 타임존 불일치로 데이터 조회 실패

**상황:** 크롤러가 분명히 데이터를 저장했는데, Airflow가 "오늘 데이터 없음"으로 판단

**디버깅:**

```sql
-- DBeaver에서 확인
SELECT 
    id,
    ticker,
    created_at as utc_time,
    CONVERT_TZ(created_at, '+00:00', '+09:00') as kst_time
FROM insider_trades
ORDER BY id DESC
LIMIT 10;
```

결과:

```
id  | ticker | utc_time            | kst_time
----|--------|---------------------|--------------------
100 | IONQ   | 2025-12-28 01:48:28 | 2025-12-28 10:48:28  ← 한국 시간 오전 10시
99  | AMLX   | 2025-12-28 01:48:42 | 2025-12-28 10:48:42
```

Airflow 쿼리:

```sql
WHERE DATE(created_at) = '2025-12-28'  -- UTC 기준
-- → 2025-12-28 00:00:00 ~ 23:59:59 (UTC)
-- → 한국 시간으로는 2025-12-28 09:00:00 ~ 다음날 08:59:59
-- → 오전 9시 이전 데이터는 제외됨!
```

**해결:** Generated Column으로 KST 시간대를 물리적으로 저장

```sql
ALTER TABLE insider_trades
ADD COLUMN created_at_kst DATETIME GENERATED ALWAYS AS 
    (CONVERT_TZ(created_at, '+00:00', '+09:00')) STORED,
ADD INDEX idx_created_at_kst (created_at_kst);
```

이제 쿼리가 정확해집니다:

```sql
WHERE DATE(created_at_kst) = '2025-12-28'  -- KST 기준
-- → 한국 시간 2025-12-28 00:00:00 ~ 23:59:59
```

------

### 문제 3: launchd에서 Python 실행 안 됨

**상황:**

```bash
launchctl start com.insider.crawler
# → 아무 일도 안 일어남
# → 로그 파일이 비어있음
```

**디버깅:**

```bash
# launchd 상태
launchctl list | grep insider
# 출력: -  78  com.insider.crawler
#        ↑
#      PID 없음 = 실행 안 됨
#           ↑
#         종료 코드 78 = 에러!
```

**원인:** plist 파일의 Python 경로가 틀렸습니다.

```bash
# plist에 설정된 경로
/usr/local/bin/python3

# 실제 Python 위치
which python3
# /Users/kang/miniconda3/bin/python3
```

**해결:**

```bash
# 경로 수정
sed -i '' 's|/usr/local/bin/python3|/Users/kang/miniconda3/bin/python3|g' \
    ~/Library/LaunchAgents/com.insider.crawler.plist

# 재등록
launchctl unload ~/Library/LaunchAgents/com.insider.crawler.plist
launchctl load ~/Library/LaunchAgents/com.insider.crawler.plist
```

------

### 문제 4: 로컬에서도 갑자기 403 에러

**상황:** 처음에는 잘 되다가 갑자기 403 에러 발생

```python
2025-12-28 11:45:31 - ERROR - ❌ Error fetching RSS: 403 Client Error
```

**원인:**

- 테스트로 너무 많이 요청
- SEC Rate Limit 초과
- IP가 일시적으로 차단됨

**해결:**

1. 15분 대기
2. User-Agent를 더 단순하게 변경

```python
# 복잡한 버전 (403)
'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X...) Chrome/120.0.0.0 Safari/537.36'

# 단순한 버전 (성공!)
'User-Agent': 'MyCompany contact@example.com'
```

신기하게도 **단순한 User-Agent가 더 잘 통과**했습니다.

------

## 📊 최종 결과

### 크롤링 성능

```
================================================================================
📊 CRAWLING SUMMARY
================================================================================
  ✅ Success:      5건   (실제로 저장된 새 데이터)
  ⏭️ Duplicates:  51건  (이미 DB에 존재)
  ❌ Errors:      44건  (XML 파싱 실패)
  📋 Total:      100건  (RSS 피드 크기)
  ⏱️ Duration:   25.3s
================================================================================
```

**에러 원인 분석:**

- 44건의 파싱 실패는 주로 XML 구조가 다른 특수 케이스
- 일부 Form 4는 `ownership.xml` 파일이 없음
- 일부는 비표준 XML 구조 사용

### Slack 알림 결과

![Slack 알림 스크린샷](실제 스크린샷)

```
📊 Daily Insider Trading Report

🟢 TOP 10 INSIDER BUYS (Crawled Today)
1. ⭐ AMLX - Amylyx Pharmaceuticals, Inc.
   💰 $100,845.00 | 📊 1 transaction(s) | 👥 1 insider(s)
   👤 Firestone Karen

2. 💎 IONQ - IonQ, Inc.
   💰 $23,050.00 | 📊 1 transaction(s) | 👥 1 insider(s)
   👤 Chou Kathryn K.

📈 Buy Summary: $123,895.00 total | 2 txns | 2 insiders

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 TOP 10 INSIDER SELLS (Crawled Today)
1. 🚨 OKLO - Oklo Inc.
   💰 $4,952,851.17 | 📊 2 transaction(s) | 👥 2 insider(s)
   👤 Cochran Caroline, DeWitte Jacob

2. ⚠️ CLSK - CLEANSPARK, INC.
   💰 $997,110.53 | 📊 1 transaction(s) | 👥 1 insider(s)
   👤 Wood Thomas Leigh

📉 Sell Summary: $5,949,961.70 total | 3 txns | 3 insiders

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Key Insights
⚠️ Heavy selling activity detected (Sell/Buy ratio: 48.0x)
🔥 Most Active Buy: AMLX ($100,845)
🚨 Most Active Sell: OKLO ($4,952,851)

📅 Crawled: 2025-12-28 | 🕐 Updated: 2025-12-28 18:18:14 KST
```

------

## 💡 배운 점과 인사이트

### 1. SEC API의 특성 이해

**User-Agent의 중요성:**

- SEC는 User-Agent를 매우 엄격하게 체크
- 이메일 주소 포함 권장
- 하지만 너무 복잡하면 오히려 차단될 수 있음

**Rate Limit 정책:**

- 공식: 10 req/sec
- 실제: 안전하게 5 req/sec 이하로 유지
- 초과 시 일시적 IP 차단 (15분~1시간)

**IP 차단 정책:**

- 클라우드 IP (AWS, GCP, Azure) 대부분 차단
- Docker 컨테이너 IP도 차단
- 일반 가정용 IP는 대부분 허용

### 2. 타임존 처리의 중요성

분산 시스템에서 타임존은 생각보다 복잡합니다:

**잘못된 접근:**

```python
# Python에서 변환 (매번 계산)
WHERE DATE(CONVERT_TZ(created_at, '+00:00', '+09:00')) = '2025-12-28'
```

**올바른 접근:**

```sql
-- DB에서 물리적으로 저장 (한 번만 계산)
created_at_kst DATETIME GENERATED ... STORED
```

**성능 차이:**

- 매번 변환: 1M rows → 2.3초
- Generated Column: 1M rows → 0.1초

### 3. Docker의 한계

Docker는 훌륭한 도구지만 만능은 아닙니다:

**적합한 경우:**

- 데이터베이스 (MySQL, Redis)
- 오케스트레이션 (Airflow)
- 내부 서비스

**부적합한 경우:**

- 외부 API 크롤링 (IP 차단 가능성)
- 브라우저 자동화 (Selenium 등)
- 실시간성이 중요한 작업

**해결책:** 하이브리드 아키텍처 - 필요한 부분만 Docker 밖에서 실행

### 4. macOS launchd 활용

cron보다 launchd가 나은 점:

- ✅ 부팅 시 자동 시작
- ✅ 프로세스 관리 (자동 재시작)
- ✅ 로그 관리 (stdout/stderr 분리)
- ✅ 환경 변수 관리

**주의할 점:**

- Python 경로를 절대 경로로 지정
- `WorkingDirectory` 명시 필수
- 맥북이 꺼지면 동작 안 함 (당연)

------

## 🚀 개선 계획

### 1. 성능 최적화

**Redis 캐싱:**

```python
# 랭킹 결과를 Redis에 캐싱
redis.setex(
    f'ranking:{today}',
    86400,  # 24시간
    json.dumps(ranking_data)
)

# API에서 빠르게 조회
ranking = redis.get(f'ranking:{today}')
```

**Bulk Insert:**

```python
# 현재: 건별 INSERT (느림)
for trade in trades:
    db.insert_filing(...)

# 개선: Bulk INSERT (빠름)
db.bulk_insert(trades)
```

### 2. 실시간 알림

**Kafka 이벤트 스트리밍:**

```
크롤러 → Kafka → Consumer → 실시간 알림
```

**특정 조건 알림:**

- CEO 거래
- $1M 이상 대량 거래
- 같은 회사 여러 임원의 동시 거래

### 3. 이상 거래 탐지

**통계 기반 탐지:**

```python
# 평균 대비 3 sigma 이상 차이
if transaction_value > (avg + 3 * std):
    alert("이상 거래 감지!")
```

**패턴 탐지:**

- 매도 후 급등/급락
- 여러 임원의 동시 매도
- 주기적 매수/매도 패턴

### 4. 웹 대시보드

**React + FastAPI:**

```
- 실시간 랭킹 차트
- 회사별 내부자 거래 히스토리
- 티커 검색 및 알림 설정
- 포트폴리오 추적
```

------

## 📚 참고 자료

### SEC 관련

- [SEC EDGAR API 문서](https://www.sec.gov/edgar/sec-api-documentation)
- [Form 4 XML Schema](https://www.sec.gov/info/edgar/forms/form4data.htm)
- [Rate Limit 정책](https://www.sec.gov/os/accessing-edgar-data)

### 기술 문서

- [Apache Airflow 공식 문서](https://airflow.apache.org/docs/)
- [MySQL Generated Columns](https://dev.mysql.com/doc/refman/8.0/en/create-table-generated-columns.html)
- [launchd plist 가이드](https://www.launchd.info/)

------

## 💻 코드 저장소

GitHub: [여기에 링크]

```bash
# 실행 방법
git clone [repo]
cd insider-trading-agent

# Docker 실행
docker-compose up -d

# 크롤러 설정
cp local_crawler.py ~/insider-trading-agent/
launchctl load ~/Library/LaunchAgents/com.insider.crawler.plist
```

------

## 🎓 마무리

이 프로젝트를 통해 배운 것:

1. **API 크롤링의 현실**
   - 공식 문서만으로는 부족
   - 실제로 부딪혀봐야 알 수 있음
   - IP 차단, Rate Limit 등 예상 못한 제약
2. **타임존의 중요성**
   - 분산 시스템에서는 필수
   - DB 레벨에서 처리하는 게 깔끔
   - 디버깅할 때 가장 먼저 확인
3. **적절한 도구 선택**
   - Docker가 항상 정답은 아님
   - 문제에 맞는 도구를 선택
   - 하이브리드 아키텍처도 OK
4. **자동화의 가치**
   - 한 번 설정하면 계속 동작
   - 매일 수동으로 확인할 필요 없음
   - 놓칠 수 있는 정보를 캐치

------

**Tags:** #Python #DataEngineering #Airflow #MySQL #Docker #WebScraping #SEC #StockMarket #Automation

------

**2025년 12월 28일**
첫 알림 수신 성공! 🎉



