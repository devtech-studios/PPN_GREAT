import path from 'node:path';
import { expect, test, type APIRequestContext, type Page } from '@playwright/test';
import { authHeaders, createApiSession } from '../support/api';
import { env } from '../support/env';
import { uploadThroughFileChooser } from '../support/file-upload';
import { clickAndWaitForApiIdle, goToAdminPage, loginAsAdmin } from '../support/flutter';
import { runFulfillmentFlow, type FulfillmentState } from './fulfillment-flow';

type BusinessState = {
  customer?: any;
  project?: any;
  product?: any;
  supplier?: any;
  quote?: any;
};

const runKey = `REAL-${new Date().toISOString().replace(/\D/g, '').slice(0, 14)}`;
const customerName = `บริษัท ทดสอบวงจรจริง ${runKey}`;
const contactName = `ผู้ประสานงาน ${runKey}`;
const productName = `ถุงผ้าทดสอบ ${runKey}`;
const supplierEmail = process.env.E2E_SUPPLIER_USERNAME ?? 'supplier@ppngreat.local';
const uploadFixture = path.resolve(__dirname, '../../web/favicon.png');

function rowsFrom(body: any): any[] {
  const data = body?.data;
  if (Array.isArray(data)) return data;
  if (Array.isArray(data?.data)) return data.data;
  return [];
}

async function apiRows(api: APIRequestContext, token: string, endpoint: string): Promise<any[]> {
  const response = await api.get(`/api${endpoint}`, { headers: authHeaders(token) });
  const body = await response.json();
  expect(response.ok(), JSON.stringify(body)).toBeTruthy();
  expect(body.success).toBe(true);
  return rowsFrom(body);
}

async function newestMatching(
  api: APIRequestContext,
  token: string,
  endpoint: string,
  predicate: (row: any) => boolean,
): Promise<any> {
  await expect.poll(async () => {
    const rows = await apiRows(api, token, endpoint);
    return rows.find(predicate) ?? null;
  }, { timeout: 20_000 }).not.toBeNull();
  return (await apiRows(api, token, endpoint)).find(predicate);
}

async function fillTextbox(page: Page, name: string | RegExp, value: string, index = 0): Promise<void> {
  const input = page.getByRole('textbox', { name }).nth(index);
  await expect(input).toBeVisible();
  await input.click();
  await input.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await input.pressSequentially(value, { delay: 8 });
}

test.describe.configure({ mode: 'serial' });

test.describe('REAL-001 | Complete realistic business cycle | วงจรธุรกิจเสมือนจริงครบกระบวนการ', () => {
  test('REAL-001 | Admin creates connected records and supplier submits a quote | แอดมินสร้างข้อมูลที่เชื่อมโยงกันและซัพพลายเออร์ส่งใบเสนอราคา', async ({ page }) => {
    const state: BusinessState = {};
    const { api, token } = await createApiSession();

    try {
      await test.step('PRE-001 | Verify the clean baseline | ตรวจสอบฐานข้อมูลตั้งต้นที่สะอาด', async () => {
        const [customers, projects, suppliers] = await Promise.all([
          apiRows(api, token, '/customers'),
          apiRows(api, token, '/projects'),
          apiRows(api, token, '/suppliers'),
        ]);
        expect(customers, 'Baseline must not contain customers / ต้องไม่มีข้อมูลลูกค้า').toHaveLength(0);
        expect(projects, 'Baseline must not contain projects / ต้องไม่มีข้อมูลโครงการ').toHaveLength(0);
        expect(suppliers, 'Baseline must contain exactly one supplier / ต้องมีซัพพลายเออร์หนึ่งราย').toHaveLength(1);
        state.supplier = suppliers[0];
        expect(state.supplier.email).toBe(supplierEmail);
      });

      await test.step('AUTH-001 | Sign in as administrator | เข้าสู่ระบบด้วยบัญชีแอดมิน', async () => {
        await loginAsAdmin(page);
        await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible();
      });

      await test.step('CUST-001 | Create a customer with contact and billing address | สร้างลูกค้าพร้อมผู้ติดต่อและที่อยู่ออกบิล', async () => {
        await goToAdminPage(page, 'Customers');
        await page.getByRole('button', { name: 'Create Customer', exact: true }).click();
        await expect(page.getByText('Company Profile', { exact: true })).toBeVisible();

        await fillTextbox(page, /บริษัท พีพีเอ็น จำกัด/, customerName);
        await fillTextbox(page, 'X-XXXX-XXXXX-XX-X', `01055${Date.now().toString().slice(-8)}`);
        await page.getByText('Direct Contact', { exact: true }).click();
        await fillTextbox(page, /ชื่อผู้ติดต่อ/, contactName);
        await fillTextbox(page, '08X-XXX-XXXX', '0812345678');
        await fillTextbox(page, 'email@company.com', `customer-${runKey.toLowerCase()}@example.test`);
        await fillTextbox(page, /กรอกที่อยู่สำหรับออกใบกำกับภาษี/, '99 ถนนทดสอบ แขวงทดสอบ เขตทดสอบ กรุงเทพมหานคร 10110');

        const sameAsBilling = page.getByText(/ใช้ที่อยู่จัดส่งเดียวกับที่อยู่ออกบิล/).first();
        await expect(sameAsBilling).toBeVisible();
        await page.getByRole('switch').last().click();
        await page.getByRole('button', { name: 'Save Customer', exact: true }).click();
        await expect(page.getByText('Confirm & Save', { exact: true })).toBeVisible();
        await clickAndWaitForApiIdle(page, page.getByText('Confirm & Save', { exact: true }));
        await expect(page.getByText(new RegExp(customerName)).first()).toBeVisible({ timeout: 20_000 });

        state.customer = await newestMatching(api, token, '/customers', row => row.name === customerName);
        expect(state.customer.contacts?.[0]?.name).toBe(contactName);
      });

      await test.step('PROJ-001 | Create a project and product for the new customer | สร้างโครงการและสินค้าให้ลูกค้ารายใหม่', async () => {
        await goToAdminPage(page, 'Dashboard');
        await page.getByText('Create New Project', { exact: true }).click();
        await expect(page.getByText('Create New Project', { exact: true }).first()).toBeVisible();

        await fillTextbox(page, 'ค้นหาลูกค้า...', customerName);
        await page.getByRole('button', { name: new RegExp(customerName) }).click();
        await page.getByText(/เลือกผู้รับผิดชอบ/).click();
        await page.keyboard.press('ArrowDown');
        await page.keyboard.press('Enter');
        await fillTextbox(page, 'งบประมาณรวม (ถ้ามี)', '125000');
        await fillTextbox(page, 'Search or type custom product...', productName);
        await fillTextbox(page, 'e.g. 1000', '1000');
        await fillTextbox(page, /ระบุวัสดุ สี ขนาด จุดสกรีน/, 'ผ้าแคนวาสสีธรรมชาติ ขนาด 35x40 ซม. สกรีนโลโก้ 1 สี');

        await page.getByRole('button', { name: 'Create Project', exact: true }).click();
        await page.getByText('Confirm & Create', { exact: true }).click();
        await expect(page.getByText('Project Created Successfully!', { exact: true })).toBeVisible({ timeout: 20_000 });
        await page.getByRole('button', { name: 'View / Edit Project', exact: true }).click();

        state.project = await newestMatching(api, token, '/projects', row => Number(row.customer_id) === Number(state.customer.id));
        const projectDetailResponse = await api.get(`/api/projects/${state.project.id}`, { headers: authHeaders(token) });
        const projectDetailBody = await projectDetailResponse.json();
        expect(projectDetailResponse.ok(), JSON.stringify(projectDetailBody)).toBeTruthy();
        const detail = projectDetailBody.data;
        state.project = detail;
        state.product = detail.products?.find((row: any) => row.name === productName)
          ?? detail.product_items?.find((row: any) => row.name === productName);
        expect(state.product, 'Product created by UI / ต้องพบสินค้าที่สร้างจากหน้า UI').toBeTruthy();
      });

      await test.step('SAMP-001 | Record and approve a local client sample | บันทึกและอนุมัติตัวอย่างที่ส่งให้ลูกค้า', async () => {
        await goToAdminPage(page, 'Samples');
        await fillTextbox(page, /ค้นหารหัส, ชื่อลูกค้า/, state.project.project_code);
        await page.getByText(state.project.project_code, { exact: false }).first().click();
        await page.getByText('Add Local Sample', { exact: true }).click();
        await fillTextbox(page, 'Courier (e.g. Grab)', 'Grab Express');
        await fillTextbox(page, 'Tracking No.', `TRACK-${runKey}`);
        await page.getByText('Save Record', { exact: true }).click();
        // The API currently forces a new In-Stock sample to "Received from China"
        // even though the Flutter payload asks for "Sent to Client". Exercise the
        // real status control to continue the business workflow.
        await expect(page.getByText('Received from China', { exact: true }).last()).toBeVisible({ timeout: 20_000 });
        await page.getByRole('button', { name: 'Received from China', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Sent to Client', exact: true }).click();
        await expect.poll(async () => {
          const samples = await apiRows(api, token, `/samples/project/${state.project.id}`);
          return samples[0]?.status;
        }).toBe('Sent to Client');

        await page.getByRole('button', { name: 'Sent to Client', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Approved by Client', exact: true }).click();
        await expect.poll(async () => {
          const samples = await apiRows(api, token, `/samples/project/${state.project.id}`);
          return samples.some(row => row.status === 'Approved');
        }).toBe(true);
      });

      await test.step('ART-001 | Upload and approve artwork through the file input | อัปโหลดและอนุมัติอาร์ตเวิร์กผ่านช่องเลือกไฟล์', async () => {
        await goToAdminPage(page, 'Artwork');
        await fillTextbox(page, /ค้นหารหัส, ชื่อลูกค้า/, state.project.project_code);
        await page.getByText(state.project.project_code, { exact: false }).first().click();
        await page.getByText('Add Artwork Log', { exact: true }).click();
        await uploadThroughFileChooser(page, page.getByText('Choose File', { exact: true }), uploadFixture);
        await page.getByText('Save Log', { exact: true }).click();
        await expect(page.getByText('V1', { exact: true })).toBeVisible({ timeout: 20_000 });

        await page.getByRole('button', { name: 'Awaiting Approval', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Reviewing', exact: true }).click();
        await expect.poll(async () => {
          const artworks = await apiRows(api, token, `/artworks/project/${state.project.id}`);
          return artworks[0]?.status;
        }).toBe('Reviewing');
        await page.getByRole('button', { name: 'Reviewing', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Approved by Client', exact: true }).click();
        await expect.poll(async () => {
          const artworks = await apiRows(api, token, `/artworks/project/${state.project.id}`);
          return artworks.some(row => String(row.status).includes('Approved'));
        }).toBe(true);
      });

      await test.step('SUP-001 | Request a quote and generate the supplier session | ขอราคาและสร้างลิงก์เซสชันสำหรับซัพพลายเออร์', async () => {
        await goToAdminPage(page, 'Suppliers');
        await fillTextbox(page, /ค้นหาชื่อโรงงาน/, state.supplier.name);
        await page.getByRole('button', { name: new RegExp(state.supplier.name) }).click();
        await page.getByRole('button', { name: '+ Request Quote', exact: true }).click();
        await page.getByText('Select Project', { exact: true }).click();
        await page.keyboard.press('ArrowDown');
        await page.keyboard.press('Enter');
        await page.keyboard.press('Tab');
        await page.keyboard.press('Space');
        const addRequest = page.getByText('Add Request', { exact: true });
        await expect(addRequest).toBeEnabled();
        await addRequest.click();

        state.quote = await newestMatching(
          api,
          token,
          `/suppliers/${state.supplier.id}/quotes`,
          row => Number(row.project_id) === Number(state.project.id),
        );
        await page.getByRole('button', { name: 'Supplier Session Link', exact: true }).last().click();
        await expect.poll(async () => {
          const rows = await apiRows(api, token, `/suppliers/${state.supplier.id}/quotes`);
          state.quote = rows.find(row => Number(row.id) === Number(state.quote.id));
          return state.quote?.status;
        }).toBe('Link Sent');
        expect(state.quote.session_token).toBeTruthy();
      });

      await test.step('PORTAL-001 | Supplier signs in and submits the real quote form | ซัพพลายเออร์เข้าสู่ระบบและส่งแบบฟอร์มเสนอราคา', async () => {
        await page.goto(process.env.E2E_SUPPLIER_URL ?? 'http://localhost:3000');
        await page.locator('#username').fill(supplierEmail);
        await page.locator('#password').fill(state.quote.session_token);
        await page.getByRole('button', { name: 'Log In to Portal' }).click();
        await expect(page.locator('#dashboard-screen')).toBeVisible();

        const card = page.locator(`#card-${state.quote.id}`);
        await expect(card).toContainText(productName);
        await page.locator(`#price-${state.quote.id}`).fill('89.50');
        await page.locator(`#lead-${state.quote.id}`).fill('21 days');
        await page.locator(`#moq-${state.quote.id}`).fill('500');
        await page.locator(`#sample-price-${state.quote.id}`).fill('750');
        await page.locator(`#sample-lead-${state.quote.id}`).fill('7 days');
        await page.locator(`#remark-${state.quote.id}`).fill(`ใบเสนอราคาทดสอบ ${runKey}`);
        await card.getByRole('button', { name: 'Submit Quote' }).click();
        await expect(page.locator('#success-banner')).toBeVisible();

        await expect.poll(async () => {
          const quotes = await apiRows(api, token, `/suppliers/${state.supplier.id}/quotes`);
          return quotes.find(row => Number(row.id) === Number(state.quote.id))?.status;
        }).toBe('Price Filled');
      });

      await test.step('VERIFY-001 | Admin reviews the supplier response | แอดมินตรวจสอบราคาที่ซัพพลายเออร์ตอบกลับ', async () => {
        await page.goto('/');
        await loginAsAdmin(page);
        await goToAdminPage(page, 'Suppliers');
        await fillTextbox(page, /ค้นหาชื่อโรงงาน/, state.supplier.name);
        await page.getByRole('button', { name: new RegExp(state.supplier.name) }).click();
        await expect(page.getByText(productName, { exact: true })).toBeVisible();
        await expect(page.getByRole('button', { name: 'Review & Resubmit', exact: true })).toBeVisible();
      });

      await runFulfillmentFlow(
        page,
        api,
        token,
        state as unknown as FulfillmentState,
      );

      await test.step('AUTH-002 | Log out cleanly | ออกจากระบบอย่างถูกต้อง', async () => {
        const logout = page.getByText('Logout', { exact: true }).first();
        if (await logout.isVisible()) {
          await logout.click();
          await expect(page.getByText('Sign In', { exact: true })).toBeVisible();
        }
      });
    } finally {
      await api.dispose();
    }
  });
});
