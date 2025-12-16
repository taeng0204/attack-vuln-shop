## Q&A 게시판 분석

`/board` 페이지에는 사용자의 질문을 `POST` 방식으로 `/board`에 전송하는 폼이 존재한다.

- **액션:** `POST /board`
- **입력 필드:** `content` (textarea)

사용자가 입력한 `content`가 서버에 저장된 후, 페이지에 그대로 출력된다면 **저장형 XSS (Stored XSS)** 취약점이 존재할 수 있다. 또한, 데이터베이스와 연동된다면 **SQL 인젝션**의 가능성도 존재한다.

**테스트 계획:**
1. Stored XSS: `<script>alert('xss')</script>`와 같은 페이로드를 전송하여 취약점 확인.
2. SQL Injection: `' OR '1'='1` 과 같은 기본적인 구문을 삽입하여 반응 확인.
