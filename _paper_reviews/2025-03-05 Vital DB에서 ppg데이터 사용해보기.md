---
layout: post
title: "Vital DB에서 ppg데이터 사용해보기"
date: 2025-03-05
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:0px 4px 8px rgba(0,0,0,0.8);"
---

## 우선 Vital DB 데이터 불러와서 데이터 구조 확인

[**A time-frequency domain approach of heart rate estimation from photoplethysmographic (PPG) signal**](https://www.sciencedirect.com/science/article/abs/pii/S1746809417300721)

**PPG 신호를 이용한 심박수 추정의 시간-주파수 영역 접근법**

<br>

[**Heart rate tracking in photoplethysmography signals affected by motion artifacts: a review ;운동 아티팩트의 영향을 받는 PPG 신호의 심박수 추적: 리뷰**](https://asp-eurasipjournals.springeropen.com/articles/10.1186/s13634-020-00714-2)

<br>

[**A Robust Dynamic Heart-Rate Detection Algorithm Framework During Intense Physical Activities Using Photoplethysmographic Signals**](https://pmc.ncbi.nlm.nih.gov/articles/PMC5713029/)

**PPG를 사용하는 강렬한 신체 활동 중 강력한 동적 심박수 감지 알고리즘 프레임워크**

<br>

[**Heart Rate Estimation using PPG signal during Treadmill Exercise**](https://pubmed.ncbi.nlm.nih.gov/31946579/)

**러닝머신 운동 중 PPG 신호를 이용한 심박수 추정**

<br>



## "정적 상태와 가벼운 움직임, 많은 움직임 조건에서 어떤 PPG 신호 처리 방법이 가장 정확한 심박수 추정 결과를 제공하는가?"

---



### Background: PPG and ECG Overview

- **ECG (Electrocardiogram)**: 심장의 전기적 활동을 측정하며, R파와 같은 피크를 통해 심박 간격을 계산합니다. 이는 심박수와 HRV(심박 변이도) 분석의 표준으로 간주됩니다. 예를 들어, [ECG vs PPG for Heart Rate Monitoring](https://neurosky.com/2015/01/ecg-vs-ppg-for-heart-rate-monitoring-which-is-best/)에 따르면 ECG는 의료 환경에서 정확도가 높습니다.
- **PPG (Photoplethysmogram)**: 혈관 내 혈류 변화를 광학적으로 측정하며, 주로 웨어러블 기기(예: 스마트워치)에 사용됩니다. [ECG or PPG? What are they and which is better?](https://www.myzone.org/blog/ecg-or-ppg)에서는 PPG가 편리하지만 움직임 노이즈에 취약하다고 설명합니다.

1. 시간 영역과 주파수 영역 분석 비교
   - **시간 영역 분석**: 신호의 시간에 따른 크기 변화를 살펴보는 방법으로, 예를 들어 PPG와 ECG에서 피크(예: PPG의 수축기 피크, ECG의 R파)를 찾아 심박 간격이나 HRV 지표(예: SDNN, RMSSD)를 계산합니다. 직관적이지만 노이즈나 움직임에 민감할 수 있습니다.
   - **주파수 영역 분석**: 푸리에 변환 같은 기법으로 신호를 주파수 성분으로 변환해 분석합니다. HRV의 저주파(LF)와 고주파(HF) 대역을 통해 자율신경계 활동을 평가할 수 있는데, 전체적인 스펙트럼을 보기 때문에 노이즈에 덜 민감할 가능성이 있습니다.
   - 두 방법을 비교하면 각 방식의 장단점을 명확히 알 수 있고, 어떤 상황에서 어떤 접근이 더 나은지 판단할 수 있습니다.

### Time-Domain Analysis: Detailed Explanation

시간 영역 분석은 신호의 시간적 변화를 기반으로 피크를 찾아 심박 간격을 계산하는 방법입니다.

- Process:
  - PPG에서는 수축기 피크(최대 혈류 변화 지점)를, ECG에서는 R파(심장 수축 시작 지점)를 탐지합니다.
  - 이를 통해 RR 간격(ECG)이나 피크 간격(PPG)을 계산하고, 심박수(60/간격, 단위: bpm)와 HRV 지표(예: SDNN, RMSSD)를 도출합니다.
  - 예를 들어, [Photoplethysmographic Time-Domain Heart Rate Measurement Algorithm for Resource-Constrained Wearable Devices and its Implementation](https://pmc.ncbi.nlm.nih.gov/articles/PMC7146569/)에서는 시간 영역에서 피크 탐지 알고리즘을 설명하며, 움직임 노이즈를 줄이기 위해 가속도계 데이터를 사용합니다.
- Advantages:
  - 직관적이고, 깨끗한 신호에서는 정확도가 높습니다.
  - 실시간 분석에 적합하며, 단기적인 심박 변화(예: 운동 중 급격한 심박수 증가)를 잘 반영합니다.
- Disadvantages:
  - 움직임 노이즈에 매우 민감합니다. 예를 들어, [Heart rate tracking in photoplethysmography signals affected by motion artifacts: a review](https://asp-eurasipjournals.springeropen.com/articles/10.1186/s13634-020-00714-2)에서는 움직임으로 인해 피크 탐지가 어려워질 수 있다고 언급합니다.
  - 신호 품질이 낮으면 잘못된 피크 탐지로 인해 심박수 추정이 왜곡될 수 있습니다.

### Frequency-Domain Analysis: Detailed Explanation

주파수 영역 분석은 푸리에 변환(FFT)이나 다른 스펙트럼 분석 기법을 통해 신호를 주파수 성분으로 변환하는 방법입니다.

- Process:

  - 신호를 주파수 도메인으로 변환하면, 심박수에 해당하는 주파수 피크(예: 1Hz = 60bpm)를 찾습니다.
  - HRV 분석에서는 저주파(LF, 0.04–0.15Hz)와 고주파(HF, 0.15–0.4Hz) 대역을 통해 자율신경계 활동(예: 교감신경, 부교감신경)을 평가합니다.
  - 예를 들어, [A time-frequency domain approach of heart rate estimation from photoplethysmographic (PPG) signal](https://www.sciencedirect.com/science/article/pii/S1746809417300721)에서는 시간-주파수 도메인 접근법을 제안하며, 움직임 노이즈를 줄이기 위해 다단계 적응 필터를 사용합니다.

- Advantages:

  - 전체 스펙트럼을 보기 때문에 노이즈에 덜 민감할 가능성이 높습니다. 특히 [RobustPPG: camera-based robust heart rate estimation using motion cancellation](https://pmc.ncbi.nlm.nih.gov/articles/PMC9664884/)에서는 격렬한 움직임에서도 주파수 영역 분석이 효과적이라고 보고합니다.
  - 장기적인 패턴 분석에 유리하며, 스펙트럼 피크 추적을 통해 안정적인 심박수 추정이 가능합니다.

- Disadvantages:

  - 단기적인 심박 변화는 놓칠 수 있습니다. 예를 들어, [Estimation of Heart Rate Variability from Finger Photoplethysmography During Rest, Mild Exercise and Mild Mental Stress](https://pmc.ncbi.nlm.nih.gov/articles/PMC8713388/)에서는 주파수 영역 분석이 운동 중 변동성을 덜 반영한다고 언급합니다.
  - 충분한 데이터 길이가 필요하며, 짧은 세그먼트에서는 정확도가 떨어질 수 있습니다.

  <br>

  ---

  

| **Aspect**          | **Time-Domain Analysis**                      | **Frequency-Domain Analysis**            |
| ------------------- | --------------------------------------------- | ---------------------------------------- |
| **Method**          | 피크 탐지 및 간격 계산                        | 푸리에 변환 및 스펙트럼 분석             |
| **Strengths**       | 직관적, 실시간 분석에 적합, 단기 변화 잘 반영 | 노이즈에 덜 민감, 장기 패턴 분석에 유리  |
| **Weaknesses**      | 움직임 노이즈에 취약, 신호 품질에 의존        | 단기 변화 놓칠 수 있음, 데이터 길이 필요 |
| **Best for**        | 정적인 상태, 깨끗한 신호                      | 움직임이 많은 상태, 노이즈가 있는 환경   |
| **Example Metrics** | 심박수, SDNN, RMSSD                           | LF/HF 비율, 주파수 피크                  |



<br>

### Comparison in Different Physical States

연구 방향은 정적인 상태, 살짝 움직이는 상태(예: 걷기), 격렬하게 움직이는 상태(예: 달리기)에서 PPG와 ECG를 동시에 측정하고, 두 방법의 성능을 비교

- Static State (정적인 상태):
  - 시간 영역 분석은 깨끗한 신호에서 정확도가 높아, PPG와 ECG 간 심박수 추정이 잘 일치할 가능성이 큽니다.
  - 주파수 영역 분석도 안정적으로 작동하지만, 스펙트럼 해석이 불필요할 수 있습니다.
- Slightly Moving State (살짝 움직이는 상태):
  - 시간 영역 분석은 약간의 노이즈로 인해 피크 탐지가 어려워질 수 있습니다. 예를 들어, [Analysis of photoplethysmogram signal to estimate heart rate during physical activity using fractional fourier transform](https://www.sciencedirect.com/science/article/abs/pii/S0169260722006757)에서는 움직임으로 인한 신호 왜곡을 언급합니다.
  - 주파수 영역 분석은 노이즈에 덜 민감해 더 강건할 가능성이 있습니다.
- Heavily Moving State (격렬하게 움직이는 상태):
  - 시간 영역 분석은 심각한 노이즈로 인해 성능이 크게 저하될 수 있습니다. [A Robust Dynamic Heart-Rate Detection Algorithm Framework During Intense Physical Activities Using Photoplethysmographic Signals](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5713029/)에서는 격렬한 활동 중 PPG 신호의 품질 저하를 보고합니다.
  - 주파수 영역 분석은 스펙트럼 피크를 추적해 일부 노이즈를 줄일 수 있지만, 여전히 움직임으로 인한 추가 주파수 성분이 문제를 일으킬 수 있습니다.

1. 비슷함과 강건함 평가
   - **비슷함(Similarity)**: PPG와 ECG로 측정한 지표(예: 심박수, HRV)가 얼마나 일치하는지 확인합니다.
   - **강건함(Robustness)**: 움직임이나 생리학적 변화에도 불구하고 측정값이 얼마나 안정적으로 유지되는지 평가합니다.
   - 이는 PPG가 웨어러블 환경에서 얼마나 신뢰할 수 있는지를 판단하는 데 핵심적인 질문입니다.

------

### **연구의 가치**

이 연구 방향은 다음과 같은 이유로 가치가 높습니다:

- **실용성**: 웨어러블 기기는 PPG를 주로 사용하지만, 움직임으로 인한 노이즈 때문에 정확도가 떨어질 수 있습니다. 다양한 상태에서 PPG와 ECG를 비교하면 실생활에서의 신뢰성을 높이는 데 기여할 수 있습니다.
- **방법론적 통찰**: 시간 영역과 주파수 영역 분석의 강약점을 밝혀 각 방법이 적합한 상황을 규명할 수 있습니다.
- **혁신 가능성**: 연구 결과는 PPG 기반 심박수나 HRV 모니터링 알고리즘을 개선하는 데 활용될 수 있어, 특히 운동 중이나 동적인 환경에서의 모니터링 성능을 높일 수 있습니다.

------

1. 데이터 수집
   - 정적인 상태, 살짝 움직이는 상태(예: 걷기), 헐떡이며 움직이는 상태(예: 달리기)에서의 데이터셋 수집
2. 전처리
   - 기본 드리프트나 고주파 노이즈를 제거하는 필터를 적용합니다.
   - 특히 PPG의 움직임 노이즈를 줄이는 알고리즘을 사용하세요.
3. 비교 하여 특징 추출
   - **시간 영역**: 심박수, HRV 지표(예: SDNN, RMSSD), 피크 탐지 정확도를 계산합니다.
   - **주파수 영역**: 전력 스펙트럼 밀도를 계산하고 LF/HF 비율 같은 지표를 추출합니다.
4. **결론 도출**

- 어떤 방법(시간 영역 vs 주파수 영역)이 평균 절대 오차(MAE), 상관계수, Bland-Altman 플롯 등을 통해 PPG와 ECG 간 더 높은 비슷함을 보이는지 판단합니다.
- 어떤 방법이 움직임과 생리학적 변화에 더 강건한지 결론 내리고, 웨어러블 기기에 적용할 추천안을 제시합니다.

------

### **예상 결과**

- **시간 영역**: 정적인 상태에서는 정확도가 높겠지만, 움직임이 많아질수록 노이즈로 인해 성능이 저하될 가능성이 큽니다.
- **주파수 영역**: 전체 스펙트럼을 보기 때문에 노이즈에 덜 민감할 수 있어 특히 움직이는 상태에서 강건함을 보일 가능성이 있습니다.
- **상태별 통찰**: 정적인 상태와 움직이는 상태에서 각 방법의 성능 차이를 밝혀 상황별 최적 방법을 제안할 수 있습니다. 정적인 상태에서는 시간 영역으로 짧은 타임포인트로 분석하고 움직임이 일정 이상 많아지면 주파수 영역으로 전체 스펙트럼을 분석한다던가

------

### 

그리고 여러 code가 있는 논문들을 읽었는데 뭘 해야할지 모르겠음.

고도화를 어케 해야하지?

데이터들도 여러 방향으로 만져봤고

어느정도 도메인지식이 쌓이긴 했는데

뭘 해야하지? 그냥 방향성이 안 잡힘. 뭔가 전기전자쪽으로 밖에 안보이는 느낌?

너무 하나의 도메인에 시야가 좁아진 느낌?

다른 도메인도 한번 공부를 해볼까?





