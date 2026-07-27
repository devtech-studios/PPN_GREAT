# REALISTIC V1 Freeze Manifest — หลักฐานเวอร์ชัน Happy Path ที่ผ่านแล้ว

Frozen at: 2026-07-18 Asia/Bangkok  
Result: `1 passed`, test 5.2 minutes, runner 5.5 minutes  
Database: `ppn_e2e` only  
Purpose: ตรวจว่า Adversarial V2 ไม่เขียนทับ test/config/runner/artifacts ของ V1

## Final Reconciliation

- Laravel users: 1 admin
- Suppliers: 1 supplier identity
- Customers: 1
- Projects: 1
- Delivered containers: 1
- Paid supplier bills: 2
- Confirmed customer payments: 2
- Finance documents: QU=`Sent`, PI=`Paid`, CI=`Sent`
- Remaining stock: 100
- Stock movements: IN=1, OUT=1
- Delivery items: 1

## SHA-256 Inventory

| File | Bytes | SHA-256 |
|---|---:|---|
| `playwright.realistic.config.ts` | 2,147 | `32ECA79D8DD391B5F0CF3AEA41CFBD4DE1D97497F0897A5D99FA8A81BBEF5781` |
| `scripts/run-realistic-e2e-video.ps1` | 1,394 | `119B917FBF67F0902EAD8C4D11DD005A1EE534D70ECD30EC33C7C61AD098B838` |
| `e2e/realistic/global-setup.ts` | 882 | `5A049CAE199525E8A657CB7FF67658FC2EF066C680CA1EF117B8AF073283C607` |
| `e2e/realistic/realistic-business-cycle.spec.ts` | 16,856 | `5255D1E956E6AFF5D9D97FCAD8B6817A6CD181CBA4231BB5A048DC13BFA9E54D` |
| `e2e/realistic/fulfillment-flow.ts` | 26,014 | `DAB68ADD8BDE5349DCA0497842016E5FD266B1DA0CD5EB05B680FBBA7A4C7C33` |
| `e2e/realistic/fulfillment-resume.spec.ts` | 965 | `3D1A3EB15700CC43672A870169BEAA055CA4427C3DCDFE30C96DCFFB845E269C` |
| `docs/PLAYWRIGHT_REALISTIC_LOCAL_E2E_TEST_PLAN_BILINGUAL_TH_EN.md` | 35,224 | `E1C2792773089A223B07CE938BCD1344EE0AB88344E2CA754748442010C922AB` |
| Full-flow `video.webm` | 12,218,326 | `D4E15B83E5BBA0D36B51B98AF9614BE7D9F88E2B477291910B6375C7CE83E3D9` |
| Full-flow `trace.zip` | 114,252,410 | `23D215BEE6D41B008B57989F17079FCC6D112F731F74222B0FAC044036FB8FBD` |

## Artifact Locations

- Video: `test-results-realistic/realistic-realistic-busine-95023-ละซัพพลายเออร์ส่งใบเสนอราคา-realistic-local-chromium-เส้นทางธุรกิจจริงบน-Local/video.webm`
- Trace: `test-results-realistic/realistic-realistic-busine-95023-ละซัพพลายเออร์ส่งใบเสนอราคา-realistic-local-chromium-เส้นทางธุรกิจจริงบน-Local/trace.zip`
- HTML: `playwright-report-realistic/index.html`
- JUnit: `test-results-realistic/junit.xml`

## Freeze Rule

V2 implementation must not modify the files or artifact directories above. If a later hash differs, report it as `V1-FREEZE-VIOLATION` and stop V2 execution before running database mutations.

This manifest freezes the Playwright V1 surface only. Whether to snapshot all three source repositories is an explicit decision still awaiting user confirmation.
