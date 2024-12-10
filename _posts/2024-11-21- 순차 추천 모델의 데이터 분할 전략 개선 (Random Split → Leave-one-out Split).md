---
layout: post
title: "순차 추천 모델의 데이터 분할 전략 개선 (Random Split → Leave-one-out Split)"
date: 2024-11-21
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:0px 4px 8px rgba(0,0,0,0.8);"

---

# 순차 추천 모델의 데이터 분할 전략 개선 (Random Split → Leave-one-out Split)

### 📄 설명

순차 추천 모델의 데이터 분할 전략 개선 (Random Split → Leave-one-out Split) 적용하고 성능 개선 확인해보기

### ✅ 작업할 내용

-  가장 성능이 괜찮았던 gru4rec에 rs -> ls 후 테스트
-  HGN(Hierarchical Gating Network) 모델에 동일한 개선사항 적용 예정
  - PapersWithCode에서 높은 성능을 보이는 모델
  - 동일한 평가 설정으로 공정한 비교 진행 예정
-  다양한 평가 지표(Recall, NDCG 등)에서의 영향 분석 고려

### 논의 사항

1. 순차 모델에 적용할 수 있는 다른 효과적인 분할 전략이 있는지?
2. LS 사용 시 주의해야 할 잠재적 단점은 없는지?
3. 이 설정으로 우선적으로 테스트해볼 만한 다른 순차 모델 추천?

---

### 현재 상황
- 기존에는 순차 추천 모델에 Random Split (RS) 전략을 사용
- GRU4Rec 초기 성능:
  - 검증 점수: 0.1099
  - 리더보드 점수: 0.0558

### 개선 사항
데이터 분할 전략을 Random Split (RS)에서 Leave-one-out Split (LS)로 변경하여 순차적 데이터의 특성을 더 잘 반영하도록 개선

#### GRU4Rec 모델 성능 비교
- **변경 전 (RS 사용)**
  - 검증 Recall@10: 0.1099
  - 리더보드 점수: 0.0558

- **변경 후 (LS 사용)**
  - 검증 Recall@10: 0.1266 (15.2% 향상)
  - 리더보드 점수: 0.0919 (64.7% 향상)

### 기술적 세부사항

#### 설정 변경 내용
```python
# 변경 전 (RS)
'eval_args': {
    'split': {'RS': [0.8, 0.1, 0.1]},
    'group_by': 'user',
    'order': 'TO',
    'mode': {'valid': 'uni100', 'test': 'uni100'},
}

# 변경 후 (LS)
'eval_args': {
    'split': {'LS': 'valid_and_test'},
    'group_by': 'user',
    'order': 'TO',
    'mode': {'valid': 'uni100', 'test': 'uni100'},
}
```

### 개선 효과의 이유
1. **시간 순서 보존**: 
   - LS는 사용자의 상호작용 시간 순서를 유지
   - 순차 모델의 학습에 더 적합한 데이터 구조 제공

2. **현실적인 평가**: 
   - 미래 데이터가 학습 과정에 유입되는 것을 방지
   - 실제 서비스 환경과 더 유사한 평가 환경 제공

3. **순차 패턴 학습**: 
   - 시간에 따른 사용자 선호도 변화를 더 효과적으로 포착
   - 더 정확한 순차적 패턴 학습 가능
