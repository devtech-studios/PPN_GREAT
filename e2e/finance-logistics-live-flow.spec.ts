import { expect, test, type APIRequestContext, type APIResponse } from '@playwright/test';
import { authHeaders, createApiSession, uniqueRunId } from './support/api';
import { goToAdminPage, loginAsAdmin } from './support/flutter';

async function readData(response: APIResponse): Promise<any> {
  const body = await response.json();
  expect(response.ok(), JSON.stringify(body)).toBeTruthy();
  expect(body.success).toBe(true);
  return body.data;
}

test.describe.configure({ mode: 'serial' });

test.describe('Finance and stock-safe delivery flow', () => {
  test('@live-mutation PI → payment verify → stock receive → delivery exact-once confirm → complete', async ({ page }) => {
    const runId = uniqueRunId('PW-LOG');
    const { api, token } = await createApiSession();
    const options = (data: object) => ({ headers: authHeaders(token), data });
    try {
      const customer = await readData(await api.post('/api/customers', options({
        name: `Logistics Customer ${runId}`,
        type: 'SME',
        billing_address: 'Playwright delivery address',
      })));
      const project = await readData(await api.post('/api/projects', options({
        customer_id: customer.id,
        credit_term: '30 Days',
        order_value: 2_000,
      })));
      const product = await readData(await api.post(`/api/projects/${project.id}/products`, options({
        name: `Logistics Product ${runId}`,
        qty: 20,
      })));
      const warehouses = await readData(await api.get('/api/inventory/warehouses', {
        headers: authHeaders(token),
      }));
      const warehouse = warehouses[0];

      const document = await readData(await api.post('/api/finance/documents', options({
        project_id: project.id,
        doc_type: 'PI',
        issue_date: new Date().toISOString().slice(0, 10),
        items: [{ item_name: product.name, qty: 20, unit_price: 100 }],
      })));
      expect(Number(document.total_amount)).toBe(2_000);

      const payment = await readData(await api.post('/api/finance/payments', options({
        project_id: project.id,
        finance_document_id: document.id,
        payment_type: 'Full',
        amount: 2_000,
        method: 'Bank Transfer',
        payment_date: new Date().toISOString().slice(0, 10),
        notes: runId,
      })));
      await readData(await api.patch(`/api/finance/payments/${payment.id}/verify`, {
        headers: authHeaders(token),
      }));

      await readData(await api.post('/api/inventory/receive', options({
        warehouse_id: warehouse.id,
        project_id: project.id,
        product_item_id: product.id,
        qty: 20,
        notes: runId,
        location_in_warehouse: 'E2E-ZONE',
      })));
      const beforeStocks = await readData(await api.get(
        `/api/inventory/warehouses/${warehouse.id}/stocks`,
        { headers: authHeaders(token) },
      ));
      const before = beforeStocks.find((row: any) => row.product_item_id === product.id);

      const round = await readData(await api.post('/api/delivery/rounds', options({
        dispatch_date: new Date(Date.now() + 86_400_000).toISOString().slice(0, 10),
        driver_name: 'Playwright Driver',
        vehicle_plate: 'E2E-0001',
        notes: runId,
        items: [{
          project_id: project.id,
          product_item_id: product.id,
          warehouse_id: warehouse.id,
          qty_to_deliver: 5,
          delivery_address: customer.billing_address,
        }],
      })));
      await readData(await api.patch(`/api/delivery/rounds/${round.id}/confirm`, {
        headers: authHeaders(token),
      }));

      const afterStocks = await readData(await api.get(
        `/api/inventory/warehouses/${warehouse.id}/stocks`,
        { headers: authHeaders(token) },
      ));
      const after = afterStocks.find((row: any) => row.product_item_id === product.id);
      expect(Number(after.qty_in_stock)).toBe(Number(before.qty_in_stock) - 5);

      const duplicateConfirm = await api.patch(`/api/delivery/rounds/${round.id}/confirm`, {
        headers: authHeaders(token),
      });
      expect(duplicateConfirm.status()).toBe(400);
      await readData(await api.patch(`/api/delivery/rounds/${round.id}/complete`, {
        headers: authHeaders(token),
      }));

      await loginAsAdmin(page);
      await page.getByRole('button', { name: 'Record Payment', exact: true }).click();
      await page.getByRole('textbox', { name: 'ค้นหาลูกค้า, รหัสโปรเจกต์...' }).fill(project.project_code);
      await expect(page.getByText(project.project_code, { exact: false }).first()).toBeVisible();

      await goToAdminPage(page, 'Delivery');
      await page.getByRole('textbox', { name: 'ค้นหาลูกค้า, รหัสโปรเจกต์...' }).fill(project.project_code);
      await expect(page.getByText(project.project_code, { exact: false }).first()).toBeVisible();
      await expect(page.getByText('Done', { exact: true }).last()).toBeVisible();
    } finally {
      await api.dispose();
    }
  });
});
