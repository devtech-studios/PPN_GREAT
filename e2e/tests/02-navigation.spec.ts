import { test, expect } from '@playwright/test';
import { loginAsAdmin, navigateTo, logout } from '../helpers/auth';
import { SIDEBAR } from '../helpers/selectors';

/**
 * Test Suite 2: Sidebar Navigation
 * หน้าจอ: main_layout.dart
 * ทดสอบ: คลิกเมนูทุกอัน → ไปหน้าจอถูกต้อง + Logout flow
 */

test.describe('02 — Sidebar Navigation', () => {

  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
  });

  test('TC-NAV-001: กดเมนู Projects → เข้าหน้า Projects', async ({ page }) => {
    await navigateTo(page, 'Projects');
    await page.waitForTimeout(2000);
    // Check that some project-related content is visible
    const hasContent = await page.locator('text=Projects').first().isVisible()
      || await page.locator('text=PPN-').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-002: กดเมนู Samples → เข้าหน้า Samples', async ({ page }) => {
    await navigateTo(page, 'Samples');
    await page.waitForTimeout(2000);
    const hasContent = await page.locator('text=Sample').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-003: กดเมนู Artwork → เข้าหน้า Artwork', async ({ page }) => {
    await navigateTo(page, 'Artwork');
    await page.waitForTimeout(2000);
    const hasContent = await page.locator('text=Artwork').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-004: กดเมนู Containers → เข้าหน้า Containers', async ({ page }) => {
    await navigateTo(page, 'Containers');
    await page.waitForTimeout(2000);
    const hasContent = await page.locator('text=Container').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-005: กดเมนู Delivery → เข้าหน้า Delivery', async ({ page }) => {
    await navigateTo(page, 'Delivery');
    await page.waitForTimeout(2000);
    const hasContent = await page.locator('text=Delivery').first().isVisible()
      || await page.locator('text=จัดส่ง').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-006: กดเมนู Customers → เข้าหน้า Customers', async ({ page }) => {
    await navigateTo(page, 'Customers');
    await page.waitForTimeout(2000);
    const hasContent = await page.locator('text=Customers').first().isVisible()
      || await page.locator('text=Customer').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-007: กดเมนู Suppliers → เข้าหน้า Suppliers', async ({ page }) => {
    await navigateTo(page, 'Suppliers');
    await page.waitForTimeout(2000);
    const hasContent = await page.locator('text=Supplier').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-008: กดเมนู Finance → เข้าหน้า Finance', async ({ page }) => {
    await navigateTo(page, 'Finance');
    await page.waitForTimeout(2000);
    const hasContent = await page.locator('text=Finance').first().isVisible()
      || await page.locator('text=เอกสาร').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-009: กดเมนู Inventory → เข้าหน้า Inventory', async ({ page }) => {
    await navigateTo(page, 'Inventory');
    await page.waitForTimeout(2000);
    const hasContent = await page.locator('text=Inventory').first().isVisible()
      || await page.locator('text=คลัง').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-010: กดเมนู Reports → เข้าหน้า Reports', async ({ page }) => {
    await navigateTo(page, 'Reports');
    await page.waitForTimeout(2000);
    const hasContent = await page.locator('text=Report').first().isVisible()
      || await page.locator('text=รายงาน').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-011: กดเมนู Settings → เข้าหน้า Settings', async ({ page }) => {
    await navigateTo(page, 'Settings');
    await page.waitForTimeout(2000);
    const hasContent = await page.locator('text=Settings').first().isVisible()
      || await page.locator('text=Setting').first().isVisible();
    expect(hasContent).toBeTruthy();
  });

  test('TC-NAV-012: Logout confirmation — กด ยกเลิก → ยังอยู่ Dashboard', async ({ page }) => {
    await page.locator(SIDEBAR.logout).first().click();
    await page.waitForTimeout(500);

    // Dialog should appear
    await expect(page.locator('text=คุณต้องการออกจากระบบ').first()).toBeVisible();

    // Click cancel
    await page.locator('text=ยกเลิก').first().click();
    await page.waitForTimeout(500);

    // Should still see Dashboard content
    await expect(page.locator('text=PPN GREAT').first()).toBeVisible();
  });

  test('TC-NAV-013: Logout confirmation — กด ออกจากระบบ → กลับ Login', async ({ page }) => {
    await logout(page);
    await expect(page.locator('text=Sign In').first()).toBeVisible({ timeout: 10_000 });
  });

  test('TC-NAV-014: กด Back จากหน้าย่อย → กลับ Dashboard', async ({ page }) => {
    await navigateTo(page, 'Customers');
    await page.waitForTimeout(2000);

    // Click Back button
    await page.locator('text=Back').first().click();
    await page.waitForTimeout(2000);

    // Should see Dashboard
    await expect(page.locator('text=Dashboard').first()).toBeVisible();
  });
});
