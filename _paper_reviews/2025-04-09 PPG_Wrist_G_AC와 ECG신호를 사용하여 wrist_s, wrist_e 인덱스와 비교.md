---
layout: post
title: "PPG_Wrist_G_AC와 ECG신호를 사용하여 wrist_s, wrist_e 인덱스와 비교"
date: 2025-04-09
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:0px 4px 8px rgba(0,0,0,0.8);"
---

## PPG_Wrist_G_AC와 ECG신호를 사용하여 wrist_s, wrist_e 인덱스와 비교

finger_s, finger_e를 안쓰고 wrist_s, wrist_e를 쓴 이유:

1. 손가락은 심장으로부터 더 멀어 맥파 전달 시간이 더 길고, 그로 인해 지연이 크게 나타남
2. 손목이 웨어러블 디바이스의 일반적인 측정위치이므로 실제 응용에 참조할 수 있는 실질적 신호이지 않을까해서

![image-20250508141804490](/assets/img/image-20250508141804490.png)

10초 테스트

→ 6초부터 검정 점(마킹)이 찍히지 않음. 이는 성능 지표에 영향을 줄 수 있으므로 전체로 확장해서 확인해봄.

![image-20250508141822426](/assets/img/image-20250508141822426.png)

확인 결과

흰색 배경 → 검정 점이 안 찍힌 곳 → HR 마킹이 안 찍힌 곳(측정오류로 예상)

![image-20250508141857071](/assets/img/image-20250508141857071.png)

심박 검출과 같은 이벤트 기반 신호 처리이기때문에 얼마나 마킹한 신호와 가깝냐.

정확한 위치보다는 "심박을 검출했는가/놓쳤는가” 분류형(categorical) 방식로 산정

**평가 기준 - `evaluate_algorithm` 함수 기반**:

- 각 참조 간격(실제 심박)의 중앙 지점을 계산합니다.
- 검출된 피크가 이 중앙 지점으로부터 허용 오차(tolerance) 범위 내에 있는지 확인합니다.
- 허용 오차는 기본적으로 각 간격 길이의 20%로 설정됩니다.

![image-20250508141915328](/assets/img/image-20250508141915328.png)

## SSF가 PPG에서만 성능이 낮은 이유

1. 신호 형태의 차이:
   - ECG는 뚜렷한 R-피크를 가지는 반면, PPG는 더 넓고 완만한 피크 형태를 가집니다.
   - SSF는 급격한 상승 구간을 감지하는데 효과적이므로 R-피크가 뚜렷한 ECG에서 더 잘 작동합니다.
2. 노이즈 민감성:
   - PPG 신호는 ECG보다 일반적으로 더 많은 노이즈와 아티팩트를 포함합니다.
   - SSF 알고리즘은 이러한 노이즈에 민감할 수 있습니다.

## SSF 알고리즘 구현 및 원리 설명

SSF 알고리즘은 다음과 같은 단계 구현되어 있습니다:

1. **신호 미분 (기울기 계산)**:첫 단계에서는 신호의 기울기(1차 미분)를 계산합니다. 이는 변화율을 측정합니다.

   ```python
   diff_signal = np.diff(signal)
   diff_signal = np.append(diff_signal, 0)# 길이 맞추기
   ```

2. **Slope Sum Function 계산**:이 단계에서는:

   ```python
   window_size = int(0.2 * fs)# 200ms 윈도우
   ssf = np.zeros_like(diff_signal)
   
   for i in range(len(diff_signal)):
       window_end = min(i + window_size, len(diff_signal))
       window = diff_signal[i:window_end]
   # 양의 기울기만 합산
       ssf[i] = np.sum(np.maximum(0, window))
   ```

   - 각 지점에서 앞으로 200ms 윈도우 내의 기울기 값을 확인합니다
   - **중요**: 양의 기울기만 합산합니다 (즉, 신호가 상승하는 부분만 고려)
   - 이렇게 하면 심박의 급격한 상승 구간에서 높은 값을 가지는 새로운 신호가 생성됩니다

3. **SSF 정규화**:SSF 값을 0~1 사이로 정규화하여 임계값 설정을 쉽게 합니다.

   ```python
   ssf_max = np.max(ssf)
   if ssf_max > 0:
       ssf_normalized = ssf / ssf_max
   else:
       ssf_normalized = ssf
   ```

4. **피크 검출**:정규화된 SSF 신호에서 높이가 0.3 이상이고, 서로 300ms 이상 떨어진 피크를 검출합니다.

   ```python
   peaks, _ = find_peaks(ssf_normalized, height=0.3, distance=int(0.3 * fs))
   ```

아마 파라미터를 조금 바꾸거나하면 성능이 나아질 가능성이 보임

ECG는 성능이 잘 나와서 이 방법을 당장 버리진 않을것같음 아래에

이걸 연구 고도화하려하는데 어케할까. 원래 내 방향성은

지금 ecg가 더 성능 좋잖아? 이제 이 ecg를 최대한 성능을 높이고 ground truth로 하여서 다시 ppg를 맞춰서 기존에 참조 간격은 회색 배경으로 표시된 구간으로, 각 간격의 중앙 지점이 실제 심박으로 비교해서 한 성능보다 더 높게 끌어올리는게 목표긴햇거든? 어케 생각해?

- ECG 알고리즘 최적화:
  - 현재 ECG 미분 기반과 SSF 알고리즘이 좋은 성능을 보이고 있으니, 이 두 알고리즘을 더 세밀하게 튜닝합니다.
  - 파라미터 최적화: 윈도우 크기, 임계값, 거리 파라미터 등을 미세 조정합니다.
  - 두 알고리즘의 앙상블 방식을 고려해 보세요. 예를 들어 두 알고리즘의 결과를 종합하여 더 정확한 검출을 시도할 수 있습니다.
- ECG 기반 Ground Truth 생성:
  - 최적화된 ECG 알고리즘으로 검출된 피크를 새로운 ground truth로 설정합니다.
  - 기존의 회색 배경 참조 구간을 완전히 대체하기보다는, 불일치하는 부분을 분석하여 참조 구간을 개선하는 방식도 고려할 수 있습니다.
- PPG 알고리즘 개선:
  - 현재 코드에서는 단순 임계값, 미분 기반, SSF 세 가지 방식을 사용했는데, 이를 더 고도화할 수 있습니다.
  - 시간 지연 요소 고려: PPG는 ECG에 비해 심장 활동이 감지되는 데 시간 지연이 있습니다. 이 지연을 자동으로 추정하고 보정하는 알고리즘을 추가하세요.
  - 적응형 알고리즘: 신호 품질에 따라 적응적으로 파라미터를 조정하는 알고리즘을 개발합니다.
- 머신러닝 접근 도입:
  - ECG 기반의 ground truth를 학습 데이터로 활용하여 PPG 신호에서 심박을 검출하는 모델을 훈련시킵니다.
  - 1D CNN, LSTM, Transformer 등의 딥러닝 모델이 효과적일 수 있습니다.
  - 특히 두 신호 간의 상관관계를 학습하여 PPG만으로도 ECG 수준의 정확도를 달성하는 것이 목표가 될 수 있습니다.

우선 ECG, PPG 둘 다 미분적방법, SSF방법 성능지표를 최대한 끌어올려 보기로 함. 왜 SSF는 ECG에는 성능이 높은데 PPG에서는 저렇게 현저히 낮은지 이유도 탐색해보기로 함.

이거 성능 끌어올리는거 몇개 찍고

논문 하나 읽은거 간략히 요약

**Fast Parabolic Fitting: An R-Peak Detection Algorithm for Wearable ECG Devices**

https://pmc.ncbi.nlm.nih.gov/articles/PMC10649215/

- 기존 알고리즘 최적화

  :

  - 미분 기반 및 SSF 알고리즘의 파라미터 튜닝
  - 각 알고리즘의 장단점 분석 및 문제점 식별

- 포물선 피팅 구현 및 테스트

  :

  - 논문에서 제시한 단일 파라미터 포물선 피팅 알고리즘 구현
  - 같은 데이터셋에서 성능 비교

- 앙상블 접근법 개발

  :

  - 가장 성능이 좋은 2-3개 알고리즘을 조합한 앙상블 모델 구축
  - 가중치 최적화를 통한 성능 극대화

- 시간 지연 보정 및 품질 기반 적응 처리

  :

  - PPG 신호의 시간 지연 특성 모델링
  - 신호 품질에 따라 알고리즘을 동적으로 선택하는 메커니즘 구현

포물선 피팅과 FTBO 앙상블 접근법을 결합한 ECG ground truth 생성 후, 시간 지연 보정을 적용하는 전략은 매우 탄탄합니다. 여기에 품질 기반 적응형 처리까지 더하면 실용적인 시스템 구축이 가능할 것입니다.

피크로 하지말고 시간을 범위로 둬서 개수로 체크해서 계산하기 그러면 손목이던 손가락이던 지연시간 상관없이 판별가능하니까.

API체크 가능한 링같은거 한번 알아보기
