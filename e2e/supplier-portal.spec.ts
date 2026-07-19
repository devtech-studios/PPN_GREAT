import { expect, test, type APIRequestContext } from '@playwright/test';
import { env } from './support/env';

async function resolveSupplierUsername(request: APIRequestContext): Promise<string> {
  if (process.env.E2E_SUPPLIER_USERNAME) return env.supplierUsername;
  const login = await request.post(`${env.apiBaseUrl}/api/auth/login`, {
    data: { email: env.adminEmail, password: env.adminPassword },
  });
  const token = (await login.json()).data.token;
  const suppliers = await request.get(`${env.apiBaseUrl}/api/suppliers`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const rows = (await suppliers.json()).data;
  return rows[0]?.email ?? rows[0]?.wechat ?? env.supplierUsername;
}

test.describe('Supplier portal', () => {
  test('@smoke validates login and switches all navigation buttons', async ({ page, request }) => {
    await page.goto('/');
    await page.locator('#username').fill('');
    await page.locator('#password').fill('');
    let validationMessage = '';
    page.once('dialog', async dialog => {
      validationMessage = dialog.message();
      await dialog.dismiss();
    });
    await page.getByRole('button', { name: 'Log In to Portal' }).click();
    expect(validationMessage).toContain('กรุณากรอก');

    await page.locator('#username').fill(await resolveSupplierUsername(request));
    await page.locator('#password').fill(env.supplierPassword);
    await page.getByRole('button', { name: 'Log In to Portal' }).click();
    await expect(page.locator('#dashboard-screen')).toBeVisible();

    await page.locator('#tab-history').click();
    await expect(page.locator('#view-history')).toBeVisible();
    await page.locator('#tab-pending').click();
    await expect(page.locator('#view-pending')).toBeVisible();

    await page.locator('.nav-item', { hasText: 'Log Out' }).click();
    await expect(page.locator('#login-screen')).toBeVisible();
  });

  test('validates quote submission fields before calling the API', async ({ page, request }) => {
    await page.goto('/');
    await page.locator('#username').fill(await resolveSupplierUsername(request));
    await page.locator('#password').fill(env.supplierPassword);
    await page.getByRole('button', { name: 'Log In to Portal' }).click();
    await expect(page.locator('#dashboard-screen')).toBeVisible();

    const submit = page.getByRole('button', { name: 'Submit Quote' }).first();
    test.skip((await submit.count()) === 0, 'No pending quote exists for the configured supplier.');
    await submit.click();
    await expect(page.locator('.error-text:visible').first()).toBeVisible();
  });
});
