import path from 'node:path';
import type {
  APIRequestContext,
  APIResponse,
  Locator,
  Page,
  TestInfo,
} from '@playwright/test';
import { authHeaders, createApiSession } from '../support/api';
import { env } from '../support/env';
import { uploadThroughFileChooser } from '../support/file-upload';
import { enableFlutterSemantics, goToAdminPage } from '../support/flutter';
import { annotateCase, attachJson } from './support/evidence';
import { expect, test } from './support/fixtures';
import { fillLogin, submitLogin } from './support/auth-ui';
import { showVideoCard, type VideoCardKind } from './support/pacing';

type FindingStatus =
  | 'PASS'
  | 'EXPECTED-REJECTION'
  | 'POLICY-OBSERVATION'
  | 'PRODUCT-MISMATCH'
  | 'BLOCKED'
  | 'COVERAGE-GAP'
  | 'AUTOMATION-ERROR';

type JourneyFinding = {
  id: string;
  workflow: string;
  title: string;
  status: FindingStatus;
  expected: string;
  actual: string;
  at: string;
};

type JourneyState = {
  supplier?: any;
  customer?: any;
  project?: any;
  product?: any;
  quote?: any;
  warehouse?: any;
  container?: any;
  deliveryRound?: any;
};

type StageMeta = {
  id: string;
  workflow: string;
  title: string;
  card: VideoCardKind;
  lines: string[];
  expected: string;
};

const uploadFixture = path.resolve(__dirname, '../../web/favicon.png');
const runKey = `LONG-${new Date().toISOString().replace(/\D/g, '').slice(0, 14)}`;
const customerName = `บริษัท โลจิสติกส์คลิปยาว ${runKey}`;
const contactName = `ผู้ประสานงานคลิปยาว ${runKey}`;
const productName = `ถุงผ้าพรีเมียม ${runKey}`;
const supplierEmail = process.env.E2E_SUPPLIER_USERNAME ?? 'supplier@ppngreat.local';
const saleUnitPrice = 149;
const orderedQty = 1_000;
const supplierBillAmount = 44_750;

function rowsFrom(body: any): any[] {
  const data = body?.data;
  if (Array.isArray(data)) return data;
  if (Array.isArray(data?.data)) return data.data;
  return [];
}

async function checkedBody(response: APIResponse): Promise<any> {
  const body = await response.json();
  expect(response.ok(), JSON.stringify(body)).toBeTruthy();
  expect(body.success, JSON.stringify(body)).toBe(true);
  return body;
}

async function apiRows(api: APIRequestContext, token: string, endpoint: string): Promise<any[]> {
  const body = await checkedBody(
    await api.get(`/api${endpoint}`, { headers: authHeaders(token) }),
  );
  return rowsFrom(body);
}

async function pollRows(
  api: APIRequestContext,
  token: string,
  endpoint: string,
  predicate: (rows: any[]) => boolean,
): Promise<any[]> {
  await expect.poll(async () => predicate(await apiRows(api, token, endpoint)), {
    timeout: 30_000,
  }).toBe(true);
  return apiRows(api, token, endpoint);
}

async function newestMatching(
  api: APIRequestContext,
  token: string,
  endpoint: string,
  predicate: (row: any) => boolean,
): Promise<any> {
  const rows = await pollRows(api, token, endpoint, items => items.some(predicate));
  return rows.find(predicate);
}

async function projectDetail(
  api: APIRequestContext,
  token: string,
  projectId: number,
): Promise<any> {
  const body = await checkedBody(
    await api.get(`/api/projects/${projectId}`, { headers: authHeaders(token) }),
  );
  return body.data;
}

async function replaceText(locator: Locator, value: string): Promise<void> {
  await expect(locator).toBeVisible();
  await locator.click();
  await locator.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await locator.pressSequentially(value, { delay: 8 });
}

async function fillTextbox(
  page: Page,
  name: string | RegExp,
  value: string,
  index = 0,
): Promise<void> {
  await replaceText(page.getByRole('textbox', { name }).nth(index), value);
}

/**
 * The first Flutter Web boot on a cold local machine can spend several minutes
 * loading/initialising the CanvasKit runtime.  The shared smoke helper keeps a
 * deliberately short timeout, while this documentary journey must wait for the
 * real UI so one transient cold start does not invalidate every later workflow.
 */
async function openLongJourneyLogin(page: Page): Promise<void> {
  await page.goto('/');
  await page.locator('flt-glass-pane').waitFor({
    state: 'attached',
    timeout: 6 * 60_000,
  });
  await enableFlutterSemantics(page);
  await expect(page.getByText('PPN GREAT', { exact: true }).first()).toBeVisible({ timeout: 30_000 });
  await expect(page.getByText('Sign In', { exact: true })).toBeVisible({ timeout: 30_000 });
}

async function loginLongJourneyThroughUi(page: Page) {
  await openLongJourneyLogin(page);
  await fillLogin(page);
  const response = await submitLogin(page);
  await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible({ timeout: 60_000 });
  return response;
}

/** Close a validation/error dialog before the recovery half of a paired case. */
async function dismissVisibleDialog(page: Page): Promise<void> {
  const names = [/^ตกลง$/, /^OK$/i, /^Close$/i, /^ปิด$/];
  for (const name of names) {
    const button = page.getByRole('button', { name }).last();
    if (await button.isVisible().catch(() => false)) {
      await button.click();
      await button.waitFor({ state: 'hidden', timeout: 10_000 }).catch(() => undefined);
      return;
    }
  }
}

async function chooseFlutterOption(
  page: Page,
  trigger: Locator,
  option: string | RegExp,
): Promise<void> {
  await expect(trigger).toBeVisible();
  await trigger.click();
  const item = page.getByRole('menuitem', { name: option }).last();
  await expect(item).toBeVisible();
  await item.click();
}

async function selectToday(page: Page, fieldLabel: string): Promise<void> {
  const trigger = page.getByRole('button', { name: `Select date: ${fieldLabel}` });
  await trigger.click();
  const ok = page.getByRole('button', { name: /^(OK|ตกลง)$/ }).last();
  await expect(ok).toBeVisible();
  await ok.click();
  await expect(trigger).toHaveAccessibleName(/\d{2}\/\d{2}\/\d{4}/, { timeout: 5_000 });
}

function errorText(error: unknown): string {
  return error instanceof Error ? error.stack || error.message : String(error);
}

async function safeCard(page: Page, kind: VideoCardKind, title: string, lines: string[]): Promise<void> {
  await showVideoCard(page, kind, title, lines).catch(() => undefined);
}

function addFinding(
  findings: JourneyFinding[],
  finding: Omit<JourneyFinding, 'at'>,
): void {
  findings.push({ ...finding, at: new Date().toISOString() });
}

async function runStage(
  page: Page,
  testInfo: TestInfo,
  findings: JourneyFinding[],
  meta: StageMeta,
  action: () => Promise<string | void>,
): Promise<void> {
  await test.step(`${meta.id} | ${meta.title}`, async () => {
    await safeCard(page, meta.card, `${meta.workflow} — ${meta.title}`, meta.lines);
    try {
      const actual = await action();
      addFinding(findings, {
        id: meta.id,
        workflow: meta.workflow,
        title: meta.title,
        status: 'PASS',
        expected: meta.expected,
        actual: actual || 'Stage completed through UI.',
      });
      await safeCard(page, 'success', `PASS — ${meta.title}`, [actual || meta.expected]);
    } catch (error) {
      const actual = errorText(error);
      const status: FindingStatus = actual.includes('BLOCKED:') ? 'BLOCKED' : 'AUTOMATION-ERROR';
      addFinding(findings, {
        id: meta.id,
        workflow: meta.workflow,
        title: meta.title,
        status,
        expected: meta.expected,
        actual,
      });
      await page.screenshot({
        path: testInfo.outputPath(`${meta.id.toLowerCase()}-stage-error.png`),
        fullPage: true,
      }).catch(() => undefined);
      await safeCard(page, 'error', `${status} — ${meta.title}`, [
        actual.split('\n')[0].slice(0, 190),
        'Journey continues to the next independent stage.',
      ]);
    }
  });
}

async function recordExpected(
  page: Page,
  findings: JourneyFinding[],
  input: {
    id: string;
    workflow: string;
    title: string;
    passed: boolean;
    expected: string;
    actual: string;
    mismatchStatus?: FindingStatus;
  },
): Promise<void> {
  const status: FindingStatus = input.passed
    ? 'EXPECTED-REJECTION'
    : input.mismatchStatus ?? 'PRODUCT-MISMATCH';
  addFinding(findings, { ...input, status });
  await safeCard(
    page,
    input.passed ? 'important' : 'error',
    `${status} — ${input.title}`,
    [input.expected, `Actual: ${input.actual}`],
  );
}

function required<T>(value: T | undefined, label: string): T {
  if (value === undefined || value === null) throw new Error(`BLOCKED: Missing ${label}`);
  return value;
}

async function createFinanceDocument(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: JourneyState,
  docType: 'QU' | 'PI' | 'CI',
): Promise<any> {
  const project = required(state.project, 'project');
  await goToAdminPage(page, 'Finance');
  const labels = {
    QU: 'Quotation',
    PI: 'Proforma Invoice',
    CI: 'Commercial Invoice',
  } as const;
  await page.getByRole('button', { name: labels[docType], exact: true }).click();
  await replaceText(
    page.getByRole('textbox', { name: 'Document item unit price 1', exact: true }),
    saleUnitPrice.toString(),
  );
  await page.getByRole('button', { name: 'Save & Issue Document', exact: true }).click();
  const docs = await pollRows(api, token, `/finance/documents?project_id=${project.id}`, rows =>
    rows.some(row => row.doc_type === docType && row.status === 'Sent'),
  );
  return docs.find(row => row.doc_type === docType && row.status !== 'Cancelled');
}

async function openRecordPayment(page: Page): Promise<void> {
  await goToAdminPage(page, 'Dashboard');
  await page.getByRole('button', { name: 'Record Payment', exact: true }).click();
  await expect(page.getByText('Payment History (ประวัติการรับชำระเงิน)', { exact: true })).toBeVisible();
}

async function recordPayment(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: JourneyState,
  amount: number,
): Promise<any> {
  const project = required(state.project, 'project');
  const before = await apiRows(api, token, `/finance/payments?project_id=${project.id}`);
  await openRecordPayment(page);
  await replaceText(page.getByRole('textbox', { name: /ยอดเงินที่ได้รับ/ }), amount.toFixed(2));
  await page.getByRole('button', { name: 'Confirm & Record Payment', exact: true }).click();
  let payments = await pollRows(api, token, `/finance/payments?project_id=${project.id}`, rows =>
    rows.length === before.length + 1,
  );
  let payment = payments.find(row => !before.some(item => Number(item.id) === Number(row.id)));
  await openRecordPayment(page);
  await uploadThroughFileChooser(
    page,
    page.getByRole('button', { name: 'อัปโหลด', exact: true }).first(),
    uploadFixture,
  );
  payments = await pollRows(api, token, `/finance/payments?project_id=${project.id}`, rows =>
    rows.some(row => Number(row.id) === Number(payment.id) && Boolean(row.slip_file_path)),
  );
  payment = payments.find(row => Number(row.id) === Number(payment.id));
  await openRecordPayment(page);
  await page.getByRole('button', { name: 'ยืนยันยอด', exact: true }).first().click();
  payments = await pollRows(api, token, `/finance/payments?project_id=${project.id}`, rows =>
    rows.some(row => Number(row.id) === Number(payment.id) && row.status === 'Confirmed'),
  );
  return payments.find(row => Number(row.id) === Number(payment.id));
}

async function openSupplier(page: Page, state: JourneyState): Promise<void> {
  const supplier = required(state.supplier, 'supplier');
  await goToAdminPage(page, 'Suppliers');
  await replaceText(page.getByRole('textbox', { name: /ค้นหาชื่อโรงงาน/ }), supplier.name);
  await page.getByRole('button', { name: new RegExp(supplier.name) }).click();
}

async function createAndPaySupplierBill(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: JourneyState,
  billType: 'Deposit' | 'Balance',
): Promise<any> {
  const supplier = required(state.supplier, 'supplier');
  const project = required(state.project, 'project');
  await openSupplier(page, state);
  await page.getByRole('button', { name: 'รอบบิลจ่ายเงิน (AP)', exact: true }).click();
  await page.getByRole('button', { name: '+ Add Bill', exact: true }).click();
  await chooseFlutterOption(
    page,
    page.getByRole('button', { name: /เลือกโปรเจกต์|Project/ }).last(),
    new RegExp(project.project_code),
  );
  if (billType === 'Balance') {
    await chooseFlutterOption(
      page,
      page.getByRole('button', { name: 'Deposit', exact: true }).last(),
      'Balance',
    );
  }
  await replaceText(
    page.getByRole('textbox', { name: '0.00', exact: true }).last(),
    supplierBillAmount.toString(),
  );
  await page.getByRole('button', { name: 'Create Bill', exact: true }).click();
  let bills = await pollRows(api, token, `/suppliers/${supplier.id}/bills`, rows =>
    rows.some(row => Number(row.project_id) === Number(project.id) && row.bill_type === billType),
  );
  let bill = bills.find(row => Number(row.project_id) === Number(project.id) && row.bill_type === billType);
  await openSupplier(page, state);
  await page.getByRole('button', { name: 'รอบบิลจ่ายเงิน (AP)', exact: true }).click();
  await uploadThroughFileChooser(page, page.getByText('PI', { exact: true }).last(), uploadFixture);
  await uploadThroughFileChooser(page, page.getByText('Invoice', { exact: true }).last(), uploadFixture);
  bills = await pollRows(api, token, `/suppliers/${supplier.id}/bills`, rows => {
    const row = rows.find(item => Number(item.id) === Number(bill.id));
    return Boolean(row?.pi_file_path && row?.invoice_file_path);
  });
  bill = bills.find(row => Number(row.id) === Number(bill.id));
  await page.getByRole('checkbox', { name: `Select supplier bill ${bill.id}` }).click();
  await page.getByRole('button', { name: 'Pay Selected Bills', exact: true }).click();
  bills = await pollRows(api, token, `/suppliers/${supplier.id}/bills`, rows =>
    rows.some(row => Number(row.id) === Number(bill.id) && row.status === 'Paid'),
  );
  return bills.find(row => Number(row.id) === Number(bill.id));
}

test.describe('PACK-LONG | One continuous system journey | คลิปยาวทดสอบ Workflow 1–13 ต่อเนื่อง', () => {
  test('LONG-001 | Full realistic, policy and error journey in one video | วงจรจริงพร้อมเคสผิดปกติในวิดีโอเดียว', async ({ page }, testInfo) => {
    test.setTimeout(2 * 60 * 60_000);
    annotateCase(testInfo, {
      caseId: 'LONG-001',
      pairId: 'LONG-001',
      classification: 'POLICY-OBSERVATION',
      method: 'One browser context and one Playwright test; every business mutation is performed through UI',
      expected: 'Workflow 1–13 completes and expected errors reject without stopping the journey',
      preconditions: ['Fresh ppn_e2e baseline', 'One Admin identity', 'One Supplier identity'],
    });

    const findings: JourneyFinding[] = [];
    const state: JourneyState = {};
    const { api, token } = await createApiSession();

    try {
      await runStage(page, testInfo, findings, {
        id: 'PRE-001', workflow: 'Baseline', card: 'final',
        title: 'Clean database baseline | ตรวจฐานข้อมูลเริ่มต้น',
        lines: ['เหลือ Admin 1 identity และ Supplier 1 identity', 'ข้อมูลธุรกิจทุกโมดูลต้องเป็นศูนย์'],
        expected: 'customers/projects/documents/payments/warehouses/containers/deliveries = 0; suppliers = 1',
      }, async () => {
        const [customers, projects, suppliers, docs, payments, warehouses, containers, rounds] = await Promise.all([
          apiRows(api, token, '/customers'),
          apiRows(api, token, '/projects'),
          apiRows(api, token, '/suppliers'),
          apiRows(api, token, '/finance/documents'),
          apiRows(api, token, '/finance/payments'),
          apiRows(api, token, '/inventory/warehouses'),
          apiRows(api, token, '/containers'),
          apiRows(api, token, '/delivery/rounds'),
        ]);
        expect(customers).toHaveLength(0);
        expect(projects).toHaveLength(0);
        expect(suppliers).toHaveLength(1);
        expect(docs).toHaveLength(0);
        expect(payments).toHaveLength(0);
        expect(warehouses).toHaveLength(0);
        expect(containers).toHaveLength(0);
        expect(rounds).toHaveLength(0);
        state.supplier = suppliers[0];
        return 'Baseline confirmed: business data is zero; Admin + Supplier identities remain.';
      });

      await runStage(page, testInfo, findings, {
        id: 'WF01-AUTH', workflow: 'Workflow 1 — Authentication', card: 'normal',
        title: 'Empty → wrong password → corrected login | ว่าง → รหัสผิด → แก้แล้วสำเร็จ',
        lines: ['ทดสอบ validation ก่อน', 'ทดสอบ 401', 'แก้ credentials แล้วเข้า Dashboard'],
        expected: 'Empty form rejected, wrong password = 401, correct login opens Dashboard',
      }, async () => {
        await openLongJourneyLogin(page);
        let emptyRequests = 0;
        page.on('request', request => {
          if (request.url().endsWith('/api/auth/login')) emptyRequests += 1;
        });
        await page.getByText('Sign In', { exact: true }).click();
        await expect(page.getByText(/Email.*Password/i)).toBeVisible();
        await recordExpected(page, findings, {
          id: 'WF01-ERR-EMPTY', workflow: 'Workflow 1 — Authentication',
          title: 'Empty login rejected | ฟอร์มว่างถูกปฏิเสธ', passed: emptyRequests === 0,
          expected: 'No login API request', actual: `loginRequests=${emptyRequests}`,
        });

        await fillLogin(page, env.adminEmail, 'wrong-password-long-video');
        const rejected = await submitLogin(page);
        await recordExpected(page, findings, {
          id: 'WF01-ERR-PASSWORD', workflow: 'Workflow 1 — Authentication',
          title: 'Wrong password rejected | รหัสผ่านผิดถูกปฏิเสธ', passed: rejected.status() === 401,
          expected: 'HTTP 401 and remain unauthenticated', actual: `HTTP ${rejected.status()}`,
        });

        await page.goto('/');
        const accepted = await loginLongJourneyThroughUi(page);
        expect(accepted.status()).toBe(200);
        return 'Recovered through the UI: HTTP 200 and Dashboard visible.';
      });

      await runStage(page, testInfo, findings, {
        id: 'WF02-CUSTOMER', workflow: 'Workflow 2 — Customers', card: 'normal',
        title: 'Validation then create customer | ตรวจข้อมูลผิดแล้วสร้างลูกค้า',
        lines: ['ลองบันทึกโดยไม่มีชื่อบริษัท', 'กรอกผู้ติดต่อ ที่อยู่ออกบิล และที่อยู่จัดส่ง', 'บันทึกผ่าน UI'],
        expected: 'Missing company name rejected; valid customer created with contact',
      }, async () => {
        await goToAdminPage(page, 'Customers');
        await page.getByRole('button', { name: 'Create Customer', exact: true }).click();
        await page.getByRole('button', { name: 'Save Customer', exact: true }).click();
        await page.getByText('Confirm & Save', { exact: true }).click();
        const missingName = await page.getByText(/กรุณากรอกชื่อบริษัท/).isVisible().catch(() => false);
        await recordExpected(page, findings, {
          id: 'WF02-ERR-NAME', workflow: 'Workflow 2 — Customers',
          title: 'Missing company name rejected | ไม่กรอกชื่อบริษัทต้องไม่บันทึก', passed: missingName,
          expected: 'Thai company-name validation visible', actual: `validationVisible=${missingName}`,
        });

        await dismissVisibleDialog(page);

        // Defensive recovery for UI variants that return to the list after an error.
        const createCustomer = page.getByRole('button', { name: 'Create Customer', exact: true });
        if (await createCustomer.isVisible().catch(() => false)) {
          await createCustomer.click();
          await expect(page.getByText('Company Profile', { exact: true })).toBeVisible();
        }

        await fillTextbox(page, /บริษัท พีพีเอ็น จำกัด/, customerName);
        await fillTextbox(page, 'X-XXXX-XXXXX-XX-X', `01055${Date.now().toString().slice(-8)}`);
        await page.getByText('Direct Contact', { exact: true }).click();
        await fillTextbox(page, /ชื่อผู้ติดต่อ/, contactName);
        await fillTextbox(page, '08X-XXX-XXXX', '0812345678');
        await fillTextbox(page, 'email@company.com', `long-${runKey.toLowerCase()}@example.test`);
        await fillTextbox(page, /กรอกที่อยู่สำหรับออกใบกำกับภาษี/, '99 ถนนโลจิสติกส์ แขวงทดสอบ เขตทดสอบ กรุงเทพฯ 10110');
        await page.getByRole('switch').last().click();
        await page.getByRole('button', { name: 'Save Customer', exact: true }).click();
        await page.getByText('Confirm & Save', { exact: true }).click();
        await expect(page.getByText(new RegExp(customerName)).first()).toBeVisible({ timeout: 25_000 });
        state.customer = await newestMatching(api, token, '/customers', row => row.name === customerName);
        expect(state.customer.contacts?.[0]?.name).toBe(contactName);
        return `Customer ${state.customer.id} created with contact and billing/shipping address.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF03-PROJECT', workflow: 'Workflow 3 — Projects', card: 'normal',
        title: 'Validation then create project/product | ตรวจข้อมูลผิดแล้วสร้างโครงการและสินค้า',
        lines: ['ลองสร้างโดยไม่เลือกลูกค้า', 'เลือกลูกค้าจาก Workflow 2', `สร้างสินค้า ${orderedQty} ชิ้น`],
        expected: 'Missing customer/contact rejected; connected project and product created',
      }, async () => {
        await goToAdminPage(page, 'Dashboard');
        await page.getByText('Create New Project', { exact: true }).click();
        await page.getByRole('button', { name: 'Create Project', exact: true }).click();
        const missingCustomer = await page.getByText(/กรุณาเลือกลูกค้าและผู้ติดต่อ/).isVisible().catch(() => false);
        await recordExpected(page, findings, {
          id: 'WF03-ERR-CUSTOMER', workflow: 'Workflow 3 — Projects',
          title: 'Missing customer rejected | ไม่เลือกลูกค้าต้องไม่สร้างโครงการ', passed: missingCustomer,
          expected: 'Customer/contact validation visible', actual: `validationVisible=${missingCustomer}`,
        });
        await dismissVisibleDialog(page);

        await fillTextbox(page, 'ค้นหาลูกค้า...', customerName);
        await page.getByRole('button', { name: new RegExp(customerName) }).click();
        await page.getByText(/เลือกผู้รับผิดชอบ/).click();
        await page.keyboard.press('ArrowDown');
        await page.keyboard.press('Enter');
        await fillTextbox(page, 'งบประมาณรวม (ถ้ามี)', '149000');
        await fillTextbox(page, 'Search or type custom product...', productName);
        await fillTextbox(page, 'e.g. 1000', orderedQty.toString());
        await fillTextbox(page, /ระบุวัสดุ สี ขนาด จุดสกรีน/, 'ผ้าแคนวาสสีธรรมชาติ ขนาด 35x40 ซม. สกรีนโลโก้ Pantone 347C');
        await page.getByRole('button', { name: 'Create Project', exact: true }).click();
        await page.getByText('Confirm & Create', { exact: true }).click();
        await expect(page.getByText('Project Created Successfully!', { exact: true })).toBeVisible({ timeout: 25_000 });
        await page.getByRole('button', { name: 'View / Edit Project', exact: true }).click();
        const created = await newestMatching(api, token, '/projects', row => Number(row.customer_id) === Number(state.customer.id));
        state.project = await projectDetail(api, token, Number(created.id));
        state.product = state.project.products?.find((row: any) => row.name === productName)
          ?? state.project.product_items?.find((row: any) => row.name === productName);
        expect(state.product).toBeTruthy();
        return `${state.project.project_code} created with product ${state.product.id} and qty ${state.product.qty}.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF04-NEG-SEQUENCE', workflow: 'Workflow 4 — Samples (negative probe)', card: 'error',
        title: 'Sample before Artwork Approved | ขอตัวอย่างก่อนอาร์ตเวิร์กอนุมัติ',
        lines: ['Business policy: ต้องบล็อก', 'ตรวจ sample count ก่อนและหลัง', 'หากสร้างได้ให้บันทึก Product Mismatch'],
        expected: 'Sample count must not increase before Artwork Approved',
      }, async () => {
        const project = required(state.project, 'project');
        const before = await apiRows(api, token, `/samples/project/${project.id}`);
        await goToAdminPage(page, 'Samples');
        await fillTextbox(page, /ค้นหารหัส, ชื่อลูกค้า/, project.project_code);
        await page.getByText(project.project_code, { exact: false }).first().click();
        await page.getByText('Add Local Sample', { exact: true }).click();
        await fillTextbox(page, 'Courier (e.g. Grab)', 'Premature Courier');
        await fillTextbox(page, 'Tracking No.', `PRE-ART-${runKey}`);
        await page.getByText('Save Record', { exact: true }).click();
        await page.waitForTimeout(2_000);
        const after = await apiRows(api, token, `/samples/project/${project.id}`);
        const blocked = after.length === before.length;
        await recordExpected(page, findings, {
          id: 'WF04-ERR-SEQUENCE', workflow: 'Workflow 4 — Samples',
          title: 'Artwork gate enforced | บังคับ Artwork Approved ก่อน Sample', passed: blocked,
          expected: `sampleCount remains ${before.length}`,
          actual: `before=${before.length}, after=${after.length}`,
        });
        if (!blocked) {
          const statusButton = page.getByRole('button', { name: 'Received from China', exact: true }).last();
          if (await statusButton.isVisible().catch(() => false)) {
            await statusButton.click();
            await page.getByRole('menuitem', { name: 'Rejected (Need Revision)', exact: true }).click();
          }
        } else {
          await dismissVisibleDialog(page);
          await page.keyboard.press('Escape').catch(() => undefined);
        }
        return blocked
          ? 'Expected rejection confirmed: no sample created.'
          : 'Product mismatch recorded: the UI/API created a sample before Artwork approval.';
      });

      await runStage(page, testInfo, findings, {
        id: 'WF05-ARTWORK', workflow: 'Workflow 5 — Artwork', card: 'normal',
        title: 'Missing file → V1 revision → V2 approved | ไม่มีไฟล์ → แก้ V1 → อนุมัติ V2',
        lines: ['ใช้ Playwright filechooser interception', 'บันทึก feedback จากลูกค้า', 'Approved by Client ก่อนกลับไป Sample'],
        expected: 'Missing file rejected; V1 revised; V2 Approved by Client',
      }, async () => {
        const project = required(state.project, 'project');
        await goToAdminPage(page, 'Artwork');
        await fillTextbox(page, /ค้นหารหัส, ชื่อลูกค้า/, project.project_code);
        await page.getByText(project.project_code, { exact: false }).first().click();
        await page.getByText('Add Artwork Log', { exact: true }).click();
        await page.getByText('Save Log', { exact: true }).click();
        const missingFile = await page.getByText(/กรุณาเลือกไฟล์ Artwork/).isVisible().catch(() => false);
        await recordExpected(page, findings, {
          id: 'WF05-ERR-FILE', workflow: 'Workflow 5 — Artwork',
          title: 'Missing Artwork file rejected | ไม่มีไฟล์ต้องไม่บันทึก', passed: missingFile,
          expected: 'Artwork file validation visible', actual: `validationVisible=${missingFile}`,
        });
        await dismissVisibleDialog(page);
        await uploadThroughFileChooser(page, page.getByText('Choose File', { exact: true }), uploadFixture);
        await page.getByText('Save Log', { exact: true }).click();
        await expect(page.getByText('V1', { exact: true })).toBeVisible({ timeout: 25_000 });
        await page.getByRole('button', { name: 'Awaiting Approval', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Reviewing', exact: true }).click();
        await page.getByRole('button', { name: 'Reviewing', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Need Revision', exact: true }).click();
        await page.getByText('Edit Note', { exact: true }).last().click();
        await replaceText(
          page.getByRole('textbox').last(),
          'โลโก้เล็กไป ขอขยาย 20% และปรับสี Pantone 347C',
        );
        await page.getByText('Save Updates', { exact: true }).click();

        await page.getByText('Add Artwork Log', { exact: true }).click();
        await uploadThroughFileChooser(page, page.getByText('Choose File', { exact: true }), uploadFixture);
        await page.getByText('Save Log', { exact: true }).click();
        await expect(page.getByText('V2', { exact: true })).toBeVisible({ timeout: 25_000 });
        await page.getByRole('button', { name: 'Awaiting Approval', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Reviewing', exact: true }).click();
        await page.getByRole('button', { name: 'Reviewing', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Approved by Client', exact: true }).click();
        const artworks = await pollRows(api, token, `/artworks/project/${project.id}`, rows =>
          rows.length >= 2 && rows.some(row => String(row.status).includes('Approved')),
        );
        return `Artwork history=${artworks.length}; V2 is Approved by Client.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF04-SAMPLE-SUCCESS', workflow: 'Workflow 4 — Samples (valid after Artwork)', card: 'normal',
        title: 'Rejected attempt → corrected attempt approved | ตัวอย่างไม่ผ่าน → แก้แล้วอนุมัติ',
        lines: ['สร้าง Sample หลัง Artwork Approved', 'บันทึก feedback Pantone', 'สร้าง attempt ถัดไปและอนุมัติ'],
        expected: 'Sample rejection history retained and a later attempt becomes Approved',
      }, async () => {
        const project = required(state.project, 'project');
        await goToAdminPage(page, 'Samples');
        await fillTextbox(page, /ค้นหารหัส, ชื่อลูกค้า/, project.project_code);
        await page.getByText(project.project_code, { exact: false }).first().click();
        await page.getByText('Add Local Sample', { exact: true }).click();
        await fillTextbox(page, 'Courier (e.g. Grab)', 'Kerry Express');
        await fillTextbox(page, 'Tracking No.', `SAMPLE-R1-${runKey}`);
        await page.getByText('Save Record', { exact: true }).click();
        await expect(page.getByRole('button', { name: 'Received from China', exact: true }).last()).toBeVisible({ timeout: 25_000 });
        await page.getByRole('button', { name: 'Received from China', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Sent to Client', exact: true }).click();
        await page.getByRole('button', { name: 'Sent to Client', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Rejected (Need Revision)', exact: true }).click();
        await page.getByText('Update', { exact: true }).last().click();
        await replaceText(
          page.getByRole('textbox').last(),
          'สีสกรีนไม่ตรง Pantone 347C และซิปไม่ลื่น',
        );
        await page.getByText('Save Feedback', { exact: true }).click();

        await page.getByText('Add Local Sample', { exact: true }).click();
        await fillTextbox(page, 'Courier (e.g. Grab)', 'Kerry Express');
        await fillTextbox(page, 'Tracking No.', `SAMPLE-R2-${runKey}`);
        await page.getByText('Save Record', { exact: true }).click();
        await page.getByRole('button', { name: 'Received from China', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Sent to Client', exact: true }).click();
        await page.getByRole('button', { name: 'Sent to Client', exact: true }).last().click();
        await page.getByRole('menuitem', { name: 'Approved by Client', exact: true }).click();
        const samples = await pollRows(api, token, `/samples/project/${project.id}`, rows =>
          rows.some(row => row.status === 'Approved') && rows.some(row => row.status === 'Rejected'),
        );
        return `Sample history=${samples.length}; includes Rejected feedback and Approved recovery.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF06-DASHBOARD', workflow: 'Workflow 6 — Dashboard', card: 'important',
        title: 'Operational snapshot | ดูภาพรวมหลังสร้างข้อมูลต้นน้ำ',
        lines: ['ตรวจ Dashboard render', 'ดู KPI และ activity หลัง Customer/Project/Artwork/Sample'],
        expected: 'Dashboard renders after upstream mutations without Flutter crash',
      }, async () => {
        await goToAdminPage(page, 'Dashboard');
        await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible();
        return 'Dashboard rendered with the newly created business activity.';
      });

      await runStage(page, testInfo, findings, {
        id: 'WF07-SUPPLIER', workflow: 'Workflow 7 — Suppliers', card: 'normal',
        title: 'Supplier sample + quote request | ขอตัวอย่างโรงงานและขอราคา',
        lines: ['ใช้ Supplier baseline เพียงรายเดียว', 'เปิด Samples และ Quotes tabs', 'สร้าง session link จริง'],
        expected: 'Supplier sample and quote requests created through UI; session token generated',
      }, async () => {
        const supplier = required(state.supplier, 'supplier');
        const project = required(state.project, 'project');
        await openSupplier(page, state);
        await page.getByRole('button', { name: 'ขอตัวอย่าง (Samples)', exact: true }).click();
        await page.getByRole('button', { name: '+ Request Sample', exact: true }).click();
        await page.getByText('Select Project', { exact: true }).click();
        await page.keyboard.press('ArrowDown');
        await page.keyboard.press('Enter');
        await page.keyboard.press('Tab');
        await page.keyboard.press('Space');
        await fillTextbox(page, /ขอตัวอย่างแคนวาส/, 'ขอตัวอย่างผ้าและงานสกรีนหลัง Artwork Approved');
        await fillTextbox(page, /ค่าใช้จ่ายตัวอย่าง/, '750 บาท');
        await page.getByText('Add Request', { exact: true }).click();
        await pollRows(api, token, `/suppliers/${supplier.id}/samples`, rows =>
          rows.some(row => Number(row.project_id) === Number(project.id)),
        );

        await page.getByRole('button', { name: 'ขอราคา (Quotes)', exact: true }).click();
        await page.getByRole('button', { name: '+ Request Quote', exact: true }).click();
        await page.getByText('Select Project', { exact: true }).click();
        await page.keyboard.press('ArrowDown');
        await page.keyboard.press('Enter');
        await page.keyboard.press('Tab');
        await page.keyboard.press('Space');
        await page.getByText('Add Request', { exact: true }).click();
        state.quote = await newestMatching(api, token, `/suppliers/${supplier.id}/quotes`, row =>
          Number(row.project_id) === Number(project.id),
        );
        await page.getByRole('button', { name: 'Supplier Session Link', exact: true }).last().click();
        const quotes = await pollRows(api, token, `/suppliers/${supplier.id}/quotes`, rows =>
          rows.some(row => Number(row.id) === Number(state.quote.id) && row.status === 'Link Sent'),
        );
        state.quote = quotes.find(row => Number(row.id) === Number(state.quote.id));
        expect(state.quote.session_token).toBeTruthy();
        return `Supplier sample requested; Quote ${state.quote.id} has a real session token.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF07-PORTAL', workflow: 'Workflow 7 — Supplier Portal', card: 'normal',
        title: 'Missing price error → valid supplier quote | ไม่กรอกราคา → แก้แล้วส่งราคา',
        lines: ['Supplier login ด้วย token จาก Admin UI', 'Submit ว่างต้องแสดง error', 'กรอกข้อมูลจริงแล้ว submit'],
        expected: 'Missing price/lead time rejected; complete quote becomes Price Filled',
      }, async () => {
        const supplier = required(state.supplier, 'supplier');
        const quote = required(state.quote, 'supplier quote');
        await page.goto(process.env.E2E_SUPPLIER_URL ?? 'http://localhost:3001');
        await page.locator('#username').fill(supplierEmail);
        await page.locator('#password').fill(quote.session_token);
        await page.getByRole('button', { name: 'Log In to Portal' }).click();
        await expect(page.locator('#dashboard-screen')).toBeVisible();
        const card = page.locator(`#card-${quote.id}`);
        await card.getByRole('button', { name: 'Submit Quote' }).click();
        const priceError = await page.locator(`#err-price-${quote.id}`).isVisible();
        const leadError = await page.locator(`#err-lead-${quote.id}`).isVisible();
        await recordExpected(page, findings, {
          id: 'WF07-ERR-QUOTE', workflow: 'Workflow 7 — Supplier Portal',
          title: 'Required quote fields rejected | ช่องราคาที่จำเป็นต้องไม่ว่าง', passed: priceError && leadError,
          expected: 'Price and lead-time errors visible', actual: `priceError=${priceError}, leadError=${leadError}`,
        });
        await page.locator(`#price-${quote.id}`).fill('89.50');
        await page.locator(`#lead-${quote.id}`).fill('21 days');
        await page.locator(`#moq-${quote.id}`).fill('500');
        await page.locator(`#sample-price-${quote.id}`).fill('750');
        await page.locator(`#sample-lead-${quote.id}`).fill('7 days');
        await page.locator(`#remark-${quote.id}`).fill(`Long journey quote ${runKey}`);
        await card.getByRole('button', { name: 'Submit Quote' }).click();
        await expect(page.locator('#success-banner')).toBeVisible();
        const quotes = await pollRows(api, token, `/suppliers/${supplier.id}/quotes`, rows =>
          rows.some(row => Number(row.id) === Number(quote.id) && row.status === 'Price Filled'),
        );
        state.quote = quotes.find(row => Number(row.id) === Number(quote.id));
        return `Supplier quote ${quote.id} submitted with unit price 89.50 and lead time 21 days.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF07-APPROVE-AP', workflow: 'Workflow 7 — Supplier approval/AP', card: 'important',
        title: 'Approve quote and pay supplier deposit | อนุมัติราคาและจ่ายมัดจำโรงงาน',
        lines: ['Admin กลับจาก Portal', 'Approve & Accept', 'สร้างบิล Deposit อัปโหลด PI/Invoice และจ่าย'],
        expected: 'Quote Approved and supplier Deposit bill Paid',
      }, async () => {
        const supplier = required(state.supplier, 'supplier');
        const quote = required(state.quote, 'quote');
        // The Admin origin still has its persisted token after visiting the
        // Supplier Portal. openSupplier handles either Dashboard or login UI.
        await openSupplier(page, state);
        await page.getByRole('button', { name: 'Review & Resubmit', exact: true }).click();
        await page.getByRole('button', { name: 'Approve & Accept', exact: true }).click();
        await pollRows(api, token, `/suppliers/${supplier.id}/quotes`, rows =>
          rows.some(row => Number(row.id) === Number(quote.id) && row.status === 'Approved'),
        );
        const bill = await createAndPaySupplierBill(page, api, token, state, 'Deposit');
        return `Quote Approved; supplier Deposit bill ${bill.id} is Paid.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF08-PI-QU', workflow: 'Workflow 8 — Finance Documents', card: 'important',
        title: 'PI without QU, then QU | ออก PI ก่อน QU แล้วออก QU ภายหลัง',
        lines: ['Policy Observation: PI ไม่มี QU ต้องอนุญาต', 'ราคา 149 × 1,000 = 149,000 บาท'],
        expected: 'PI is Sent while no QU exists yet; QU can be issued afterward',
      }, async () => {
        const project = required(state.project, 'project');
        const before = await apiRows(api, token, `/finance/documents?project_id=${project.id}`);
        expect(before.some(row => row.doc_type === 'QU')).toBe(false);
        const pi = await createFinanceDocument(page, api, token, state, 'PI');
        addFinding(findings, {
          id: 'WF08-POLICY-PI-NO-QU', workflow: 'Workflow 8 — Finance Documents',
          title: 'PI without QU allowed | PI โดยไม่มี QU', status: 'POLICY-OBSERVATION',
          expected: 'PI can be issued before QU', actual: `PI ${pi.doc_no} status=${pi.status}`,
        });
        const qu = await createFinanceDocument(page, api, token, state, 'QU');
        return `PI ${pi.doc_no} issued first; QU ${qu.doc_no} issued afterward.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF09-PAYMENTS-PRE', workflow: 'Workflow 9 — Customer Payments', card: 'normal',
        title: 'Negative amount → two partial payments | ยอดติดลบ → แบ่งจ่ายสองงวดแรก',
        lines: ['จำนวน -1 ต้องถูกปฏิเสธ', 'งวด 1 = 30,000', 'งวด 2 = 20,000', 'คงค้างก่อนส่ง = 99,000'],
        expected: 'Negative amount rejected; two confirmed partial payments total 50,000',
      }, async () => {
        const project = required(state.project, 'project');
        const before = await apiRows(api, token, `/finance/payments?project_id=${project.id}`);
        await openRecordPayment(page);
        await replaceText(page.getByRole('textbox', { name: /ยอดเงินที่ได้รับ/ }), '-1');
        await page.getByRole('button', { name: 'Confirm & Record Payment', exact: true }).click();
        const negativeValidation = await page.getByText(/กรุณาระบุยอดเงินที่ได้รับให้ถูกต้อง/).isVisible().catch(() => false);
        const afterNegative = await apiRows(api, token, `/finance/payments?project_id=${project.id}`);
        await recordExpected(page, findings, {
          id: 'WF09-ERR-NEGATIVE', workflow: 'Workflow 9 — Customer Payments',
          title: 'Negative payment rejected | ยอดชำระติดลบถูกปฏิเสธ',
          passed: negativeValidation && afterNegative.length === before.length,
          expected: 'Validation visible and payment count unchanged',
          actual: `validation=${negativeValidation}, before=${before.length}, after=${afterNegative.length}`,
        });
        await dismissVisibleDialog(page);
        await recordPayment(page, api, token, state, 30_000);
        await recordPayment(page, api, token, state, 20_000);
        const payments = await apiRows(api, token, `/finance/payments?project_id=${project.id}`);
        const confirmed = payments.filter(row => row.status === 'Confirmed');
        const paid = confirmed.reduce((sum, row) => sum + Number(row.amount), 0);
        expect(confirmed).toHaveLength(2);
        expect(paid).toBe(50_000);
        return `Two confirmed installments total ${paid}; outstanding=${orderedQty * saleUnitPrice - paid}.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF10-CONTAINER', workflow: 'Workflow 10 — Containers', card: 'normal',
        title: 'Invalid container → full transport lifecycle | ตู้ไม่ครบข้อมูล → เดินสถานะขนส่งครบ',
        lines: ['ไม่กรอกเลขตู้ต้องถูกปฏิเสธ', 'เชื่อม Project', 'ทดสอบวันที่ก่อนเลื่อนสถานะ', 'Delivered ถึงไทย'],
        expected: 'Invalid create rejected; valid container reaches Delivered through UI',
      }, async () => {
        const project = required(state.project, 'project');
        await goToAdminPage(page, 'Containers');
        await page.getByRole('button', { name: /Create Container/ }).click();
        await page.getByRole('button', { name: 'บันทึก', exact: true }).click();
        const noNumber = await page.getByText(/กรุณากรอกเลขตู้สินค้า/).isVisible().catch(() => false);
        await recordExpected(page, findings, {
          id: 'WF10-ERR-NUMBER', workflow: 'Workflow 10 — Containers',
          title: 'Missing container number rejected | ไม่กรอกเลขตู้ถูกปฏิเสธ', passed: noNumber,
          expected: 'Container number validation visible', actual: `validationVisible=${noNumber}`,
        });
        await dismissVisibleDialog(page);
        await replaceText(page.getByRole('textbox', { name: /Container No/ }), `LONG-${project.project_code}`);
        await replaceText(page.getByRole('textbox', { name: /Vessel Name/ }), 'EVERGREEN LONG JOURNEY');
        await page.getByRole('checkbox', { name: new RegExp(project.project_code) }).click();
        await page.getByRole('button', { name: 'บันทึก', exact: true }).click();
        let containers = await pollRows(api, token, '/containers', rows => rows.length === 1);
        let container = containers[0];
        state.container = container;
        await goToAdminPage(page, 'Containers');
        await page.getByRole('button', { name: new RegExp(`^${container.container_code}\\b`) }).click();
        await page.getByRole('button', { name: /Set Sailing/ }).click();
        await page.waitForTimeout(1_000);
        containers = await apiRows(api, token, '/containers');
        container = containers.find(row => Number(row.id) === Number(container.id));
        const dateGateHeld = container.status === 'Factory to Port';
        await recordExpected(page, findings, {
          id: 'WF10-ERR-DATE', workflow: 'Workflow 10 — Containers',
          title: 'Missing departure date blocks status | ไม่มีวันที่ต้องไม่ข้ามสถานะ', passed: dateGateHeld,
          expected: 'Status remains Factory to Port', actual: `status=${container.status}`,
        });
        await dismissVisibleDialog(page);
        if (container.status === 'Factory to Port') {
          await selectToday(page, 'วันที่เริ่มออกจากโรงงาน (Factory Departure)');
          await page.getByRole('button', { name: /Set Sailing/ }).click();
          containers = await pollRows(api, token, '/containers', rows =>
            rows.some(row => Number(row.id) === Number(container.id) && row.status === 'Sailing'),
          );
          container = containers.find(row => Number(row.id) === Number(container.id));
        }
        if (container.status === 'Sailing') {
          await selectToday(page, 'วันเรือคาดว่าจะถึงท่าไทย (ETA) *');
          await page.getByRole('button', { name: /Set Port Arrival/ }).click();
          containers = await pollRows(api, token, '/containers', rows =>
            rows.some(row => Number(row.id) === Number(container.id) && row.status === 'Port to Warehouse'),
          );
          container = containers.find(row => Number(row.id) === Number(container.id));
        }
        if (container.status === 'Port to Warehouse') {
          await selectToday(page, 'วันที่เรือถึงไทยจริง (Actual Arrival) *');
          await page.getByRole('button', { name: /Set Delivered/ }).click();
          containers = await pollRows(api, token, '/containers', rows =>
            rows.some(row => Number(row.id) === Number(container.id) && row.status === 'Delivered'),
          );
          container = containers.find(row => Number(row.id) === Number(container.id));
        }
        state.container = container;
        expect(container.status).toBe('Delivered');
        return `Container ${container.container_code} completed Factory → Sailing → Port → Delivered.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF11-INVENTORY', workflow: 'Workflow 11 — Inventory', card: 'normal',
        title: 'Create warehouse, stock 10%, reject duplicate | สร้างคลัง เก็บ 10% และกันรับซ้ำ',
        lines: ['สร้างคลังผ่าน UI', 'รับ 100 จาก 1,000 ชิ้น', 'ลองรับ container เดิมซ้ำ'],
        expected: 'Warehouse stock becomes 100 exactly once; duplicate receive rejected',
      }, async () => {
        const project = required(state.project, 'project');
        const product = required(state.product, 'product');
        const container = required(state.container, 'container');
        await goToAdminPage(page, 'Inventory');
        await page.getByRole('button', { name: /เพิ่มคลังสินค้าใหม่/ }).click();
        await replaceText(page.getByRole('textbox', { name: /ชื่อคลังสินค้า/ }), 'Long Journey Bangkok Warehouse');
        await replaceText(page.getByRole('textbox', { name: /ที่อยู่จริง/ }), '99 Long Journey Logistics Road');
        await replaceText(page.getByRole('textbox', { name: /จังหวัด/ }), 'Bangkok');
        await page.getByRole('button', { name: 'บันทึกคลังสินค้า', exact: true }).click();
        const warehouses = await pollRows(api, token, '/inventory/warehouses', rows => rows.length === 1);
        state.warehouse = warehouses[0];

        await goToAdminPage(page, 'Containers');
        await page.getByRole('button', { name: new RegExp(`^${container.container_code}\\b`) }).click();
        await page.getByRole('button', { name: 'ขาเข้าศุลกากร (Customs)', exact: true }).click();
        await page.getByRole('button', { name: /Receive Goods into Warehouse/ }).click();
        await chooseFlutterOption(page, page.getByRole('button', { name: /Product received/ }), product.name);
        await replaceText(page.getByRole('textbox', { name: /Quantity received/ }), '100');
        await page.getByRole('button', { name: /Confirm Stock IN/ }).click();
        await pollRows(api, token, '/inventory/movements', rows =>
          rows.some(row => row.reference_type === 'Container' && Number(row.reference_id) === Number(container.id)),
        );
        let stocks = await apiRows(api, token, `/inventory/warehouses/${state.warehouse.id}/stocks`);
        expect(Number(stocks.find(row => Number(row.product_item_id) === Number(product.id))?.qty_in_stock)).toBe(100);

        await goToAdminPage(page, 'Containers');
        await page.getByRole('button', { name: new RegExp(`^${container.container_code}\\b`) }).click();
        await page.getByRole('button', { name: 'ขาเข้าศุลกากร (Customs)', exact: true }).click();
        await page.getByRole('button', { name: /Receive Goods into Warehouse/ }).click();
        await chooseFlutterOption(page, page.getByRole('button', { name: /Product received/ }), product.name);
        await replaceText(page.getByRole('textbox', { name: /Quantity received/ }), '100');
        await page.getByRole('button', { name: /Confirm Stock IN/ }).click();
        const duplicateMessage = await page.getByText(/Unable to receive goods/).isVisible().catch(() => false);
        stocks = await apiRows(api, token, `/inventory/warehouses/${state.warehouse.id}/stocks`);
        const qtyAfterDuplicate = Number(stocks.find(row => Number(row.product_item_id) === Number(product.id))?.qty_in_stock);
        await recordExpected(page, findings, {
          id: 'WF11-ERR-DUPLICATE', workflow: 'Workflow 11 — Inventory',
          title: 'Duplicate container receipt rejected | รับตู้เดิมซ้ำถูกปฏิเสธ',
          passed: duplicateMessage && qtyAfterDuplicate === 100,
          expected: 'Error visible and stock remains 100',
          actual: `errorVisible=${duplicateMessage}, stock=${qtyAfterDuplicate}`,
        });
        await dismissVisibleDialog(page);
        await page.getByText('Cancel | ยกเลิก', { exact: true }).click().catch(() => page.keyboard.press('Escape'));
        addFinding(findings, {
          id: 'WF11-GAP-SPLIT', workflow: 'Workflow 11 — Inventory',
          title: 'Container 90/10 split control missing | หน้า Container ยังไม่มีตัวเลือก 90/10',
          status: 'COVERAGE-GAP',
          expected: 'Container dialog exposes direct_delivery + inventory routes',
          actual: 'Real UI exposes only a single inventory warehouse route; Delivery UI will demonstrate the split.',
        });
        return `Warehouse ${state.warehouse.id} contains exactly 100 buffer units; duplicate was rejected.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF12-DELIVERY', workflow: 'Workflow 12 — Delivery', card: 'important',
        title: 'Insufficient stock → 90/10 split → Delivered | สต๊อกไม่พอ → ส่งตรง 90% + คลัง 10%',
        lines: ['ลองส่งจากคลัง 101 แต่มี 100', '900 Direct Shipped', '100 ตัดคลัง', 'ส่งก่อนลูกค้าชำระครบ'],
        expected: 'Insufficient-stock round rejected; valid split departs and completes with stock 0',
      }, async () => {
        const project = required(state.project, 'project');
        const product = required(state.product, 'product');
        const warehouse = required(state.warehouse, 'warehouse');
        await goToAdminPage(page, 'Delivery');
        await replaceText(page.getByRole('textbox', { name: 'Driver Name', exact: true }), 'Insufficient Stock Driver');
        await replaceText(page.getByRole('textbox', { name: 'Vehicle Plate', exact: true }), 'ERR-0101');
        await chooseFlutterOption(page, page.getByRole('button', { name: /Delivery product 1/ }), product.name);
        await chooseFlutterOption(page, page.getByRole('button', { name: /Delivery warehouse 1/ }), new RegExp(warehouse.name));
        await replaceText(page.getByRole('textbox', { name: /Delivery quantity 1/ }), '101');
        const roundsBefore = await apiRows(api, token, '/delivery/rounds');
        await page.getByText('Confirm Delivery', { exact: true }).click();
        await page.waitForTimeout(2_000);
        const roundsAfterInvalid = await apiRows(api, token, '/delivery/rounds');
        const insufficientRejected = roundsAfterInvalid.length === roundsBefore.length;
        await recordExpected(page, findings, {
          id: 'WF12-ERR-STOCK', workflow: 'Workflow 12 — Delivery',
          title: 'Insufficient warehouse stock rejected | สต๊อกไม่พอถูกปฏิเสธ',
          passed: insufficientRejected,
          expected: 'No delivery round created for 101 warehouse units',
          actual: `before=${roundsBefore.length}, after=${roundsAfterInvalid.length}`,
        });
        await dismissVisibleDialog(page);

        await goToAdminPage(page, 'Delivery');
        await replaceText(page.getByRole('textbox', { name: 'Driver Name', exact: true }), 'Long Journey Driver');
        await replaceText(page.getByRole('textbox', { name: 'Vehicle Plate', exact: true }), 'LONG-9001');
        await chooseFlutterOption(page, page.getByRole('button', { name: /Delivery product 1/ }), product.name);
        await chooseFlutterOption(page, page.getByRole('button', { name: /Delivery warehouse 1/ }), 'ไม่ตัดสต็อก (Direct)');
        await replaceText(page.getByRole('textbox', { name: /Delivery quantity 1/ }), '900');
        await page.getByRole('button', { name: 'Add product to this delivery', exact: true }).click();
        await chooseFlutterOption(page, page.getByRole('button', { name: /Delivery product 2/ }), product.name);
        await chooseFlutterOption(page, page.getByRole('button', { name: /Delivery warehouse 2/ }), new RegExp(warehouse.name));
        await replaceText(page.getByRole('textbox', { name: /Delivery quantity 2/ }), '100');
        await page.getByText('Confirm Delivery', { exact: true }).click();
        // If the product incorrectly accepted the 101-unit negative probe, keep
        // that mismatch as evidence but discover the valid round relative to the
        // post-probe snapshot so the documentary journey can still continue.
        let rounds = await pollRows(api, token, '/delivery/rounds', rows =>
          rows.length === roundsAfterInvalid.length + 1,
        );
        let round = rounds.find(row =>
          !roundsAfterInvalid.some(item => Number(item.id) === Number(row.id)),
        );
        state.deliveryRound = round;
        const paymentsBeforeDelivery = await apiRows(api, token, `/finance/payments?project_id=${project.id}`);
        const paidBeforeDelivery = paymentsBeforeDelivery
          .filter(row => row.status === 'Confirmed')
          .reduce((sum, row) => sum + Number(row.amount), 0);
        expect(paidBeforeDelivery).toBe(50_000);
        addFinding(findings, {
          id: 'WF12-POLICY-SHIP-BEFORE-PAID', workflow: 'Workflow 12 — Delivery',
          title: 'Ship before full payment | ส่งก่อนลูกค้าชำระครบ', status: 'POLICY-OBSERVATION',
          expected: 'Delivery allowed with outstanding balance recorded',
          actual: `paid=${paidBeforeDelivery}, outstanding=${orderedQty * saleUnitPrice - paidBeforeDelivery}`,
        });
        await goToAdminPage(page, 'Delivery');
        await page.getByRole('button', { name: /Depart/ }).click();
        rounds = await pollRows(api, token, '/delivery/rounds', rows =>
          rows.some(row => Number(row.id) === Number(round.id) && row.status === 'In Transit'),
        );
        round = rounds.find(row => Number(row.id) === Number(round.id));
        const departStillVisible = await page.getByRole('button', { name: /Depart/ }).isVisible().catch(() => false);
        await recordExpected(page, findings, {
          id: 'WF12-ERR-DEPART-TWICE', workflow: 'Workflow 12 — Delivery',
          title: 'Duplicate Depart unavailable | ปล่อยรถซ้ำไม่ได้', passed: !departStillVisible,
          expected: 'Depart action disappears after In Transit', actual: `departVisible=${departStillVisible}`,
        });
        let stocks = await apiRows(api, token, `/inventory/warehouses/${warehouse.id}/stocks`);
        expect(Number(stocks.find(row => Number(row.product_item_id) === Number(product.id))?.qty_in_stock)).toBe(0);
        await page.getByRole('button', { name: /Complete/ }).click();
        rounds = await pollRows(api, token, '/delivery/rounds', rows =>
          rows.some(row => Number(row.id) === Number(round.id) && row.status === 'Delivered'),
        );
        state.deliveryRound = rounds.find(row => Number(row.id) === Number(round.id));
        return 'One round delivered 900 direct + 100 warehouse; stock changed 100 → 0 while balance remained outstanding.';
      });

      await runStage(page, testInfo, findings, {
        id: 'WF08-CI-BEFORE-PAID', workflow: 'Workflow 8 — Finance Documents', card: 'important',
        title: 'CI before final payment | ออก CI ก่อนรับเงินครบ',
        lines: ['สินค้าส่งถึงลูกค้าแล้ว', 'ยอดคงค้างยัง 99,000', 'ออก CI เพื่อใช้บัญชี/ศุลกากร'],
        expected: 'CI becomes Sent while customer still has outstanding balance',
      }, async () => {
        const project = required(state.project, 'project');
        const before = await apiRows(api, token, `/finance/payments?project_id=${project.id}`);
        const paid = before.filter(row => row.status === 'Confirmed').reduce((sum, row) => sum + Number(row.amount), 0);
        expect(paid).toBe(50_000);
        const ci = await createFinanceDocument(page, api, token, state, 'CI');
        addFinding(findings, {
          id: 'WF08-POLICY-CI-EARLY', workflow: 'Workflow 8 — Finance Documents',
          title: 'CI before full payment allowed | CI ก่อนรับครบ', status: 'POLICY-OBSERVATION',
          expected: 'CI allowed before final payment', actual: `CI ${ci.doc_no} status=${ci.status}, outstanding=${149_000 - paid}`,
        });
        return `CI ${ci.doc_no} issued while outstanding balance is ${149_000 - paid}.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF09-PAYMENT-FINAL', workflow: 'Workflow 9 — Customer Payments', card: 'important',
        title: 'Third installment after delivery | รับงวดที่สามหลังส่งสินค้า',
        lines: ['งวดสุดท้าย 99,000', 'อัปโหลดสลิปและยืนยัน', 'ยอดรวมต้องเท่ากับ 149,000'],
        expected: 'Three confirmed installments reconcile exactly to 149,000',
      }, async () => {
        const project = required(state.project, 'project');
        await recordPayment(page, api, token, state, 99_000);
        const payments = await apiRows(api, token, `/finance/payments?project_id=${project.id}`);
        const confirmed = payments.filter(row => row.status === 'Confirmed');
        const total = confirmed.reduce((sum, row) => sum + Number(row.amount), 0);
        expect(confirmed).toHaveLength(3);
        expect(total).toBe(149_000);
        return `Confirmed installments: 30,000 + 20,000 + 99,000 = ${total}.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF07-AP-BALANCE', workflow: 'Workflow 7 — Supplier AP', card: 'normal',
        title: 'Pay supplier balance | จ่ายยอดคงเหลือโรงงาน',
        lines: ['สร้าง Balance bill', 'อัปโหลด PI/Invoice', 'Mark Paid หลังส่งลูกค้า'],
        expected: 'Supplier has Deposit + Balance bills and both are Paid',
      }, async () => {
        const bill = await createAndPaySupplierBill(page, api, token, state, 'Balance');
        return `Supplier Balance bill ${bill.id} is Paid after customer delivery.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'WF13-REPORTS', workflow: 'Workflow 13 — Reports', card: 'normal',
        title: 'Open every report view | เปิดรายงานทุกหมวด',
        lines: ['Financials', 'Operations', 'Partners & Claims', 'Market Insights'],
        expected: 'Every implemented report tab renders without a Flutter crash',
      }, async () => {
        await goToAdminPage(page, 'Reports');
        const reportTabs = [
          'คาดการณ์รายรับ & วางบิล',
          'กำไรสุทธิรายโปรเจกต์',
          'กระแสเงินสด & AR/AP',
          'ภาษีนำเข้า & ค่าธรรมเนียม',
          'สถานะการทยอยส่งของ',
          'วิเคราะห์เวลาทำงาน (Lead Time)',
          'สินค้าค้างสต็อก (Aging)',
          'Ranking ซัพพลายเออร์',
          'สถิติของเคลม (FOC)',
          'สัดส่วนรายได้ลูกค้า',
        ];
        for (const tab of reportTabs) {
          await page.getByText(tab, { exact: true }).click();
          await page.waitForTimeout(700);
        }
        return `${reportTabs.length} report views opened through their real menu controls.`;
      });

      await runStage(page, testInfo, findings, {
        id: 'REC-FINAL', workflow: 'Final Reconciliation', card: 'final',
        title: 'Finance, stock and delivery reconciliation | กระทบยอดทั้งระบบ',
        lines: ['Payments = 149,000', 'Supplier bills 2 Paid', 'QU/PI/CI', 'Stock 0 after split delivery', 'Round Delivered'],
        expected: 'Cross-module totals and statuses reconcile',
      }, async () => {
        const supplier = required(state.supplier, 'supplier');
        const project = required(state.project, 'project');
        const product = required(state.product, 'product');
        const warehouse = required(state.warehouse, 'warehouse');
        const round = required(state.deliveryRound, 'delivery round');
        const [payments, bills, docs, stocks, movements, rounds] = await Promise.all([
          apiRows(api, token, `/finance/payments?project_id=${project.id}`),
          apiRows(api, token, `/suppliers/${supplier.id}/bills`),
          apiRows(api, token, `/finance/documents?project_id=${project.id}`),
          apiRows(api, token, `/inventory/warehouses/${warehouse.id}/stocks`),
          apiRows(api, token, '/inventory/movements'),
          apiRows(api, token, '/delivery/rounds'),
        ]);
        const paid = payments.filter(row => row.status === 'Confirmed').reduce((sum, row) => sum + Number(row.amount), 0);
        expect(paid).toBe(149_000);
        expect(payments.filter(row => row.status === 'Confirmed')).toHaveLength(3);
        expect(bills.filter(row => row.status === 'Paid')).toHaveLength(2);
        expect(new Set(docs.map(row => row.doc_type))).toEqual(new Set(['QU', 'PI', 'CI']));
        expect(Number(stocks.find(row => Number(row.product_item_id) === Number(product.id))?.qty_in_stock)).toBe(0);
        expect(movements.some(row => row.reference_type === 'Container' && row.movement_type === 'IN')).toBe(true);
        expect(movements.some(row => row.reference_type === 'Delivery' && row.movement_type === 'OUT')).toBe(true);
        expect(rounds.some(row => Number(row.id) === Number(round.id) && row.status === 'Delivered')).toBe(true);
        await goToAdminPage(page, 'Dashboard');
        await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible();
        return 'Reconciled: customer 149,000; supplier bills 2 Paid; QU/PI/CI; IN+OUT movements; delivery Delivered.';
      });

      const counts = findings.reduce<Record<string, number>>((acc, finding) => {
        acc[finding.status] = (acc[finding.status] ?? 0) + 1;
        return acc;
      }, {});
      await attachJson(testInfo, 'long-journey-findings', findings);
      await attachJson(testInfo, 'long-journey-summary', {
        runKey,
        customerName,
        projectCode: state.project?.project_code,
        counts,
        totalFindings: findings.length,
      });
      await safeCard(page, 'final', 'FINAL SUMMARY — สรุปคลิปยาว Workflow 1–13', [
        `Stages/checks recorded: ${findings.length}`,
        `PASS: ${counts.PASS ?? 0} | EXPECTED REJECTION: ${counts['EXPECTED-REJECTION'] ?? 0}`,
        `POLICY OBSERVATION: ${counts['POLICY-OBSERVATION'] ?? 0}`,
        `PRODUCT MISMATCH: ${counts['PRODUCT-MISMATCH'] ?? 0} | BLOCKED: ${counts.BLOCKED ?? 0}`,
        `COVERAGE GAP: ${counts['COVERAGE-GAP'] ?? 0} | AUTOMATION ERROR: ${counts['AUTOMATION-ERROR'] ?? 0}`,
        'วิดีโอและ trace บันทึกครบก่อนตัดสินผลสุดท้าย',
      ]);

      const failing = findings.filter(item =>
        item.status === 'PRODUCT-MISMATCH'
        || item.status === 'BLOCKED'
        || item.status === 'AUTOMATION-ERROR',
      );
      expect(failing, failing.map(item => `${item.id}: ${item.actual}`).join('\n')).toEqual([]);
    } finally {
      await api.dispose();
    }
  });
});
