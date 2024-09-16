---
layout: post
title: "데이터 전처리, Feature engineering"
date: 2024-09-12
typora-root-url: ../

---

## 데이터 클렌징

### 이상치(Outlier) 다루기

이상치란 다른 값들과 크게 동떨어진 값을 의미합니다. 이는 관측치의 변동성, 실험 오차, 기록 오류 등으로 발생할 수 있습니다.

## 이상치 탐지 방법:

1. 최대/최소값 설정
2. IQR (Interquartile Range) 방법
3. Z-Score 방법

## 이상치 처리 방법:

1. 그대로 두기
2. 제거하기
3. Winsorization (최소/최대값으로 대체)

### 결측치(Missing Value) 처리하기

결측치는 데이터에서 값이 누락된 경우를 말합니다. 단순히 데이터를 놓친 경우일 수도 있지만, 때로는 응답자의 의도를 반영하는 중요한 정보일 수 있습니다.

## 결측치 처리 방법:

1. 대표값 대체
   - 평균값 대체
   - 중간값 대체
   - 최빈값 대체
2. MICE (Multivariate Imputation by Chained Equations)
   - 다른 변수들을 이용해 결측치를 예측하여 대체하는 방법

## 데이터 전처리

## 스케일링 (Scaling)

Standardization (Standard Scaling)

- 데이터의 평균을 0, 표준편차를 1로 변환
- 수식: (x - μ) / σ

Normalization (Min-Max Scaling)

- 데이터의 범위를 0과 1 사이로 변환
- 수식: (x - min(x)) / (max(x) - min(x))

## 트랜스폼 (Transform)

트랜스폼은 데이터의 분포를 조정하는 방법입니다. 이는 데이터의 정규성을 개선하고 패턴을 더 잘 학습할 수 있게 합니다.

1. Log Transform
   - 로그 함수를 적용하여 양수 데이터의 분포를 정규화
2. Box-Cox Transform
   - Log Transform보다 더 일반적인 방법
   - Lambda 파라미터로 변환 강도 조절
3. Power Transform
   - 데이터의 정규성을 확보하면서 변수의 단위를 보존
4. Quantile Transform
   - 데이터를 정규분포로 변환하는 방법

## 인코딩 (Encoding)

인코딩은 범주형 데이터를 수치형으로 변환하는 방법입니다. 이를 통해 머신러닝 모델이 범주형 데이터를 처리할 수 있게 됩니다.

1. Label Encoding
   - 범주형 데이터를 정수로 변환
   - 주로 타겟 변수 y에 사용
2. Ordinal Encoding
   - 지정한 순서로 범주형 데이터를 정수로 변환
3. One-Hot Encoding
   - 각 범주를 별도의 이진 변수로 변환
   - 순서 없는 범주형 데이터에 적합

## Feature Engineering이란?

Feature Engineering은 새로운 특성(feature)을 생성하거나 기존 특성을 변형하는 과정입니다. 이는 모델의 성능을 향상시키고, 더 나은 데이터 표현을 만들어내는 데 중요한 역할을 합니다.

### Feature Engineering의 주요 목적

1. 모델 성능 향상
2. 모델 설명력 향상
3. 데이터의 더 나은 표현
4. 예측 정확도 증대

### Feature Engineering의 주요 기법

1. 특성 생성 (Feature Creation)
   - 도메인 지식을 활용한 새로운 특성 도출
   - 상호작용항(Interaction Terms) 생성
2. 특성 선택 (Feature Selection)
   - 불필요한 특성 제거
   - 차원 축소 기법 활용 (예: PCA, LDA)

### **How To Select Features in Machine Learning?**

- 해결하려는 문제를 이해해야 합니다. '문제와 가장 관련성이 높은 기능은 무엇인가?', '대상 변수를 가장 잘 예측할 수 있는 기능은 무엇인가?' 등의 질문에 답해 보세요.
- 데이터를 탐색해야 합니다. 피처의 분포를 살펴보고 이상치나 누락된 값이 있는지 확인해야 합니다. 데이터를 정리하거나 정보가 없는 피처를 제거해야 할 수도 있습니다.
- 결과를 평가해야 합니다. 일단 기능 집합을 선택하면 결과를 평가해야 합니다. 선택한 기능으로 모델이 얼마나 잘 수행됩니까? 모델의 성능에 큰 영향을 미치지 않고 기능을 제거할 수 있습니까?

![ML에서 Python을 사용한 기능 선택을 위한 이미지](/assets/img/Feature_Selection_in_ML.webpw=940&dpr=1.jpeg)

CSV 파일에서 데이터를 로드하고 카이제곱 검정을 사용하여 상위 10개 피처를 선택하는 코드

## 학습, 검증, 테스트 데이터 이해하기

**학습 데이터(Training Data)**: 모델을 학습시키기 위해 사용하는 데이터입니다.

**검증 데이터(Validation Data)**: 모델의 하이퍼파라미터 튜닝 및 성능 평가를 위해 사용하는 데이터입니다.

**테스트 데이터(Test Data)**: 모델의 최종 성능을 평가하기 위해 사용하는 데이터입니다.

## 데이터 분할하기

## train_test_split

데이터를 분할할 때는 주로 scikit-learn의 `train_test_split` 함수를 사용

```
from sklearn.model_selection import train_test_split

*# 전체 데이터를 훈련+검증 세트와 테스트 세트로 분할* 
X_train, X_temp, y_train, y_temp = train_test_split(X, y, train_size=0.7, random_state=42) 

*# 훈련+검증 세트를 다시 훈련 세트와 검증 세트로 분할* 
X_val, X_test, y_val, y_test = train_test_split(X_temp, y_temp, train_size=0.5, random_state=42)
```

train: 70% , val: 15%, test: 15%로 무작위로 섞어서 분할

찾아보니까 시간순서대로 분할하는 것도 있던데 시간순서대로 분할이면 사실상 순서대로 분할이네? 그럼 효과가 덜해지려나? 더 좋아지려나? 모르겠다. 담에 한번 해봐야지.

## 불균형한 데이터셋 생성 후 데이터 분할

```
#(불균형한) 데이터셋 생성
X, y = make_classification(n_samples=1000, n_features=20, n_classes=3, n_clusters_per_class=1, weights=[0.01, 0.04, 0.95], flip_y=0, random_state=42)

#데이터를 훈련 데이터와 테스트 데이터로 분할 (비율 유지하지 않음) X_train, X_test, y_train, y_test = train_test_split(X, y, train_size=0.8, random_state=42)
```

- 데이터를 무작위 분할하기 때문에,레이블 분포 서로 다름

## stratify

```
#(불균형한) 데이터셋 생성
X, y = make_classification(n_samples=1000, n_features=20, n_classes=3, n_clusters_per_class=1, weights=[0.01, 0.04, 0.95], flip_y=0, random_state=42)

#데이터를 훈련 데이터와 테스트 데이터로 분할 (비율 유지하지 않음) X_train, X_test, y_train, y_test = train_test_split(X, y, train_size=0.8, random_state=42, stratify=y)
```

-  stratify:데이터 분할 시 클래스 비율을 동일하게 유지하여 각 세트가 원본 데이터의 클래스 분포를 반영하도록 함

## 데이터 불균형 해결 방법

1. 언더샘플링(Undersampling)

   : 다수 클래스의 데이터를 줄여 소수 클래스의 비율과 맞추는 방법

   - Random Sampling, Near Miss, Tomek Links 등

2. 오버샘플링(Oversampling)

   : 소수 클래스의 데이터를 늘려 다수 클래스의 비율과 맞추는 방법

   - Resampling, SMOTE(Synthetic Minority Over-sampling Technique) 등

## 데이터 유출 문제

데이터 유출(Data Leakage)은 모델을 학습하는 과정에서 검증 단계에서 사용할 정보를 학습하게 되어, 성능을 과대평가하는 문제

### 자주 발생하는 데이터 유출 케이스

1. **이벤트 이후의 정보 포함**: 예측 시점 이후의 정보를 사용하는 경우
2. **타겟 변수의 대리변수 포함**: 타겟과 매우 높은 상관관계를 가진 변수를 사용하는 경우
3. **데이터 전처리 과정에서의 유출**: 전체 데이터셋의 통계를 사용하여 스케일링하는 경우

데이터를 훈련/검증 데이터로 분할 -> 훈련 데이터 스케일링 -> 동일한 변환을 검증 데이터에 적용 -> 이러면 검증 데이터의 정보가 스케일링에 포함되지 않아 데이터 유출 방지 가능

```
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split

#데이터를 훈련 데이터와 검증 데이터로 먼저 분할합니다.
X_train, X_valid, y_train, y_valid = train_test_split(X, y, test_size=0.3, random_state=42) 

#훈련 데이터에 대해 스케일링을 수행합니다.
scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)

#동일한 스케일링 변환을 검증 데이터에 적용합니다.
X_valid = scaler.transform(X_valid)
```

