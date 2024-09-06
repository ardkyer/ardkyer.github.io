---
layout: post
title: "Probabilistic Matrix Factorization"
date: 2024-09-04
typora-root-url: ../
---

PMF에서는 user embedding과 item embedding을 평균이 0이고 분산이 α 인
가우시안 분포에서 샘플링합니다.

모델 구현이 어려울 수 있으니 참고 github과 논문의 수식과 알고리즘을 같이 보시는 것을 추천 드립니다!

[Probabilistic Matrix Factorization](https://proceedings.neurips.cc/paper_files/paper/2007/file/d7322ed717dedf1eb4e6e52a37ea7bcd-Paper.pdf)

##  Abstract

Many existing approaches to collaborative filtering can neither handle very large datasets nor easily deal with users who have very few ratings.

기존의 많은 협업 필터링 접근법들은 매우 큰 데이터셋을 처리하거나 평가가 매우 적은 사용자를 쉽게 다룰 수 없습니다.

In this paper we present the Probabilistic Matrix Factorization (PMF) model which scales linearly with the number of observations and, more importantly, performs well on the large, sparse, and very imbalanced Netflix dataset.

이 논문에서는 관측치 수에 대해 선형적으로 확장되는 확률적 행렬 분해(PMF) 모델을 제시하며, 더 중요하게는 크고 희소하며 매우 불균형한 Netflix 데이터셋에서 좋은 성능을 보입니다.

We further extend the PMF model to include an adaptive prior on the model parameters and show how the model capacity can be controlled automatically.

우리는 PMF 모델을 더 확장하여 모델 매개변수에 대한 적응형 사전 확률을 포함시키고, 모델 용량을 자동으로 제어할 수 있는 방법을 보여줍니다.

## Introduction

































