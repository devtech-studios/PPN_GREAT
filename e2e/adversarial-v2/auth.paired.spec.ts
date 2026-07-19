import { env } from '../support/env';
import { openFlutterApp } from '../support/flutter';
import { annotateCase, attachJson, recordCard } from './support/evidence';
import { expect, test } from './support/fixtures';
import { fillLogin, loginThroughUi, openLogin, submitLogin } from './support/auth-ui';

test.describe('PACK-AUTH | Authentication positive, negative and recovery | ล็อกอินสำเร็จ ผิดพลาด และกู้คืน', () => {
  test('PAIR-AUTH-001-A | Valid login succeeds | ล็อกอินข้อมูลถูกต้องสำเร็จ', async ({ page }, testInfo) => {
    annotateCase(testInfo, {
      caseId: 'PAIR-AUTH-001-A',
      pairId: 'PAIR-AUTH-001',
      classification: 'CONTRACT-CONFIRMED',
      method: 'Admin email and password submitted through Flutter UI',
      expected: 'HTTP 200 and Dashboard visible',
      preconditions: ['Fresh ppn_e2e baseline', 'Admin identity exists'],
    });
    await openLogin(page);
    await recordCard(page, testInfo, 'normal', 'Valid Login | ล็อกอินแบบถูกต้อง', [
      'กรอกอีเมลและรหัสผ่านของ Admin ผ่าน UI',
      'Expected: API 200 และเปิด Dashboard',
    ], 'step-card');
    await fillLogin(page);
    const response = await submitLogin(page);
    expect(response.status()).toBe(200);
    await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible();
    await attachJson(testInfo, 'login-result', { status: response.status(), dashboardVisible: true });
    await recordCard(page, testInfo, 'success', 'SUCCESS: Admin Login | แอดมินเข้าสู่ระบบสำเร็จ', [
      'Method: email + password ผ่านหน้า Sign In',
      'UI: Dashboard แสดงผล',
      'API: POST /api/auth/login = 200',
    ], 'success-path-card');
  });

  test('PAIR-AUTH-001-B | Wrong password is rejected | รหัสผ่านผิดต้องถูกปฏิเสธ', async ({ page }, testInfo) => {
    annotateCase(testInfo, {
      caseId: 'PAIR-AUTH-001-B',
      pairId: 'PAIR-AUTH-001',
      classification: 'EXPECTED-REJECTION',
      method: 'Correct admin email with an invalid password through UI',
      expected: 'HTTP 401, remain on Sign In, no Dashboard',
      preconditions: ['PAIR-AUTH-001-A proves normal login works'],
    });
    await openLogin(page);
    await recordCard(page, testInfo, 'error', 'ERROR CASE: Wrong Password | ทดลองรหัสผ่านผิด', [
      'ใช้ Admin email ที่ถูกต้อง',
      'เปลี่ยนเฉพาะ password เป็นค่าผิด',
      'Expected: 401 และยังอยู่หน้า Sign In',
    ], 'error-case-card');
    await fillLogin(page, env.adminEmail, 'wrong-password-v2');
    const response = await submitLogin(page);
    await attachJson(testInfo, 'rejection-result', { status: response.status() });
    expect(response.status()).toBe(401);
    await expect(page.getByText('Sign In', { exact: true })).toBeVisible();
    await expect(page.getByText('Dashboard', { exact: true })).toHaveCount(0);
    await recordCard(page, testInfo, 'important', 'EXPECTED REJECTION | ระบบปฏิเสธตามคาด', [
      `API status: ${response.status()}`,
      'ไม่เข้าสู่ Dashboard',
      'ข้อมูลผิดไม่สร้าง authenticated session',
    ], 'expected-rejection-card');
  });

  test('PAIR-AUTH-001-C | Corrected credentials recover successfully | แก้ credentials แล้วเข้าสำเร็จ', async ({ page }, testInfo) => {
    annotateCase(testInfo, {
      caseId: 'PAIR-AUTH-001-C',
      pairId: 'PAIR-AUTH-001',
      classification: 'CONTRACT-CONFIRMED',
      method: 'Start a clean UI context and submit corrected credentials',
      expected: 'HTTP 200 and Dashboard visible after the paired rejection',
      preconditions: ['Wrong-password case was rejected without mutating business data'],
    });
    const response = await loginThroughUi(page);
    expect(response.status()).toBe(200);
    await recordCard(page, testInfo, 'final', 'RECOVERY SUCCESS | แก้ข้อมูลแล้วกลับมาใช้งานได้', [
      'แก้รหัสผ่านกลับเป็นค่าถูกต้อง',
      'API login = 200',
      'Dashboard เปิดได้หลังจากเคส error',
    ], 'recovery-success-card');
  });

  test('PAIR-AUTH-002-A | Empty form shows validation | ฟอร์มว่างต้องแสดง validation', async ({ page }, testInfo) => {
    annotateCase(testInfo, {
      caseId: 'PAIR-AUTH-002-A',
      pairId: 'PAIR-AUTH-002',
      classification: 'EXPECTED-REJECTION',
      method: 'Submit Sign In without entering either field',
      expected: 'Client validation shown and no authentication request',
      preconditions: ['Login page visible'],
    });
    await openLogin(page);
    let loginRequests = 0;
    page.on('request', request => {
      if (request.url().endsWith('/api/auth/login')) loginRequests += 1;
    });
    await recordCard(page, testInfo, 'error', 'ERROR CASE: Empty Login | ส่งฟอร์มว่าง', [
      'ไม่กรอก email และ password',
      'Expected: validation ฝั่ง UI',
      'Expected: ไม่เรียก API login',
    ], 'error-case-card');
    await page.getByText('Sign In', { exact: true }).click();
    await expect(page.getByText(/Email.*Password/i)).toBeVisible();
    expect(loginRequests).toBe(0);
    await attachJson(testInfo, 'empty-validation-result', { loginRequests });
    await recordCard(page, testInfo, 'important', 'VALIDATION DISPLAYED | แสดงข้อความตรวจสอบแล้ว', [
      'UI แจ้งข้อมูล Email/Password ไม่ครบ',
      'API login requests = 0',
    ], 'expected-rejection-card');
  });

  test('PAIR-AUTH-002-B | Fill required fields after validation and succeed | กรอกหลัง validation แล้วสำเร็จ', async ({ page }, testInfo) => {
    annotateCase(testInfo, {
      caseId: 'PAIR-AUTH-002-B',
      pairId: 'PAIR-AUTH-002',
      classification: 'CONTRACT-CONFIRMED',
      method: 'Trigger empty validation, then fill both required fields in the same UI session',
      expected: 'Validation clears and login succeeds',
      preconditions: ['Fresh login page'],
    });
    await openLogin(page);
    await page.getByText('Sign In', { exact: true }).click();
    await expect(page.getByText(/Email.*Password/i)).toBeVisible();
    await fillLogin(page);
    const response = await submitLogin(page);
    expect(response.status()).toBe(200);
    await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible();
    await recordCard(page, testInfo, 'final', 'RECOVERY SUCCESS | กรอกข้อมูลครบแล้วสำเร็จ', [
      'เริ่มจาก validation error ใน session เดียวกัน',
      'กรอกข้อมูลที่จำเป็นครบ',
      'Dashboard แสดงผลสำเร็จ',
    ], 'recovery-success-card');
  });

  test('PAIR-AUTH-003-A | Corrupted stored token returns to Sign In | token ใน storage เสียต้องไม่ผ่าน', async ({ page }, testInfo) => {
    annotateCase(testInfo, {
      caseId: 'PAIR-AUTH-003-A',
      pairId: 'PAIR-AUTH-003',
      classification: 'EXPECTED-REJECTION',
      method: 'Inject a local corrupted token and reload the Flutter app',
      expected: 'Protected UI is unavailable and Sign In is shown',
      preconditions: ['Local browser context only; no valid session'],
    });
    await page.addInitScript(() => localStorage.setItem('auth_token', 'corrupted-v2-token'));
    await openFlutterApp(page);
    await recordCard(page, testInfo, 'error', 'ERROR CASE: Corrupted Token | token เสียใน localStorage', [
      'จำลอง token ที่ไม่สามารถ authenticate ได้',
      'Expected: ไม่เปิด Dashboard',
      'Expected: แสดงหน้า Sign In',
    ], 'error-case-card');
    await expect(page.getByText('Sign In', { exact: true })).toBeVisible();
    await expect(page.getByText('Dashboard', { exact: true })).toHaveCount(0);
  });
});
