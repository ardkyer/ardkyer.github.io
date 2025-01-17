---
layout: post
title: "Upstage API Test"
date: 2025-01-11
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:0px 4px 8px rgba(0,0,0,0.8);"

---



## Upstage API Test

API test를 위해 

1. 간략하게 Fast API로 백엔드를 짜서 테스트해보고
2. 잘 되면 Postgresql DB에 연결해서 저장도 해보고
3. 잘 되면 NEXT.js로 프론트엔드도 해보고
4. 잘 되면 배포까지 해보려고 한다. 배포는 최대한 간단히 aws 안 쓰고 백엔드는 render, 프론트엔드는 vercel로 배포 예정이다.



---



구분주기능상세기능설명담당자마감일개발상태검수여부Github issues1.1 DB 설계엔티티 설계User 엔티티 설계- User 기본 정보<br>- OAuth 연동 정보<br>- 권한 설정김백엔드2025-01-15대기-#1UserSubject 설계- 과목 연관 관계<br>- 학습 진도 관리김백엔드2025-01-16대기-#2Study/Feedback 설계- 학습 로그 스키마<br>- 피드백 히스토리김백엔드2025-01-16대기-#31.2 회원가입이메일 가입기본 정보 입력- 이메일/비밀번호 입력<br>- 유효성 검증<br>- 과목 선택 저장김백엔드2025-01-17대기-#4소셜 로그인OAuth 연동- 카카오/네이버/구글 연동<br>- 프로필 정보 연동<br>- 과목 선택 저장김백엔드2025-01-19대기-#51.3 인증/인가JWT 구현토큰 관리- Access/Refresh 토큰<br>- 토큰 갱신 로직김백엔드2025-01-20대기-#6권한 관리- Role 기반 접근 제어<br>- API 엔드포인트 보호김백엔드2025-01-21대기-#7



















