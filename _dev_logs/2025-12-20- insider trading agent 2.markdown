---
layout: post
title: "insider trading agent 2"
date: 2025-12-20
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:2px 2px 8px rgba(0,0,0,0.8);"
---



# 🚀 Airflow로 SEC 내부자 거래 실시간 모니터링 시스템 구축하기

## 📌 프로젝트 개요

미국 증권거래위원회(SEC)에 공시되는 내부자 거래(Insider Trading) 정보를 실시간으로 수집하고, 일일 매수/매도 상위 기업을 자동으로 분석하여 Slack으로 알림받는 시스템을 구축했습니다.

**Tech Stack:**

- Apache Airflow (워크플로우 오케스트레이션)
- MySQL 8.0 (데이터 저장)
- Redis (캐싱)
- Docker Compose (컨테이너 오케스트레이션)
- Python 3.11
- Slack Webhook (알림)

**개발 기간:** 1일
**비용:** $0 (로컬 실행)

------

## 🎯 왜 이 프로젝트를 만들었나?

내부자 거래는 기업의 임원, 이사 등이 자사 주식을 매수/매도할 때 SEC에 의무적으로 신고해야 하는 정보입니다. 이들은 일반 투자자보다 기업의 내부 상황을 잘 알고 있기 때문에, 내부자 거래 패턴을 분석하면 투자 인사이트를 얻을 수 있습니다.

**핵심 아이디어:**

- 임원들이 자기 회사 주식을 **대량 매수**하면? → 주가 상승 신호일 수 있음
- 임원들이 자기 회사 주식을 **대량 매도**하면? → 주가 하락 신호일 수 있음

------

## 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    SEC EDGAR RSS                         │
│          (Form 4 Insider Trading Filings)                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Airflow DAG #1: Crawler                     │
│  ┌──────────────────────────────────────────────────┐   │
│  │  fetch_sec_rss (최신 100개 Form 4 수집)         │   │
│  └──────────────┬───────────────────────────────────┘   │
│                 │                                         │
│  ┌──────────────▼───────────────────────────────────┐   │
│  │  parse_and_save_filings (XML 파싱 + MySQL 저장) │   │
│  └──────────────┬───────────────────────────────────┘   │
│                 │                                         │
│  ┌──────────────▼───────────────────────────────────┐   │
│  │  send_to_kafka (통계 전송, 향후 구현)           │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                     │
                     ▼
              ┌──────────┐
              │  MySQL   │ ← insider_trades 테이블
              └──────┬───┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│            Airflow DAG #2: Daily Ranking                 │
│  ┌──────────────────────┬──────────────────────────┐    │
│  │ calculate_top_buys   │ calculate_top_sells      │    │
│  └──────────┬───────────┴───────────┬──────────────┘    │
│             │                       │                    │
│             └───────────┬───────────┘                    │
│                         ▼                                │
│              ┌──────────────────┐                        │
│              │  save_to_redis   │                        │
│              └────────┬─────────┘                        │
│                       ▼                                  │
│              ┌──────────────────┐                        │
│              │ save_to_mysql    │                        │
│              └────────┬─────────┘                        │
│                       ▼                                  │
│              ┌──────────────────┐                        │
│              │ generate_summary │                        │
│              └────────┬─────────┘                        │
│                       ▼                                  │
│              ┌──────────────────┐                        │
│              │ send_slack_alert │ → 📱 Slack           │
│              └──────────────────┘                        │
└─────────────────────────────────────────────────────────┘
```

**실행 스케줄:**

- **Crawler DAG**: 30분마다 실행 (`*/30 * * * *`)
- **Ranking DAG**: 매일 오후 6시 실행 (`0 18 * * *`)

------

## 💾 데이터베이스 스키마

### insider_trades 테이블

```sql
CREATE TABLE insider_trades (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    -- Form 4 정보
    accession_number VARCHAR(100) NOT NULL,
    filing_date DATE NOT NULL,
    
    -- 기업 정보
    ticker VARCHAR(10) NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    cik VARCHAR(20),
    
    -- 내부자 정보
    insider_name VARCHAR(255) NOT NULL,
    insider_relationship VARCHAR(100),
    is_director BOOLEAN DEFAULT FALSE,
    is_officer BOOLEAN DEFAULT FALSE,
    
    -- 거래 정보
    transaction_date DATE NOT NULL,
    transaction_code VARCHAR(10),
    transaction_type ENUM('BUY','SELL','OPTION','GRANT','GIFT','OTHER'),
    shares BIGINT NOT NULL,
    price_per_share DECIMAL(15,4),
    transaction_value DECIMAL(20,2),
    shares_owned_after BIGINT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- 인덱스
    INDEX idx_accession_number (accession_number),
    INDEX idx_ticker (ticker),
    INDEX idx_filing_date (filing_date),
    INDEX idx_transaction_type (transaction_type)
);
```

**핵심 필드:**

- `ticker`: 주식 티커 (예: AAPL, TSLA)
- `insider_name`: 내부자 이름
- `transaction_type`: BUY(매수), SELL(매도), OPTION(옵션 행사)
- `transaction_value`: 거래 금액 (달러)

------

## 🔧 핵심 기능 구현

### 1. SEC Form 4 XML 파서

SEC는 Form 4 데이터를 XML 형식으로 제공합니다. 이를 파싱하여 구조화된 데이터로 변환합니다.

**파서 핵심 로직:**

```python
class Form4Parser:
    def parse_form4(self, index_url: str) -> Dict:
        # 1. Index 페이지에서 ownership.xml URL 추출
        xml_url = self.get_xml_url_from_index(index_url)
        
        # 2. XML 다운로드
        xml_content = self.download_xml(xml_url)
        
        # 3. XML 파싱
        root = ET.fromstring(xml_content)
        
        # Issuer (발행사/기업)
        issuer = {
            'cik': root.find('.//issuer/issuerCik').text,
            'name': root.find('.//issuer/issuerName').text,
            'ticker': root.find('.//issuer/issuerTradingSymbol').text
        }
        
        # Owner (내부자)
        owner = {
            'cik': root.find('.//reportingOwner/reportingOwnerId/rptOwnerCik').text,
            'name': root.find('.//reportingOwner/reportingOwnerId/rptOwnerName').text,
            'is_director': self._parse_bool(root.find('.//reportingOwner/reportingOwnerRelationship/isDirector')),
            'is_officer': self._parse_bool(root.find('.//reportingOwner/reportingOwnerRelationship/isOfficer'))
        }
        
        # Transactions (거래 내역)
        transactions = []
        for trans in root.findall('.//nonDerivativeTransaction'):
            transaction = {
                'date': trans.find('.//transactionDate/value').text,
                'code': trans.find('.//transactionCoding/transactionCode').text,
                'shares': int(float(trans.find('.//transactionAmounts/transactionShares/value').text)),
                'price': float(trans.find('.//transactionAmounts/transactionPricePerShare/value').text),
                'type': self._get_transaction_type(code)
            }
            transactions.append(transaction)
        
        return {
            'issuer': issuer,
            'owner': owner,
            'transactions': transactions
        }
```

**거래 코드 매핑:**

- `P` → BUY (매수)
- `S` → SELL (매도)
- `M` → OPTION (옵션 행사)
- `A` → GRANT (무상 부여)

------

### 2. MySQL 저장 로직

중복 방지 및 트랜잭션 단위 저장:

```python
class InsiderTradesDB:
    def insert_filing(self, accession_number: str, filing_data: Dict) -> bool:
        with connection.cursor() as cursor:
            # 중복 확인
            if self._is_duplicate(cursor, accession_number):
                return False
            
            # 각 거래별 INSERT
            for trans in filing_data['transactions']:
                try:
                    self._insert_transaction(cursor, accession_number, filing_data, trans)
                except IntegrityError as e:
                    if '1062' in str(e):  # Duplicate entry
                        break  # 같은 Form 4의 다른 거래는 스킵
                    raise
            
            connection.commit()
            return True
```

------

### 3. 일일 랭킹 계산 SQL

**매수 상위 10개 기업:**

```sql
SELECT 
    ticker,
    company_name,
    COUNT(*) as buy_count,
    SUM(transaction_value) as total_buy_value,
    COUNT(DISTINCT insider_name) as insider_count,
    GROUP_CONCAT(DISTINCT insider_name ORDER BY insider_name SEPARATOR ', ') as insiders
FROM insider_trades
WHERE DATE(transaction_date) = CURDATE()
  AND transaction_type IN ('BUY', 'OPTION')
  AND transaction_value > 0
GROUP BY ticker, company_name
ORDER BY total_buy_value DESC
LIMIT 10;
```

**핵심 포인트:**

- `CURDATE()`: 하드코딩 없이 당일 자동 계산
- `IN ('BUY', 'OPTION')`: 옵션 행사도 매수로 간주
- `GROUP_CONCAT`: 여러 내부자를 하나의 문자열로

------

### 4. Slack 알림 포맷

```python
def send_slack_notification(**context):
    top_buys = context['task_instance'].xcom_pull(
        task_ids='calculate_top_buys',
        key='top_buys'
    )
    
    message = {
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "📊 Daily Insider Trading Report"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*🟢 TOP 10 INSIDER BUYS ({today})*\n" + 
                           "\n".join([
                               f"{i}. *{row['ticker']}* ({row['company_name'][:30]}...)\n"
                               f"   💰 ${row['total_buy_value']:,.2f} | "
                               f"📊 {row['buy_count']} txns | "
                               f"👥 {row['insider_count']} insider(s)"
                               for i, row in enumerate(top_buys, 1)
                           ])
                }
            }
        ]
    }
    
    requests.post(webhook_url, json=message)
```

**실제 알림 예시:**

```
📊 Daily Insider Trading Report

🟢 TOP 10 INSIDER BUYS (2025-12-27)
1. IONQ (IonQ, Inc.)
   💰 $23,050.00 | 📊 1 txns | 👥 1 insider(s)

2. AAPL (Apple Inc.)
   💰 $1,250,000.00 | 📊 5 txns | 👥 3 insider(s)

───────────────────────────

🔴 TOP 10 INSIDER SELLS (2025-12-27)
1. TSLA (Tesla, Inc.)
   💰 $5,000,000.00 | 📊 2 txns | 👥 1 insider(s)
```

------

## 🐳 Docker Compose 설정

**7개 컨테이너 구성:**

```yaml
services:
  mysql:           # 데이터 저장
  redis:           # 캐싱 + Celery 브로커
  zookeeper:       # Kafka 코디네이터
  kafka:           # 메시지 큐 (향후 사용)
  airflow-init:    # DB 초기화
  airflow-webserver:  # UI (http://localhost:8081)
  airflow-scheduler:  # DAG 스케줄러
  airflow-worker:     # Task 실행
```

**환경변수 전달 (중요!):**

```yaml
airflow-worker:
  environment:
    AIRFLOW__CORE__SQL_ALCHEMY_CONN: mysql+pymysql://admin:password@mysql:3306/insider_trading
    SLACK_WEBHOOK_URL: ${SLACK_WEBHOOK_URL}  # .env에서 로드
```

------

## 📊 실행 결과

### Crawler DAG 로그

```
📡 Fetching RSS from: https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&type=4&count=100
✅ Found 100 Form 4 filings

[1/100] 🔄 Parsing: urn:tag:sec.gov,2008:accession-number=0001193125-25-331321
  📊 IONQ - IonQ, Inc.
  👤 Chou Kathryn K. (Director)
  💼 2 transaction(s)
  ✅ Saved to MySQL
    - OPTION: 5,000 shares @ $4.61 = $23,050.00
    - SELL: 5,000 shares @ $55.00 = $275,000.00

================================================================================
📊 PROCESSING SUMMARY
================================================================================
  ✅ Success: 92
  ⏭️  Duplicates: 8
  ❌ Errors: 0
  📋 Total: 100
================================================================================
```

### Ranking DAG 로그

```
📊 Calculating top 10 BUY transactions for today
✅ Found 15 companies with BUY transactions
  1. AAPL (Apple Inc.): $5,000,000.00 (10 transactions, 5 insiders)
  2. TSLA (Tesla, Inc.): $3,200,000.00 (8 transactions, 4 insiders)
  ...

✅ Slack notification sent successfully
```

------

## 🚧 트러블슈팅

### 문제 1: accession_number VARCHAR(50) → 데이터 길이 초과

**증상:**

```
Error: (1406, "Data too long for column 'accession_number' at row 1")
```

**원인:**
SEC의 accession_number는 실제로 66자까지 가능 (`urn:tag:sec.gov,2008:accession-number=0001193125-25-331321`)

**해결:**

```sql
ALTER TABLE insider_trades 
MODIFY COLUMN accession_number VARCHAR(100) NOT NULL;
```

------

### 문제 2: 같은 Form 4에서 여러 거래 중복 에러

**증상:**

```
IntegrityError: (1062, "Duplicate entry ... for key 'accession_number'")
```

**원인:**
한 Form 4에 여러 거래가 있는데, 모두 같은 `accession_number` 사용

**해결:**

```python
# UNIQUE 제약조건 제거
ALTER TABLE insider_trades DROP INDEX accession_number;

# 일반 INDEX로 변경
CREATE INDEX idx_accession_number ON insider_trades(accession_number);
```

------

### 문제 3: Slack 알림 안 옴

**증상:**

```
WARNING - ⚠️ SLACK_WEBHOOK_URL not set, skipping notification
```

**원인:**
환경변수가 Docker 컨테이너에 전달 안 됨

**해결:**

1. `.env` 파일 생성:

```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

1. `docker-compose.yml`에 추가:

```yaml
airflow-worker:
  environment:
    SLACK_WEBHOOK_URL: ${SLACK_WEBHOOK_URL}
```

1. 재시작:

```bash
docker-compose down
docker-compose up -d
```

------

## 📈 성능 최적화

### 1. Rate Limiting

SEC는 초당 10 request 제한:

```python
for filing in filings:
    time.sleep(0.15)  # 6.67 req/sec → 안전
    parse_form4(filing)
```

### 2. MySQL 인덱스

```sql
-- 조회 성능 향상
CREATE INDEX idx_ticker ON insider_trades(ticker);
CREATE INDEX idx_filing_date ON insider_trades(filing_date);
CREATE INDEX idx_transaction_type ON insider_trades(transaction_type);

-- 복합 인덱스 (날짜 + 타입 필터링)
CREATE INDEX idx_date_type ON insider_trades(transaction_date, transaction_type);
```

### 3. 중복 체크 최적화

```python
def _is_duplicate(self, cursor, accession_number: str) -> bool:
    sql = "SELECT 1 FROM insider_trades WHERE accession_number = %s LIMIT 1"
    cursor.execute(sql, (accession_number,))
    return cursor.fetchone() is not None  # EXISTS 대신 SELECT 1 사용
```

------

## 🎯 향후 개선 사항

### 1. Reddit 감성 분석 통합

- r/wallstreetbets 크롤링
- FinBERT로 감성 점수 계산
- 내부자 거래 + Reddit 감성 결합

### 2. Kafka 실시간 스트리밍

```
SEC RSS → Airflow → Kafka Producer → Kafka Consumer → MySQL/Redis
```

### 3. FastAPI 대시보드

- 실시간 차트 (Chart.js)
- 티커별 내부자 거래 히스토리
- 알림 설정 UI

### 4. 클라우드 배포

- AWS ECS / GCP Cloud Run
- 24/7 자동 실행
- PostgreSQL RDS

------

## 💡 배운 점

### 1. Airflow XCom의 활용

Task 간 데이터 전달을 XCom으로 깔끔하게 처리:

```python
# Producer Task
context['task_instance'].xcom_push(key='top_buys', value=results)

# Consumer Task
top_buys = context['task_instance'].xcom_pull(
    task_ids='calculate_top_buys',
    key='top_buys'
)
```

### 2. Docker Compose 환경변수 관리

`.env` 파일 + `${VARIABLE}` 조합으로 보안 향상

### 3. SEC EDGAR XML 파싱

- RSS는 index.html URL만 제공
- 실제 데이터는 ownership.xml
- 거래 코드(P, S, M) 매핑 필요

### 4. MySQL pymysql 트랜잭션 처리

```python
try:
    cursor.execute(sql)
    connection.commit()
except Exception as e:
    connection.rollback()
    raise
```

------

## 🔗 참고 자료

- [SEC EDGAR API](https://www.sec.gov/developer)
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [Slack Block Kit Builder](https://app.slack.com/block-kit-builder/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

------

## 📦 프로젝트 구조

```
insider-trading-agent/
├── airflow/
│   ├── dags/
│   │   ├── sec_form4_crawler.py       # 크롤러 DAG
│   │   └── daily_insider_ranking.py   # 랭킹 DAG
│   ├── plugins/
│   │   ├── parsers/
│   │   │   └── form4_parser.py        # XML 파서
│   │   └── database/
│   │       └── insider_db.py          # MySQL 핸들러
│   └── Dockerfile
├── scripts/
│   └── init_db.sql                    # DB 초기화
├── docker-compose.yml
├── .env
└── README.md
```

------

## 🎬 마무리

하루 만에 SEC 내부자 거래 모니터링 시스템을 구축했습니다. Airflow의 강력한 스케줄링 기능과 Docker Compose의 편리한 컨테이너 관리 덕분에 빠르게 프로토타입을 완성할 수 있었습니다.

**핵심 성과:**

- ✅ 30분마다 최신 100개 Form 4 자동 수집
- ✅ 일일 매수/매도 TOP 10 자동 계산
- ✅ Slack으로 매일 오후 6시 알림
- ✅ 비용 $0 (로컬 실행)

다음에는 Reddit 감성 분석을 추가해서 소셜 미디어 트렌드와 내부자 거래를 결합한 투자 시그널을 만들어보려고 합니다!

**GitHub:** [링크 추가]
**Tech Blog:** [링크 추가]

------

**Tags:** `#Airflow` `#DataEngineering` `#Python` `#Docker` `#SEC` `#InsiderTrading` `#FinTech` `#Slack` `#MySQL`



