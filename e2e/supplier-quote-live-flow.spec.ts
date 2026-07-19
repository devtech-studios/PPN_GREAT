import { expect, test, type APIRequestContext, type APIResponse } from '@playwright/test';
import { authHeaders, createApiSession, uniqueRunId } from './support/api';
import { goToAdminPage } from './support/flutter';

async function dataOf(response: APIResponse): Promise<any> {
  const body = await response.json();
  expect(response.ok(), JSON.stringify(body)).toBeTruthy();
  expect(body.success).toBe(true);
  return body.data;
}

async function createFixture(api: APIRequestContext, token: string, runId: string) {
  const options = (data: object) => ({ headers: authHeaders(token), data });
  const customer = await dataOf(await api.post('/api/customers', options({
    name: `Quote Customer ${runId}`,
    type: 'SME',
  })));
  const project = await dataOf(await api.post('/api/projects', options({
    customer_id: customer.id,
    credit_term: '30 Days',
  })));
  const product = await dataOf(await api.post(`/api/projects/${project.id}/products`, options({
    name: `Quote Product ${runId}`,
    qty: 100,
    specs: 'Supplier Portal Playwright fixture',
  })));
  const supplier = await dataOf(await api.post('/api/suppliers', options({
    name: `Quote Supplier ${runId}`,
    category: 'E2E',
    email: `${runId.toLowerCase()}@example.test`,
    is_active: true,
  })));
  const quote = await dataOf(await api.post(`/api/suppliers/${supplier.id}/quotes`, options({
    project_id: project.id,
    product_item_id: product.id,
    product_name: product.name,
    qty: product.qty,
    specs: product.specs,
  })));
  const link = await dataOf(await api.post(
    `/api/suppliers/${supplier.id}/quotes/${quote.id}/generate-link`,
    { headers: authHeaders(token) },
  ));
  return { customer, project, product, supplier, quote, link };
}

test.describe.configure({ mode: 'serial' });

test.describe('Supplier quote cross-system flow', () => {
  test('@live-mutation admin request → generated token → supplier submit → admin review', async ({ page }) => {
    const runId = uniqueRunId('PW-QUOTE');
    const { api, token } = await createApiSession();
    try {
      const fixture = await createFixture(api, token, runId);

      await page.goto('http://localhost:3000');
      await page.locator('#username').fill(fixture.supplier.email);
      await page.locator('#password').fill(fixture.link.session_token);
      await page.getByRole('button', { name: 'Log In to Portal' }).click();
      await expect(page.locator('#dashboard-screen')).toBeVisible();

      const card = page.locator(`#card-${fixture.quote.id}`);
      await expect(card).toContainText(fixture.product.name);
      await page.locator(`#price-${fixture.quote.id}`).fill('12.50');
      await page.locator(`#lead-${fixture.quote.id}`).fill('14 days');
      await page.locator(`#moq-${fixture.quote.id}`).fill('100');
      await page.locator(`#sample-price-${fixture.quote.id}`).fill('50');
      await page.locator(`#sample-lead-${fixture.quote.id}`).fill('5 days');
      await page.locator(`#remark-${fixture.quote.id}`).fill(runId);
      await card.getByRole('button', { name: 'Submit Quote' }).click();
      await expect(page.locator('#success-banner')).toBeVisible();

      const quotes = await api.get(`/api/suppliers/${fixture.supplier.id}/quotes`, {
        headers: authHeaders(token),
      });
      const saved = (await quotes.json()).data.find((row: any) => row.id === fixture.quote.id);
      expect(saved.status).toBe('Price Filled');
      expect(Number(saved.quoted_price)).toBe(12.5);

      await goToAdminPage(page, 'Suppliers');
      await page.getByRole('textbox', { name: 'ค้นหาชื่อโรงงาน...' }).fill(runId);
      await page.getByText(fixture.supplier.name, { exact: true }).click();
      await expect(page.getByText(fixture.product.name, { exact: true })).toBeVisible();
      await expect(page.getByRole('button', { name: 'Review & Resubmit', exact: true })).toBeVisible();
    } finally {
      await api.dispose();
    }
  });

  test.fixme('@live-mutation portal submit endpoint rejects a caller without the generated supplier token', async () => {
    // Known security defect: POST /api/supplier/portal/quotes/{qid}/submit has no token/session check.
    // Keep disabled on shared data until backend authorization is implemented.
  });
});
