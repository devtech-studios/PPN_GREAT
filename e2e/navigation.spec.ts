import { expect, test } from '@playwright/test';
import {
  clickAndWaitForApiIdle,
  collectRuntimeFailures,
  expectNoRuntimeFailures,
  goToAdminPage,
  loginAsAdmin,
} from './support/flutter';

const implementedMenus = [
  'Dashboard',
  'Projects (12)',
  'Samples',
  'Artwork',
  'Containers',
  'Delivery',
  'Customers',
  'Suppliers',
  'Finance',
  'Inventory',
  'Reports',
] as const;

test.describe('Global navigation', () => {
  test('@smoke renders every implemented menu and opens it without a Flutter crash', async ({ page }) => {
    test.slow();
    let currentMenu = 'Dashboard';
    const failures = collectRuntimeFailures(page, () => currentMenu);
    await loginAsAdmin(page);

    for (const menu of implementedMenus) {
      if (menu !== 'Dashboard') {
        currentMenu = menu;
        const menuButton = page.getByText(menu, { exact: true }).first();
        await expect(menuButton).toBeVisible();
        await clickAndWaitForApiIdle(page, menuButton);

        if (menu === 'Projects (12)') {
          // At Playwright's desktop viewport the responsive Projects detail
          // hides its Back control, so browser history is the only available exit.
          // All API calls have settled above, preventing disposed-widget races.
          await page.goBack();
        } else {
          // Reports names its app-level Back control "Dashboard".
          const backButton = menu === 'Reports'
            ? page.getByText('Dashboard', { exact: true }).first()
            : page.getByText('Back', { exact: true }).first();
          await expect(backButton).toBeVisible({ timeout: 20_000 });
          await clickAndWaitForApiIdle(page, backButton, { timeoutMs: 10_000 });
        }

        await expect(
          page.getByText('Dashboard', { exact: true }).first(),
          `Failed to return to Dashboard after opening ${menu}`,
        ).toBeVisible({ timeout: 20_000 });
        await page.waitForTimeout(250);
      }
    }

    currentMenu = 'Dashboard';
    expectNoRuntimeFailures(failures);
  });

  test('Settings is explicitly identified as a placeholder', async ({ page }) => {
    await goToAdminPage(page, 'Settings');
    await expect(page.getByText('Settings Page', { exact: true })).toBeVisible();
    await page.getByText('Back to Dashboard', { exact: true }).click();
    await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible();
  });
});
