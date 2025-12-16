# 추가 취약점 탐색 결과

## 추가 발견된 취약점

### 8. Host Header Injection
**심각도**: Medium (CVSS 5.4)

**위치**: 전체 응답의 meta 태그

**설명**:
Host 헤더 값이 검증 없이 HTML 응답에 반영됩니다.

**공격 방법**:
```bash
curl -H "Host: evil.com" "http://192.168.0.28:3000"
```

**증거**:
```html
<meta property="og:image" content="http://evil.com/images/oversized-hoodie.jpg">
<meta property="og:url" content="http://evil.com">
```

**영향**:
- 캐시 포이즈닝
- 피싱 공격
- 패스워드 재설정 링크 조작 가능성

---

### 9. 약한 패스워드 정책
**심각도**: Medium (CVSS 5.3)

**위치**: POST /signup

**설명**:
패스워드 복잡성 검증이 없습니다. 1글자 패스워드로도 회원가입 가능.

**공격 방법**:
```bash
curl -X POST -d "username=a&password=a" "http://192.168.0.28:3000/signup"
```

**증거**:
- `username=a`, `password=a`로 회원가입 성공 (302 Redirect)
- 최소 길이, 복잡성 요구 없음

**영향**:
- 무차별 대입 공격 용이
- 취약한 계정 생성

---

### 10. 세션 관리 취약점
**심각도**: High (CVSS 7.1)

**위치**: 쿠키 기반 인증

**설명**:
세션이 서버 측에서 관리되지 않고 클라이언트 쿠키에만 의존합니다.

**문제점**:
- `user`, `isAdmin`, `user_id` 쿠키가 서명되지 않음
- 세션 만료 없음
- HttpOnly 플래그 미설정

---

### 11. 사용자 계정 열거
**심각도**: Low (CVSS 3.7)

**위치**: POST /signup, POST /login

**설명**:
회원가입 시 중복 사용자명에 대해 다른 응답을 반환하여
기존 사용자명 존재 여부 확인 가능.

---

## 테스트 시도했으나 취약하지 않은 항목

| 테스트 | 결과 |
|--------|------|
| Path Traversal (/uploads/../etc/passwd) | 차단됨 |
| HTTP PUT/DELETE 메소드 | 404 반환 |
| NoSQL Injection | 500 에러 (처리됨) |
| LFI (profile?user=) | 무시됨 |

---

## 사용된 도구 및 명령어

### 수동 테스트
```bash
# Host Header Injection
curl -H "Host: evil.com" "http://192.168.0.28:3000"

# 약한 패스워드 테스트
curl -X POST -d "username=a&password=a" "http://192.168.0.28:3000/signup"

# NoSQL Injection 시도
curl -X POST -H "Content-Type: application/json" \
  -d '{"username":{"$ne":""},"password":{"$ne":""}}' \
  "http://192.168.0.28:3000/login"
```

### 자동화 도구
- SQLMap: SQL Injection 심화 분석
- Gobuster: 디렉토리 스캔
- Nikto: 웹 취약점 스캔
