---
layout: post
title: "physionet db 중 하나 탐색"
date: 2025-03-12
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:0px 4px 8px rgba(0,0,0,0.8);"
---

[**Wrist PPG During Exercise - 운동 중 손목 PPG**](https://physionet.org/content/wrist/1.0.0/)

여러개 데이터베이스 중 가장 주제에 매칭이 잘 되는 데이터베이스 먼저 시각화해봄

- 8명의 건강한 자원자들로부터 수집되었습니다
- 참가자들은 트레드밀에서 걷기와 달리기를 포함한 다양한 운동 강도로 테스트를 받았습니다
- 각 참가자는 손목에 PPG 센서를 착용했습니다
- 동시에 참조용 ECG(심전도) 데이터도 수집되었습니다

바이너리 데이터 .dat 걷기, 뛰기, 약한 자전거, 강한 자전거

해야할 주요 시각화 - ECG와 PPG가 걷기, 뛰기, 약한 자전거, 강한 자전거에서 어느정도 차이가 나는지



## s3의 데이터

![image-20250327020503810](/assets/img/image-20250327020503810.png)



## === S3_ 0~30초 심박수 분석 결과 요약 ===

피험자 | 활동 | ECG 심박수 | PPG 심박수 | 평균 오차 | 최대 오차

s3 | high_resistance_bike | 244.9 BPM | 177.6 BPM | 69.1 BPM | 164.6 BPM s3 | low_resistance_bike | 243.9 BPM | 130.5 BPM | 113.5 BPM | 145.5 BPM s3 | run | 52.2 BPM | 127.7 BPM | 75.5 BPM | 120.1 BPM s3 | walk | 68.7 BPM | 94.9 BPM | 43.3 BPM | 95.7 BPM

1. 모든 활동에서 PPG로 측정한 심박수오차가 ECG로 측정한 심박수(파란색 막대)보다 일관되게 높게 나타납니다.

강한 자전거 > 약한 자전거 > 뛰기 > 걷기 순서대로 ECG와 PPG의 심박수 오차가 큼

→ 정적인 상태보다 상태가 동적으로 될수록 오차가 커짐을 나타냄.

근데 사람을 바꾼다거나 행동을 바꾼다거나 측정시각을 바꾸거나 하면서 시각화를 계속 관찰하면서 보이는건데 데이터가 생각보다 너무 더러움.

이게 단순히 급격한 운동이 될수록 피크간 간격만 줄어들어서 심박수가 빨라진다 이런 느낌을 기대했는데

아예 안 찍힌 데이터도 많고 ECG던 PPG던 그래프가 너무 자기 맘대로 뛰어서 솔직히 정상적인 데이터분석을 못하고 있음.

그러다보니까 peak도 검출이 잘 안되서 원래는 각각의 그래프에서 peak를 검출해서

ecg와 ppg의 심박수간 비교를 하려했는데 peak도

height_threshold = np.std(ecg_data) * 2 이렇게하니까 peak가 잘 검출이 안되서

height_threshold = np.std(ecg_data) * 1.5 값도 수정해보면서 해보려햇는데 워낙 비정규적이라 애매함.

![image-20250327020516588](/assets/img/image-20250327020516588.png)



피크검출이 안 대서 그래프가 이상하게 나옴

![image-20250327020530979](/assets/img/image-20250327020530979.png)





코드를 잘못짯나? 바이너리 데이터 시각화가 처음이라 잘 모르겠음.

.csv만 시각화해봐서 이걸 그대로 진행해야 할지 .dat → .csv로 변환해야할지?

gpt의 답변 → **.dat 파일**을 그대로 사용하는 것보다는 **.csv 파일**로 변환하는 것이 일반적으로 더 바람직

할거

1. 아직 데이터구조를 잘 이해를 못한거같아서 다시 한번 살펴보고 시각화해봐야할것같음
2. 값이 더러운 field데이터를 어케 처리해야할지에 관한 논문이나 칼럼도 읽어봐야 할듯





