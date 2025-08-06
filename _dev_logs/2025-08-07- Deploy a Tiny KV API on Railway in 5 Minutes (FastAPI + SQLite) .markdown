---
layout: post
title: "Deploy a Tiny KV API on Railway in 5 Minutes (FastAPI + SQLite)"
date: 2025-08-05
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:2px 2px 8px rgba(0,0,0,0.8);"
---

# Deploy a Tiny KV API on Railway in 5 Minutes (FastAPI + SQLite)

## Why this?

- **초간단**: FastAPI + SQLite만 사용. 환경변수도 선택 사항.
- **바로 데모 가능**: 3개의 엔드포인트로 기능이 명확—데모, 테스트, 봇/웹훅 초간단 상태 저장
- **Railway 친화적**: 템플릿화해서 한 번의 클릭으로 누구나 복제 배포 가능.

------

## What we’ll build

- `GET /set?key=foo&val=bar` — 값을 저장/갱신
- `GET /get?key=foo` — 값 조회
- `GET /keys` — 저장된 키 목록

> **사용 예시**: 가벼운 봇 상태 저장, 임시 설정 저장, 프로토타입용 세션 대용 등.

------

## 1) 코드 작성 후 깃허브 연결

```
git init
git add .
git commit -m "Tiny KV API on Railway"
git branch -M main
git remote add origin https://github.com/ardkyer/tiny-kv-railway
git push -u origin main
```

# 2) Railway에 배포

1. Railway → **New Project → Deploy from GitHub** → 방금 레포 선택.
2. 환경변수 필요 없음(기본 `data.db`). 원하는 경우 `DB_PATH=data/data.db` 추가 가능.
3. 배포 완료되면 `https://<your>.railway.app/health` 확인 → `{"ok": true}` 나오면 성공.

```
https://web-production-88195.up.railway.app/health
```

![image-20250807024645545](/assets/img/image-20250807024645545.png)

# 3) 템플릿으로 배포

- 프로젝트 화면 우상단 **Create Template** →
  - Name: `Tiny KV API (FastAPI + SQLite)`

![image-20250807024532019](/assets/img/image-20250807024532019.png)

10분안에 배포가능. 

해당 링크 들어가면 확인 가능.

![image-20250807024546364](/assets/img/image-20250807024546364.png)



![image-20250807025422145](/assets/img/image-20250807025422145.png)
