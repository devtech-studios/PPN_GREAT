import { expect, test } from '@playwright/test';
import {
  clickAndWaitForApiIdle,
  collectRuntimeFailures,
  expectNoRuntimeFailures,
  goToAdminPage,
  loginAsAdmin,
} from './support/flutter';

test.describe('Page actions and buttons (non-mutating)', () => {
  test('Dashboard quick actions open all six workflows', async ({ page }) => {
    test.slow();
    const actions = [
      'Create New Project',
      'Manage Samples',
      'Upload Artwork',
      'Generate PI',
      'Book Container',
      'Record Payment',
    ];
    let currentAction = 'Dashboard';
    const failures = collectRuntimeFailures(page, () => currentAction);
    await loginAsAdmin(page);

    for (const action of actions) {
      currentAction = action;
      await clickAndWaitForApiIdle(page, page.getByRole('button', { name: action, exact: true }));
      const backButton = page.getByText('Back', { exact: true }).first();
      await expect(backButton).toBeVisible({ timeout: 20_000 });
      await clickAndWaitForApiIdle(page, backButton, { timeoutMs: 10_000 });
      await expect(page.getByRole('button', { name: action, exact: true })).toBeVisible();
    }
    currentAction = 'Dashboard';
    expectNoRuntimeFailures(failures);
  });

  test('Customers exposes create form and Cancel returns without saving', async ({ page }) => {
    await goToAdminPage(page, 'Customers');
    await page.getByRole('button', { name: 'Create Customer', exact: true }).click();
    await expect(page.getByText('Save Customer', { exact: true })).toBeVisible();
    await expect(page.getByText('Add Another Contact', { exact: true })).toBeVisible();
    await expect(page.getByText('Add Shipping Address', { exact: true })).toBeVisible();
    await page.getByText('Cancel', { exact: true }).click();
    await expect(page.getByText('Cancel Creation?', { exact: true })).toBeVisible();
    await page.getByText('Yes, Discard', { exact: true }).click();
    await expect(page.getByRole('button', { name: 'Create Customer', exact: true })).toBeVisible();
  });

  test('Suppliers opens add/request dialogs and all three tabs', async ({ page }) => {
    await goToAdminPage(page, 'Suppliers');

    await page.getByRole('button', { name: 'Add New Supplier', exact: true }).click();
    await expect(page.getByText('Save Supplier', { exact: true })).toBeVisible();
    await page.getByText('Cancel', { exact: true }).last().click();
    for (const tab of ['ขอราคา (Quotes)', 'ขอตัวอย่าง (Samples)', 'รอบบิลจ่ายเงิน (AP)']) {
      await page.getByRole('button', { name: tab, exact: true }).click();
      await expect(page.getByRole('button', { name: tab, exact: true })).toBeVisible();
    }

    await page.getByRole('button', { name: 'ขอราคา (Quotes)', exact: true }).click();
    await page.getByRole('button', { name: '+ Request Quote', exact: true }).click();
    await expect(page.getByText('Add Request', { exact: true })).toBeVisible();
    await page.getByText('Cancel', { exact: true }).last().click();
  });

  test('Supplier Edit button opens the edit dialog', async ({ page }) => {
    await goToAdminPage(page, 'Suppliers');
    await page.getByRole('button', { name: 'Edit Supplier', exact: true }).click();
    await expect(page.getByText('Save Changes', { exact: true })).toBeVisible();
  });

  test('Inventory opens add warehouse and manual adjustment dialogs', async ({ page }) => {
    await goToAdminPage(page, 'Inventory');
    await page.getByRole('button', { name: 'เพิ่มคลังสินค้าใหม่', exact: true }).click();
    await expect(page.getByText('บันทึกคลังสินค้า', { exact: true })).toBeVisible();
    await page.getByText('ยกเลิก', { exact: true }).last().click();

    await page.getByRole('button', { name: 'Manual Adjust', exact: true }).click();
    await expect(page.getByText('Confirm Adjustment', { exact: true })).toBeVisible();
    await page.getByText('Cancel', { exact: true }).last().click();
  });

  test('Containers opens create dialog, validates fields, and cancels safely', async ({ page }) => {
    await goToAdminPage(page, 'Containers');
    const buttons = page.getByRole('button');
    await buttons.nth(1).click();
    await expect(page.getByText('สร้างตู้สินค้า & การขนส่งใหม่ (Create Container)', { exact: true })).toBeVisible();
    await page.getByText('บันทึก', { exact: true }).click();
    await expect(page.getByText('สร้างตู้สินค้า & การขนส่งใหม่ (Create Container)', { exact: true })).toBeVisible();
    await page.getByText('ยกเลิก', { exact: true }).last().click();
  });

  test('Reports switches every financial, operations, partner, and insight tab', async ({ page }) => {
    const reportTabs = [
      'คาดการณ์รายรับ & วางบิล',
      'กำไรสุทธิรายโปรเจกต์',
      'กระแสเงินสด & AR/AP',
      'ภาษีนำเข้า & ค่าธรรมเนียม',
      'สถานะการทยอยส่งของ',
      'วิเคราะห์เวลาทำงาน (Lead Time)',
      'สินค้าค้างสต็อก (Aging)',
      'Ranking ซัพพลายเออร์',
      'สถิติของเคลม (FOC)',
      'สัดส่วนรายได้ลูกค้า',
      'กลุ่มสินค้าขายดี',
      'ประสิทธิภาพขนส่ง',
    ];
    const failures = collectRuntimeFailures(page);
    await goToAdminPage(page, 'Reports');
    for (const tab of reportTabs) {
      const control = page.getByRole('button', { name: tab, exact: true });
      await expect(control).toBeVisible();
      await control.click();
    }
    expectNoRuntimeFailures(failures);
  });
});
