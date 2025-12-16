## 2025-12-11 Recon Notes

- Target: http://192.168.0.28:3000, testing from Kali; exported MY_IP=10.0.0.102 for headers.
- Reminder: include `X-Forwarded-For: 10.0.0.102` on every request; avoid DoS.
- Initial check via curl with header returned 200 OK, Express app, homepage shows product grid (6 items) and nav to `/board`, `/login`, `/signup`; SEC toggle indicates v1.
- Q&A board (`/board`): unauthenticated form posts to `/board`. Source comments call out unescaped output; verified stored XSS with `curl -d "content=<script>alert('xss')</script>"` then `curl /board | grep alert('xss')` showing payload rendered.
- Created user `attacker:pass123`; cookies set (`user`, `isAdmin`, `user_id`). Tampering cookie `isAdmin=true` surfaced admin nav and unlocked `/admin/products` (product edit forms) and `/admin/users` (full user list with delete actions) without server-side checks → privilege escalation by client-side trust.
- Profile upload accepts arbitrary files and serves them from `/uploads/` without content-type/extension filtering. Uploaded `profile_payload.html` containing `<script>alert('img')</script>` and retrieved at `/uploads/profile_payload.html` with `Content-Type: text/html` (publicly reachable XSS-able file).
- Login SQLi: POST `/login` with `username=' OR '1'='1&password=' OR '1'='1` returned Set-Cookie `user=admin; user_id=1` despite invalid creds → authentication bypass via injection. Combined with cookie flip `isAdmin=true` grants full admin access.
- CSRF 없음: 로그인/회원가입/게시글/프로필 업로드/관리자 상품·사용자 관리 폼 모두 토큰 부재. 쿠키에도 HttpOnly/Secure/SameSite 없음 → 변조·XSS 탈취·CSRF 모두 용이.
- 관리자 상품명 XSS 시도 시 `<script>`는 이스케이프되어 렌더링(현재 v1에서 상품 필드는 엔코딩됨). 주요 XSS는 게시판·업로드 경로에 집중.
- 세션 스푸핑 및 IDOR: 브라우저 없이 쿠키 `user=guest; user_id=2` 주입만으로 로그인 없이 주문/프로필 접근 가능. `/order` 목록에 주문 #2 노출, `order?id=1`로 관리자 주문 상세까지 열람(Shipping info 포함) → 사용자 검증·권한 체크 부재.
- Upload path handling trims `../` (filename normalized to basename), but still allows arbitrary file types and overwrites same-name files.
- 추가 퍼징: ffuf(common.txt, 60~120s 제한)으로 추가 경로 시도했으나 의미 있는 응답 없음. 수동 확인한 `/cart`, `/checkout`, `/api`, `/health`, `/ping`, `/debug` 모두 404.
