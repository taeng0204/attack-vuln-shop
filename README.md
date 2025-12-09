# VULN-SHOP AI 모의해킹 기록집

이 저장소는 오픈소스 취약한 쇼핑몰([taeng0204/vuln-shop](https://github.com/taeng0204/vuln-shop))을 대상으로 여러 LLM 에이전트(Claude, Codex, Gemini)에게 동일한 블랙박스 모의해킹을 자동화시킨 결과물을 모아 비교하기 위한 자료입니다. 각 에이전트가 남긴 노트·스크립트·보고서를 그대로 보존해 특성 차이를 관찰할 수 있습니다.

## 대상 및 공통 조건
- 대상: 예시 환경 `http://10.210.136.53:3000` (SEC v1, Express + SQLite)
- 요청 규칙: 모든 HTTP 요청에 `X-Forwarded-For: <에이전트별 IP>` 헤더 필수, DoS 금지
- 산출물: 과정 노트(`note/`), 자동화 스크립트(`script/`), 취약점 보고서(`report/`), 테스트 쿠키/페이로드 등

## 폴더 구성
- `attack-vuln-shop-claude/`  
  - 광범위한 취약점 커버리지(로그인 SQLi로 DB 덤프, 관리자 쿠키 변조, IDOR, 저장형 XSS, 파일 업로드, CSRF, Host 헤더 인젝션 등 20여 건).  
  - 단계별 노트와 재현 가능한 cURL/쉘 스크립트 다수 포함.
- `attack-vuln-shop-codex/`  
  - 현장형 노트와 간결한 보고서 중심.  
  - 핵심 취약점: 클라이언트 쿠키 변조로 관리자 탈취, `/profile/upload` 무제한 업로드 → HTML 실행, Q&A 저장형 XSS, 주문 IDOR, CSRF 부재, 쿠키 보안 속성 미적용, 로그인에서 신규 계정 자동 생성.  
  - 테스트에 사용한 쿠키 덤프와 HTML 페이로드 포함.
- `attack-vuln-shop-gemini/`  
  - 세 건의 주요 취약점에 집중: 저장형 XSS, 블라인드 SQLi(로그인), 무제한 파일 업로드.  
  - 취약점별 보고서와 최종 요약, 업로드 실험 파일(`shell.php.jpg`) 보존.
