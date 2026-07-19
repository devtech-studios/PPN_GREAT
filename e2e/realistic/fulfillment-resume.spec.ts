import { test } from '@playwright/test';
import { createApiSession } from '../support/api';
import { loginAsAdmin } from '../support/flutter';
import { resolveLatestFulfillmentState, runFulfillmentFlow } from './fulfillment-flow';

test.describe.configure({ mode: 'serial' });

test.describe('RESUME-001 | Fulfillment checkpoint mode | โหมดทำงานต่อจากข้อมูลเดิม', () => {
  test('RESUME-001 | Continue procurement, finance, logistics, stock and delivery | ทำงานต่อด้านจัดซื้อ การเงิน โลจิสติกส์ สต๊อก และจัดส่ง', async ({ page }) => {
    const { api, token } = await createApiSession();
    try {
      const state = await resolveLatestFulfillmentState(api, token);
      await loginAsAdmin(page);
      await runFulfillmentFlow(page, api, token, state);
    } finally {
      await api.dispose();
    }
  });
});
