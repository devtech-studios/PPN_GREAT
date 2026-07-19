import { annotateCase, attachJson, recordCard } from './support/evidence';
import { expect, test } from './support/fixtures';
import { fillLogin, loginThroughUi, openLogin, submitLogin } from './support/auth-ui';

test.describe('PACK-NETWORK | Normal, latency, failure and recovery | เครือข่ายปกติ ช้า ล้มเหลว และกู้คืน', () => {
  test('PAIR-NET-001-A | Normal network login succeeds | เครือข่ายปกติล็อกอินสำเร็จ', async ({ page }, testInfo) => {
    annotateCase(testInfo, {
      caseId: 'PAIR-NET-001-A', pairId: 'PAIR-NET-001',
      classification: 'CONTRACT-CONFIRMED',
      method: 'Normal unmodified local network',
      expected: 'Login API returns 200 and Dashboard opens',
      preconditions: ['No page.route injection'],
    });
    await recordCard(page, testInfo, 'normal', 'NETWORK BASELINE | เครือข่ายปกติ', [
      'ไม่มีการหน่วงหรือจำลอง error',
      'ใช้เป็น comparator ของ latency และ 503',
    ], 'baseline-card');
    const response = await loginThroughUi(page);
    expect(response.status()).toBe(200);
    await recordCard(page, testInfo, 'success', 'SUCCESS: Normal Network | เครือข่ายปกติสำเร็จ', [
      'POST /api/auth/login = 200',
      'Dashboard พร้อมใช้งาน',
    ], 'success-path-card');
  });

  test('PAIR-NET-001-B | Three-second API latency still succeeds | API ช้า 3 วินาทียังสำเร็จ', async ({ page }, testInfo) => {
    annotateCase(testInfo, {
      caseId: 'PAIR-NET-001-B', pairId: 'PAIR-NET-001',
      classification: 'VALID-ALTERNATIVE',
      method: 'page.route delays POST /api/auth/login by 3 seconds then continues',
      expected: 'UI waits and eventually opens Dashboard without duplicate request',
      preconditions: ['Normal network comparator passed'],
    });
    let requestCount = 0;
    await page.route('**/api/auth/login', async route => {
      requestCount += 1;
      await new Promise(resolve => setTimeout(resolve, 3_000));
      await route.continue();
    });
    await openLogin(page);
    await fillLogin(page);
    await recordCard(page, testInfo, 'important', 'LATENCY INJECTION | จำลอง API ช้า 3 วินาที', [
      'หน่วงเฉพาะ POST /api/auth/login',
      'Expected: ผู้ใช้รอได้และไม่ส่ง request ซ้ำ',
    ], 'latency-card');
    const startedAt = Date.now();
    const response = await submitLogin(page);
    const elapsedMs = Date.now() - startedAt;
    expect(response.status()).toBe(200);
    await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible();
    expect(requestCount).toBe(1);
    expect(elapsedMs).toBeGreaterThanOrEqual(3_000);
    await attachJson(testInfo, 'latency-result', { requestCount, elapsedMs, status: response.status() });
    await recordCard(page, testInfo, 'success', 'SUCCESS UNDER LATENCY | สำเร็จแม้ API ช้า', [
      `Elapsed: ${elapsedMs} ms`,
      `Login requests: ${requestCount}`,
      'Dashboard แสดงผลหลัง response กลับ',
    ], 'success-path-card');
  });

  test('PAIR-NET-002-A | Synthetic 503 is handled without navigation | จำลอง 503 แล้วต้องไม่เข้าระบบ', async ({ page }, testInfo) => {
    annotateCase(testInfo, {
      caseId: 'PAIR-NET-002-A', pairId: 'PAIR-NET-002',
      classification: 'EXPECTED-REJECTION',
      method: 'page.route fulfills login request with local HTTP 503 JSON',
      expected: 'Remain on Sign In and show an error state; no Dashboard',
      preconditions: ['Network injection explicitly authorized'],
    });
    await page.route('**/api/auth/login', route => route.fulfill({
      status: 503,
      contentType: 'application/json',
      body: JSON.stringify({ success: false, message: 'Synthetic local service unavailable' }),
    }));
    await openLogin(page);
    await fillLogin(page);
    await recordCard(page, testInfo, 'error', 'ERROR CASE: HTTP 503 | จำลองระบบ API ไม่พร้อม', [
      'ตอบ 503 จาก page.route ในเครื่อง local',
      'Expected: ไม่เปิด Dashboard',
      'Expected: ผู้ใช้ยังแก้ไข/ลองใหม่ได้',
    ], 'error-case-card');
    const response = await submitLogin(page);
    expect(response.status()).toBe(503);
    await expect(page.getByText('Sign In', { exact: true })).toBeVisible();
    await expect(page.getByText('Dashboard', { exact: true })).toHaveCount(0);
    await attachJson(testInfo, 'synthetic-503-result', { status: response.status(), stayedOnLogin: true });
    await recordCard(page, testInfo, 'important', '503 OBSERVED | ระบบยังอยู่หน้า Login', [
      'API status = 503',
      'Dashboard ไม่เปิด',
      'ทดสอบ recovery ใน case ถัดไป',
    ], 'expected-rejection-card');
  });

  test('PAIR-NET-002-B | Normal network recovers after synthetic 503 | เครือข่ายกลับมาปกติแล้วล็อกอินได้', async ({ page }, testInfo) => {
    annotateCase(testInfo, {
      caseId: 'PAIR-NET-002-B', pairId: 'PAIR-NET-002',
      classification: 'CONTRACT-CONFIRMED',
      method: 'New browser context without route injection submits valid UI login',
      expected: 'HTTP 200 and Dashboard after the paired synthetic failure',
      preconditions: ['Previous 503 did not mutate server or credentials'],
    });
    const response = await loginThroughUi(page);
    expect(response.status()).toBe(200);
    await recordCard(page, testInfo, 'final', 'RECOVERY SUCCESS AFTER 503 | ระบบกลับมาใช้งานได้', [
      'ยกเลิก network injection ด้วย browser context ใหม่',
      'Login API = 200',
      'Dashboard เปิดได้ตามปกติ',
    ], 'recovery-success-card');
  });
});
