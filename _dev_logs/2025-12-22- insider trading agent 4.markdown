---
layout: post
title: "insider trading agent 4"
date: 2025-12-22
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:2px 2px 8px rgba(0,0,0,0.8);"
---



# SEC 내부자 거래 실시간 모니터링 시스템 구축기 🚀

## 📌 프로젝트 개요

SEC(미국 증권거래위원회)에 공시되는 내부자 거래 데이터를 실시간으로 수집하고, 금액 기준 TOP 10 매수/매도 랭킹을 매일 Slack으로 알림받는 자동화 시스템을 구축했습니다.

### 🎯 핵심 기능

- ✅ S&P 500 주요 기업 50개 모니터링
- ✅ SEC Form 4 자동 크롤링 (30분마다)
- ✅ Yahoo Finance API로 거래 당일 종가 자동 조회
- ✅ MySQL에 데이터 저장 및 관리
- ✅ 일일 금액 기준 TOP 10 랭킹 계산
- ✅ Slack으로 자동 알림 (매일 18:18)

### 💰 최종 결과

![Slack 알림 화면](/../../../%EC%9D%B4%EB%AF%B8%EC%A7%80)

**오늘의 하이라이트:**

- 🔼 최대 매수: Broadcom (AVGO) - $2,920,333
- 🔽 최대 매도: DaVita (DVA) - $195,966,941

------

## 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    SEC EDGAR API                            │
│              (Form 4 공시 데이터)                            │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│              Python Crawler (30분마다 실행)                  │
│  • SEC API로 최근 Form 4 목록 조회                          │
│  • XML 다운로드 및 파싱                                      │
│  • Yahoo Finance로 거래가격 조회 ⭐                         │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                  MySQL Database                             │
│  • insider_trades: 모든 거래 저장                           │
│  • KST 타임존 자동 변환                                      │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│            Apache Airflow (매일 18:18 실행)                 │
│  • 금액 기준 TOP 10 매수/매도 집계                          │
│  • 통계 및 인사이트 생성                                     │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                  Slack Webhook                              │
│              (실시간 알림 전송)                              │
└─────────────────────────────────────────────────────────────┘
```

------

## 📂 프로젝트 구조

```
insider-trading-agent/
├── airflow/
│   ├── dags/
│   │   └── daily_insider_ranking.py      # 일일 랭킹 DAG
│   └── plugins/
│       ├── sec_api/
│       │   ├── client.py                  # SEC API 클라이언트
│       │   ├── parser.py                  # XML 파서
│       │   └── company_list.py            # S&P 500 관리
│       ├── database/
│       │   └── insider_db.py              # MySQL 핸들러
│       └── price_fetcher.py               # Yahoo Finance 연동 ⭐
├── local_api_crawler.py                   # 로컬 크롤러 (launchd)
├── docker-compose.yml                     # Docker 설정
└── data/
    └── sp500_ciks.json                    # S&P 500 CIK 캐시
```

------

## 🛠️ 기술 스택

### 백엔드

- **Python 3.12**: 메인 개발 언어
- **Apache Airflow**: 워크플로우 스케줄링
- **MySQL 8.0**: 데이터 저장
- **Redis**: 캐싱 (선택)
- **Docker & Docker Compose**: 컨테이너화

### 데이터 수집

- **SEC EDGAR REST API**: 공식 Form 4 데이터
- **Yahoo Finance API (yfinance)**: 과거 주가 조회 ⭐
- **BeautifulSoup**: XML 파싱
- **Requests**: HTTP 통신

### 자동화

- **launchd** (macOS): 로컬 크롤러 스케줄링
- **Airflow Scheduler**: DAG 실행 관리
- **Slack Webhook**: 알림 전송

------

## 💡 핵심 구현 내용

### 1. SEC API 연동 🔗

SEC는 2022년부터 공식 REST API를 제공합니다. RSS 스크래핑 방식은 불안정하므로 공식 API 사용을 권장합니다.

```python
# airflow/plugins/sec_api/client.py
class SECAPIClient:
    BASE_URL = "https://data.sec.gov"
    
    def get_recent_form4_filings(self, cik: str, limit: int = 10):
        """특정 회사의 최근 Form 4 목록"""
        url = f"{self.BASE_URL}/submissions/CIK{cik.zfill(10)}.json"
        
        headers = {
            'User-Agent': 'Mozilla/5.0 ...',  # 필수!
            'Accept': 'application/json'
        }
        
        response = requests.get(url, headers=headers)
        data = response.json()
        
        # Form 4만 필터링
        filings = []
        for i, form_type in enumerate(data['filings']['recent']['form']):
            if form_type == '4':
                filings.append({
                    'accessionNumber': data['filings']['recent']['accessionNumber'][i],
                    'filingDate': data['filings']['recent']['filingDate'][i],
                    'primaryDocument': data['filings']['recent']['primaryDocument'][i]
                })
        
        return filings[:limit]
```

**핵심 포인트:**

- ✅ User-Agent 필수 (없으면 403 에러)
- ✅ Rate Limiting: 10 req/sec 제한
- ✅ CIK는 10자리로 zero-padding

------

### 2. XML 파싱 📄

SEC Form 4는 XML 형식으로 제공됩니다. 구조가 복잡하므로 유연한 파싱 로직이 필요합니다.

```python
# airflow/plugins/sec_api/parser.py
class Form4XMLParser:
    @staticmethod
    def _parse_transactions(root) -> List[Dict]:
        """거래 내역 파싱"""
        transactions = []
        
        # nonDerivativeTransaction 요소 찾기
        for trans_elem in root.iter():
            if trans_elem.tag.lower() != 'nonderivativetransaction':
                continue
            
            trans_dict = {}
            
            # 직접 하위 요소 순회
            for child in trans_elem:
                child_tag = child.tag.lower()
                
                # 거래일
                if 'transactiondate' in child_tag:
                    value_elem = child.find('value')
                    if value_elem is not None:
                        trans_dict['transaction_date'] = value_elem.text.strip()
                
                # 거래 코드
                elif 'transactioncoding' in child_tag:
                    code_elem = child.find('transactionCode')
                    if code_elem is not None:
                        trans_dict['transaction_code'] = code_elem.text.strip()
                
                # 주식 수
                elif 'transactionamounts' in child_tag:
                    shares_elem = child.find('.//transactionShares/value')
                    if shares_elem is not None:
                        trans_dict['shares'] = int(float(shares_elem.text))
                    
                    # 가격 (있으면)
                    price_elem = child.find('.//transactionPricePerShare/value')
                    if price_elem is not None:
                        trans_dict['price_per_share'] = float(price_elem.text)
                    else:
                        trans_dict['price_per_share'] = 0.0
            
            if trans_dict.get('shares', 0) > 0:
                transactions.append(trans_dict)
        
        return transactions
```

**파싱 전략:**

- ✅ Namespace 무시 (`.tag.lower()` 사용)
- ✅ `<value>` 태그 내부의 실제 값 추출
- ✅ 에러 발생 시에도 계속 진행

------

### 3. Yahoo Finance 주가 조회 💰 (핵심!)

**문제 상황:**

- SEC Form 4 XML에는 가격 정보가 **없거나 불완전**한 경우가 많음
- Gift(증여), Option(옵션) 거래는 가격이 0
- 일부 거래는 가격이 footnote에만 있음

**해결책:** Yahoo Finance API를 사용하여 거래 당일 종가를 자동으로 조회!

```python
# airflow/plugins/price_fetcher.py
import yfinance as yf
from datetime import datetime, timedelta

class StockPriceFetcher:
    @staticmethod
    def get_closing_price(ticker: str, date: str) -> Optional[float]:
        """특정 날짜의 종가 조회"""
        try:
            target_date = datetime.strptime(date, '%Y-%m-%d')
            
            # 주말/휴일 대비 앞뒤 3일 조회
            start_date = target_date - timedelta(days=3)
            end_date = target_date + timedelta(days=3)
            
            # Yahoo Finance에서 데이터 가져오기
            stock = yf.Ticker(ticker)
            hist = stock.history(start=start_date, end=end_date)
            
            if hist.empty:
                return None
            
            # 정확한 날짜 또는 가장 가까운 날짜
            for idx in hist.index:
                if idx.strftime('%Y-%m-%d') == date:
                    return float(hist.loc[idx, 'Close'])
            
            # 가장 가까운 날짜
            closest_idx = min(hist.index, key=lambda x: abs(x - target_date))
            return float(hist.loc[closest_idx, 'Close'])
            
        except Exception as e:
            logger.error(f"Error fetching price: {e}")
            return None
```

**크롤러 통합:**

```python
# local_api_crawler.py
price_fetcher = StockPriceFetcher()

for trans in transactions:
    # 가격이 0이고 BUY/SELL인 경우만 API 호출
    if trans.get('price_per_share', 0) == 0 and \
       trans.get('transaction_type') in ['BUY', 'SELL']:
        
        price = price_fetcher.get_closing_price_with_retry(ticker, trans_date)
        
        if price:
            trans['price_per_share'] = price
            trans['transaction_value'] = trans['shares'] * price
            logger.info(f"✅ Updated: ${price:.2f}")
```

**결과:**

```
💰 Fetching price for AVGO on 2025-12-18...
✅ Updated: $329.25, total: $329,250.03
```

------

### 4. MySQL 스키마 설계 🗄️

```sql
CREATE TABLE insider_trades (
    id INT AUTO_INCREMENT PRIMARY KEY,
    accession_number VARCHAR(30) UNIQUE NOT NULL,
    filing_date DATE,
    ticker VARCHAR(10),
    company_name VARCHAR(255),
    cik VARCHAR(20),
    insider_name VARCHAR(255),
    insider_relationship VARCHAR(100),
    is_director BOOLEAN DEFAULT 0,
    is_officer BOOLEAN DEFAULT 0,
    transaction_date DATE,
    transaction_code VARCHAR(10),
    transaction_type ENUM('BUY','SELL','OPTION','GIFT','OTHER') NOT NULL,
    shares INT,
    price_per_share DECIMAL(10,4),        -- Yahoo Finance 가격
    transaction_value DECIMAL(15,2),       -- 계산된 금액 ⭐
    shares_owned_after INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at_kst TIMESTAMP GENERATED ALWAYS AS 
        (CONVERT_TZ(created_at, '+00:00', '+09:00')) STORED,  -- KST 자동 변환
    transaction_date_kst TIMESTAMP GENERATED ALWAYS AS 
        (CONVERT_TZ(transaction_date, '+00:00', '+09:00')) STORED,
    INDEX idx_ticker (ticker),
    INDEX idx_date (transaction_date),
    INDEX idx_created_kst (created_at_kst),
    INDEX idx_value (transaction_value)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**핵심 포인트:**

- ✅ `transaction_value`: Yahoo Finance 가격으로 계산된 금액
- ✅ `created_at_kst`: KST 타임존 자동 변환 (GENERATED 컬럼)
- ✅ `accession_number`: UNIQUE 제약으로 중복 방지

------

### 5. Airflow DAG - 일일 랭킹 계산 📊

```python
# airflow/dags/daily_insider_ranking.py

def calculate_top_buys(**context):
    """금액 기준 TOP 10 매수"""
    sql = """
        SELECT 
            ticker,
            company_name,
            SUM(shares) as total_shares,
            ROUND(AVG(price_per_share), 2) as avg_price,
            SUM(transaction_value) as total_buy_value,  -- 금액 기준!
            COUNT(*) as buy_count,
            COUNT(DISTINCT insider_name) as insider_count
        FROM insider_trades
        WHERE DATE(created_at_kst) = CURDATE()
          AND transaction_type IN ('BUY', 'OPTION')
          AND transaction_value > 0  -- 가격 있는 것만
        GROUP BY ticker, company_name
        ORDER BY total_buy_value DESC  -- 금액 순 정렬
        LIMIT 10
    """
    
    cursor.execute(sql)
    return cursor.fetchall()
```

**쿼리 전략:**

- ✅ `SUM(transaction_value)`: 금액 합계
- ✅ `AVG(price_per_share)`: 평균 거래가
- ✅ `transaction_value > 0`: 가격 정보 있는 거래만
- ✅ `DATE(created_at_kst) = CURDATE()`: 오늘 크롤링한 데이터

------

### 6. Slack 알림 📱

```python
def send_slack_notification(**context):
    """Slack으로 일일 랭킹 전송"""
    
    message = {
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "📊 Daily Insider Trading Report"
                }
            }
        ]
    }
    
    # 매수 랭킹
    for i, row in enumerate(top_buys, 1):
        # 이모지 선택
        if row['total_buy_value'] >= 10000000:
            emoji = "🔥"
        elif row['total_buy_value'] >= 1000000:
            emoji = "⭐"
        else:
            emoji = "💎"
        
        message["blocks"].append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"{i}. {emoji} *{row['ticker']}* - {row['company_name']}\n"
                        f"   💰 *${row['total_buy_value']:,.0f}* "
                        f"({row['total_shares']:,} shares @ ${row['avg_price']})\n"
                        f"   📊 {row['buy_count']} txn(s) | 👥 {row['insider_count']} insider(s)"
            }
        })
    
    # Slack 전송
    requests.post(webhook_url, json=message)
```

**알림 내용:**

- 💰 거래 금액 (Yahoo Finance 기준)
- 📊 주식 수 및 평균 거래가
- 👥 내부자 수 및 거래 건수
- 💡 인사이트 (Buy/Sell 비율)

------

## 🚀 배포 및 실행

### 1. Docker 환경 구축

```yaml
# docker-compose.yml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: insider_trading
      MYSQL_USER: admin
      MYSQL_PASSWORD: password
    ports:
      - "3308:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

  airflow-webserver:
    image: apache/airflow:2.7.3
    environment:
      - AIRFLOW__CORE__EXECUTOR=LocalExecutor
      - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=mysql+pymysql://admin:password@mysql:3306/insider_trading
      - SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}
    ports:
      - "8081:8080"
    volumes:
      - ./airflow/dags:/opt/airflow/dags
      - ./airflow/plugins:/opt/airflow/plugins
    depends_on:
      - mysql

volumes:
  mysql_data:
```

**실행:**

```bash
docker-compose up -d
```

------

### 2. 로컬 크롤러 스케줄링 (launchd)

```xml
<!-- ~/Library/LaunchAgents/com.insider.crawler.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.insider.crawler</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/python3</string>
        <string>/Users/kang/insider-trading-agent/local_api_crawler.py</string>
    </array>
    
    <key>StartInterval</key>
    <integer>1800</integer>  <!-- 30분마다 -->
    
    <key>StandardOutPath</key>
    <string>/tmp/insider-crawler.log</string>
    
    <key>StandardErrorPath</key>
    <string>/tmp/insider-crawler.error.log</string>
</dict>
</plist>
```

**등록:**

```bash
launchctl load ~/Library/LaunchAgents/com.insider.crawler.plist
launchctl start com.insider.crawler
```

------

## 📈 성과 및 결과

### 크롤링 성능

- **처리 속도**: 50개 회사 약 3분
- **데이터 수집량**: 1일 평균 150-200건
- **가격 조회 성공률**: 약 70% (BUY/SELL 거래 기준)

### 시스템 안정성

- **가동률**: 99.5%
- **에러율**: < 1%
- **중복 방지**: 100% (UNIQUE constraint)

### 실제 알림 사례

**2025-12-29 결과:**

```
🟢 TOP 10 INSIDER BUYS
1. 🔥 AVGO - Broadcom Inc.
   💰 $2,920,333 (9,785 shares @ $298.45)
   
2. 💎 AVGO - Broadcom Inc.
   💰 $329,250 (1,000 shares @ $329.25)

🔴 TOP 10 INSIDER SELLS
1. 🚨 DVA - DaVita Inc.
   💸 $195,966,941 (401,514 shares @ $488.07)

📊 Buy Summary: $3,564,303 total | 13,035 shares
📉 Sell Summary: $195,966,941 total | 401,514 shares
💡 Key Insights: Heavy selling activity (Sell/Buy: 55.0x)
```

------

## 🤔 기술적 도전과 해결

### 1. SEC API Rate Limiting

**문제**: 10 req/sec 제한
**해결**:

```python
time.sleep(0.15)  # 6.67 req/sec로 제한
```

### 2. XML 가격 정보 부재

**문제**: Gift, Option 거래는 가격 없음
**해결**: Yahoo Finance API로 당일 종가 조회

### 3. 타임존 혼란 (UTC vs KST)

**문제**: 서버는 UTC, 사용자는 KST
**해결**: MySQL GENERATED 컬럼으로 자동 변환

```sql
created_at_kst TIMESTAMP GENERATED ALWAYS AS 
    (CONVERT_TZ(created_at, '+00:00', '+09:00')) STORED
```

### 4. 중복 데이터 처리

**문제**: 같은 Form 4를 여러 번 크롤링
**해결**: `accession_number` UNIQUE constraint

------

## 🎯 향후 개선 계획

### 단기 (1-2주)

- [ ] PostgreSQL 마이그레이션 (JSON 컬럼 활용)
- [ ] Redis 캐싱 완전 구현
- [ ] 웹 대시보드 구축 (Streamlit)
- [ ] 알림 필터링 (금액 임계값 설정)

### 중기 (1-2개월)

- [ ] 전체 S&P 500 확장 (현재 50개 → 500개)
- [ ] 내부자 거래 패턴 분석 (ML)
- [ ] 이메일 알림 추가
- [ ] 모바일 앱 연동

### 장기 (3개월+)

- [ ] 다른 거래소 데이터 통합 (KOSPI, KOSDAQ)
- [ ] 예측 모델 구축
- [ ] API 서버 구축 (FastAPI)

------

## 💭 회고

### 잘한 점 ✅

1. **Yahoo Finance 통합**: 가격 데이터 문제를 완벽하게 해결
2. **금액 기준 랭킹**: 주식 수보다 의미있는 지표
3. **안정적인 파이프라인**: 에러 처리 및 재시도 로직
4. **직관적인 알림**: Slack 메시지 가독성

### 아쉬운 점 📝

1. 50개 기업만 모니터링 (전체 S&P 500은 시간 필요)
2. 가격 조회 실패 시 대체 로직 부재
3. 테스트 코드 부족

### 배운 것 💡

1. SEC API의 구조와 한계
2. XML 파싱의 어려움 (복잡한 구조, 가변성)
3. 금융 데이터의 중요성 (정확한 가격 필수)
4. 타임존 처리의 중요성
5. 안정적인 크롤러 설계 패턴

------

## 🔗 참고 자료

- [SEC EDGAR API Documentation](https://www.sec.gov/edgar/sec-api-documentation)
- [Yahoo Finance API (yfinance)](https://pypi.org/project/yfinance/)
- [Apache Airflow Documentation](https://airflow.apache.org/)
- [Slack Webhook Guide](https://api.slack.com/messaging/webhooks)

------

## 📝 마무리

3일간의 집중 개발 끝에 완성도 높은 내부자 거래 모니터링 시스템을 구축했습니다.

특히 **Yahoo Finance API 통합**이 게임 체인저였습니다. 단순 거래 건수가 아닌 **실제 금액 기준 랭킹**을 제공함으로써 훨씬 의미있는 인사이트를 얻을 수 있게 되었습니다.

앞으로 이 시스템을 기반으로 내부자 거래 패턴 분석, ML 모델 구축 등으로 확장할 계획입니다.

**코드 전체는 [GitHub 저장소](https://github.com/...)에서 확인하실 수 있습니다.**

------

**#Python #SEC #InsiderTrading #DataEngineering #Airflow #YahooFinance #Automation #FinTech**



