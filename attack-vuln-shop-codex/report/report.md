# 취약점 보고서 — VULN SHOP (SEC v1)
- 대상: http://10.210.136.53:3000
- 테스트 IP 헤더: `X-Forwarded-For: 192.168.64.7`

## 1) 쿠키 변조로 관리자 탈취 (치명적)
- 문제: 인증·인가가 클라이언트 쿠키(`user`, `user_id`, `isAdmin`)에만 의존. `isAdmin=true`, `user=admin` 만으로 자격 증명 없이 관리자 권한 획득.
- 재현:
  1. 필수 헤더와 변조 쿠키를 넣어 요청:  
     `curl -i -H "X-Forwarded-For: 192.168.64.7" -b "user=admin; user_id=1; isAdmin=true" http://10.210.136.53:3000/profile`
  2. 관리자 내비게이션이 표시됨. `/admin/products`, `/admin/users` 접근 시 200과 전체 관리 UI/사용자 목록(약 72kB)이 노출.
- 영향: 관리자 완전 장악(제품 수정, 사용자 삭제, 전체 사용자 열람) 및 추가 공격(XSS 주입 등) 발판.
- 조치: 서버 측 세션 검증 강제, 쿠키 서명/검증, 관리자 라우트에 서버 역할 체크 적용.

## 2) 무제한 프로필 업로드 → 저장형 XSS (높음)
- 문제: `/profile/upload`가 임의 파일을 받아 `/uploads/`에서 `Content-Type: text/html`로 서빙.
- 재현(로그인 후):  
  `curl -i -b cookie.txt -H "X-Forwarded-For: 192.168.64.7" -F "profile_image=@script/payload.html" http://10.210.136.53:3000/profile/upload`  
  이후 `http://10.210.136.53:3000/uploads/payload.html` 요청 시 `<script>alert('upload-test')</script>`가 HTML로 반환. 기존 `/uploads/test.html`도 `<script>alert(1)</script>` 실행.
- 영향: 동일 오리진에서 임의 HTML/JS 호스팅 가능 → 저장형 XSS, 피싱, 자격 증명 탈취, 페이로드 스테이징.
- 조치: 이미지 MIME/매직바이트 검증으로 제한, 웹루트 밖 저장, 안전한 Content-Type으로 서빙.

## 3) Q&A 게시판 저장형 XSS (높음)
- 문제: `/board`의 `content`가 이스케이프 없이 렌더링됨.
- 재현:  
  `curl -i -H "X-Forwarded-For: 192.168.64.7" -H "Content-Type: application/x-www-form-urlencoded" -d "content=<script>alert('pwn')</script>" http://10.210.136.53:3000/board` → 302 후 페이지에서 스크립트 태그가 그대로 표시·실행.
- 영향: 모든 방문자(관리자 포함)에게 지속형 XSS 노출 → 세션 탈취, CSRF, 추가 침해 가능.
- 조치: 출력 시 HTML 이스케이프/정규화, 필요 시 sanitization 라이브러리 사용, CSP·입력 검증 적용.

## 4) 주문 IDOR (높음)
- 문제: 주문 내역/상세가 클라이언트 쿠키 `user_id`와 `id` 쿼리 파라미터만으로 결정됨. 쿠키 변조로 타인 주문 열람 가능.
- 재현:  
  - 변조 쿠키로 주문 목록 조회:  
    `curl -i -H "X-Forwarded-For: 192.168.64.7" -b "user=guest; user_id=2; isAdmin=false" http://10.210.136.53:3000/order` → 사용자 2의 ORDER #2와 상세보기 링크 노출.  
  - 타인 주문 직접 열람:  
    `curl -i -H "X-Forwarded-For: 192.168.64.7" -b "user=guest; user_id=2; isAdmin=false" http://10.210.136.53:3000/order?id=2` → 주문 품목과 “SHIPPING TO: User ID: 2” 표시.
- 영향: 주문/배송 정보 무단 노출, 수정 엔드포인트 존재 시 위조 가능성.
- 조치: 서버 세션 기반 사용자 식별로 권한 확인, 클라이언트 제공 `user_id` 무시, 쿼리 시 `order.id` 소유자 검증.

## 5) CSRF 보호 부재 (중간)
- 문제: 상태 변경 엔드포인트(`/board` POST, `/profile/upload`, `/admin/products/*`, `/admin/users/*`, `/order` 관련) 폼에 CSRF 토큰 없음, SameSite 등 쿠키 보호 미비.
- 영향: 로그인된 사용자(또는 관리자 쿠키를 변조한 공격자)가 악성 페이지 방문 시 게시/업로드/관리자 액션이 강제 실행될 수 있음.
- 조치: CSRF 토큰 적용, SameSite=Lax/Strict 쿠키, 관리자 액션 시 재인증 고려.

## 6) 안전하지 않은 쿠키 (중간)
- 문제: 인증 쿠키 `user`, `user_id`, `isAdmin`에 `HttpOnly`, `Secure`, `SameSite` 미설정.
- 재현: 로그인 응답 헤더 예시:  
  `Set-Cookie: user=pentester; Path=/` (보안 속성 없음)
- 영향: XSS로 쿠키 읽기 가능, 크로스사이트 전송 가능, 평문 HTTP 노출 → XSS/CSRF 리스크 증폭, 세션 탈취 용이.
- 조치: 인증 쿠키에 `HttpOnly; Secure; SameSite=Lax/Strict` 적용, 서명된 서버 세션 사용 권장.

## 7) 로그인 엔드포인트의 자동 계정 생성 (낮음/정보)
- 문제: `/login`에 신규 username을 POST하면 `/signup` 검증 없이 302와 함께 새 쿠키 발급으로 사실상 자가 가입.
- 재현:  
  `curl -i -H "X-Forwarded-For: 192.168.64.7" -H "Content-Type: application/x-www-form-urlencoded" -d "username=newuser123&password=anything" http://10.210.136.53:3000/login` → `user=newuser123`, `user_id` 쿠키 설정.
- 영향: 의도된 가입 통제(예: CAPTCHA/이메일 인증) 우회, 대량 가짜 계정·유저네임 스쿼팅 가능.
- 조치: 로그인과 가입을 분리, 로그인 시 기존 계정 검증·레이트리밋 적용, 검증된 명시적 가입만 허용.
