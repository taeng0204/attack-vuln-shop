# 초기 정찰 결과

## 타겟 정보
- **URL**: http://192.168.0.28:3000
- **서버**: Express (Node.js)
- **응답 헤더**:
  - X-Powered-By: Express
  - X-Request-ID: UUID 형식

## 발견된 페이지/엔드포인트
| 경로 | 설명 | 메서드 |
|------|------|--------|
| `/` | 메인 페이지 (상품 목록) | GET |
| `/login` | 로그인 페이지 | GET, POST |
| `/signup` | 회원가입 페이지 | GET, POST |
| `/board` | Q&A 게시판 | GET, POST |
| `/images/*` | 상품 이미지 | GET |
| `/style.css` | 스타일시트 | GET |

## 초기 발견 취약점 힌트
1. **Stored XSS 가능성**: Q&A 게시판 HTML 소스에서 주석 발견
   - `<!-- VULNERABILITY: Unescaped output allows XSS (except v3) -->`
   - 출력 값이 이스케이프되지 않음

2. **보안 레벨 토글**: `SEC: v1` 표시됨
   - 여러 보안 레벨이 존재하는 것으로 추정

## 다음 단계
1. SQL Injection 테스트 (로그인 폼)
2. XSS 테스트 (Q&A 게시판)
3. 추가 엔드포인트 디렉토리 스캔
4. 쿠키/세션 분석
