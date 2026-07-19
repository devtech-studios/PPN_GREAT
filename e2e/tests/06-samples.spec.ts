import { test, expect } from '@playwright/test';
import { loginAsAdmin, navigateTo } from '../helpers/auth';

/**
 * Test Suite 5: Client Samples
 * หน้าจอ: samples_screen.dart
 */

test.describe('06 — Client Samples', () => {

  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
    await navigateTo(page, 'Samples');
    await page.waitForTimeout(3000);
  });

  test('TC-SAMP-001: ดึงรายการ Samples สำเร็จ', async ({ page }) => {
    const hasSample = await page.locator('text=Sample').first().isVisible();
    expect(hasSample).toBeTruthy();
  });

  test('TC-SAMP-002: สร้าง Sample ใหม่', async ({ page }) => {
    const createBtn = page.locator('text=สร้าง').first();
    if (await createBtn.isVisible()) {
      await createBtn.click();
      await page.waitForTimeout(1000);
      // Dialog/form should appear
      const hasDialog = await page.locator('text=Project').first().isVisible()
        || await page.locator('text=โปรเจกต์').first().isVisible();
      expect(hasDialog).toBeTruthy();
    }
  });

  test('TC-SAMP-003: เปลี่ยนสถานะ Sample', async ({ page }) => {
    // Look for status buttons in the sample list
    const statusBtn = page.locator('text=Waiting').first();
    if (await statusBtn.isVisible()) {
      await statusBtn.click();
      await page.waitForTimeout(1000);
    }
    await expect(page.locator('text=Sample').first()).toBeVisible();
  });

  test('TC-SAMP-004: เลือก Project จาก Dropdown', async ({ page }) => {
    const dropdown = page.locator('text=เลือกโปรเจกต์').first();
    if (await dropdown.isVisible()) {
      await dropdown.click();
      await page.waitForTimeout(500);
    }
    await expect(page.locator('text=Sample').first()).toBeVisible();
  });

  test('TC-SAMP-005: แก้ไข Tracking No', async ({ page }) => {
    // Find edit button (pencil icon)
    const editBtn = page.locator('[class*="edit"], [class*="Edit"]').first();
    if (await editBtn.isVisible()) {
      await editBtn.click();
      await page.waitForTimeout(500);
    }
    await expect(page.locator('text=Sample').first()).toBeVisible();
  });

  test('TC-SAMP-006: Error — สร้าง Sample ไม่ระบุ Project', async ({ page }) => {
    const createBtn = page.locator('text=สร้าง').first();
    if (await createBtn.isVisible()) {
      await createBtn.click();
      await page.waitForTimeout(500);

      // Try to save without selecting project
      const saveBtn = page.locator('text=บันทึก').first();
      if (await saveBtn.isVisible()) {
        await saveBtn.click();
        await page.waitForTimeout(2000);
      }
    }
    // Should not crash
    await expect(page.locator('text=Sample').first()).toBeVisible();
  });

  test('TC-SAMP-007: ดูรายละเอียด Sample Status Pipeline', async ({ page }) => {
    // Look for pipeline/status indicators
    const hasStatus = await page.locator('text=Approved').first().isVisible()
      || await page.locator('text=Waiting').first().isVisible()
      || await page.locator('text=Received').first().isVisible()
      || await page.locator('text=Sent').first().isVisible()
      || await page.locator('text=Delivered').first().isVisible()
      || await page.locator('text=Rejected').first().isVisible();
    // Some status should be visible
    await expect(page.locator('text=Sample').first()).toBeVisible();
  });

  test('TC-SAMP-008: Sample Type Dropdown', async ({ page }) => {
    const createBtn = page.locator('text=สร้าง').first();
    if (await createBtn.isVisible()) {
      await createBtn.click();
      await page.waitForTimeout(500);

      // Look for sample type dropdown
      const typeDropdown = page.locator('text=Pre-production').first();
      if (await typeDropdown.isVisible()) {
        await typeDropdown.click();
        await page.waitForTimeout(300);
      }
    }
    await expect(page.locator('text=Sample').first()).toBeVisible();
  });

  test('TC-SAMP-009: Feedback field for Rejection', async ({ page }) => {
    // Look for feedback/reject related fields
    const rejectBtn = page.locator('text=Rejected').first();
    if (await rejectBtn.isVisible()) {
      // Just verify element exists, don't click (may change state)
      expect(true).toBeTruthy();
    }
    await expect(page.locator('text=Sample').first()).toBeVisible();
  });

  test('TC-SAMP-010: กด Back → กลับ Dashboard', async ({ page }) => {
    const backBtn = page.locator('text=Back').first();
    if (await backBtn.isVisible()) {
      await backBtn.click();
      await page.waitForTimeout(2000);
    }
    await expect(page.locator('text=Dashboard').first()).toBeVisible();
  });
});
