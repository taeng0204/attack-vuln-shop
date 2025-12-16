# 취약점 발견 요약

## 취약점 통계
- **총 발견 취약점**: 7개
- **Critical**: 3개
- **High**: 2개
- **Medium**: 2개

## 취약점 목록

### Critical (즉시 조치 필요)

#### 1. SQL Injection - 로그인 우회
- **위치**: `/login`
- **페이로드**: `admin'--`
- **영향**: 모든 사용자 계정 로그인 가능
- **CVSS 점수**: 9.8

#### 2. Stored XSS - Q&A 게시판
- **위치**: `/board`
- **페이로드**: `<script>alert('XSS')</script>`
- **영향**: 쿠키 탈취, 피싱, 악성코드 배포
- **CVSS 점수**: 8.2

#### 3. Broken Access Control - 쿠키 기반 권한 상승
- **위치**: 모든 인증 페이지
- **방법**: `isAdmin=true` 쿠키 설정
- **영향**: 일반 사용자가 관리자 권한 획득
- **CVSS 점수**: 9.1

### High (빠른 조치 권장)

#### 4. IDOR - 주문 정보 노출
- **위치**: `/order?id=`
- **방법**: 주문 ID 변경
- **영향**: 다른 사용자의 개인정보 노출
- **CVSS 점수**: 7.5

#### 5. SVG 파일 업로드를 통한 XSS
- **위치**: `/profile/upload`
- **방법**: 악성 SVG 파일 업로드
- **영향**: 지속적인 XSS 공격
- **CVSS 점수**: 7.1

### Medium (조치 권장)

#### 6. 보안 헤더 누락
- X-Frame-Options (Clickjacking)
- X-Content-Type-Options (MIME Sniffing)
- Content-Security-Policy

#### 7. 서버 정보 노출
- X-Powered-By: Express

## 공격 체인 예시

```
[1] SQL Injection으로 admin 로그인
         ↓
[2] isAdmin=true 쿠키 설정
         ↓
[3] 관리자 페이지 접근 (/admin/users)
         ↓
[4] 전체 사용자 목록 획득
         ↓
[5] XSS 페이로드 게시판에 삽입
         ↓
[6] 다른 사용자 세션 탈취
```

## 즉각적인 권장 조치

1. **SQL Injection**: Prepared Statement 사용
2. **XSS**: 출력 시 HTML 인코딩
3. **권한 관리**: 서버 측 세션 기반 인증
4. **IDOR**: 리소스 접근 시 소유자 검증
5. **파일 업로드**: 허용 확장자 제한, 콘텐츠 검증
6. **보안 헤더**: Helmet.js 미들웨어 사용
