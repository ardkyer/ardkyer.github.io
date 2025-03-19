---
layout: post
title: "Photoplethysmogram Analysis and Applications: An Integrative Review"
date: 2025-02-05
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:0px 4px 8px rgba(0,0,0,0.8);"
---



https://www.frontiersin.org/journals/physiology/articles/10.3389/fphys.2021.808451/full

https://journals.plos.org/globalpublichealth/article?id=10.1371/journal.pgph.0003204

https://arxiv.org/html/2412.17860v1

AI데이터로 연관지을 수 있는 지표들 찾으면서 읽기

**주요 연구 내용**

A) PPG 파형 B) PPG 특징과 임상 응용

C) PPG 노이즈

D) PPG 신호 처리

1. PPG 파형의 기본 구성

- PPG 파형은 크게 두 가지 성분으로 구성됩니다:
  1. 박동성 성분(AC component, Pulsatile component)
     - 심장 박동에 따라 변하는 부분
     - 심장이 뛸 때마다 혈관이 팽창하고 수축하면서 생기는 변화
     - 이 성분을 통해 심박수와 혈관의 상태를 알 수 있음
  2. 비박동성 성분(DC component, Non-pulsatile component)
     - 쉽게말하면 변화가 거의 없는 기본적인 상태 신호
     - 피부 조직, 기본 혈액량 등에 영향을 받음

![image-20250304022011843](/assets/img2025-02-02 Photoplethysmogram Analysis and Applications: An Integrative Review/image-20250304022011843.png)

**광검출기로 기록된 빛의 강도를 반전시켜 획득**

- 관류지수(Perfusion Index) 측정
  - AC와 DC 성분의 비율을 계산해서 혈액 순환이 잘 되는지 확인
  - PI = (AC 성분 / DC 성분) × 100%
- 회색 부분: 피부, 뼈, 근육의 기본 흡수
- 노란색 부분: 정맥혈의 흡수
- 주황색 부분: 동맥혈의 비박동성 성분
- 빨간색 부분: 동맥혈의 박동성 성분 (심장 박동에 따라 변화)

PPG 파형의 주요 특징을 보여주며 다음과 같은 중요한 지점들이 표시되어 있습니다:

1. **주요 피크**

- Systolic Peak (수축기 피크): 심장이 수축할 때 나타나는 최고점
- Diastolic Peak (이완기 피크): 심장이 이완할 때 나타나는 두 번째 피크

1. **특징적인 지점들**

- Pulse Onset: 맥박이 시작되는 지점
- Dicrotic Notch: 이중파 절흔이라고 불리는 특징적인 함몰 부분

1. **구성 요소**

- AC 성분(Pulsatile Component): 심장 박동에 따라 변화하는 박동성 성분
  - 건강한 상태: AC 성분이 크고 뚜렷해서 관류지수가 높게 나옴
  - 혈액순환이 좋지 않은 상태: AC 성분이 작아져서 관류지수가 낮게 나옴
- DC 성분(Non-pulsatile Component): 기본적인 혈류량을 나타내는 비박동성 성분

![image-20250304022036233](/assets/img2025-02-02 Photoplethysmogram Analysis and Applications: An Integrative Review/image-20250304022036233.png)

1. 시간 간격 관련 지표들:

- PPIsystolic: 인접한 수축기 정점들 사이의 간격
- PPIdv/dt: 인접한 최대 기울기 지점들 사이의 간격
- PPIonset: 인접한 맥박 시작점들 사이의 간격
- PWx: 수축기 진폭의 x% 지점에서의 맥박 폭

1. 진폭 관련 지표:

- Systolic Amplitude: 수축기의 최대 진폭
- % of amplitude: 진폭의 백분율 지점

1. 면적 관련 지표(오른쪽 회색 부분):

- Asys: 수축기 영역의 면적
- Adia: 이완기 영역의 면적
- Atotal: 전체 맥박의 면적

이러한 지표들의 임상적 의미:

- 시간 간격: 심박수와 심박 변이도 평가
- 진폭: 혈관 탄성도와 혈류량 평가
- 면적: 심장 기능과 혈관 상태 평가

![image-20250304022055919](/assets/img2025-02-02 Photoplethysmogram Analysis and Applications: An Integrative Review/image-20250304022055919.png)

1. PPG 미분 분석의 역사적 배경

- 1970년대부터 PPG 미분 파형의 생리학적 의미 연구 시작
- Takazawa 등(1998)이 2차 미분 PPG와 노화의 상관관계 발견 후 본격적 연구 시작

1. PPG 미분의 장점

- 시공간적 변화를 더 잘 표현:
  - 피크 위치
  - 변곡점
  - 상승 기울기
  - 하강 기울기
- 원본 PPG 파형에서 감지하기 어려운 중복절흔과 이완기 피크 검출의 대안 방법 제공

**특히 1차, 2차 미분을 통해 원신호에서 발견하기 어려운 특징들을 효과적으로 추출할 수 있음을 보여주고 있어 사용되고 있음**

1. 1차 미분 특징 (VPG: Velocity Plethysmography)

- 임상적 의의:

  - 혈관 질환이나 고혈압 환자에서 더 길어짐
  - SVM 사용 시 87.5% 정확도로 심혈관 질환 분류 가능

  2차 미분 특징 (SDPTG: Second Derivative of Photoplethysmogram)

  - 노화와 유의한 상관관계 보임

![image-20250304022115516](/assets/img2025-02-02 Photoplethysmogram Analysis and Applications: An Integrative Review/image-20250304022115516.png)

1. PPG 분석에 영향을 미치는 대표적인 노이즈 유형

A. 동작 인공물(Motion Artifacts, MAs)

- 발생 원인:
  - 신체 움직임
  - 센서 부착 상태 변화

B. 기준선 변화(Baseline Wandering)

- 발생 원인:
  - 호흡
  - 신체 움직임

C. 저관류(Hypoperfusion)

- 발생 원인:
  - 말초 관류 감소

1. 동작 인공물의 기본 특성

- 주요 발생 원인:
  - 손 움직임
  - 걷기
  - 달리기
- 주파수 범위: 0.01-10 Hz
- 문제점: PPG 주요 주파수 대역(0.5-5 Hz)과 중첩되어 신호 왜곡 발생

1. 동작 인공물의 영향 요인

- 필터 성능 비교 연구:
  - 90개 필터 조합 비교
  - 4차 Chebyshev type II 필터가 최상 성능

B. 독립 성분 분석(ICA) 방법

- PPG와 MA를 독립적 랜덤 벡터로 가정
- 다파장 광원 활용한 다중채널 PPG에 적용
- 성능:
  - 걷기: 99% ECG QRS 위치 일치
  - 빠른 걷기: 96.2% 일치
  - 달리기: 82.0% 일치

C. 적응 노이즈 제거(ANC) 방법

- 가속도계와 PPG 동시 측정
- 적용 사례:
  - 가벼운 동작에서의 MA 제거
  - 걷기/달리기 중 MA 제거
- 2차원 능동 노이즈 제거 알고리즘:
  - 4차 NLMS 적응 필터 사용
  - 신호 왜곡률 52.3%에서 3.53%로 감소

D. 기타 방법들

- Kalman 필터 기반 적응 필터링
- Fourier 시리즈 분석:
  - 정규화된 평균 제곱근 오차 35 dB 감소
- 정지 웨이블릿 변환:
  - 수직/회전 손가락 움동에 의한 MA 제거
  - ECG 대비 HR/HRV 오차 감소

**PPG 신호에서 가장 중요한 노이즈 중 하나인 동작 인공물의 특성과 다양한 제거 방법들을 상세히 설명**

1. 기준선 변동의 특성

- 발생 원인:
  - 호흡
  - 교감신경계 활동
  - 체온조절
- 영향: PPG의 박동성 성분(AC)과 진폭에 변화 초래

1. 기준선 제거 방법

A. 직접 제거 방법: 고역 통과 필터링(HPF)

- 장점:
  - 단순하고 편리한 구현
  - 주파수 대역 차이를 이용한 분리
- 주파수 특성:
  - PPG AC 성분: > 0.5 Hz (정상인 기준)
  - 호흡 성분: 0.15-0.5 Hz
- 단점:
  - PPG AC 성분이 차단주파수보다 낮을 경우 신호 왜곡 발생

B. 간접 제거 방법

1. 보간법(Interpolation)

- 선형 보간법
  - 장점: 저차 다항식으로 간단한 기준선 추정
  - 단점:
    - 정밀도 낮음
    - 미분 불가능
- 3차 스플라인 보간법
  - 장점: 3차 다항식으로 신호의 불연속성 보완
  - 특징: 추정된 기준선을 PPG에서 감산하여 제거

1. 웨이블릿과 LMS 적응 필터 조합

- 처리 과정:
  - 웨이블릿 변환으로 기준선 성분 추출
  - LMS 적응 필터로 기준선 성분 제거
  - 역 웨이블릿 변환으로 최종 신호 복원
- 장점:
  - PPG의 비정상성(non-stationary) 특성에 적합
- 단점:
  - 높은 계산 복잡도
  - 짧은 신호에는 부적합(필터의 전이대역 때문)

1. PPG 파형 재구성의 주요 목적

- 노이즈(특히 동작 인공물)로 인한 PPG 손상 복원
- 파형 개선 및 향상

1. 재구성 방법들

A. 경미한 왜곡의 경우

1. 이산 웨이블릿 변환 방법

- 처리 과정:
  - PPG를 웨이블릿 성분으로 분해
  - 각 성분별 노이즈 제거
  - PPG 신호 복원

1. 고유값 분해(Eigen-decomposition) 방법

- 처리 과정:
  - PPG의 고유 성분 추출
  - 노이즈 성분 제거
  - 주요 성분만으로 PPG 복원

B. 심각한 왜곡의 경우 (대부분의 파형 정보 손실 시)

- 기계학습 기반 접근:
  - 순환 신경망 사용
  - 손상된 부분 감지
  - 해당 부분의 파형 추정
  - 파형 복원

C. 파형 개선을 위한 재구성

- 진폭 변동 보정 방법:
  - PPG 파형의 포락선으로부터 진폭 보상 곡선 생성
  - PPG 진폭 보정
- 적용 상황:
  - 심각한 기준선 변동 발생 시
  - 큰 진폭 변동 발생 시

이 섹션은 PPG 신호의 왜곡 정도에 따른 다양한 재구성 방법들을 소개

![image-20250304022136419](/assets/img2025-02-02 Photoplethysmogram Analysis and Applications: An Integrative Review/image-20250304022136419.png)

1. 그래프 구성

- X축: 시간 (초), 0-16초 범위
- Y축: PPG 신호 강도 (임의 단위, a.u.)
- 표시 내용:
  - 점선: 왜곡된 신호 (Distorted Signal)
  - 굵은 실선: 재구성된 신호 (Reconstructed Signal)

1. 신호 특성 분석 A. 왜곡된 구간 (약 5-11초)

- 심한 노이즈와 신호 불안정성 관찰
- 기본 파형의 식별이 어려움
- 높은 주파수의 변동성 보임
- 신호 진폭의 불규칙한 변화

B. 정상 구간 (0-5초, 11-16초)

- 안정적이고 규칙적인 PPG 파형
- 명확한 수축기와 이완기 패턴
- 일정한 진폭과 주기성

1. 재구성 결과

- 왜곡 구간에서도 원래 PPG 파형의 특성을 성공적으로 복원
- 신호의 주기성과 진폭이 잘 유지됨
- 노이즈가 효과적으로 제거됨

1. 재구성의 효과

- 신호의 연속성 유지
- 파형의 기본 특성 보존
- 임상적으로 의미 있는 분석이 가능한 수준으로 복원

![image-20250304022154267](/assets/img2025-02-02 Photoplethysmogram Analysis and Applications: An Integrative Review/image-20250304022154267.png)

1. Figure 8 분석

- 구성:
  - 상단: PPG 신호 파형
  - 하단: SQI(Signal Quality Index) 표시
    - Good: 양호한 신호 품질
    - Bad: 불량한 신호 품질
- 특징:
  - 시간에 따른 신호 품질 변화를 이진적으로 표시
  - 신호 왜곡이 발생한 구간을 'Bad'로 표시

1. 신호 품질 지수(SQI)의 중요성

A. 기본 개념

- 신호 품질(신호 대 잡음비 등) 평가에 사용
- 신호 분석 전 사용 가능성 평가
- 펄스 품질 평가 포함

B. 필요성

- 파형 품질이 분석 정확도에 직접적 영향
- 저품질 신호의 문제점:
  - 오경보 증가
  - 분석 오류 가능성 증가
  - 임상적 오진 위험

1. 임상적 중요성

A. 실시간 환자 모니터링

- 활력징후 실시간 감시
- 문제점:
  - 움직임이나 센서 부착 상태로 인한 오경보
  - 의료진의 노이즈 스트레스
  - 신속한 대응 방해

1. 초기 규칙 기반 방법 (Early Rule-based Methods)

- 기본적인 파라미터 기반 평가
  - 진폭 (Amplitude)
  - 박동 간격 (Beat interval)
  - 파형 특징값 (Feature values)
- 특정 임계값을 기준으로 순차적 평가
- 간단하지만 유연성이 부족한 한계

1. 통계적 특징 기반 방법 (Statistical Feature-based Methods)

- 왜도(Skewness)와 첨도(Kurtosis) 도입
  - Krishnan et al. (2008): 기본적인 통계적 특징 활용
  - Selvaraj et al. (2011): Shannon 엔트로피 추가
- 장점:
  - PPG 파형의 전반적 특성 반영 가능
  - 동작 노이즈와의 구분이 비교적 명확
- 한계:
  - 절대값 기반 왜곡 감지의 어려움

1. PQR 방법의 등장 (Song et al., 2019)

- 종합적 접근법 도입:
  - P: 고주파 노이즈 영향
  - Q: 기준선 효과
  - R: 동작 인공물 효과
- 각 요소를 통합하여 최종 품질 점수 산출

1. 기계학습 도입기

- Sukor et al. (2011): 의사결정트리 활용
- Pradhan et al. (2019): 다양한 기계학습 분류기 비교
  - k-NN
  - SVM
  - 나이브 베이즈
  - 의사결정 트리
  - 랜덤 포레스트

1. 딥러닝 시대 (2019-현재) A. CNN 기반 접근

B. 고급 딥러닝 구조

- Liu et al. (2020):
  - 퍼지 신경망 도입
  - 2D 이미지 변환 접근
  - ResNet-50 활용

C. 최신 발전

- Guo et al. (2021):
  - U-Net 구조 활용
  - 능동 윤곽 기반 손실 함수 도입
  - DICE 점수 0.87-0.91 달성

발전 동향의 특징:

1. 단순 → 복잡: 규칙 기반에서 딥러닝까지 발전
2. 고정 → 적응적: 고정된 임계값에서 적응적 평가로 발전
3. 단일 특징 → 다중 특징: 통합적 접근법으로 발전
4. 수동 → 자동: 자동화된 특징 추출과 평가로 발전

현재 과제:

- 더 많은 데이터셋 확보 필요
- 실시간 처리 능력 향상
- 다양한 환경에서의 안정성 확보
- 계산 효율성 개선

AI데이터로 활용할 수 있어보이는 것들?

**관류지수지표 관류지수 시간적지표**

**PPG미분지표**

**PPG노이즈 유형 제거**

**PPG 신호 파형 분석**

http://journal.dcs.or.kr/_PR/view/?aidx=18449&bidx=1424#!po=55.0000

CNN 기반의 PPG 신호 동잡음 구간 검출

1. 연구의 배경과 목적

- PPG는 빛을 이용해 혈류량을 측정하는 신호
- 사용자의 움직임으로 인한 신호 왜곡(동잡음)이 큰 단점
- 기존 방법들(약 83-88% 정확도)보다 더 정확한 동잡음 검출 방법 필요

1. 합성곱 신경망(CNN) 활용

- 연속적인 PPG 신호를 1맥박 단위로 분리
- 분리된 신호를 이미지로 변환하여 학습 데이터로 활용
- PhysioNet 데이터베이스의 정상신호 3,000개와 동잡음 신호 3,000개 사용

![image-20250304022224525](/assets/img2025-02-02 Photoplethysmogram Analysis and Applications: An Integrative Review/image-20250304022224525.png)

![image-20250304022235953](/assets/img2025-02-02 Photoplethysmogram Analysis and Applications: An Integrative Review/image-20250304022235953.png)

1. 연구 결과

- 약 92%의 정확도로 동잡음 구간 검출 성공
- 기존 연구들보다 4-9% 향상된 정확도 달성

https://www.nature.com/articles/s41598-023-36068-6

다중 채널 PPG 신호는 동시에 수집되었지만, 다른 채널 간의 BP 예측 성능에 상당한 차이가 있는 것은 각 사용자마다 PPG 센서에 얹은 손가락의 위치 차이와 손가락의 특성 차이 때문일 수 있다. 따라서 단일 채널 PPG 센서를 통해 모든 사용자에 대해 일관되게 PPG 신호를 수집하는 것은 어렵다고 할 수 있습니다.

호흡 신호 추출을 위한 PPG2RespNet 모델

https://pubmed.ncbi.nlm.nih.gov/39287773/

딥러닝 논문들이 조금 이해하기 어려워서 머신러닝 논문쪽으로 탐색

그러나 요즘 PPG관련 연구들은 아무래도 머신러닝 보다는 딥러닝.

계속 논문을 찾아보다 든 의문

근데 웨어러블기기에 ppg 쓸거면 딥러닝 어차피 무거워서 못쓰는거 아닌가?

웨어러블 기기에 PPG를 활용할 때, 딥러닝 모델을 사용하는 것은 여러 가지 제약이 있을 수 있습니다. 특히, 웨어러블 기기는 일반적으로 전력 소모가 낮고, 컴퓨팅 자원이 제한적인 경우가 많습니다. 이러한 이유로, 복잡한 딥러닝 모델을 직접 웨어러블 기기에 구현하는 것은 어려울 수 있습니다.

다만, 최근에는 모델 경량화와 엣지 컴퓨팅 기술이 발전하면서, 웨어러블 기기에서도 일부 딥러닝 모델을 실행할 수 있는 방법들이 연구되고 있습니다. 예를 들어, 모델 프루닝이나 모델 양자화와 같은 기법을 통해 모델의 크기와 복잡성을 줄일 수 있습니다.

그래서 최신 애플워치 이런거에는 AI 가 머신러닝이 들어가? 딥러닝이 들어가?

https://b2bnews.co.nz/articles/ai-features-you-didnt-know-existed-on-your-apple-watch/

https://www.hackster.io/news/apple-watch-series-9-launches-with-quad-core-neural-engine-for-on-wrist-machine-learning-c977175582fc

ECG 데이터 분석과 같은 특정 기능에서 딥러닝이 사용되지만, PPG 신호 처리와 같은 다른 기능에서는 주로 머신러닝이 사용됩니다.

최신이고 인용도 높은 PPG관련 연구

최적화된 머신러닝 알고리즘이나 딥러닝 모델 경량화 쪽을 탐구하는게 맞는 방향인지

아니면 그래도 최신기술동향인 딥러닝쪽을 더 보는게 맞는 방향인지







































