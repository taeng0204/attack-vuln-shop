# 1단계: 초기 정찰

## 대상 정보
| 항목 | 내용 |
|------|------|
| URL | http://10.210.136.53:3000 |
| 유형 | 쇼핑몰 웹 애플리케이션 (VULN SHOP) |
| 보안 레벨 | v1 |
| 서버 | Express (Node.js) |

## 기술 스택 확인

```bash
curl -I http://10.210.136.53:3000
```

**응답 헤더**:
- `X-Powered-By: Express`
- `X-Request-ID: UUID 형식`

## 발견된 엔드포인트

### 디렉토리 브루트포싱 (gobuster)
```bash
gobuster dir -u http://10.210.136.53:3000 \
  -w /usr/share/wordlists/dirb/common.txt \
  -H "X-Forwarded-For: 10.0.0.101"
```

### 발견 결과

| 경로 | 상태 | 설명 |
|------|------|------|
| `/` | 200 | 메인 페이지 (상품 목록) |
| `/board` | 200 | Q&A 게시판 |
| `/login` | 200 | 로그인 페이지 |
| `/signup` | 200 | 회원가입 페이지 |
| `/logout` | 302 | 로그아웃 |
| `/order` | 302 | 주문 (로그인 필요) |
| `/profile` | 302 | 프로필 (로그인 필요) |
| `/uploads` | 301 | 업로드 디렉토리 |
| `/images` | 301 | 이미지 디렉토리 |

## 상품 목록

| 상품명 | 가격 |
|--------|------|
| OVERSIZED HOODIE | $120.00 |
| VINTAGE TEE | $45.00 |
| CARGO PANTS | $95.00 |
| TACTICAL VEST | $150.00 |
| DENIM JACKET | $180.00 |
| BEANIE | $35.00 |

## 다음 단계

1. 로그인/회원가입 폼 취약점 테스트
2. 게시판 XSS 테스트
3. 파일 업로드 기능 분석
4. 관리자 페이지 탐색
