# PPN GREAT Playwright E2E

อ่านแผนและ coverage ฉบับเต็มที่ `docs/PLAYWRIGHT_E2E_MASTER_PLAN_TH.md`

## Quick start

```powershell
cd D:\07_Projects\Work\PNN\ppn_great
npm install
npm run e2e:install
npm run build:web
npm run e2e:smoke
```

ค่า default คือ Flutter `127.0.0.1:4173`, API `127.0.0.1:8000`, Supplier Portal `localhost:3000` และ PHP `C:/xampp/php/php.exe` Playwright จะ reuse server ที่เปิดอยู่

หากเปิด server เองทั้งหมด ให้ตั้ง `$env:E2E_EXTERNAL_SERVERS='1'`

## Suites

- `auth.spec.ts`: required/invalid/success/persistence/logout
- `navigation.spec.ts`: ทุกเมนูและ Settings placeholder
- `module-actions.spec.ts`: ปุ่ม/dialog/tab แบบไม่แก้ข้อมูล
- `supplier-portal.spec.ts`: portal validation/login/tabs/logout/quote validation
- `full-business-flow.spec.ts`: Customer → Project → Sample → Artwork revision (`@live-mutation`)
- `supplier-quote-live-flow.spec.ts`: Admin → Supplier Portal → admin review (`@live-mutation`)
- `finance-logistics-live-flow.spec.ts`: PI → Payment → Inventory → Delivery exact-once (`@live-mutation`)
- `semantics-audit.spec.ts`: developer tool สำหรับพิมพ์ accessible controls
- `tests/`: specs เดิมที่อยู่ใน workspace; ต้องทยอยย้ายมาใช้ helper semantics-aware ก่อนนำเข้าชุด CI หลัก

Mutation test ต้องใช้ isolated staging database และรัน `npm run e2e:live -- --workers=1`

## บันทึกวิดีโอทุกเทสต์

โหมดปกติเก็บวิดีโอเฉพาะเทสต์ที่ไม่ผ่าน ส่วนคำสั่งต่อไปนี้ใช้ `video: 'on'` เพื่อเก็บวิดีโอทั้งเทสต์ที่ผ่านและไม่ผ่าน:

```powershell
# Smoke 5 tests
npm run e2e:video:smoke

# Regression แบบไม่แก้ข้อมูล (ไม่รวม @live-mutation)
npm run e2e:video

# เปิด HTML report แล้วเลือกแต่ละ test เพื่อดู Video attachment
npm run e2e:video:report
```

ไฟล์ `.webm` จะอยู่ใต้ `test-results-video/<ชื่อเทสต์>/video.webm` และ HTML report อยู่ใน `playwright-report-video` หากต้องการบันทึกเฉพาะไฟล์เดียวหรือเทสต์เดียว สามารถส่ง argument ต่อท้ายได้ เช่น:

```powershell
npm run e2e:video -- e2e/navigation.spec.ts
npm run e2e:video -- --grep "Supplier Edit"
```
