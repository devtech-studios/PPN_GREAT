import { expect, test, type APIRequestContext, type APIResponse } from '@playwright/test';
import { authHeaders, createApiSession, uniqueRunId } from './support/api';
import { goToAdminPage } from './support/flutter';

async function bodyOf(response: APIResponse): Promise<any> {
  const body = await response.json();
  expect(response.ok(), JSON.stringify(body)).toBeTruthy();
  expect(body.success).toBe(true);
  return body.data;
}

async function post(api: APIRequestContext, token: string, path: string, data: object): Promise<any> {
  return bodyOf(await api.post(`/api${path}`, { headers: authHeaders(token), data }));
}

async function patch(api: APIRequestContext, token: string, path: string, data: object): Promise<any> {
  return bodyOf(await api.patch(`/api${path}`, { headers: authHeaders(token), data }));
}

test.describe.configure({ mode: 'serial' });

test.describe('Critical integration flow', () => {
  test('@live-mutation creates Customer → Project → Sample → Artwork revisions and verifies every UI', async ({ page }) => {
    const runId = uniqueRunId('PW-FLOW');
    const { api, token } = await createApiSession();

    try {
      const customer = await post(api, token, '/customers', {
        name: `Playwright Customer ${runId}`,
        type: 'SME',
        status: 'Active',
        tax_id: Date.now().toString().slice(-13),
        lead_source: 'Direct Contact',
        billing_address: 'E2E isolated test address',
      });

      const project = await post(api, token, '/projects', {
        customer_id: customer.id,
        priority: 1,
        target_date: new Date(Date.now() + 30 * 86_400_000).toISOString().slice(0, 10),
        order_value: 12_345,
        usage_location: 'Playwright staging',
        credit_term: '30 Days',
      });

      const product = await post(api, token, `/projects/${project.id}/products`, {
        name: `E2E Product ${runId}`,
        qty: 25,
        specs: 'Playwright integration fixture',
      });

      const sample = await post(api, token, '/samples', {
        project_id: project.id,
        product_item_id: product.id,
        sample_type: 'Pre-production Sample',
        origin: 'In-Stock',
        local_courier: 'E2E Courier',
        local_tracking: runId,
      });
      await patch(api, token, `/samples/${sample.id}/status`, { status: 'Sent to Client' });
      await patch(api, token, `/samples/${sample.id}/status`, { status: 'Approved', feedback: 'Approved by Playwright' });

      const artworkV1 = await post(api, token, '/artworks', {
        project_id: project.id,
        product_item_id: product.id,
        version: 'V1',
        source: 'In-house Designer',
        file_name: `${runId}-v1.png`,
        file_path: `/storage/artworks/${runId}-v1.png`,
      });
      await patch(api, token, `/artworks/${artworkV1.id}/feedback`, {
        status: 'Need Revision',
        feedback: 'Revise color in Playwright flow',
      });
      const artworkV2 = await post(api, token, '/artworks', {
        project_id: project.id,
        product_item_id: product.id,
        version: 'V2',
        source: 'In-house Designer',
        file_name: `${runId}-v2.png`,
        file_path: `/storage/artworks/${runId}-v2.png`,
      });
      await patch(api, token, `/artworks/${artworkV2.id}/status`, { status: 'Approved by Client' });

      await goToAdminPage(page, 'Customers');
      await page.getByRole('textbox', { name: 'ค้นหาชื่อบริษัท...' }).fill(runId);
      await expect(page.getByText(`Playwright Customer ${runId}`, { exact: true })).toBeVisible();

      await goToAdminPage(page, 'Projects (12)');
      await page.getByRole('textbox', { name: 'Search ID, Customer...' }).fill(project.project_code);
      await expect(page.getByText(project.project_code, { exact: false }).first()).toBeVisible();

      await goToAdminPage(page, 'Samples');
      await page.getByRole('textbox', { name: 'ค้นหารหัส, ชื่อลูกค้า...' }).fill(project.project_code);
      await page.getByText(project.project_code, { exact: false }).first().click();
      await expect(page.getByText(sample.sample_code, { exact: false })).toBeVisible({ timeout: 15_000 });
      await expect(page.getByText('Approved', { exact: true }).last()).toBeVisible();

      await goToAdminPage(page, 'Artwork');
      await page.getByRole('textbox', { name: 'ค้นหารหัส, ชื่อลูกค้า...' }).fill(project.project_code);
      await page.getByText(project.project_code, { exact: false }).first().click();
      await expect(page.getByText('V1', { exact: true })).toBeVisible({ timeout: 15_000 });
      await expect(page.getByText('V2', { exact: true })).toBeVisible();
      await expect(page.getByText('Approved by Client', { exact: true })).toBeVisible();
    } finally {
      await api.dispose();
    }
  });
});
