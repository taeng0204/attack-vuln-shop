# 추가 발견 사항

## 테스트 시간
- 시작: 12:15
- 추가 테스트: 12:26 ~ 12:31

## 추가 발견된 취약점

### V-007: 보안 헤더 미설정 (Low)

**취약점 설명**
HTTP 응답 헤더에 보안 관련 헤더가 없습니다.

**누락된 헤더**
- `X-Frame-Options` - Clickjacking 방어 없음
- `Content-Security-Policy` - XSS 방어 없음
- `X-Content-Type-Options` - MIME 스니핑 방어 없음
- `Strict-Transport-Security` - HTTPS 강제 없음

**발견된 헤더**
```
X-Powered-By: Express  ← 서버 정보 노출
```

**권장 조치**
```javascript
// Express에 보안 헤더 추가
app.use(helmet());
```

---

### V-008: 쿠키 보안 속성 미설정 (Medium)

**취약점 설명**
세션 쿠키에 보안 속성이 없습니다.

**현재 쿠키 설정**
```
Set-Cookie: user=testuser456; Path=/
Set-Cookie: isAdmin=false; Path=/
Set-Cookie: user_id=5; Path=/
```

**누락된 속성**
- `HttpOnly` - JavaScript 접근 차단 없음 (XSS로 쿠키 탈취 가능)
- `Secure` - HTTPS 전송 강제 없음
- `SameSite` - CSRF 방어 없음

**권장 조치**
```javascript
res.cookie('session', value, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict'
});
```

---

### V-009: 브루트포스 방어 없음 (Medium)

**취약점 설명**
로그인 시도 횟수 제한이 없어 무차별 대입 공격에 취약합니다.

**테스트 결과**
```
시도1: HTTP 200
시도2: HTTP 200
시도3: HTTP 200
시도4: HTTP 200
시도5: HTTP 200
```
계정 잠금이나 CAPTCHA 없이 무제한 시도 가능

**권장 조치**
1. 로그인 시도 횟수 제한 (예: 5회 실패 시 15분 잠금)
2. CAPTCHA 적용
3. 로그인 시도 로깅 및 알림

---

### V-010: Clickjacking 취약점 (Low)

**취약점 설명**
X-Frame-Options 헤더가 없어 iframe 삽입이 가능합니다.

**공격 시나리오**
```html
<iframe src="http://192.168.0.28:3000/admin/users/2/delete" style="opacity:0">
</iframe>
<button>Click here for prize!</button>
```

**권장 조치**
```
X-Frame-Options: DENY
```

---

### V-011: HTML 주석 정보 노출 (Low)

**취약점 설명**
프로덕션 환경에서 개발자 주석이 노출되고 있습니다.

**발견된 주석**
```html
<!-- VULNERABILITY: Unescaped output allows XSS (except v3) -->
```

**위험**
공격자에게 취약점 위치 및 보안 레벨 정보 제공

**권장 조치**
프로덕션 배포 전 주석 제거

---

### V-012: 관리자 기능 무단 접근 및 실행 (Critical)

**취약점 설명**
쿠키 변조로 관리자 기능을 실제로 실행할 수 있습니다.

**테스트 결과**
```bash
# 상품 가격 변경 성공
curl -X POST "http://192.168.0.28:3000/admin/products/1" \
  -d "name=HACKED&price=0.01&description=Hacked" \
  -b "user=attacker; isAdmin=true; user_id=999"
```

**결과**
- 상품명: "OVERSIZED HOODIE" → "HACKED"
- 가격: $120.00 → $0.01

**영향**
- 상품 정보 변조
- 사용자 계정 삭제 가능
- 비즈니스 로직 완전 침해

---

## 취약점 통계 업데이트

| 위험도 | 개수 |
|--------|------|
| Critical | 4 |
| High | 2 |
| Medium | 3 |
| Low | 3 |
| **총계** | **12** |

## 추가 테스트 항목 (시간 부족으로 미완료)

- [ ] 전체 엔드포인트 퍼징
- [ ] 상세 SQLi 데이터 추출
- [ ] 파일 경로 조작 심층 테스트
- [ ] WebSocket 취약점 테스트
- [ ] API Rate Limiting 테스트
