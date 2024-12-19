---
layout: post
title: "Airflow를 활용한 Batch Serving"
date: 2024-12-16
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:0px 4px 8px rgba(0,0,0,0.8);"

---

## 과제1 Airflow를 활용한 Batch Serving



## 목표

- Batch Serving을 하는 Airflow에 익숙해집니다.
- Airflow DAG을 만들고 그 안의 Task를 구성하는 것이 목표입니다.

<br>

## 요구 사항

- 다음 요구사항을 구현해야 합니다. 총 **4개의 DAG**을 만듭니다.
  1. 주기적으로 모델을 학습하는 Airflow DAG를구현합니다.
     - 모델은 여러분들이 과거에 하셨던 모델을 사용해도 됩니다.
     - 단, 모델의 학습이 오래 걸리는 경우보단 학습 시간이 적은 모델부터 시작해 주세요.
     - 모델 추론 결과는 output 폴더를 만들어 해당 폴더에 저장해 주세요.
     - 단, 버저닝을 할 수 있는 방법으로 모델을 저장해주세요.
     - 학습 시 오류가 발생하면 오류 메시지를 슬랙으로 보낼 수 있게 알림 프로세스를 구성해 주세요.
     - 슬랙은 개인용 워크스페이스를 만들어 사용해 주세요. (구현 과정에서 Key 발급을 쉽게 하기 위함)
  2. 학습한 모델이 기존에 있던 모델보다 성능이 좋은 경우엔 모델을 저장하고, 그러지 않는 경우엔 패스하는 Airflow DAG를 구현합니다.
     - 조건에 따라 분기하고 싶은 경우엔 BranchPythonOperator를 사용합니다.
     - 학습한 모델이 기존 모델보다 성능이 좋은 경우엔 모델 파일을 업데이트 합니다.
     - 성공 시 슬랙 메시지를 보내주도록 구현합니다.
  3. 주기적으로 예측(인퍼런스)하는 Airflow DAG를 구현합니다.
     - 모델을 불러오고 예측하는 DAG을 만듭니다. 5분에 1번씩 예측을 수행하도록 설정하고, 한번 학습할 때 랜덤으로 5개만 예측하도록 구현해 주세요.
     - 실제 회사에서는 클라우드의 데이터 저장소나 데이터베이스에 있는 데이터를 가지고 와서 처리하지만, 여기서는 로컬에 있는 파일을 랜덤으로 추출해서 예측하는 방식으로 진행합니다.
  4. 1시간에 1번씩 서울 지역의 날씨 데이터를 수집하는 Airflow DAG를 구현합니다.
     - 초단기 예보 서비스를 사용해 앞으로 1시간 후의 날씨를 1시간마다 저장합니다.
     - 중복 데이터가 있다면 최신 데이터를 사용합니다.
     - Dag의 Task는 데이터 수집과 전처리의 두 단계로 나누어 총 2개의 Task로 구성해 주세요.
     - 데이터 전처리는 각 지역에 대한 날씨를 구분할 수 있도록 csv 파일을 구성해서 로컬에 저장해 주세요.
     - (TIP) 로컬에서 리소스 등의 이유로 아래와 같은 오류가 확인될 경우, cloud composer 환경에서 시도해 보세요.
       ![image](https://user-images.githubusercontent.com/75998700/138587675-6c2a9fbc-df4b-4f8c-accb-f6d7931287bc.png)

<br>

## 고려 사항

- 모델 학습과 인퍼런스에 집중하는 것보다 Airflow에 익숙해지는 것을 목표로 진행해 주세요.
- 구현 대상 DAG 중 날씨에 관한 DAG를 구현할 때 [기상청의 단기예보 조회 서비스](https://www.data.go.kr/data/15084084/openapi.do)를 사용합니다.

<br>

## 더 공부하면 좋을 내용

- Airflow에서 제공하는 Operator가 무엇이 있는지 파악합니다.
- Airflow에서 주기적으로 데이터를 수집할 때, 데이터를 저장할 데이터베이스(MySQL 등)를 학습하면 전처리한 데이터를 저장할 수 있습니다.
- PythonOperator 활용해서 DAG 내에 Python 함수를 구현하고 사용할 수 있습니다.
  다만, 반복 가능한 업무는 [Custom Operator](https://airflow.apache.org/docs/apache-airflow/stable/howto/custom-operator.html)를 활용해 개발하는 것을 권장합니다.

---

## 과제 시작

우선 assignmets.tar.gz를 다운받고 우분투환경으로 옮겼다. 

## Windows와 Ubuntu의 파일 형식 다름

그리고 압축을 풀려고 했는데

![image-20241216152030246](/assets/img/image-20241216152030246.png)

? 뭐지 .tar.gz면 gzip풀고 tar풀어야 되는거아닌가? 

![image-20241216152137407](/assets/img/image-20241216152137407.png)

파일형식을 확인해보니 

![image-20241216152226681](/assets/img/image-20241216152226681.png)

Ubuntu vscode에서는 tar이고 Windows에서는 gzip이네? 

머임? 슈뢰딩거의 파일임?

아마 Windows에서 Ubuntu로 옮기면서 압축이 해제 된건가? 찾아봐도 이런 사례는 없던데 머징.

뭐 그래도 tar파일 압축풀면 차피 상관은 없겟지.

![image-20241216152607910](/assets/img/image-20241216152607910.png)

---

**이제 과제의 조건대로 코드를 고친 후 Airflow 세팅**

```
# Airflow 설치
pip install apache-airflow

# Slack 연동을 위한 provider 설치
pip install apache-airflow-providers-slack

# scikit-learn 설치 (모델 학습에 필요)
pip install scikit-learn

# 필요한 다른 패키지들 설치
pip install pandas joblib

# Airflow 초기화 (최초 1회만 실행)
airflow db init
```

**User 생성**

```
airflow users create \
    --username admin \
    --firstname admin \
    --lastname admin \
    --role Admin \
    --email admin@example.com \
    --password admin
```

**Login**

![image-20241216172657576](/assets/img/image-20241216172657576.png)











