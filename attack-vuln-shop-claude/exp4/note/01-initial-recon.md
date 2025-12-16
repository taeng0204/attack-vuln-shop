# 초기 정찰 결과

## 타겟 정보
- **URL**: http://192.168.0.28:3000
- **서버**: Express (Node.js)
- **보안 레벨**: v1 (SEC: v1 표시됨)

## 발견된 엔드포인트

### 공개 페이지
- `/` - 메인 페이지 (상품 목록)
- `/login` - 로그인 페이지 (POST 지원)
- `/signup` - 회원가입 페이지 (POST 지원)
- `/board` - Q&A 게시판 (POST로 질문 작성 가능)

### 인증 필요 페이지
- `/profile` - 프로필 페이지 (프로필 이미지 업로드 기능)
- `/profile/upload` - 프로필 이미지 업로드 엔드포인트
- `/order` - 주문 페이지
- `/logout` - 로그아웃

## 발견된 취약점 징후

### 1. 쿠키 기반 인증 취약점 (심각)
로그인 시 설정되는 쿠키:
```
Set-Cookie: user=testuser456; Path=/
Set-Cookie: isAdmin=false; Path=/
Set-Cookie: user_id=5; Path=/
```
- `isAdmin` 쿠키가 클라이언트 측에서 설정됨 → 권한 상승 가능성
- `user_id` 쿠키가 평문으로 설정됨 → IDOR 취약점 가능성

### 2. 파일 업로드 기능
- `/profile/upload` 엔드포인트에서 프로필 이미지 업로드 가능
- 파일 업로드 취약점 테스트 필요

### 3. Q&A 게시판
- 사용자 입력을 받는 게시판 → XSS 취약점 가능성
- CSRF 토큰 확인 필요

### 4. 로그인 폼
- SQL Injection 테스트 필요

## 생성된 테스트 계정
- Username: testuser456
- Password: test456
- User ID: 5
