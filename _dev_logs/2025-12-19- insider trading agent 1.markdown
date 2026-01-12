---
layout: post
title: "insider trading agent 1"
date: 2025-12-19
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:2px 2px 8px rgba(0,0,0,0.8);"
---



# Insider Trading Alert Agent 개발기 - Day 1: 인프라 구축과 SEC 크롤러 구현

## 📌 프로젝트 개요

**목표**: SEC Form 4(내부자 거래 공시)를 실시간으로 모니터링하고, Reddit/Twitter 감성분석과 결합하여 Slack으로 알림을 보내는 AI Agent 시스템 구축

**기술 스택**:

- **Orchestration**: Apache Airflow
- **Message Queue**: Apache Kafka
- **Database**: MySQL 8.0
- **Cache/Ranking**: Redis
- **Containerization**: Docker, Docker Compose
- **언어**: Python 3.11

------

## 🎯 오늘의 목표

1. ✅ 프로젝트 구조 설계 및 GitHub Repository 세팅
2. ✅ Docker 기반 인프라 구축 (MySQL, Redis, Kafka, Zookeeper)
3. ✅ MySQL 데이터베이스 스키마 설계
4. ✅ Apache Airflow 환경 구축
5. ✅ SEC Form 4 크롤러 DAG 구현 및 테스트

------

## 1. 프로젝트 구조 설계

### 1-1. 디렉토리 구조

```
insider-trading-agent/
├── .github/
│   └── workflows/          # CI/CD (향후 추가)
├── airflow/
│   ├── dags/
│   │   └── sec_form4_crawler.py
│   ├── logs/
│   ├── plugins/
│   ├── Dockerfile
│   └── requirements.txt
├── kafka/
│   ├── producer/           # Kafka Producer (향후 구현)
│   └── consumer/           # Kafka Consumer (향후 구현)
├── api/                    # FastAPI Dashboard (향후 구현)
├── scripts/
│   └── init_db.sql        # MySQL 초기화 스크립트
├── docker-compose.yml
├── .env
├── .gitignore
└── README.md
```

### 1-2. 시스템 아키텍처

```
┌─────────────┐
│  SEC EDGAR  │ ← RSS Feed
└──────┬──────┘
       ↓
┌─────────────┐
│   Airflow   │ ← DAG Scheduler (30분마다)
└──────┬──────┘
       ↓
┌─────────────┐
│    Kafka    │ ← Event Streaming
└──────┬──────┘
       ↓
┌──────┴──────────┐
│                 │
↓                 ↓
[Consumer 1]   [Consumer 2]
MySQL 저장     감성분석
│                 │
↓                 ↓
Redis 랭킹      Slack 알림
```

------

## 2. GitHub Repository 초기 세팅

### 2-1. Git 초기화 및 기본 파일 생성

```bash
mkdir insider-trading-agent
cd insider-trading-agent
git init

# README.md 생성
cat > README.md << 'EOF'
# Insider Trading Alert Agent 🚨

Real-time monitoring system for SEC Form 4 insider trading filings 
with community sentiment analysis.

## Features
- 🔍 Real-time SEC Form 4 monitoring
- 📊 Reddit/Twitter sentiment analysis
- ⚡ Kafka-based event streaming
- 🔔 Slack alerts for top insider trades
- 📈 FastAPI dashboard

## Tech Stack
- **Orchestration**: Apache Airflow
- **Streaming**: Apache Kafka
- **Cache/Ranking**: Redis
- **Database**: MySQL
- **API**: FastAPI
- **Container**: Docker, Docker Compose
EOF
```

### 2-2. .gitignore 설정

```bash
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
.Python
venv/

# Airflow
airflow/logs/
airflow/airflow.db

# Environment
.env
.env.local

# Database
*.sql.gz

# OS
.DS_Store
EOF
```

### 2-3. 환경 변수 템플릿

```bash
cat > .env.example << 'EOF'
# MySQL
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=insider_trading
MYSQL_USER=admin
MYSQL_PASSWORD=password

# Redis
REDIS_PASSWORD=redispassword

# Airflow
AIRFLOW__CORE__EXECUTOR=CeleryExecutor
AIRFLOW__CORE__SQL_ALCHEMY_CONN=mysql+pymysql://admin:password@mysql:3306/insider_trading

# Kafka
KAFKA_BROKER_ID=1
KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181

# Slack (향후 설정)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
EOF

cp .env.example .env
```

------

## 3. MySQL 데이터베이스 스키마 설계

### 3-1. 테이블 설계 철학

내부자 거래 데이터는 다음과 같은 특징이 있습니다:

- **시계열 데이터**: 거래 날짜가 중요
- **고유성**: accession_number로 중복 방지
- **관계형**: 여러 테이블 간 JOIN 필요

### 3-2. 핵심 테이블 5개

```sql
-- 1. insider_trades: 내부자 거래 메인 테이블
CREATE TABLE insider_trades (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    -- SEC Filing 정보
    accession_number VARCHAR(50) UNIQUE NOT NULL,
    filing_date DATE NOT NULL,
    
    -- 기업 정보
    ticker VARCHAR(10) NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    cik VARCHAR(20),
    
    -- 내부자 정보
    insider_name VARCHAR(255) NOT NULL,
    insider_relationship VARCHAR(100),  -- CEO, CFO, Director 등
    is_director BOOLEAN DEFAULT FALSE,
    is_officer BOOLEAN DEFAULT FALSE,
    
    -- 거래 정보
    transaction_date DATE NOT NULL,
    transaction_code VARCHAR(10),
    transaction_type ENUM('BUY','SELL','OPTION','GIFT','OTHER'),
    shares BIGINT NOT NULL,
    price_per_share DECIMAL(15,4),
    transaction_value DECIMAL(20,2),
    shares_owned_after BIGINT,
    
    -- 메타데이터
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- 인덱스
    INDEX idx_ticker (ticker),
    INDEX idx_filing_date (filing_date),
    INDEX idx_transaction_type (transaction_type)
);

-- 2. reddit_mentions: 커뮤니티 감성 데이터
CREATE TABLE reddit_mentions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ticker VARCHAR(10) NOT NULL,
    post_id VARCHAR(50) UNIQUE NOT NULL,
    subreddit VARCHAR(100),
    title TEXT,
    sentiment ENUM('POSITIVE','NEGATIVE','NEUTRAL'),
    sentiment_score DECIMAL(5,4),
    posted_at TIMESTAMP NOT NULL,
    INDEX idx_ticker (ticker)
);

-- 3. daily_rankings: 일별 상위 거래 (Redis 백업용)
CREATE TABLE daily_rankings (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ranking_date DATE NOT NULL,
    rank_position INT NOT NULL,
    ticker VARCHAR(10) NOT NULL,
    insider_name VARCHAR(255),
    total_buy_value DECIMAL(20,2),
    UNIQUE KEY unique_daily_rank (ranking_date, rank_position)
);

-- 4. slack_alerts: 알림 로그
CREATE TABLE slack_alerts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ticker VARCHAR(10) NOT NULL,
    alert_type ENUM('LARGE_BUY','MULTIPLE_INSIDERS','HIGH_SENTIMENT'),
    alert_message TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. processing_status: 멱등성 보장
CREATE TABLE processing_status (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    accession_number VARCHAR(50) UNIQUE NOT NULL,
    status ENUM('PENDING','PROCESSING','COMPLETED','FAILED'),
    processed_at TIMESTAMP NULL,
    INDEX idx_status (status)
);
```

### 3-3. 샘플 데이터 삽입

```sql
INSERT INTO insider_trades (
    accession_number, filing_date, ticker, company_name, cik,
    insider_name, insider_relationship, is_officer,
    transaction_date, transaction_code, transaction_type,
    shares, price_per_share, transaction_value
) VALUES (
    '0001234567-25-000001',
    '2025-01-15',
    'NVDA',
    'NVIDIA Corporation',
    '0001234567',
    'Jensen Huang',
    'CEO',
    TRUE,
    '2025-01-14',
    'P',
    'BUY',
    10000,
    500.00,
    5000000.00
);
```

------

## 4. Docker Compose 인프라 구축

### 4-1. 포트 충돌 해결 과정

**문제**: 로컬 환경에 MySQL(3306), Airflow Webserver(8080)가 이미 실행 중

**해결**:

- MySQL: `3308:3306` (로컬 3308 포트로 매핑)
- Airflow: `8081:8080` (로컬 8081 포트로 매핑)

```bash
# 포트 사용 확인
lsof -i :3306
lsof -i :8080

# 대안 포트로 변경
```

### 4-2. docker-compose.yml 최종 버전

```yaml
services:
  # MySQL 8.0
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
    command: --default-authentication-plugin=mysql_native_password

  # Redis
  redis:
    image: redis:7-alpine
    container_name: insider-redis
    command: redis-server --requirepass redispassword
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - insider-network

  # Zookeeper (Kafka 의존성)
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: insider-zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    networks:
      - insider-network

  # Kafka
  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: insider-kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    networks:
      - insider-network

  # Airflow Init (DB 마이그레이션 & 사용자 생성)
  airflow-init:
    build: ./airflow
    container_name: insider-airflow-init
    depends_on:
      - mysql
      - redis
    environment:
      AIRFLOW__CORE__EXECUTOR: CeleryExecutor
      AIRFLOW__CORE__SQL_ALCHEMY_CONN: mysql+pymysql://admin:password@mysql:3306/insider_trading
      _AIRFLOW_DB_MIGRATE: 'true'
      _AIRFLOW_WWW_USER_CREATE: 'true'
      _AIRFLOW_WWW_USER_USERNAME: admin
      _AIRFLOW_WWW_USER_PASSWORD: admin
    volumes:
      - ./airflow/dags:/opt/airflow/dags
      - ./airflow/logs:/opt/airflow/logs
    networks:
      - insider-network
    command:
      - -c
      - |
        airflow db migrate
        airflow users create \
          --username admin \
          --password admin \
          --firstname Admin \
          --lastname User \
          --role Admin \
          --email admin@example.com || true

  # Airflow Webserver
  airflow-webserver:
    build: ./airflow
    container_name: insider-airflow-webserver
    depends_on:
      - airflow-init
    ports:
      - "8081:8080"  # 포트 충돌 회피
    volumes:
      - ./airflow/dags:/opt/airflow/dags
      - ./airflow/logs:/opt/airflow/logs
    networks:
      - insider-network
    command: webserver

  # Airflow Scheduler
  airflow-scheduler:
    build: ./airflow
    container_name: insider-airflow-scheduler
    depends_on:
      - airflow-init
    volumes:
      - ./airflow/dags:/opt/airflow/dags
      - ./airflow/logs:/opt/airflow/logs
    networks:
      - insider-network
    command: scheduler

  # Airflow Worker (Celery Executor)
  airflow-worker:
    build: ./airflow
    container_name: insider-airflow-worker
    depends_on:
      - airflow-init
    volumes:
      - ./airflow/dags:/opt/airflow/dags
      - ./airflow/logs:/opt/airflow/logs
    networks:
      - insider-network
    command: celery worker

networks:
  insider-network:
    driver: bridge

volumes:
  mysql_data:
  redis_data:
```

### 4-3. 컨테이너 실행 및 확인

```bash
# 전체 서비스 시작
docker-compose up -d

# 상태 확인
docker-compose ps

# 결과:
# insider-mysql          Up      3308->3306/tcp
# insider-redis          Up      6379/tcp
# insider-kafka          Up      9092/tcp
# insider-zookeeper      Up      2181/tcp
# insider-airflow-*      Up      8081->8080/tcp
```

### 4-4. MySQL 접속 테스트

```bash
# MySQL 컨테이너 접속
docker exec -it insider-mysql mysql -u admin -ppassword -D insider_trading

# 테이블 확인
mysql> SHOW TABLES;
+---------------------------+
| Tables_in_insider_trading |
+---------------------------+
| daily_rankings            |
| insider_trades            |
| processing_status         |
| reddit_mentions           |
| slack_alerts              |
+---------------------------+

# 샘플 데이터 확인
mysql> SELECT ticker, insider_name, transaction_value 
       FROM insider_trades;
+--------+--------------+-------------------+
| ticker | insider_name | transaction_value |
+--------+--------------+-------------------+
| NVDA   | Jensen Huang |        5000000.00 |
+--------+--------------+-------------------+
```

------

## 5. Apache Airflow 환경 구축

### 5-1. Airflow Dockerfile

```dockerfile
FROM apache/airflow:2.8.1-python3.11

USER root

# 시스템 패키지 설치
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && apt-get clean

USER airflow

# Python 패키지 설치
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

# Airflow 설정
ENV AIRFLOW__CORE__LOAD_EXAMPLES=False
ENV AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION=True
```

### 5-2. requirements.txt

```txt
# Airflow
apache-airflow==2.8.1
apache-airflow-providers-mysql==5.5.0
apache-airflow-providers-redis==3.5.0

# Kafka
kafka-python==2.0.2

# Database
pymysql==1.1.0
cryptography==41.0.7

# Web scraping
requests==2.31.0
beautifulsoup4==4.12.3
lxml==5.1.0
feedparser==6.0.11

# Data processing
pandas==2.1.4
```

### 5-3. Airflow UI 접속

```
URL: http://localhost:8081
ID: admin
PW: admin
```

------

## 6. SEC Form 4 크롤러 DAG 구현

### 6-1. SEC Form 4란?

**Form 4 (Statement of Changes in Beneficial Ownership)**

- 회사 내부자(임원, 이사, 10% 이상 대주주)가 자사 주식을 매매할 때 제출
- **제출 기한**: 거래 후 2영업일 이내
- **공개 위치**: SEC EDGAR 시스템
- **중요성**: 내부자의 회사 전망에 대한 신호로 해석 가능

### 6-2. SEC EDGAR RSS 구조 분석

**RSS Feed URL**:

```
https://www.sec.gov/cgi-bin/browse-edgar?action=getcurrent&type=4&company=&dateb=&owner=include&start=0&count=100&output=atom
```

**주요 필드**:

- `entry.id`: Accession Number (고유 식별자)
- `entry.link`: Form 4 HTML 페이지 URL
- `entry.title`: 회사명 및 내부자 정보
- `entry.summary`: 제출 날짜, 파일 크기

**주의사항**: SEC는 **User-Agent 헤더**를 필수로 요구!

### 6-3. DAG 구현

```python
"""
SEC Form 4 Insider Trading Crawler DAG
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import feedparser
import requests
from bs4 import BeautifulSoup
import logging
import time

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2025, 1, 1),
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'sec_form4_crawler',
    default_args=default_args,
    description='Crawl SEC Form 4 insider trading filings',
    schedule_interval='*/30 * * * *',  # 30분마다 실행
    catchup=False,
    tags=['sec', 'insider-trading'],
)


def fetch_sec_rss(**context):
    """SEC EDGAR RSS 피드에서 최신 Form 4 가져오기"""
    
    logger = logging.getLogger(__name__)
    
    # SEC 요구사항: User-Agent 필수
    headers = {
        'User-Agent': 'InsiderTradingAgent/1.0 (your-email@example.com)',
        'Accept-Encoding': 'gzip, deflate',
        'Host': 'www.sec.gov'
    }
    
    rss_url = (
        "https://www.sec.gov/cgi-bin/browse-edgar"
        "?action=getcurrent&type=4&count=100&output=atom"
    )
    
    logger.info(f"Fetching RSS from: {rss_url}")
    
    # RSS 요청
    response = requests.get(rss_url, headers=headers, timeout=30)
    response.raise_for_status()
    
    logger.info(f"Response status: {response.status_code}")
    logger.info(f"Response length: {len(response.content)} bytes")
    
    # feedparser로 파싱
    feed = feedparser.parse(response.content)
    
    logger.info(f"Feed entries: {len(feed.entries)}")
    
    filings = []
    for entry in feed.entries:
        filing = {
            'accession_number': entry.id.split('/')[-1],
            'filing_url': entry.link,
            'title': entry.title,
            'company': entry.title.split('-')[0].strip(),
            'filed_at': entry.get('published', ''),
            'summary': entry.get('summary', ''),
        }
        filings.append(filing)
    
    logger.info(f"✅ Found {len(filings)} Form 4 filings")
    
    # XCom에 저장 (다음 Task로 전달)
    context['task_instance'].xcom_push(key='filings', value=filings)
    
    return len(filings)


def parse_form4_details(**context):
    """Form 4 상세 정보 파싱"""
    
    logger = logging.getLogger(__name__)
    
    # 이전 Task에서 데이터 가져오기
    filings = context['task_instance'].xcom_pull(
        task_ids='fetch_sec_rss',
        key='filings'
    )
    
    if not filings:
        logger.warning("No filings to process")
        return 0
    
    logger.info(f"Processing {len(filings)} filings")
    
    parsed_filings = []
    headers = {'User-Agent': 'InsiderTradingAgent/1.0'}
    
    # 처음 5개만 파싱 (테스트)
    for i, filing in enumerate(filings[:5]):
        try:
            logger.info(f"[{i+1}/5] Parsing: {filing['accession_number']}")
            
            # Rate limiting (SEC: 10 requests/sec)
            time.sleep(0.2)
            
            response = requests.get(
                filing['filing_url'],
                headers=headers,
                timeout=15
            )
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'lxml')
            
            # 간단한 정보만 추출 (향후 개선 예정)
            parsed = {
                'accession_number': filing['accession_number'],
                'company': filing['company'],
                'html_length': len(response.text),
                'parsed_at': datetime.now().isoformat(),
            }
            
            parsed_filings.append(parsed)
            logger.info(f"✅ Parsed: {filing['company']}")
            
        except Exception as e:
            logger.error(f"Error: {e}")
            continue
    
    logger.info(f"✅ Successfully parsed {len(parsed_filings)} filings")
    
    context['task_instance'].xcom_push(
        key='parsed_filings',
        value=parsed_filings
    )
    
    return len(parsed_filings)


def send_to_kafka(**context):
    """파싱된 데이터를 Kafka로 전송 (향후 구현)"""
    
    logger = logging.getLogger(__name__)
    
    parsed_filings = context['task_instance'].xcom_pull(
        task_ids='parse_form4_details',
        key='parsed_filings'
    )
    
    if not parsed_filings:
        logger.warning("No parsed filings to send")
        return 0
    
    # TODO: 실제 Kafka Producer 구현
    for filing in parsed_filings:
        logger.info(f"📤 [KAFKA] Would send: {filing['company']}")
    
    return len(parsed_filings)


# Task 정의
task_fetch = PythonOperator(
    task_id='fetch_sec_rss',
    python_callable=fetch_sec_rss,
    dag=dag,
)

task_parse = PythonOperator(
    task_id='parse_form4_details',
    python_callable=parse_form4_details,
    dag=dag,
)

task_kafka = PythonOperator(
    task_id='send_to_kafka',
    python_callable=send_to_kafka,
    dag=dag,
)

# Task 의존성 설정
task_fetch >> task_parse >> task_kafka
```

### 6-4. DAG 실행 결과

**Airflow UI에서 수동 실행 (Trigger DAG)**

#### Task 1: fetch_sec_rss

```
[2025-12-27, 03:22:42 UTC] INFO - Fetching RSS from: https://www.sec.gov/...
[2025-12-27, 03:22:43 UTC] INFO - Response status: 200
[2025-12-27, 03:22:43 UTC] INFO - Response length: 56083 bytes
[2025-12-27, 03:22:43 UTC] INFO - Feed entries: 100
[2025-12-27, 03:22:43 UTC] INFO - ✅ Found 100 Form 4 filings
```

#### Task 2: parse_form4_details

```
[2025-12-27, 03:22:43 UTC] INFO - Processing 100 filings
[2025-12-27, 03:22:43 UTC] INFO - [1/5] Parsing: urn:tag:sec.gov,2008:accession-number=0001193125-25-331321
[2025-12-27, 03:22:44 UTC] INFO - ✅ Parsed: IonQ, Inc.
...
[2025-12-27, 03:22:45 UTC] INFO - ✅ Successfully parsed 5 filings
```

#### Task 3: send_to_kafka

```
[2025-12-27, 03:22:45 UTC] INFO - Sending 5 filings to Kafka
[2025-12-27, 03:22:45 UTC] INFO - 📤 [KAFKA] Would send: IonQ, Inc.
[2025-12-27, 03:22:45 UTC] INFO - ✅ Sent 5 filings to Kafka
```

**결과**: 🎉 **100개 Form 4 수집, 5개 파싱 성공!**

------

## 7. 트러블슈팅 기록

### 문제 1: MySQL 포트 충돌

**에러**: `Bind for 0.0.0.0:3306 failed: port is already allocated`

**원인**: 로컬에 MySQL이 이미 실행 중

**해결**:

```yaml
ports:
  - "3308:3306"  # 외부 3308 포트로 변경
```

------

### 문제 2: Airflow 포트 충돌

**에러**: `Bind for 0.0.0.0:8080 failed: port is already allocated`

**해결**:

```yaml
airflow-webserver:
  ports:
    - "8081:8080"  # 외부 8081 포트로 변경
```

------

### 문제 3: SEC RSS에서 데이터 0개

**에러**: `Found 0 Form 4 filings`

**원인**: User-Agent 헤더 누락

**해결**:

```python
headers = {
    'User-Agent': 'InsiderTradingAgent/1.0 (your-email@example.com)',
    'Host': 'www.sec.gov'
}
response = requests.get(rss_url, headers=headers)
```

**중요**: SEC는 봇 방지를 위해 User-Agent 체크!

------

## 8. 오늘의 성과

### ✅ 완료된 작업

1. **인프라 구축 완료**
   - Docker Compose로 7개 컨테이너 실행
   - MySQL, Redis, Kafka, Zookeeper, Airflow (webserver, scheduler, worker)
2. **데이터베이스 설계 완료**
   - 5개 테이블 생성 (insider_trades, reddit_mentions, 등)
   - 인덱스 최적화 완료
3. **Airflow DAG 작동 검증**
   - SEC RSS에서 100개 Form 4 수집 성공
   - 파싱 파이프라인 구축
4. **Git 버전 관리**
   - GitHub Repository 세팅
   - .gitignore, README 작성

### 📊 주요 메트릭

- **크롤링 속도**: 100개 Form 4 수집 ~1초
- **파싱 시간**: 5개 파싱 ~2초 (Rate Limit 준수)
- **컨테이너 메모리**: 총 ~2GB 사용
- **DAG 실행 주기**: 30분마다 자동 실행

------

## 9. 다음 단계 (Day 2 계획)

### 🎯 우선순위 높음

1. **Form 4 XML 파서 완성**
   - 티커(Ticker) 추출
   - 내부자 이름, 직책 파싱
   - 거래 유형(매수/매도) 구분
   - 거래 금액 계산
2. **Kafka Producer 구현**
   - `raw-filings` Topic 생성
   - Form 4 데이터를 Kafka로 전송
   - 멱등성 보장 (중복 방지)
3. **Kafka Consumer 구현**
   - MySQL 저장 Consumer
   - Redis 랭킹 Consumer

### 🔮 향후 계획

1. **Reddit 크롤러 추가** (PRAW API)
2. **감성분석 (FinBERT)**
3. **Slack 알림 구현**
4. **FastAPI 대시보드**
5. **모니터링 (Prometheus + Grafana)**

------

## 10. 배운 점 & 회고

### 💡 기술적 인사이트

1. **User-Agent의 중요성**
   - SEC같은 공공기관도 봇 방지를 위해 User-Agent 체크
   - 크롤링 시 항상 적절한 User-Agent 설정 필수
2. **Airflow XCom의 활용**
   - Task 간 데이터 전달에 XCom 사용
   - 작은 데이터(<1MB)에만 적합, 큰 데이터는 외부 저장소 사용
3. **Docker 포트 관리**
   - 로컬 개발 환경에서 포트 충돌 빈번
   - `docker-compose.yml`에서 외부 포트 유연하게 변경

### 🚀 생산성 향상 팁

- **Docker Compose Logs**: `docker-compose logs -f [service]`로 실시간 디버깅
- **Airflow Task Test**: `airflow tasks test [dag_id] [task_id] [date]`로 개별 Task 테스트
- **MySQL 빠른 접속**: `docker exec -it insider-mysql mysql -u admin -p`

------

## 11. 참고 자료

- [SEC EDGAR API Documentation](https://www.sec.gov/edgar/sec-api-documentation)
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [Kafka Python Client](https://kafka-python.readthedocs.io/)
- [feedparser Documentation](https://feedparser.readthedocs.io/)

------

## 📁 프로젝트 저장소

GitHub: [insider-trading-agent](https://github.com/YOUR_USERNAME/insider-trading-agent)

------

**다음 포스팅**: Day 2 - Form 4 파싱 & Kafka 파이프라인 구축



