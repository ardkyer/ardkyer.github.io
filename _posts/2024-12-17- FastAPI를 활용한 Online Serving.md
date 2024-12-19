---

layout: post
title: "FastAPI를 활용한 Online Serving"
date: 2024-12-17
typora-root-url: ../
image_style: "max-width:80%; display:block; margin:1em auto; border-radius:10px; box-shadow:0px 4px 8px rgba(0,0,0,0.8);"

---



## 과제 내용

1. 과제 링크

   - [CV](https://drive.google.com/file/d/1RcgywqDilZdZMbaGxpFelk8tazo0Dc-P/view?usp=sharing)
   - [NLP](https://drive.google.com/file/d/1ODvV2q3MMACartEZYdpkN2X71sxh7Y5L/view?usp=sharing)
   - [REC SYS](https://drive.google.com/file/d/1muruJRrZD_DpN-tbo4SwEcR-A0ZVbLI6/view?usp=drive_link)

2. 목표

   - 내가 만든 모델을 서빙하는 API 서버를 만들 수 있습니다.

3. 요구 사항

   - 내가 만든 모델을 서빙하는 API 서버 엔드 포인트를 구현합니다.
   - 위 과제 링크에서 TODO를 검색해보시면 구현해야할 함수를 확인할 수 있습니다.

4. 고려 사항

   - 단순히 모델 출력 결과를 응답하는 것 뿐 아니라, 그 결과를 DB에 저장해야 합니다.

5. 더 공부하면 좋을 내용

   - [FastAPI 공식 문서](https://fastapi.tiangolo.com/)
   - [SQL Model (ORM) 공식 문서](https://sqlmodel.tiangolo.com/) 

6. 과제 제출 방법

   - 프로젝트 파일 전체를 압축하여 제출합니다. 

     <br>

----

## 용량 크기 문제

압축햇는데도 용량이 너무 커서 불필요한 파일들을 제외하고 압축하였다.

```
tar -czvf task2.tar.gz task2/
```

```
tar --exclude='task2/recsys_serving/.venv' \
    --exclude='task2/recsys_serving/__pycache__' \
    --exclude='task2/recsys_serving/*.pyc' \
    -czvf task2.tar.gz task2/
```

<br>

## 웹페이지 렌더링

sqlite3에 데이터를 저장하고 계속 그걸 불러오는게 귀찮아서 index웹페이지에서 user와 isbn , model을 선택해서 값을 불러오게 하였다.

![image-20241217143334767](/assets/img/image-20241217143334767.png)

웹페이지에서 잘 되긴하는데 Rating이 자꾸 음수가 나온다. 원래였으면 고쳤겠지만 서빙하고 엔지니어링 공부니까 나중에 할래..

<br>

---



## 추가기능 구현

**데이터 삭제**

- Delete 버튼 클릭 시 모든 레코드 삭제

- db.sqlite3 파일은 유지되고 내부 데이터만 삭제됨

  

  

  **데이터 조회**

  - 웹페이지 접속 시 자동으로 최근 100개 결과 표시

  - DB에서 데이터를 가져와 테이블 형태로 보여줌

    <br>

    ---

## 데이터의 흐름과 저장 과정

1. **웹 인터페이스 (Frontend)**

- 웹페이지(templates/index.html)에서 사용자가 입력:
  - User ID
  - ISBN
  - Model Type
- 이 데이터는 JavaScript를 통해 API로 전송됨

2. **API 요청 처리 (Backend)**

```
@router.post("/scoring/context")
def predict(request: PredictionRequest) -> PredictionResponse:
    # 1. 요청 데이터 처리
    # 2. 모델로 예측 수행
    # 3. DB에 저장
    # 4. 결과 반환
```

1. **데이터베이스 저장**

- SQLite 데이터베이스 사용
- 파일 위치: `~/task2/recsys_serving/db.sqlite3`

**테이블 구조**

```
class PredictionResult(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int
    isbn: str
    rating: float
    created_at: datetime
```

![image-20241217144634911](/assets/img/image-20241217144634911.png)





![image-20241217151720437](/assets/img/image-20241217151720437.png)

goood. 과제2끗.

심화과제는 Auth이랑 로그를 파일 작성, 부하테스트인데..

흠.. 할까말까.. 나중에 제대로 만들고 하고싶은데.

docker로 배포부터해볼까.

