# 초기 정찰 결과

## 타겟 정보
- URL: http://192.168.0.28:3000
- 플랫폼: Express (Node.js)
- 보안 레벨: v1

## 발견된 엔드포인트
| 경로 | 상태 | 설명 |
|------|------|------|
| / | 200 | 메인 쇼핑몰 페이지 |
| /login | 200 | 로그인 페이지 |
| /signup | 200 | 회원가입 페이지 |
| /board | 200 | Q&A 게시판 |
| /profile | 302 | 프로필 (로그인 필요) |
| /order | 302 | 주문 (로그인 필요) |
| /logout | 302 | 로그아웃 |
| /images/ | 301 | 이미지 디렉토리 |
| /uploads/ | 301 | 업로드 디렉토리 |

## 주요 발견 사항
1. Q&A 게시판에 XSS 취약점 힌트 발견 (소스코드 주석: "VULNERABILITY: Unescaped output allows XSS")
2. /uploads 디렉토리 존재 - 파일 업로드 기능 가능성
3. 세션 기반 인증 시스템 사용

## HTTP 헤더 정보
```
X-Powered-By: Express
X-Request-ID: UUID 형식
Content-Type: text/html; charset=utf-8
```

## 다음 테스트 계획
1. XSS 취약점 테스트 (/board)
2. SQL Injection 테스트 (/login, /signup)
3. 파일 업로드 취약점 테스트
4. 인증 우회 테스트
5. IDOR 테스트 (/order, /profile)
