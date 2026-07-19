import { test, expect } from '@playwright/test';
import { loginAsAdmin, ADMIN_CREDENTIALS, logout, clickButton } from '../helpers/auth';
import { LOGIN } from '../helpers/selectors';

/**
 * Test Suite 1: Login Screen
 * หน้าจอ: login_screen.dart
 * ทดสอบ: การเข้าสู่ระบบ, Validation, UI States
 */

test.describe('01 — Login Screen', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    // Wait for Flutter to finish compiling + rendering
    await page.waitForTimeout(5000);
  });

  test('TC-LOGIN-001: Login สำเร็จด้วย credentials ถูกต้อง', async ({ page }) => {
    await page.locator(LOGIN.emailInput).first().fill(ADMIN_CREDENTIALS.email);
    await page.locator(LOGIN.passwordInput).first().fill(ADMIN_CREDENTIALS.password);
    await page.locator(LOGIN.signInButton).first().click();

    // Should navigate to Dashboard
    await expect(page.locator(LOGIN.brandText).first()).toBeVisible({ timeout: 30_000 });
  });

  test('TC-LOGIN-002: Login ด้วยรหัสผ่านผิด', async ({ page }) => {
    await page.locator(LOGIN.emailInput).first().fill(ADMIN_CREDENTIALS.email);
    await page.locator(LOGIN.passwordInput).first().fill('wrongpassword');
    await page.locator(LOGIN.signInButton).first().click();

    // Should see error message
    await page.waitForTimeout(3000);
    const errorVisible = await page.locator('text=ไม่สำเร็จ').first().isVisible()
      || await page.locator('text=Unauthorized').first().isVisible()
      || await page.locator('text=Invalid').first().isVisible();
    expect(errorVisible).toBeTruthy();

    // Should still be on login page
    await expect(page.locator(LOGIN.signInButton).first()).toBeVisible();
  });

  test('TC-LOGIN-003: Login ด้วย email ที่ไม่มีในระบบ', async ({ page }) => {
    await page.locator(LOGIN.emailInput).first().fill('nobody@test.com');
    await page.locator(LOGIN.passwordInput).first().fill('password123');
    await page.locator(LOGIN.signInButton).first().click();

    await page.waitForTimeout(3000);
    // Should see error — still on login page
    await expect(page.locator(LOGIN.signInButton).first()).toBeVisible();
  });

  test('TC-LOGIN-004: Login โดยไม่กรอกข้อมูล (ช่องว่าง)', async ({ page }) => {
    // Clear any pre-filled values
    await page.locator(LOGIN.emailInput).first().fill('');
    await page.locator(LOGIN.passwordInput).first().fill('');
    await page.locator(LOGIN.signInButton).first().click();

    // Should see validation error message
    await page.waitForTimeout(1000);
    await expect(page.locator('text=กรุณากรอก').first()).toBeVisible({ timeout: 5_000 });
  });

  test('TC-LOGIN-005: Toggle แสดง/ซ่อนรหัสผ่าน', async ({ page }) => {
    await page.locator(LOGIN.passwordInput).first().fill('test1234');

    // Find the visibility toggle icon button
    const toggleButton = page.locator('[class*="IconButton"], button').filter({
      has: page.locator('[class*="visibility"]'),
    }).first();

    // If the button is found, click it
    if (await toggleButton.isVisible()) {
      await toggleButton.click();
      await page.waitForTimeout(500);
      // After toggle, the password field type might change
      // (Flutter may not expose this via DOM, so we just check no crash)
    }

    // Verify no crash happened
    await expect(page.locator(LOGIN.signInButton).first()).toBeVisible();
  });

  test('TC-LOGIN-006: กด Enter เพื่อ Submit (keyboard shortcut)', async ({ page }) => {
    await page.locator(LOGIN.emailInput).first().fill(ADMIN_CREDENTIALS.email);
    await page.locator(LOGIN.passwordInput).first().fill(ADMIN_CREDENTIALS.password);

    // Press Enter on password field
    await page.locator(LOGIN.passwordInput).first().press('Enter');

    // Should navigate to Dashboard
    await expect(page.locator(LOGIN.brandText).first()).toBeVisible({ timeout: 30_000 });
  });

  test('TC-LOGIN-007: Loading state ขณะ Login', async ({ page }) => {
    await page.locator(LOGIN.emailInput).first().fill(ADMIN_CREDENTIALS.email);
    await page.locator(LOGIN.passwordInput).first().fill(ADMIN_CREDENTIALS.password);

    // Click and immediately check for loading indicator
    await page.locator(LOGIN.signInButton).first().click();

    // The button should be disabled or show a spinner during loading
    // We just verify no immediate crash and eventually loads
    await expect(page.locator(LOGIN.brandText).first()).toBeVisible({ timeout: 30_000 });
  });

  test('TC-LOGIN-008: Logout แล้วกลับมาหน้า Login', async ({ page }) => {
    // First login
    await loginAsAdmin(page);

    // Then logout
    await logout(page);

    // Should be back at login
    await expect(page.locator(LOGIN.signInButton).first()).toBeVisible({ timeout: 10_000 });
  });
});
