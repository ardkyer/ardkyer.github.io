---
layout: post
title: "Claude API 끌어와서 Discord 봇 만들기"
date: 2024-09-4
typora-root-url: ../
---



맨날 클로드 붙잡고 공부질문하고 개발 하고 있으니까

몇시간만 지나면 토큰 부족하다고 찡찡된다.

솔직히 몇개월 전보다 훨씬 늘어난 거 같긴 한데

유료계정을 두개 둘 수도 없고.. 하다가 걍 API끌어서 쓰면 더 싸려나? 한번 써볼까? 해서 재밌을 것 같아서 진행해보기로 했다.



1. pip install discord.py requests

   라이브러리 설치를 합시다. python없으면 그것부터 설치합시다.

2. Discord 봇 생성 및 디스코드 토큰 발급

   - [Discord 개발자 포털](https://discord.com/developers/applications)에 들어가서 "New Application" 버튼을 클릭해서 새 애플리케이션을 만듭시다.

   - "Bot" 섹션가서 토큰을 생성하고 메모장에 복붙

   - "Bot" 섹션 아래에 얘네 다 체크해줘야 댐

     ![image-20240903184850589](/assets/img/image-20240903184850589.png)

3. Claude API키 발급

   - [Anthropic 웹사이트](https://www.anthropic.com)로 이동, 대충 로그인하고 

   ![image-20240903183424494](/assets/img/image-20240903183424494.png)

   Get API keys 눌러서

   <img src="/assets/img/image-20240903183619796.png" alt="image-20240903183619796" style="zoom:150%;" />

   Create Key누르고 임의의 이름 입력 후 발급된 토큰 메모장에 복붙

   지금 이벤트중인가? 전화번호 등록하면 무료로 5$크레딧도 주넹 굳굳.

4. Python 스크립트 작성

   - discord_claude_bot.py복붙해서 파일 만들기

     ```
     import os
     import discord
     from discord.ext import commands
     import requests
     
     DISCORD_TOKEN = os.getenv('DISCORD_TOKEN', 'your_TOKEN')
     CLAUDE_API_KEY = os.getenv('CLAUDE_API_KEY', 'your_API_KEY')
     
     intents = discord.Intents.default()
     intents.message_content = True
     bot = commands.Bot(command_prefix='!', intents=intents)
     
     @bot.event
     async def on_ready():
         print(f'{bot.user} has connected to Discord!')
     
     @bot.command(name='ask')
     async def ask_claude(ctx, *, question):
         try:
             response = requests.post(
                 "https://api.anthropic.com/v1/messages",
                 headers={
                     "Content-Type": "application/json",
                     "X-API-Key": CLAUDE_API_KEY,  
                     "anthropic-version": "2023-06-01"  
                 },
                 json={
                     "model": "claude-3-sonnet-20240229",
                     "max_tokens": 1000,
                     "messages": [{"role": "user", "content": question}]
                 }
             )
             
             response.raise_for_status() 
             
             claude_response = response.json()['content'][0]['text']  
             await ctx.send(claude_response)
         except requests.exceptions.RequestException as e:
             print(f"API 요청 오류: {e}")
             await ctx.send(f"죄송합니다. API 요청 중 오류가 발생했습니다: {e}")
         except Exception as e:
             print(f"예상치 못한 오류: {e}")
             await ctx.send(f"죄송합니다. 예상치 못한 오류가 발생했습니다: {e}")
     
     bot.run(DISCORD_TOKEN)
     ```

     

5.  코드에 있는 your_TOKEN, your_API_KEY 자리에 디스코드 토큰이랑 Claude API 발급 받은거 각각 붙여넣기

   참고로 Claude 결제창 들어가서 결제해야 될 수 도 있음.

   결제할때 이걸로 뭐 할거냐 물어보면 대충 대답해주면 댐.

   난 무료 5$에 5$만 추가로 Build 플랜으로 결제해놨음.

   개인 프로젝트나 소규모 사용이라면 Build 플랜.

   대규모 사용이나 기업용이라면 Scale 플랜.

   ![image-20240903184337195](/assets/img/image-20240903184337195.png)

매달 결제는 아닌거같고 설정해놓은 한도가 매달 갱신되는 듯?

아래에 최대한도나 자잘한거 설정할 수 있으니 만져보시고.

6. 디스코드에서 서버추가하기 해서 빈방하나 만들기

7. [Discord 개발자 포털](https://discord.com/developers/applications) 여기 다시 들어가서 OAuth2 섹션 들어가서 URL Generator 클릭

   - "SCOPES"에서 "bot"을 체크

   - "BOT PERMISSIONS"에서 아래 권한들 선택

   - View Channels

     Send Messages

     Read Message History

     Embed Links 

     Attach Files 

     Add Reactions

   - 페이지 하단에 생성된 URL을 복사

   - 복사한 URL을 웹 브라우저에 붙여넣고 접속

   - 아까 만든 빈방 서버를 선택하면 봇 서버에 추가 완료

8. 봇 실행

   ![image-20240903185414941](/assets/img/image-20240903185414941.png)

지금 디스코드 들어가면 이 상태일텐데

cmd 열어서 python discord_claude_bot.py 

<img src="/assets/img/image-20240903185604750.png" alt="image-20240903185604750" style="zoom:150%;" />

기상

![image-20240903185618351](/assets/img/image-20240903185618351.png)

!ask 로 질문대면 연동성공

![image-20240903185716444](/assets/img/image-20240903185716444.png)

Claude 구독모델

![image-20240903185857476](/assets/img/image-20240903185857476.png)



Claude API 버전

![image-20240903185816883](/assets/img/image-20240903185816883.png)



그래도 이정도면 괜찮은거같긴한데 이 질문의 토큰 사용량은?
![image-20240903190024927](/assets/img/image-20240903190024927.png)

Input Tokens 31 + Output Tokens 753 = 784 

근데 이거 더해서 계산하는 거 맞나? 784 사용? 0.01$사용 되었다고 뜨는데 생각보다 별로 안 드는 것 같기도 하고..?

만약 클로드 모델 토큰 다 썼는데 급하게 써야 될때 유용하게 쓸듯..?

![image-20240903191225868](/assets/img/image-20240903191225868.png)

근데 사진이나 파일은 첨부안되나 보네.. 이러면 조금 아쉬운데..

다음엔 이어서 디스코드 봇에 이미지 첨부기능을 추가해보자.