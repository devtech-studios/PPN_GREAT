import { test } from '@playwright/test';
import { goToAdminPage, loginAsAdmin } from './support/flutter';

test.describe('Flutter semantics inventory', () => {
  test.skip(!process.env.E2E_SEMANTICS_AUDIT, 'Run with E2E_SEMANTICS_AUDIT=1 when auditing selectors.');

  test('prints interactive semantics for every admin page', async ({ page }) => {
    const menus = ['Dashboard', 'Projects (12)', 'Samples', 'Artwork', 'Containers', 'Delivery', 'Customers', 'Suppliers', 'Finance', 'Inventory', 'Reports'];
    await loginAsAdmin(page);

    for (const menu of menus) {
      if (menu !== 'Dashboard') await goToAdminPage(page, menu);
      const controls: Array<{ role: string; label: string }> = [];
      for (const role of ['button', 'textbox', 'combobox', 'tab'] as const) {
        const locator = page.getByRole(role);
        for (let index = 0; index < await locator.count(); index += 1) {
          const item = locator.nth(index);
          controls.push({
            role,
            label: (await item.getAttribute('aria-label')) ?? (await item.textContent()) ?? '',
          });
        }
      }
      console.log(`SEMANTICS ${menu}: ${JSON.stringify(controls)}`);
      if (menu !== 'Dashboard') await page.goBack();
    }
  });
});
