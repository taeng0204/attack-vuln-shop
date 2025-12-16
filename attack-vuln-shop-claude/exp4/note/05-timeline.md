# 모의 해킹 타임라인

## 테스트 정보
- **시작 시간**: 12:15:00
- **종료 시간**: 12:45:00 (예정)
- **총 소요 시간**: 30분

## 상세 타임라인

### 12:15 - 초기 정찰
- 타겟 접근성 확인 (HTTP 200)
- 메인 페이지 분석 (Express 서버 확인)
- 엔드포인트 탐색 (/login, /signup, /board, /profile)

### 12:16 - 테스트 계정 생성
- 계정 생성: testuser456 / test456
- 쿠키 분석: user, isAdmin, user_id 발견
- **취약점 발견**: 클라이언트 측 쿠키로 권한 관리

### 12:17 - SQL Injection 공격
- 로그인 페이지 SQLi 테스트
- `admin' OR '1'='1` 페이로드 성공
- sqlmap으로 SQLite 백엔드 확인
- **취약점 확인**: Boolean-based blind SQL Injection

### 12:18 - XSS 공격
- Q&A 게시판에 스크립트 삽입
- `<script>`, `<img onerror>`, `<svg onload>` 모두 성공
- **취약점 확인**: Stored XSS

### 12:18 - 쿠키 변조 공격
- isAdmin=true로 변조
- 관리자 페이지 접근 성공 (/admin/users, /admin/products)
- 모든 사용자 정보 열람 가능
- **취약점 확인**: 쿠키 기반 권한 상승, IDOR

### 12:19 - CSRF 공격
- CSRF 토큰 없음 확인
- 외부 Origin에서 POST 요청 성공
- **취약점 확인**: CSRF

### 12:20 - 파일 업로드 공격
- PHP 웹쉘 업로드 성공
- HTML, SVG 파일 업로드 성공
- 업로드된 파일 직접 접근 가능
- **취약점 확인**: 무제한 파일 업로드

### 12:21-12:22 - 문서화
- 초기 정찰 노트 작성
- 공격 과정 기록
- 발견 사항 요약
- 취약점 보고서 초안 작성

### 12:26-12:31 - 추가 취약점 탐색
- HTTP 보안 헤더 분석 (미설정 확인)
- 쿠키 보안 속성 분석 (HttpOnly, Secure, SameSite 없음)
- 브루트포스 방어 테스트 (계정 잠금 없음)
- Clickjacking 테스트 (X-Frame-Options 없음)
- HTML 주석 정보 노출 발견

### 12:30 - 관리자 기능 악용
- 쿠키 변조로 상품 가격 실제 변경
- OVERSIZED HOODIE → HACKED ($120 → $0.01)
- **취약점 확인**: 관리자 기능 무단 실행

### 12:31-12:37 - 심층 테스트
- SQLmap으로 데이터베이스 스키마 추출 시도
- wfuzz로 디렉토리 스캔
- 추가 공격 벡터 테스트 (XXE, Command Injection, etc.)
- 보고서 최종 업데이트

## 발견된 취약점 요약

| 시간 | 취약점 | 위험도 |
|------|--------|--------|
| 12:17 | SQL Injection | Critical |
| 12:18 | Stored XSS | High |
| 12:18 | 쿠키 기반 권한 상승 | Critical |
| 12:18 | IDOR | High |
| 12:19 | CSRF | Medium |
| 12:20 | 파일 업로드 | Critical |
| 12:28 | 보안 헤더 미설정 | Low |
| 12:28 | 쿠키 보안 속성 없음 | Medium |
| 12:29 | 브루트포스 방어 없음 | Medium |
| 12:29 | Clickjacking | Low |
| 12:30 | HTML 주석 정보 노출 | Low |
| 12:30 | 관리자 기능 무단 실행 | Critical |

**총 발견 취약점: 12개**
- Critical: 4개
- High: 2개
- Medium: 3개
- Low: 3개
