---
layout: post
title: "Self-Attentive Sequential Recommendation"
date: 2024-11-18
typora-root-url: ../
---

## Self-Attentive Sequential Recommendation

## Abstract

1. 연구 배경

- 추천 시스템에서 순차적 동적(Sequential dynamics)은 핵심 특징
- 사용자의 최근 행동을 기반으로 '컨텍스트'를 파악하는 것이 목표

1. 기존 접근 방식

- 마르코프 체인(MC): 사용자의 다음 행동을 최근 몇 개의 행동으로만 예측
- 순환 신경망(RNN): 더 장기적인 의미론적 패턴을 파악 가능

1. 기존 방식의 특징

- MC: 매우 sparse한 데이터셋에서 좋은 성능
- RNN: 더 dense한 데이터셋에서 좋은 성능

1. 제안하는 방법 (SASRec)

- Self-attention 기반 순차 모델
- RNN처럼 장기적 의미를 파악하면서도
- MC처럼 적은 수의 행동으로 예측 가능
- 각 시점마다 사용자 행동 기록에서 '관련성 있는' 아이템을 식별

1. 연구 결과

- 희소/밀집 데이터셋 모두에서 SOTA 성능 달성
- MC/CNN/RNN 기반 접근법보다 우수한 성능
- 기존 CNN/RNN 모델보다 10배 더 효율적
- Attention weight 시각화를 통해 모델의 적응성 확인

## Introduction

1. 순차 추천 시스템의 목표

- 사용자의 과거 행동 기반의 개인화 모델과
- 최근 행동 기반의 '컨텍스트'를 결합하는 것

2. 순차적 패턴 캡처의 주요 도전과제

- 입력 공간의 차원이 과거 행동 수에 따라 기하급수적으로 증가
- 이런 고차원 동적 패턴을 어떻게 간결하게 포착할 것인가가 핵심 연구 문제

3. 기존 접근법들의 특징과 한계

a) 마르코프 체인(MC)

- 다음 행동이 이전 행동(들)에만 조건부로 의존한다고 가정
- 아이템 간의 단기 전이(transition) 특성을 잘 포착
- 장점: 높은 희소성(high-sparsity) 환경에서 잘 작동
- 단점: 복잡한 시나리오의 미묘한 동적 특성을 포착하지 못할 수 있음

b) 순환 신경망(RNN)

- 모든 이전 행동을 hidden state로 요약
- 이를 통해 다음 행동을 예측
- 장점: 표현력이 뛰어남
- 단점: 많은 양의 데이터가 필요함

이 부분에서는 두 가지 주요 접근법의 trade-off를 명확히 보여주고 있습니다:

- MC: 단순하지만 sparse 데이터에 강함
- RNN: 복잡하고 표현력이 좋지만 많은 데이터 필요



1. Transformer의 영향

- 기계 번역 분야에서 SOTA 성능과 효율성 달성
- 기존의 CNN, RNN과 달리 'self-attention' 메커니즘만 사용
- 문장 내 단어 간의 구문적/의미적 패턴을 효과적으로 포착

1. SASRec(Self-Attention based Sequential Recommendation) 모델 제안

- Transformer의 self-attention을 추천 문제에 적용
- RNN처럼 과거 모든 행동에서 컨텍스트 추출 가능
- MC처럼 소수의 관련 행동만으로 예측 가능
- 각 시점마다 이전 아이템들에 가중치를 적응적으로 할당

1. 모델의 주요 장점들

a) 성능

- 여러 벤치마크 데이터셋에서 SOTA MC/CNN/RNN 기반 방법들 능가
- 데이터 희소성에 따른 적응적 동작
  - Dense 데이터셋: 장기 의존성 고려
  - Sparse 데이터셋: 최근 활동에 집중

b) 효율성

- Self-attention block이 병렬 처리에 적합
- CNN/RNN 기반 대안들보다 10배 빠른 속도

1. 논문의 분석 범위

- 복잡도와 확장성 분석
- 주요 컴포넌트들의 효과를 보여주는 ablation study
- Attention 가중치 시각화를 통한 모델 동작 분석

이 논문의 핵심 contribution은:

1. Transformer의 self-attention을 추천 시스템에 성공적으로 적용
2. 데이터 희소성에 따라 적응적으로 동작하는 유연한 모델 설계
3. 높은 성능과 효율성의 동시 달성



