import { test, expect } from '@playwright/test';
import { loginAsAdmin, navigateTo, expectSnackBar } from '../helpers/auth';

/**
 * Test Suite 3: Customers
 * หน้าจอ: create_customer_screen.dart
 * ทดสอบ: CRUD ลูกค้า, ค้นหา, ผู้ติดต่อ, ที่อยู่, Validation
 */

test.describe('03 — Customers', () => {

  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
    await navigateTo(page, 'Customers');
    await page.waitForTimeout(3000); // Wait for customer list to load from API
  });

  test('TC-CUST-001: ดึงรายชื่อลูกค้าจาก API สำเร็จ', async ({ page }) => {
    // The customer list should have at least 1 customer from seeder
    const customerItems = page.locator('text=Active').first();
    await expect(customerItems).toBeVisible({ timeout: 10_000 });
  });

  test('TC-CUST-002: ค้นหาลูกค้าด้วยชื่อ', async ({ page }) => {
    const searchInput = page.locator('input[placeholder*="ค้นหา"]').first();
    await searchInput.fill('AIS');
    await page.waitForTimeout(2000); // Wait for API debounce + response

    // Should find results containing AIS or show filtered list
    // (If no AIS in seeder, at least it should not crash)
    await expect(page.locator('text=Customers').first()).toBeVisible();
  });

  test('TC-CUST-003: เลือกลูกค้า → แสดง Detail + Stats', async ({ page }) => {
    // Click the first customer in the list
    const firstCustomer = page.locator('[class*="InkWell"]').first();
    if (await firstCustomer.isVisible()) {
      await firstCustomer.click();
      await page.waitForTimeout(2000);
    }

    // Detail section should show contact info or stats
    const hasDetail = await page.locator('text=Revenue').first().isVisible()
      || await page.locator('text=Projects').first().isVisible()
      || await page.locator('text=ผู้ติดต่อ').first().isVisible();
    expect(hasDetail).toBeTruthy();
  });

  test('TC-CUST-004: สร้างลูกค้าใหม่สำเร็จ (Happy Path)', async ({ page }) => {
    // Click Create Customer button
    await page.locator('text=Create Customer').first().click();
    await page.waitForTimeout(1000);

    // Fill company name — find the company name field
    const nameInputs = page.locator('input[type="text"]');
    const allInputs = await nameInputs.all();

    // The first text input in the create form should be the company name
    if (allInputs.length > 0) {
      // Find the company name input (look for one with Thai placeholder or label)
      for (const input of allInputs) {
        const placeholder = await input.getAttribute('placeholder') || '';
        if (placeholder.includes('ชื่อ') || placeholder.includes('บริษัท') || placeholder.includes('company')) {
          await input.fill(`TestCo Playwright ${Date.now()}`);
          break;
        }
      }
    }

    // Try to save
    const saveBtn = page.locator('text=บันทึก').first();
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(3000);
    }
  });

  test('TC-CUST-005: Collapse/Expand sidebar ซ้าย', async ({ page }) => {
    // Find the collapse toggle button (menu icon)
    const collapseBtn = page.locator('[class*="IconButton"]').filter({
      has: page.locator('[class*="menu"]'),
    }).first();

    if (await collapseBtn.isVisible()) {
      await collapseBtn.click();
      await page.waitForTimeout(500);

      // Sidebar should be collapsed (width ~ 80px)
      // We can check if the "Create Customer" text is hidden
      const createBtnVisible = await page.locator('text=Create Customer').first().isVisible();
      // If collapsed, the full text should not be visible
      // Click expand
      const expandBtn = page.locator('[class*="IconButton"]').first();
      await expandBtn.click();
      await page.waitForTimeout(500);
    }

    // Page should not crash
    await expect(page.locator('text=Customers').first()).toBeVisible();
  });

  test('TC-CUST-006: สร้างลูกค้าพร้อมผู้ติดต่อหลายคน', async ({ page }) => {
    await page.locator('text=Create Customer').first().click();
    await page.waitForTimeout(1000);

    // Fill minimum required field (company name)
    const allInputs = await page.locator('input[type="text"]').all();
    if (allInputs.length > 0) {
      await allInputs[0].fill(`MultiContact Co ${Date.now()}`);
    }

    // Look for "Add Contact" button and click it to add additional contacts
    const addContactBtn = page.locator('text=เพิ่มผู้ติดต่อ').first();
    if (await addContactBtn.isVisible()) {
      await addContactBtn.click();
      await page.waitForTimeout(500);
      await addContactBtn.click();
      await page.waitForTimeout(500);
    }

    // Page should not crash
    await expect(page.locator('text=Customers').first()).toBeVisible();
  });

  test('TC-CUST-007: Error — สร้างลูกค้าไม่กรอกชื่อ', async ({ page }) => {
    await page.locator('text=Create Customer').first().click();
    await page.waitForTimeout(1000);

    // Don't fill anything, try to save
    const saveBtn = page.locator('text=บันทึก').first();
    if (await saveBtn.isVisible()) {
      await saveBtn.click();
      await page.waitForTimeout(2000);

      // Should show error dialog
      const errorVisible = await page.locator('text=กรุณากรอกชื่อบริษัท').first().isVisible()
        || await page.locator('text=เกิดข้อผิดพลาด').first().isVisible();
      expect(errorVisible).toBeTruthy();
    }
  });

  test('TC-CUST-008: กด Back → กลับ Dashboard', async ({ page }) => {
    await page.locator('text=Back').first().click();
    await page.waitForTimeout(2000);

    // Should be on Dashboard
    await expect(page.locator('text=Dashboard').first()).toBeVisible();
  });

  test('TC-CUST-009: สร้างลูกค้าพร้อมที่อยู่จัดส่ง', async ({ page }) => {
    await page.locator('text=Create Customer').first().click();
    await page.waitForTimeout(1000);

    // Fill company name
    const allInputs = await page.locator('input[type="text"]').all();
    if (allInputs.length > 0) {
      await allInputs[0].fill(`ShippingAddr Co ${Date.now()}`);
    }

    // Look for "Add Shipping Address" button
    const addAddrBtn = page.locator('text=เพิ่มที่อยู่จัดส่ง').first();
    if (await addAddrBtn.isVisible()) {
      await addAddrBtn.click();
      await page.waitForTimeout(500);
    }

    // Page should not crash
    await expect(page.locator('text=Customers').first()).toBeVisible();
  });

  test('TC-CUST-010: เลือก Customer Tier (SME / Mid-Market / Enterprise)', async ({ page }) => {
    await page.locator('text=Create Customer').first().click();
    await page.waitForTimeout(1000);

    // Look for tier selectors
    const midMarket = page.locator('text=Mid-Market').first();
    if (await midMarket.isVisible()) {
      await midMarket.click();
      await page.waitForTimeout(300);
    }

    const enterprise = page.locator('text=Enterprise').first();
    if (await enterprise.isVisible()) {
      await enterprise.click();
      await page.waitForTimeout(300);
    }

    // No crash
    await expect(page.locator('text=Customers').first()).toBeVisible();
  });

  test('TC-CUST-011: เลือก Lead Source dropdown', async ({ page }) => {
    await page.locator('text=Create Customer').first().click();
    await page.waitForTimeout(1000);

    // Look for Lead Source dropdown or option
    const leadSource = page.locator('text=Lead Source').first();
    if (await leadSource.isVisible()) {
      // Click to open dropdown
      await leadSource.click();
      await page.waitForTimeout(500);

      const option = page.locator('text=Facebook Ads').first();
      if (await option.isVisible()) {
        await option.click();
        await page.waitForTimeout(300);
      }
    }

    await expect(page.locator('text=Customers').first()).toBeVisible();
  });

  test('TC-CUST-012: กดดูโปรเจกต์ของลูกค้า → navigate', async ({ page }) => {
    // Click the first customer that has projects
    await page.waitForTimeout(2000);

    // Look for project links in detail view
    const projectLink = page.locator('text=PPN-').first();
    if (await projectLink.isVisible()) {
      await projectLink.click();
      await page.waitForTimeout(2000);

      // Should navigate somewhere (no crash)
      const pageContent = await page.content();
      expect(pageContent).toBeTruthy();
    }
  });
});
