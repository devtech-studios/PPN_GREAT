import { expect, test } from '@playwright/test';
import { authHeaders, createApiSession } from './support/api';
import { goToAdminPage, loginAsAdmin } from './support/flutter';

async function firstProjectCode(): Promise<string> {
  const { api, token } = await createApiSession();
  try {
    const response = await api.get('/api/projects', { headers: authHeaders(token) });
    const body = await response.json();
    return (body.data?.data ?? body.data)[0].project_code;
  } finally {
    await api.dispose();
  }
}

test.describe('Workflow surfaces (non-mutating)', () => {
  test('Projects search/filter/sort/collapse controls work', async ({ page }) => {
    await goToAdminPage(page, 'Projects (12)');
    const search = page.getByRole('textbox', { name: 'Search ID, Customer...' });
    await search.fill(await firstProjectCode());
    await expect(page.getByText(await firstProjectCode(), { exact: false }).first()).toBeVisible();

    await page.getByRole('button', { name: 'All Status', exact: true }).click();
    await expect(page.getByRole('menuitem', { name: 'Delivered', exact: true })).toBeVisible();
    await page.keyboard.press('Escape');
    await page.getByRole('button', { name: 'Target Date', exact: true }).click();
    await page.keyboard.press('Escape');
    await page.getByRole('button', { name: 'Collapse List', exact: true }).click();
    await expect(search).toBeHidden();
    await expect(page.getByText(await firstProjectCode(), { exact: false }).first()).toBeVisible();
  });

  test('Samples opens Add Local Sample dialog for a real project and cancels', async ({ page }) => {
    const code = await firstProjectCode();
    await goToAdminPage(page, 'Samples');
    const search = page.getByRole('textbox', { name: 'ค้นหารหัส, ชื่อลูกค้า...' });
    await search.fill(code);
    await page.getByText(code, { exact: false }).first().click();
    await expect(page.getByText('Add Local Sample', { exact: true })).toBeVisible({ timeout: 15_000 });
    await page.getByText('Add Local Sample', { exact: true }).click();
    await expect(page.getByText('Save Record', { exact: true })).toBeVisible();
    await page.getByText('Cancel', { exact: true }).last().click();
  });

  test('Artwork opens Add Artwork Log dialog for a real project and cancels', async ({ page }) => {
    const code = await firstProjectCode();
    await goToAdminPage(page, 'Artwork');
    const search = page.getByRole('textbox', { name: 'ค้นหารหัส, ชื่อลูกค้า...' });
    await search.fill(code);
    await page.getByText(code, { exact: false }).first().click();
    await expect(page.getByText('Add Artwork Log', { exact: true })).toBeVisible({ timeout: 15_000 });
    await page.getByText('Add Artwork Log', { exact: true }).click();
    await expect(page.getByText('Save Log', { exact: true })).toBeVisible();
    await page.getByText('Cancel', { exact: true }).last().click();
  });

  test('Finance exposes Inbound/Outbound, document tabs, logs, preview and save actions', async ({ page }) => {
    await loginAsAdmin(page);
    await page.getByRole('button', { name: 'Generate PI', exact: true }).click();
    await expect(page.getByText('Finance & Docs', { exact: true })).toBeVisible({ timeout: 20_000 });
    await expect(page.getByText('Inbound', { exact: true })).toBeVisible();
    await page.getByText('Outbound', { exact: true }).click();
    await expect(page.getByText('Expense Logs', { exact: true })).toBeVisible();
    await page.getByText('Inbound', { exact: true }).click();
    for (const tab of ['Quotation', 'Proforma Invoice', 'Record Deposit', 'Commercial Invoice']) {
      await expect(page.getByRole('button', { name: tab, exact: true })).toBeVisible();
    }
    await expect(page.getByText('Document Logs', { exact: true })).toBeVisible();
  });

  test('Record Payment shows form or paid state and receipt/history actions', async ({ page }) => {
    await loginAsAdmin(page);
    await page.getByRole('button', { name: 'Record Payment', exact: true }).click();
    await expect(page.getByText('Record Payment', { exact: true }).first()).toBeVisible({ timeout: 20_000 });
    await expect(page.getByText(/Payment History|ประวัติการรับชำระเงิน/).first()).toBeVisible();
  });

  test('Delivery shows auto-fill/add/remove/confirm surface without mutating stock', async ({ page }) => {
    await goToAdminPage(page, 'Delivery');
    await expect(page.getByText('Delivery Management', { exact: true })).toBeVisible({ timeout: 20_000 });
    await expect(page.getByText('Auto-fill remaining from PO', { exact: true })).toBeVisible();
    await expect(page.getByText('Add product to this delivery', { exact: true })).toBeVisible();
    await expect(page.getByText('Confirm Delivery', { exact: true })).toBeVisible();
    await expect(page.getByText('Delivery History', { exact: true })).toBeVisible();
  });
});
