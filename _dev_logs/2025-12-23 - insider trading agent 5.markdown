---
layout: post
title: "insider trading agent 4"
date: 2025-12-23
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:2px 2px 8px rgba(0,0,0,0.8);"
---



# 🚀 SEC 내부자 거래 모니터링 시스템 구축기 (1부)

## 📋 목차

1. [프로젝트 개요](#프로젝트-개요)
2. [시스템 아키텍처](#시스템-아키텍처)
3. [로컬 개발 환경 구축](#로컬-개발-환경-구축)
4. [크롤러 개발](#크롤러-개발)
5. [Airflow 파이프라인 구축](#airflow-파이프라인-구축)
6. [Slack 알림 연동](#slack-알림-연동)
7. [트러블슈팅](#트러블슈팅)
8. [다음 단계 (AWS 배포 이슈)](#다음-단계)

------

## 프로젝트 개요

### 🎯 목표

SEC(미국 증권거래위원회)에 공시되는 **모든 내부자 거래(Form 4)**를 실시간으로 크롤링하여:

- 대형주부터 중소형주까지 전체 커버
- 매일 매수/매도 상위 10개 기업 집계
- Slack으로 일일 리포트 자동 발송
- Yahoo Finance 가격 데이터로 거래 금액 계산

### 🛠 기술 스택

- **크롤링**: Python, Requests, BeautifulSoup, feedparser
- **데이터베이스**: MySQL 8.0 (Docker)
- **파이프라인**: Apache Airflow 2.8
- **가격 조회**: Yahoo Finance API (yfinance)
- **알림**: Slack Webhook
- **인프라**: Docker Compose
- **스케줄링**: macOS launchd (로컬) / Cron (서버)

------

## 시스템 아키텍처

### 최종 아키텍처

```
┌─────────────────────────────────────┐
│  SEC RSS Feed (매 30분)              │
│  - 최신 100개 Form 4 공시            │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  로컬 크롤러 (local_crawler.py)      │
│  - RSS 파싱                         │
│  - XML 다운로드 & 파싱              │
│  - Yahoo Finance 가격 조회          │
│  - 중복 체크                        │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  MySQL (Docker)                     │
│  - insider_trades 테이블            │
│  - created_at_kst (KST 자동 변환)   │
└──────────────┬──────────────────────┘
               ↓
┌─────────────────────────────────────┐
│  Airflow DAG (매일 18:18 KST)       │
│  - 오늘 크롤링 데이터 집계          │
│  - TOP 10 매수/매도 계산            │
│  - Slack 알림 전송                  │
└──────────────┬──────────────────────┘
               ↓
          Slack 채널
```

### 데이터 흐름

1. **30분마다**: RSS 크롤러가 최신 100개 Form 4 수집
2. **실시간**: MySQL에 저장 (중복 자동 제거)
3. **매일 18:18**: Airflow가 당일 데이터 집계
4. **즉시**: Slack으로 리포트 발송

------

## 로컬 개발 환경 구축

### 1. 프로젝트 구조

```
insider-trading-agent/
├── docker-compose.yml          # Docker 서비스 정의
├── .env                        # 환경변수 (Slack Webhook)
├── local_crawler.py            # RSS 크롤러 (메인)
├── local_api_crawler.py        # API 크롤러 (테스트용)
├── scripts/
│   └── init_db.sql            # MySQL 초기화 스크립트
├── data/
│   └── sp500_ciks.json        # S&P 500 CIK 캐시
├── airflow/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── dags/
│   │   ├── daily_insider_ranking.py  # 랭킹 DAG
│   │   └── sec_api_crawler.py        # 크롤러 DAG (미사용)
│   └── plugins/
│       ├── database/
│       │   └── insider_db.py         # MySQL 연결
│       ├── parsers/
│       │   └── form4_parser.py       # Form 4 XML 파서
│       ├── sec_api/
│       │   ├── client.py             # SEC API 클라이언트
│       │   ├── parser.py             # XML 파서
│       │   └── company_list.py       # S&P 500 관리
│       └── price_fetcher.py          # Yahoo Finance
└── logs/
    ├── crawler_stdout.log
    └── crawler_stderr.log
```

### 2. Docker Compose 설정

**docker-compose.yml**

```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: insider-mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: insider_trading
      MYSQL_USER: admin
      MYSQL_PASSWORD: password
    ports:
      - "3308:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./scripts/init_db.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - insider-network

  redis:
    image: redis:7-alpine
    container_name: insider-redis
    command: redis-server --requirepass redispassword
    ports:
      - "6379:6379"
    networks:
      - insider-network

  airflow-webserver:
    build: ./airflow
    container_name: insider-airflow-webserver
    environment:
      AIRFLOW__CORE__EXECUTOR: CeleryExecutor
      AIRFLOW__CORE__SQL_ALCHEMY_CONN: mysql+pymysql://admin:password@mysql:3306/insider_trading
      AIRFLOW__CELERY__BROKER_URL: redis://:redispassword@redis:6379/0
      SLACK_WEBHOOK_URL: ${SLACK_WEBHOOK_URL}
    ports:
      - "8081:8080"
    volumes:
      - ./airflow/dags:/opt/airflow/dags
      - ./airflow/plugins:/opt/airflow/plugins
      - ./data:/opt/airflow/data
    networks:
      - insider-network

  # airflow-scheduler, airflow-worker도 동일한 구조

networks:
  insider-network:
    driver: bridge

volumes:
  mysql_data:
```

### 3. MySQL 스키마

**scripts/init_db.sql**

```sql
CREATE TABLE IF NOT EXISTS insider_trades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    accession_number VARCHAR(255) UNIQUE NOT NULL,
    ticker VARCHAR(20),
    company_name VARCHAR(255),
    insider_name VARCHAR(255),
    insider_title VARCHAR(255),
    transaction_date DATE,
    transaction_type ENUM('BUY','SELL','OPTION','GRANT','GIFT','OTHER') NOT NULL,
    shares INT,
    price_per_share DECIMAL(10, 2),
    transaction_value DECIMAL(15, 2),
    shares_owned_after INT,
    filing_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 🔥 KST 자동 변환 (GENERATED COLUMN)
    created_at_kst TIMESTAMP GENERATED ALWAYS AS 
        (CONVERT_TZ(created_at, '+00:00', '+09:00')) STORED,
    
    INDEX idx_ticker (ticker),
    INDEX idx_transaction_date (transaction_date),
    INDEX idx_created_at_kst (created_at_kst),
    INDEX idx_transaction_value (transaction_value)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**핵심 포인트:**

- `created_at_kst`: UTC → KST 자동 변환 (쿼리 성능 향상)
- `accession_number`: UNIQUE 제약으로 중복 방지
- ENUM 타입: `GRANT` 추가 (RSU 지급 처리)

------

## 크롤러 개발

### 1. RSS vs API 방식 비교

| 항목       | RSS 방식 ⭐    | API 방식                |
| ---------- | ------------- | ----------------------- |
| 커버리지   | **모든 회사** | 지정한 회사만           |
| 1회 수집량 | 100개 공시    | 50개 회사 × 5개 = 250개 |
| 신규 비율  | 92%           | 20% (중복 많음)         |
| 속도       | 빠름 (~2분)   | 느림 (~5분)             |
| 무명 기업  | ✅ 포함        | ❌ 제외                  |

**결론:** RSS 방식 채택 ✅

### 2. RSS 크롤러 구현

**local_crawler.py (핵심 코드)**

```python
import feedparser
import requests
from datetime import datetime
import pytz

KST = pytz.timezone('Asia/Seoul')

def main():
    # SEC RSS 피드
    url = "https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&type=4&count=100&output=atom"
    
    headers = {
        'User-Agent': 'MyCompany contact@example.com',
        'Accept': 'application/atom+xml',
    }
    
    response = requests.get(url, headers=headers, timeout=30)
    feed = feedparser.parse(response.content)
    
    print(f"✅ Found {len(feed.entries)} Form 4 filings")
    
    # MySQL 연결
    db = InsiderTradesDB(
        host='localhost',
        port=3308,
        user='admin',
        password='password',
        database='insider_trading'
    )
    
    parser = Form4Parser()
    price_fetcher = StockPriceFetcher()
    
    for i, entry in enumerate(feed.entries, 1):
        accession_number = entry.id.split('/')[-1]
        index_url = entry.link
        
        # 중복 체크 (가장 먼저!)
        if db.is_duplicate(accession_number):
            continue
        
        # Rate limiting (SEC 규정: 10 req/sec)
        time.sleep(0.15)
        
        # XML 파싱
        parsed_data = parser.parse_form4(index_url)
        
        if not parsed_data:
            continue
        
        # 🔥 가격 보정 (Yahoo Finance)
        transactions = parsed_data.get('transactions', [])
        for trans in transactions:
            if trans.get('price_per_share', 0) == 0 and \
               trans.get('transaction_type') in ['BUY', 'SELL']:
                
                ticker = parsed_data['issuer'].get('ticker')
                trans_date = trans.get('transaction_date')
                
                if ticker and trans_date:
                    price = price_fetcher.get_closing_price_with_retry(
                        ticker, trans_date
                    )
                    
                    if price:
                        trans['price_per_share'] = price
                        trans['transaction_value'] = trans['shares'] * price
        
        # MySQL 저장
        db.insert_filing(accession_number, parsed_data)
```

### 3. Form 4 XML 파서 개선

**핵심 문제:** RSS는 index.htm URL만 제공 → XML URL을 찾아야 함

**해결책: 4단계 폴백**

```python
def get_xml_url_from_index(self, index_url: str):
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # 방법 1: ownership.xml 링크 직접 찾기
    for link in soup.find_all('a', href=True):
        if 'ownership.xml' in link['href'].lower():
            return self._build_absolute_url(link['href'])
    
    # 방법 2: .xml 파일 찾기
    for link in soup.find_all('a', href=True):
        if link['href'].endswith('.xml'):
            return self._build_absolute_url(link['href'])
    
    # 방법 3: 테이블에서 XML 타입 찾기
    for table in soup.find_all('table'):
        for row in table.find_all('tr'):
            if 'xml' in row.get_text().lower():
                link = row.find('a', href=True)
                if link:
                    return self._build_absolute_url(link['href'])
    
    # 방법 4: Accession number로 추측 후 HEAD 요청
    match = re.search(r'/(\d{10}-\d{2}-\d{6})/', index_url)
    if match:
        accession = match.group(1)
        base_url = '/'.join(index_url.split('/')[:-1])
        
        for filename in ['ownership.xml', f'{accession}.xml']:
            test_url = f"{base_url}/{filename}"
            if requests.head(test_url).status_code == 200:
                return test_url
    
    return None
```

**성공률:** ~70% (30%는 XML이 없거나 다른 구조)

### 4. Yahoo Finance 가격 조회

**문제:** SEC XML에 가격이 없는 경우 많음 (특히 BUY/SELL)

**해결:**

```python
class StockPriceFetcher:
    def get_closing_price_with_retry(self, ticker, date, max_retries=3):
        """재시도 로직 포함"""
        for attempt in range(max_retries):
            try:
                stock = yf.Ticker(ticker)
                hist = stock.history(
                    start=date,
                    end=(datetime.strptime(date, '%Y-%m-%d') + 
                         timedelta(days=3)).strftime('%Y-%m-%d')
                )
                
                if not hist.empty:
                    return round(hist['Close'].iloc[0], 2)
                    
            except Exception as e:
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
                    continue
                    
        return None
```

------

## Airflow 파이프라인 구축

### 1. DAG 구조

**daily_insider_ranking.py**

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import pytz

KST = pytz.timezone('Asia/Seoul')

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2026, 1, 1, tzinfo=KST),
    'retries': 1,
    'retry_delay': timedelta(minutes=10),
}

dag = DAG(
    'daily_insider_ranking',
    default_args=default_args,
    description='Calculate top 10 insider buy/sell rankings',
    schedule_interval='18 9 * * *',  # UTC 09:18 = KST 18:18
    catchup=False,
    tags=['insider-trading', 'ranking', 'daily'],
)

# Tasks
task_top_buys = PythonOperator(
    task_id='calculate_top_buys',
    python_callable=calculate_top_buys,
    dag=dag,
)

task_top_sells = PythonOperator(
    task_id='calculate_top_sells',
    python_callable=calculate_top_sells,
    dag=dag,
)

task_slack = PythonOperator(
    task_id='send_slack_notification',
    python_callable=send_slack_notification,
    dag=dag,
)

# Dependencies
[task_top_buys, task_top_sells] >> task_slack
```

### 2. 랭킹 계산 로직

**핵심 쿼리:**

```python
def calculate_top_buys(**context):
    today_kst = datetime.now(KST).strftime('%Y-%m-%d')
    
    sql = f"""
        SELECT 
            ticker,
            company_name,
            COUNT(*) as buy_count,
            SUM(shares) as total_shares,
            ROUND(AVG(price_per_share), 2) as avg_price,
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
```

**포인트:**

- `created_at_kst` 사용 (GENERATED COLUMN)
- `transaction_value > 0` (가격 있는 것만)
- `GROUP_CONCAT`으로 내부자 이름 집계

------

## Slack 알림 연동

### 1. Webhook 설정

```bash
# .env 파일
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### 2. 메시지 포맷

```python
def send_slack_notification(**context):
    top_buys = context['task_instance'].xcom_pull(
        task_ids='calculate_top_buys',
        key='top_buys'
    )
    
    # 매수 섹션
    buy_text = "*🟢 TOP 10 INSIDER BUYS*\n"
    for i, row in enumerate(top_buys, 1):
        emoji = "🔥" if row['total_buy_value'] >= 10000000 else "⭐"
        
        buy_text += (
            f"{i}. {emoji} *{row['ticker']}* - {row['company_name'][:40]}\n"
            f"   💰 *${row['total_buy_value']:,.0f}* "
            f"({row['total_shares']:,} shares @ ${row['avg_price']})\n"
            f"   📊 {row['buy_count']} txn(s) | "
            f"👥 {row['insider_count']} insider(s)\n\n"
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
                "text": {"type": "mrkdwn", "text": buy_text}
            },
            # ... 매도 섹션, 인사이트 섹션
        ]
    }
    
    requests.post(webhook_url, json=message)
```

### 3. 실제 알림 예시

```
📊 Daily Insider Trading Report

🟢 TOP 10 INSIDER BUYS (Crawled Today)
1. 💎 LOW - LOWES COMPANIES INC
   💰 $228,760 (1,000 shares @ $228.76)
   📊 1 txn(s) | 👥 1 insider(s)

2. ⭐ NMCO - Nuveen Municipal Credit Opportunities Fund
   💰 $83,025 (1,500 shares @ $55.35)
   📊 1 txn(s) | 👥 1 insider(s)

🔴 TOP 10 INSIDER SELLS (Crawled Today)
1. 🚨 AVGO - Broadcom Inc.
   💸 $10,614,617 (30,178 shares @ $350.73)
   📊 2 txn(s) | 👥 2 insider(s)

2. ⚠️ DHR - DANAHER CORP /DE/
   💸 $8,272,960 (35,899 shares @ $230.45)
   📊 1 txn(s) | 👥 1 insider(s)

💡 Key Insights
⚠️ Heavy selling activity (Sell/Buy: 127.8x)
🔥 Highest Buy: LOW ($228,760)
🚨 Highest Sell: AVGO ($10,614,617)

📅 Crawled: 2026-01-03 | 💰 Prices via Yahoo Finance
```

------

## 트러블슈팅

### 1. Docker yfinance 모듈 없음

**문제:**

```
Broken plugin: No module named 'yfinance'
```

**해결:**

```bash
# airflow/requirements.txt에 추가
yfinance==0.2.33
multitasking>=0.0.11

# 재빌드
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 2. launchd 크롤러가 실행 안 됨

**문제:** PID는 있는데 로그가 없음

**원인:**

- 파일 경로 오류 (`local_crawler.py` vs `local_api_crawler.py`)
- 로그 경로가 `/tmp`로 설정됨
- `WorkingDirectory` 누락

**해결:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.insider.crawler</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/kang/miniconda3/bin/python3</string>
        <string>/Users/kang/insider-trading-agent/local_crawler.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/Users/kang/insider-trading-agent</string>
    <key>StartInterval</key>
    <integer>1800</integer>
    <key>StandardOutPath</key>
    <string>/Users/kang/insider-trading-agent/logs/crawler_stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/kang/insider-trading-agent/logs/crawler_stderr.log</string>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
# 재등록
launchctl unload ~/Library/LaunchAgents/com.insider.crawler.plist
launchctl load ~/Library/LaunchAgents/com.insider.crawler.plist
```

### 3. MySQL ENUM 타입 에러

**문제:**

```
Data truncated for column 'transaction_type' at row 1
```

**원인:** `GRANT` 타입이 ENUM에 없음

**해결:**

```sql
ALTER TABLE insider_trades 
MODIFY COLUMN transaction_type 
ENUM('BUY','SELL','OPTION','GRANT','GIFT','OTHER') NOT NULL;
```

### 4. Timezone 혼란 (UTC vs KST)

**문제:** `WHERE DATE(created_at) = '2025-12-28'` (UTC)로 쿼리하면 한국 아침 데이터 누락

**해결:** MySQL GENERATED COLUMN

```sql
created_at_kst TIMESTAMP GENERATED ALWAYS AS 
    (CONVERT_TZ(created_at, '+00:00', '+09:00')) STORED
```

**쿼리:**

```sql
WHERE DATE(created_at_kst) = CURDATE()
```

### 5. Slack Webhook 환경변수 전달 안 됨

**문제:** `SLACK_WEBHOOK_URL not set`

**원인:** docker-compose.yml에 환경변수 누락

**해결:**

```yaml
airflow-worker:
  environment:
    SLACK_WEBHOOK_URL: ${SLACK_WEBHOOK_URL}  # 추가!
```

------

## 성능 및 통계

### 크롤링 성능

```
- 1회 실행 시간: ~2분
- 처리량: 100개 공시
- 신규 데이터: 5-25건/회 (95-75% 중복)
- 가격 조회 성공률: ~70%
- 일일 신규 데이터: 150-300건
```

### 데이터 품질

```sql
SELECT 
    DATE(created_at_kst) as date,
    COUNT(*) as total,
    COUNT(CASE WHEN price_per_share > 0 THEN 1 END) as with_price,
    ROUND(COUNT(CASE WHEN price_per_share > 0 THEN 1 END) * 100.0 / COUNT(*), 1) 
        as price_coverage
FROM insider_trades
WHERE created_at_kst >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY DATE(created_at_kst);
```

**결과:**

- 전체 커버리지: 100% (모든 Form 4)
- 가격 데이터: 70-80% (BUY/SELL만)
- 중복 제거율: 99.9% (UNIQUE 제약)

------

## 다음 단계

### AWS EC2 배포 시도 및 이슈

**목표:** 24/7 자동 크롤링

**시도 과정:**

1. ✅ EC2 인스턴스 생성 (t3.micro → t3.small)
2. ✅ Docker & Docker Compose 설치
3. ✅ 프로젝트 파일 전송 (scp)
4. ✅ 보안 그룹 설정 (SSH, 8081, 3308)
5. ✅ MySQL 컨테이너 실행
6. ❌ Airflow 시작 실패

**발생한 문제들:**

**1. 메모리 부족 (t3.micro)**

```
1GB RAM에 7개 컨테이너
→ 시스템 멈춤, SSH 타임아웃
→ t3.small (2GB) 업그레이드
```

**2. Airflow 로그 권한 에러**

```
PermissionError: [Errno 13] Permission denied: 
'/opt/airflow/logs/scheduler/2026-01-03'

해결 시도:
sudo chown -R 50000:50000 airflow/logs
```

**3. MySQL 접근 권한**

```
(1130, "172.18.0.8 is not allowed to connect to this MySQL server")

해결 시도:
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';
```

**4. Airflow 컨테이너 로그 없음**

```
docker logs insider-airflow-webserver
→ 완전히 비어있음 (entrypoint 실행 안 됨)
```

**5. 반복적인 렉/타임아웃**

- EC2 SSH 연결 불안정
- Docker 명령어 응답 없음
- 브라우저 접속 실패

### 대안 검토 중

**1. Oracle Cloud Free Tier**

- VM 2개 무료 (평생)
- 1GB RAM × 2
- ARM 아키텍처 고려 필요

**2. Google Cloud Run + Cloud Scheduler**

- 서버리스 컨테이너
- Cloud Scheduler로 트리거
- 무료 한도 내 충분

**3. Fly.io / Railway**

- 무료/저렴한 호스팅
- Docker 직접 배포
- 자동 스케일링

**4. 로컬 맥북 유지**

- launchd로 자동 실행
- 안정적 작동
- 단점: 맥북 꺼지면 중단

------

## 배운 점

### 기술적 성과

1. ✅ **SEC RSS 크롤링** 완전 자동화
2. ✅ **Yahoo Finance 가격 조회** 통합
3. ✅ **MySQL Timezone 처리** (GENERATED COLUMN)
4. ✅ **Airflow 파이프라인** 구축
5. ✅ **Slack 알림** 자동화
6. ✅ **중복 제거** 로직 완성

### 트러블슈팅 경험

1. Docker 네트워크 환경변수 전달
2. launchd plist 디버깅
3. MySQL 권한 관리
4. Airflow 로그 권한 이슈
5. EC2 메모리 부족 대응

### 미완성 과제

1. ❌ AWS EC2 안정적 배포
2. ⏸️ Kafka 스트리밍 파이프라인
3. ⏸️ FastAPI 대시보드
4. ⏸️ ML 패턴 분석

------

## 소스 코드

**GitHub:** [링크 예정]

**주요 파일:**

- `local_crawler.py`: RSS 크롤러 메인
- `airflow/dags/daily_insider_ranking.py`: Airflow DAG
- `airflow/plugins/parsers/form4_parser.py`: XML 파서
- `airflow/plugins/price_fetcher.py`: Yahoo Finance
- `scripts/init_db.sql`: MySQL 스키마

------

## 마무리

**현재 상태:**

- ✅ 로컬 환경에서 완벽 작동
- ✅ 30분마다 자동 크롤링
- ✅ 매일 18:18 Slack 리포트
- ⚠️ 서버 배포 진행 중

**다음 글 예고:**

- 대안 클라우드 플랫폼 비교
- 최종 배포 및 운영
- 대시보드 구축
- 실제 투자 인사이트 분석

------

**작성일:** 2026년 1월 3일
**태그:** #SEC #InsiderTrading #Airflow #Docker #Python #Crawling





![image-20260103194019075](/assets/img/image-20260103194019075.png)

