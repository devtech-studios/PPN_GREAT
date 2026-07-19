import { expect, test } from '@playwright/test';
import { collectRuntimeFailures, enableFlutterSemantics, loginAsAdmin, openFlutterApp } from './support/flutter';

test.describe('Authentication', () => {
  test('@smoke validates required credentials', async ({ page }) => {
    await openFlutterApp(page);
    await page.getByText('Sign In', { exact: true }).click();
    await expect(page.getByText(/Email.*Password/i)).toBeVisible();
  });

  test('rejects invalid credentials without navigating', async ({ page }) => {
    await openFlutterApp(page);
    const fields = page.getByRole('textbox');
    await fields.first().click();
    await fields.first().pressSequentially('invalid@example.com');
    await fields.nth(1).click();
    await fields.nth(1).pressSequentially('wrong-password');
    const rejectedLogin = page.waitForResponse(response =>
      response.url().endsWith('/api/auth/login') && response.request().method() === 'POST',
    );
    await page.getByText('Sign In', { exact: true }).click();
    expect((await rejectedLogin).status()).toBe(401);
    await expect(page.getByText('Sign In', { exact: true })).toBeVisible();
  });

  test('@smoke logs in, reloads with a persisted token, and logs out', async ({ page }) => {
    const failures = collectRuntimeFailures(page);
    await loginAsAdmin(page);
    await page.reload();
    await enableFlutterSemantics(page);
    await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible();

    await page.getByText('Log Out', { exact: true }).first().click();
    await expect(page.getByText('Log Out', { exact: true }).last()).toBeVisible();
    await page.getByText(/ออกจากระบบ/, { exact: false }).last().click();
    await expect(page.getByText('Sign In', { exact: true })).toBeVisible();
    expect(failures.filter(item => !item.includes('401'))).toEqual([]);
  });
});
