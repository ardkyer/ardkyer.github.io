---
layout: post
title: " A novel cryptocurrency price trend forecasting model based on LightGBM"
date: 2024-09-09
typora-root-url: ../
---

 A novel cryptocurrency price trend forecasting model based on LightGBM논문을 읽어봅시당

## Abstract

Forecasting cryptocurrency prices is crucial for investors. ... This can effectively guide investors in constructing an appropriate cryptocurrency portfolio and mitigate risks.

이 논문은 암호화폐 가격 추세 예측 모델을 제안하며, LightGBM 알고리즘을 사용하여 암호화폐 시장의 가격 추세(하락 또는 비하락)를 예측합니다. 이를 위해 42종의 주요 암호화폐의 일일 데이터와 주요 경제 지표를 결합하여 시장 정보를 활용합니다.

## LightGBM이 뭔데?

LightGBM은 부스팅 알고리즘 중에 2016년 출시로 비교적 최근에 만들어졌습니다. XGBoost보다 2년 후에 만들어지다 보니 XGBoost의 장점은 계승하고 단점은 보완하는 방식으로 개발 되었습니다. Light Graient-Boosting Machine의 약자로 Microsoft에서 개발한 머신 러닝 무료 오픈 소스 프레임워크입니다. 앞에서 언급한 것처럼 기존 알고리즘의 정확도를 유지하면서 훨씬 좋은 효율성을 가지고 있는 LightGBM은 이름처럼 가볍다는 게 특징입니다. 

## XGBoost와 LightGBM 비교

두 알고리즘의 가장 큰 차이점은 노드 분할 방식이 다르다는 것입니다. 

XGBoost

- 트리의 깊이를 효과적으로 줄이기 위한 균형 트리 분할 (Level-Wise)을 사용
- 최대한 균형 잡힌 트리를 유지하면서 분할하기 때문에 트리의 깊이가 최소화
- 균형 잡힌 트리를 생성하는 이유는 과적합을 방지할 수 있기 때문이나 균형을 맞추기 위한 시간이 오래 걸린다는 단점

LightGBM

- 리프 중심 분할 (Leaf-wise)은 트리의 균형을 맞추지 않고 최대 손실 값을 가지는 리프 노드를 지속적으로 분할
- 트리의 깊이가 깊어지고 비대칭적인 트리가 생성
  

![XGBoost vs LightGBM 차이](/assets/img/img-1725861132793-1.png)

장점

- 학습시간이 적습니다.
- 메모리 사용량이 상대적으로 적은편입니다. 
- Categorical feature들의 자동 변환과 최적 분할이 가능합니다. 
- GPU 학습을 지원합니다. 

단점

- 적은 데이터셋에 적용 시 과적합이 발생하기 쉽습니다.

[Boosting 알고리즘 - LightGBM 특징(GOSS, EFB, 장단점) by 데이널](https://bommbom.tistory.com/entry/Boosting-%EC%95%8C%EA%B3%A0%EB%A6%AC%EC%A6%98-LightGBM-%ED%8A%B9%EC%A7%95GOSS-EFB-%EC%9E%A5%EB%8B%A8%EC%A0%90)

[XGBoost, LightGBM, CatBoost 정리 및 비교 by Stat_in_KNU](https://statinknu.tistory.com/33)

[LightGBM Algorithm: The Key to Winning Machine Learning Competitions](https://dataaspirant.com/lightgbm-algorithm/)

[What is Light GBM? Advantages & Disadvantages? Light GBM vs XGBoost?](https://www.kaggle.com/discussions/general/264327)

[7 Most Popular Boosting Algorithms to Improve Machine Learning Model’s Performance](https://dataaspirant.com/boosting-algorithms/)

## Introduction

 Considering that the investment risk of cryptocurrencies is greater than other products, forecasting the fluctuation tendency of cryptocurrency price is of great importance.

암호화폐의 투자 위험이 다른 상품보다 크다는 점을 감안할 때 암호화폐 가격의 변동 경향을 예측하는 것이 매우 중요합니다.

## Model specifications



### 목표 함수

$$
f^ = arg min_f E_y,x L(y, f(x))
$$

LightGBM은 손실 함수 L(y, f(x))의 기대값을 최소화하는 함수 f를 찾습니다.

#### 회귀 트리의 합

$$
f_T(X) = Σ^T_t=1 f_t(X)
$$

최종 모델은 T개의 회귀 트리의 합으로 구성됩니다.

## 학습 과정

1. **단계별 학습**:
   $$
   Γ_t = Σ^n_i=1 L(y_i, F_t-1(x_i) + f_t(x_i))
   $$
   각 단계에서 가법적으로 학습됩니다.

2. **Newton's 방법 적용**:
   $$
   Γ_t ≃ Σ^n_i=1 (g_if_t(x_i) + 1/2 h_if_t^2(x_i))
   $$
   gi와 hi는 각각 1차 및 2차 그래디언트 통계입니다.

## 리프 노드 최적화

1. **리프 노드 최적화**:
   $$
   Γ_t = Σ^J_j=1 ((Σ_i∈I_j g_i)w_j + 1/2 (Σ_i∈I_j h_i+λ)w_j^2)
   $$
   Ij는 리프 j에 속하는 샘플 집합입니다.

2. **최적 가중치 계산**:
   $$
   w_j* = -Σ_i∈I_j g_i / (Σ_i∈I_j h_i + λ)
   $$
   각 리프 노드의 최적 가중치는 이 식으로 계산됩니다.

## 트리 분할 후의 목적 함수

**트리 구조 q의 품질을 측정하는 점수 함수**:
$$
Γ*t = -1/2 Σ^J_j=1 (Σ_i∈I_j g_i)^2 / (Σ_i∈I_j h_i + λ)
$$

- 값이 작을수록 더 좋은 트리 구조

**분할 후의 목적 함수**
$$
G = 1/2 ((Σ_i∈I_L g_i)^2 / (Σ_i∈I_L h_i + λ) + (Σ_i∈I_R g_i)^2 / (Σ_i∈I_R h_i + λ) - (Σ_i∈I g_i)^2 / (Σ_i∈I h_i + λ))
$$


- G는 분할의 이득(gain), 값이 클수록 분할이 더 효과적

## Data and results

1. 데이터 처리 및 모델 구성:

   - 42개 암호화폐의 4,873개 샘플을 사용했습니다.
   - 입력 변수로 40개의 특성 변수를 선택했습니다.
   - 예측 기간은 2일, 2주, 2개월로 설정했습니다.
   - 데이터셋은 훈련(50%), 검증(30%), 테스트(20%)로 분할했습니다.
   - LightGBM, SVM, RF(Random Forest) 모델을 비교했습니다.

2. 모델 성능 평가:

   - AUC와 정확도를 사용하여 성능을 측정했습니다.

   - 두 가지 카테고리로 나누어 평가했습니다:

     1. 테스트 세트가 훈련 세트의 부분집합인 경우

     2. 테스트 세트가 훈련 세트와 독립적인 경우

        

   ![image-20240909175746741](/assets/img/image-20240909175746741.png)

3. 주요 결과 (Table 3, 4 및 Fig. 1 기반):

   - 첫 번째 카테고리 (Table 3):
     - 2주 예측 기간에서 모든 모델이 가장 좋은 성능을 보였습니다.
     - LightGBM은 2개월 및 2주 기간에서 가장 높은 AUC를 기록했습니다.
     - RF 모델은 2일 기간에서 가장 좋은 성능을 보였습니다.
   - 두 번째 카테고리 (Table 4):
     - LightGBM과 SVM은 2주 기간에서 동일한 성능을 보였습니다.
     - RF 모델은 2일 기간에서 약간 더 나은 성능을 보였습니다.
     - 전반적으로 2일 예측이 2주 예측보다 더 정확했습니다.
   - 상위 10개 암호화폐 서브샘플 분석 (Fig. 1):
     - 첫 번째 카테고리에서는 전체 42개 암호화폐보다 더 나은 성능을 보였습니다.
     - 두 번째 카테고리에서는 큰 차이가 없었습니다.

4. 주요 통찰:

   - 예측 성능은 예측 기간과 암호화폐의 경쟁력에 따라 달라집니다.
   - 2주 기간이 대체로 가장 좋은 예측 성능을 보였습니다.
   - 상위 암호화폐들이 더 예측 가능한 경향을 보였습니다.
   - 다른 암호화폐들의 가격 정보를 함께 사용하는 것이 예측 정확도를 높이는 데 기여했습니다.

5. 투자 시사점:

   - 암호화폐 투자 시 해당 화폐의 종합적인 강점과 투자 주기(특히 2주 기간)를 고려해야 합니다.
   - 상위 암호화폐들이 더 예측 가능하므로 투자 위험이 상대적으로 낮을 수 있습니다.
   - 다양한 암호화폐 간의 상호작용과 자금 흐름을 고려한 투자 전략이 효과적일 수 있습니다.

## Conclusions

- LightGBM이라는 새로운 GBDT(Gradient Boosting Decision Tree) 알고리즘을 사용하여 암호화폐 시장의 가격 추세를 예측했습니다.

- LightGBM의 우수성: LightGBM 모델이 SVM과 RF에 비해 안정성(robustness)면에서 더 우수한 성능을 보였습니다.