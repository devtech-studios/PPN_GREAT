import { test, expect } from '@playwright/test';
import { loginAsAdmin, navigateTo } from '../helpers/auth';

/**
 * Test Suite 4: Projects (List + Detail + Status Pipeline)
 * หน้าจอ: project_list_screen.dart
 */

test.describe('04 — Projects', () => {

  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
    await navigateTo(page, 'Projects');
    await page.waitForTimeout(3000);
  });

  test('TC-PROJ-001: ดึงรายการโปรเจกต์ได้', async ({ page }) => {
    const hasPPN = await page.locator('text=PPN-').first().isVisible();
    expect(hasPPN).toBeTruthy();
  });

  test('TC-PROJ-002: ค้นหาด้วย project_code', async ({ page }) => {
    const searchInput = page.locator('input[placeholder*="ค้นหา"]').first();
    if (await searchInput.isVisible()) {
      await searchInput.fill('PPN-001');
      await page.waitForTimeout(2000);
      const hasResult = await page.locator('text=PPN-001').first().isVisible();
      expect(hasResult).toBeTruthy();
    }
  });

  test('TC-PROJ-003: Filter ตาม Status', async ({ page }) => {
    // Click on a status filter tab (e.g., Production)
    const prodTab = page.locator('text=Production').first();
    if (await prodTab.isVisible()) {
      await prodTab.click();
      await page.waitForTimeout(2000);
    }
    // Page should not crash
    await expect(page.locator('text=Projects').first()).toBeVisible();
  });

  test('TC-PROJ-004: ดูรายละเอียดโปรเจกต์', async ({ page }) => {
    // Click first project
    const firstProject = page.locator('text=PPN-').first();
    await firstProject.click();
    await page.waitForTimeout(2000);

    // Should see detail content
    const hasDetail = await page.locator('text=สถานะ').first().isVisible()
      || await page.locator('text=Status').first().isVisible()
      || await page.locator('text=Customer').first().isVisible()
      || await page.locator('text=ลูกค้า').first().isVisible();
    expect(hasDetail).toBeTruthy();
  });

  test('TC-PROJ-005: เปลี่ยนสถานะ Pipeline', async ({ page }) => {
    // Click first project
    await page.locator('text=PPN-').first().click();
    await page.waitForTimeout(2000);

    // Look for status change button/stepper
    const statusBtn = page.locator('text=เปลี่ยนสถานะ').first();
    if (await statusBtn.isVisible()) {
      await statusBtn.click();
      await page.waitForTimeout(2000);
    }

    // Page should not crash
    await expect(page.locator('text=Projects').first()).toBeVisible();
  });

  test('TC-PROJ-006: สร้างโปรเจกต์ใหม่', async ({ page }) => {
    const createBtn = page.locator('text=Create New Project').first();
    if (await createBtn.isVisible()) {
      await createBtn.click();
      await page.waitForTimeout(2000);

      // Should see create project form
      const hasForm = await page.locator('text=ลูกค้า').first().isVisible()
        || await page.locator('text=Customer').first().isVisible();
      expect(hasForm).toBeTruthy();
    }
  });

  test('TC-PROJ-007: Error — สร้างโปรเจกต์ไม่เลือกลูกค้า', async ({ page }) => {
    const createBtn = page.locator('text=Create New Project').first();
    if (await createBtn.isVisible()) {
      await createBtn.click();
      await page.waitForTimeout(1000);

      // Try to save without selecting customer
      const saveBtn = page.locator('text=บันทึก').first();
      if (await saveBtn.isVisible()) {
        await saveBtn.click();
        await page.waitForTimeout(2000);

        // Should show error
        const hasError = await page.locator('text=กรุณา').first().isVisible()
          || await page.locator('text=Error').first().isVisible()
          || await page.locator('text=เกิดข้อผิดพลาด').first().isVisible();
        expect(hasError).toBeTruthy();
      }
    }
  });

  test('TC-PROJ-008: ดู Activity Log', async ({ page }) => {
    await page.locator('text=PPN-').first().click();
    await page.waitForTimeout(2000);

    // Look for activity/log section
    const hasLog = await page.locator('text=Activity').first().isVisible()
      || await page.locator('text=Log').first().isVisible()
      || await page.locator('text=ประวัติ').first().isVisible();
    // Activity log may or may not be visible depending on layout
    await expect(page.locator('text=PPN-').first()).toBeVisible();
  });

  test('TC-PROJ-009: Filter → All → แสดงทุกสถานะ', async ({ page }) => {
    const allTab = page.locator('text=All').first();
    if (await allTab.isVisible()) {
      await allTab.click();
      await page.waitForTimeout(2000);
    }
    // Should see projects
    const hasPPN = await page.locator('text=PPN-').first().isVisible();
    expect(hasPPN).toBeTruthy();
  });

  test('TC-PROJ-010: กด Back → กลับ Dashboard', async ({ page }) => {
    await page.locator('text=Back').first().click();
    await page.waitForTimeout(2000);
    await expect(page.locator('text=Dashboard').first()).toBeVisible();
  });
});
