# 취약점 보고서: VULN-02 - SQL 인젝션을 통한 인증 우회

- **취약점 ID:** VULN-02
- **종류:** SQL 인젝션을 통한 인증 우회 (Authentication Bypass via SQL Injection)
- **위험도:** 치명적 (Critical)
- **발견 날짜:** 2025-12-11

## 요약
VULN-SHOP의 로그인 페이지(`/login`)에는 SQL 인젝션 취약점이 존재합니다. 공격자는 `username` 파라미터에 조작된 SQL 구문을 삽입하여, 패스워드를 알지 못해도 특정 사용자(e.g., admin)의 계정으로 인증을 우회하고 로그인할 수 있습니다.

## 재현 과정
1. 로그인 페이지(`http://172.20.10.2:3000/login`)에 접속합니다.
2. `username` 입력란에 아래와 같은 SQL 인젝션 페이로드를 입력합니다.
   ```sql
   ' OR '1'='1'--
   ```
3. `password` 입력란에는 아무 값이나 입력합니다 (e.g., `a`).
4. 'Login' 버튼을 클릭하면, `admin` 사용자로 로그인이 성공하며 메인 페이지로 리디렉션됩니다.

## 상세 설명
로그인 처리 로직이 아래와 유사한 형태로, 사용자 입력을 그대로 쿼리문에 결합하여 발생한 취약점으로 추정됩니다.
```sql
SELECT * FROM users WHERE username = 'USER_INPUT' AND password = 'PASSWORD_INPUT';
```
공격 페이로드 `' OR '1'='1'--` 가 `USER_INPUT`으로 삽입되면, 쿼리는 다음과 같이 변경됩니다.
```sql
SELECT * FROM users WHERE username = '' OR '1'='1'--' AND password = '...';
```
`--` 뒤의 모든 구문이 주석 처리되고, `OR '1'='1'` 조건 때문에 `WHERE` 절은 항상 참(True)이 됩니다. 그 결과, 데이터베이스의 첫 번째 사용자(일반적으로 `admin`)로 로그인이 성공하게 됩니다.

공격 성공 시, 서버는 다음과 같은 쿠키를 발급하며 `admin` 계정(user_id=1)으로 세션이 생성됩니다.
```
user=admin
isAdmin=false
user_id=1
```
`isAdmin` 쿠키가 `false`로 설정된 점으로 보아, 관리자 권한은 별도의 로직으로 제어될 가능성이 있습니다.

## 권고 사항
1. **파라미터화된 쿼리 (Parameterized Queries / Prepared Statements) 사용:**
   - 사용자 입력을 쿼리문에 직접 결합하지 말고, 반드시 파라미터화된 쿼리를 사용하여 SQL 인젝션 공격을 원천적으로 방어해야 합니다.
2. **입력값 검증:** 사용자 입력값에 대해 허용된 문자열과 길이 등 화이트리스트 기반의 엄격한 검증을 수행해야 합니다.
3. **최소 권한 원칙:** 데이터베이스 사용자는 애플리케이션 실행에 필요한 최소한의 권한만을 가지도록 설정해야 합니다.
