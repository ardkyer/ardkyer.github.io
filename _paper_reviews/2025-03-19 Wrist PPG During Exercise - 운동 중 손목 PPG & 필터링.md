---
layout: post
title: "Wrist PPG During Exercise - 운동 중 손목 PPG & 필터링"
date: 2025-03-19
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:0px 4px 8px rgba(0,0,0,0.8);"
---



[Wrist PPG During Exercise - 운동 중 손목 PPG](https://physionet.org/content/wrist/1.0.0/)

저번에 하던 시각화 마무리

걷기, 뛰기, 저저항 자전거, 고저항 자전거에서의 ECG와 PPG 그래프 비교

![image-20250319153736148](/assets/img2025-03-19 Wrist PPG During Exercise - 운동 중 손목 PPG & 필터링/image-20250319153736148.png)



![image-20250319153804276](/assets/img2025-03-19 Wrist PPG During Exercise - 운동 중 손목 PPG & 필터링/image-20250319153804276.png)



![image-20250319153825788](/assets/img2025-03-19 Wrist PPG During Exercise - 운동 중 손목 PPG & 필터링/image-20250319153825788.png)



![image-20250319153841293](/assets/img2025-03-19 Wrist PPG During Exercise - 운동 중 손목 PPG & 필터링/image-20250319153841293.png)



- 모든 활동에서 ECG 이후에 PPG 신호의 상승이 뒤따르는 패턴이 관찰

저저항 > 고저항 > 걷기 > 달리기

자전거활동은 손목이 고정된 채로 채집하기에 걷기와 달리기보다 더 안정적임



근데 필터링이 안대서 사실 그래프만으로 뭘 판별하기는 어려워보임

## 필터링 방법 탐색

[**Removal of Motion Artifacts in Photoplethysmograph Sensors during Intensive Exercise for Accurate Heart Rate Calculation Based on Frequency Estimation and Notch Filtering**](https://pmc.ncbi.nlm.nih.gov/articles/PMC6696451/)

**주파수 추정 및 노치 필터링에 기반한 정확한 심박수 계산을 위한 집중 운동 중 광체계 센서의 모션 아티팩트 제거**

<br>

## 노치필터를 사용하는 이유

PPG 데이터에서 60Hz를 제거하는 이유는 주로 **전력선 잡음** 때문입니다. 전력선 잡음은 전기 시스템에서 발생하는 50Hz 또는 60Hz의 주파수 성분으로, PPG 신호와 유사한 주파수 대역에 위치할 수 있습니다. 이 잡음은 PPG 신호의 품질을 저하시키고, 정확한 심박수 추정이나 혈중 산소 포화도(SpO2) 측정에 영향을 미칠 수 있습니다.

그래서 SciPy 라이브러리 **`scipy.signal.iirnotch`** 를 사용하여 60Hz를 감쇠를 했는데 아직까지 잘 이해가 안댐. 왜 해당 주파수를 감쇠해야 하는지? 위에 설명으로 잘 이해가 가지 않음



A: 전류때매. 전기신호가 60Hz가 생체신호안에 들어가버림. 얘를 들어 음성신호 같은 경우는 어차피 주파수가 높기때문에 상관없는데 생체신호는 그안에 들어가 버려서 필터링이 필요함.



## 다시 주파수부터

### 주파수(Hz)의 기본 개념

주파수는 1초 동안 발생하는 진동이나 사이클의 횟수를 나타내며, 단위는 Hz(헤르츠)입니다.

- 1 Hz = 1초당 1회 진동
- 10 Hz = 1초당 10회 진동

### 심박수와 주파수의 관계

심박수는 분당 심장 박동 횟수(BPM, Beats Per Minute)로 표현됩니다.

- 60 BPM = 1초당 1회 박동 = 1 Hz
- 120 BPM = 1초당 2회 박동 = 2 Hz

따라서 심박수를 주파수로 변환하는 공식은: **주파수(Hz) = 심박수(BPM) ÷ 60**

### ECG 신호의 주파수 성분

ECG 신호는 다양한 주파수 성분으로 구성됩니다:

1. 기본 심박수 주파수:
   - 일반적인 휴식 시 심박수: 60-100 BPM = 1-1.67 Hz
   - 운동 시 심박수: 최대 200 BPM = 3.33 Hz

그러면 필터링을 할때

일반적인 휴식과 운동할때의 경우를 같은 기준으로 주파수를 필터링하면 안되지 않나?

A: 순서가 달라서 안댐. 우리가 그걸 운동이라고 알고 필터링을 할 수 없기에 불가능. Real-world에서 사용가능한지 생각해야 함.

뭔가 옛날 비트코인 예측 했을때 생각났음. 그때 이 기법을 Real-world에 적용가능한지 말이 많았는데.



## S3_run 노치, 밴드패스 필터 후 시각화

## 시간도메인 그래프

![image-20250319154204217](/assets/img2025-03-19 Wrist PPG During Exercise - 운동 중 손목 PPG & 필터링/image-20250319154204217.png)

## 주파수 도메인 그래프

![image-20250319154235262](/assets/img2025-03-19 Wrist PPG During Exercise - 운동 중 손목 PPG & 필터링/image-20250319154235262.png)



원본

원본 → 노치 필터

원본 → 노치 필터 → 밴드패스 필터

Q: 보면 노치 필터를 적용하면 60hz에서 감쇠하는게 보이지만 결국 밴드패스필터를 거치면 저렇게 되는데 저러면 노치필터를 사용할필요없이 넘어가고 바로 밴드패스로가면 되는거 아닌가?

GPT Answer:

- **전원 노이즈의 강도**: 60Hz 전원 노이즈는 종종 매우 강해서 밴드패스 필터만으로는 완전히 제거하기 어려울 수 있습니다.
- **단계적 필터링의 장점**: 강한 특정 주파수 노이즈를 먼저 제거한 후 밴드패스 필터를 적용하면 전체적인 필터링 품질이 향상될 수 있습니다.

실제로는 응용 분야와 신호 특성에 따라 노치 필터를 생략하고 적절한 밴드패스 필터만 사용하는 경우도 있습니다. 하지만 의료 장비와 같이 신호 품질이 중요한 경우에는 단계적 필터링 접근 방식이 더 안전하고 효과적일 수 있습니다.

교수님 추가 Ansewr: 필터링이 정확히 0과 1로 필터링하지 않기 때문에 여러개가 더 효과가 좋음



## 시간 도메인 그래프 

![image-20250319154339103](/assets/img2025-03-19 Wrist PPG During Exercise - 운동 중 손목 PPG & 필터링/image-20250319154339103.png)



## 주파수 도메인 그래프

![image-20250319154400618](/assets/img2025-03-19 Wrist PPG During Exercise - 운동 중 손목 PPG & 필터링/image-20250319154400618.png)





![image-20250319154420375](/assets/img2025-03-19 Wrist PPG During Exercise - 운동 중 손목 PPG & 필터링/image-20250319154420375.png)



## 필터링을 적용한 후 ECG, PPG의 그래프가 안정화되어 주요요소가 강조댐.



아마 여기서 이제 지연시간이 달라서 이 지연시간을 맞춰서 ECG를 그라운드로해서 PPG를 맞춰나갈지

단순 peak를 검출하여 이 peak로 하여금 PPG를 ECG에 맞춰나갈지 고민해봐야댈 것 같음.





