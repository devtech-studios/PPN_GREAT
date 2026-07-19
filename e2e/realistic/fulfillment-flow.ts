import path from 'node:path';
import {
  expect,
  test,
  type APIRequestContext,
  type APIResponse,
  type Locator,
  type Page,
} from '@playwright/test';
import { authHeaders } from '../support/api';
import { uploadThroughFileChooser } from '../support/file-upload';
import { goToAdminPage } from '../support/flutter';

export type FulfillmentState = {
  customer: any;
  project: any;
  product: any;
  supplier: any;
  quote: any;
  warehouse?: any;
  container?: any;
  deliveryRound?: any;
};

const uploadFixture = path.resolve(__dirname, '../../web/favicon.png');
const saleUnitPrice = 149;
const supplierDepositAmount = 44_750;
const supplierBalanceAmount = 44_750;
const customerDepositAmount = 50_000;

function responseRows(body: any): any[] {
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

export async function apiRows(
  api: APIRequestContext,
  token: string,
  endpoint: string,
): Promise<any[]> {
  const body = await checkedBody(
    await api.get(`/api${endpoint}`, { headers: authHeaders(token) }),
  );
  return responseRows(body);
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

export async function resolveLatestFulfillmentState(
  api: APIRequestContext,
  token: string,
): Promise<FulfillmentState> {
  const [projects, suppliers] = await Promise.all([
    apiRows(api, token, '/projects'),
    apiRows(api, token, '/suppliers'),
  ]);
  expect(projects.length, 'Resume requires an existing project / โหมด Resume ต้องมีโครงการเดิม').toBeGreaterThan(0);
  expect(suppliers.length, 'Resume requires the baseline supplier / โหมด Resume ต้องมีซัพพลายเออร์').toBeGreaterThan(0);

  const project = await projectDetail(api, token, Number(projects[0].id));
  const product = project.products?.[0] ?? project.product_items?.[0];
  expect(product, 'Project must have a product / โครงการต้องมีสินค้า').toBeTruthy();
  const supplier = suppliers[0];
  const quotes = await apiRows(api, token, `/suppliers/${supplier.id}/quotes`);
  const quote = quotes.find(row => Number(row.project_id) === Number(project.id));
  expect(quote, 'Project must have a supplier quote / โครงการต้องมีใบเสนอราคาซัพพลายเออร์').toBeTruthy();

  return {
    customer: project.customer,
    project,
    product,
    supplier,
    quote,
  };
}

async function replaceText(locator: Locator, value: string): Promise<void> {
  await expect(locator).toBeVisible();
  await locator.click();
  await locator.press(process.platform === 'darwin' ? 'Meta+A' : 'Control+A');
  await locator.fill(value);
}

async function chooseFlutterOption(
  page: Page,
  trigger: Locator,
  option: string | RegExp,
): Promise<void> {
  await expect(trigger).toBeVisible();
  await trigger.click();
  const optionLocator = page.getByRole('menuitem', { name: option }).last();
  await expect(optionLocator).toBeVisible();
  await optionLocator.click();
}

async function selectToday(page: Page, fieldLabel: string): Promise<void> {
  const trigger = page.getByRole('button', {
    name: `Select date: ${fieldLabel}`,
  });
  for (let attempt = 0; attempt < 2; attempt += 1) {
    await trigger.click();
    const ok = page.getByRole('button', { name: /^(OK|ตกลง)$/ }).last();
    await expect(ok).toBeVisible();
    await ok.click();
    const dateWasApplied = await expect(trigger)
      .toHaveAccessibleName(/\d{2}\/\d{2}\/\d{4}/, { timeout: 4_000 })
      .then(() => true)
      .catch(() => false);
    if (dateWasApplied) return;
  }
  throw new Error(`Date selection was not applied: ${fieldLabel}`);
}

async function pollRows(
  api: APIRequestContext,
  token: string,
  endpoint: string,
  predicate: (rows: any[]) => boolean,
): Promise<any[]> {
  await expect.poll(async () => predicate(await apiRows(api, token, endpoint)), {
    timeout: 25_000,
  }).toBe(true);
  return apiRows(api, token, endpoint);
}

async function approveSupplierQuote(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: FulfillmentState,
): Promise<void> {
  const endpoint = `/suppliers/${state.supplier.id}/quotes`;
  const current = (await apiRows(api, token, endpoint)).find(
    row => Number(row.id) === Number(state.quote.id),
  );
  if (current?.status === 'Approved') return;

  await goToAdminPage(page, 'Suppliers');
  await replaceText(page.getByRole('textbox', { name: /ค้นหาชื่อโรงงาน/ }), state.supplier.name);
  await page.getByRole('button', { name: new RegExp(state.supplier.name) }).click();
  await page.getByRole('button', { name: 'Review & Resubmit', exact: true }).click();
  const approve = page.getByRole('button', { name: 'Approve & Accept', exact: true });
  await expect(approve).toBeVisible();
  await approve.click();
  const rows = await pollRows(api, token, endpoint, rows =>
    rows.some(row => Number(row.id) === Number(state.quote.id) && row.status === 'Approved'),
  );
  state.quote = rows.find(row => Number(row.id) === Number(state.quote.id));
}

async function ensureWarehouse(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: FulfillmentState,
): Promise<void> {
  let warehouses = await apiRows(api, token, '/inventory/warehouses');
  if (warehouses.length === 0) {
    await goToAdminPage(page, 'Inventory');
    await page.getByRole('button', { name: /เพิ่มคลังสินค้าใหม่/ }).click();
    await replaceText(page.getByRole('textbox', { name: /ชื่อคลังสินค้า/ }), 'E2E Bangkok Warehouse');
    await replaceText(page.getByRole('textbox', { name: /ที่อยู่จริง/ }), '99 E2E Logistics Road');
    await replaceText(page.getByRole('textbox', { name: /จังหวัด/ }), 'Bangkok');
    await page.getByRole('button', { name: 'บันทึกคลังสินค้า', exact: true }).click();
    warehouses = await pollRows(api, token, '/inventory/warehouses', rows => rows.length === 1);
  }
  state.warehouse = warehouses[0];
}

async function openSupplierPayables(page: Page, state: FulfillmentState): Promise<void> {
  await goToAdminPage(page, 'Suppliers');
  await replaceText(page.getByRole('textbox', { name: /ค้นหาชื่อโรงงาน/ }), state.supplier.name);
  await page.getByRole('button', { name: new RegExp(state.supplier.name) }).click();
  await page.getByRole('button', { name: 'รอบบิลจ่ายเงิน (AP)', exact: true }).click();
}

async function ensureSupplierBillPaid(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: FulfillmentState,
  billType: 'Deposit' | 'Balance',
  amount: number,
): Promise<void> {
  const endpoint = `/suppliers/${state.supplier.id}/bills`;
  let bills = await apiRows(api, token, endpoint);
  let bill = bills.find(
    row => Number(row.project_id) === Number(state.project.id) && row.bill_type === billType,
  );

  if (!bill) {
    await openSupplierPayables(page, state);
    await page.getByRole('button', { name: '+ Add Bill', exact: true }).click();
    await chooseFlutterOption(
      page,
      page.getByRole('button', { name: /เลือกโปรเจกต์|Project/ }).last(),
      new RegExp(state.project.project_code),
    );
    const productField = page.getByRole('textbox', { name: 'Product Name', exact: true });
    if (await productField.count()) await replaceText(productField, state.product.name);
    if (billType === 'Balance') {
      await chooseFlutterOption(
        page,
        page.getByRole('button', { name: 'Deposit', exact: true }).last(),
        'Balance',
      );
    }
    await replaceText(page.getByRole('textbox', { name: '0.00', exact: true }).last(), amount.toString());
    await page.getByRole('button', { name: 'Create Bill', exact: true }).click();
    bills = await pollRows(api, token, endpoint, rows =>
      rows.some(row => Number(row.project_id) === Number(state.project.id) && row.bill_type === billType),
    );
    bill = bills.find(
      row => Number(row.project_id) === Number(state.project.id) && row.bill_type === billType,
    );
  }

  if (!bill.pi_file_path || !bill.invoice_file_path || bill.status !== 'Paid') {
    await openSupplierPayables(page, state);
    if (!bill.pi_file_path) {
      await uploadThroughFileChooser(page, page.getByText('PI', { exact: true }).last(), uploadFixture);
    }
    if (!bill.invoice_file_path) {
      await uploadThroughFileChooser(page, page.getByText('Invoice', { exact: true }).last(), uploadFixture);
    }
    bills = await pollRows(api, token, endpoint, rows => {
      const row = rows.find(item => Number(item.id) === Number(bill.id));
      return Boolean(row?.pi_file_path && row?.invoice_file_path);
    });
    bill = bills.find(row => Number(row.id) === Number(bill.id));

    if (bill.status !== 'Paid') {
      await page.getByRole('checkbox', {
        name: `Select supplier bill ${bill.id}`,
      }).click();
      await page.getByRole('button', { name: 'Pay Selected Bills', exact: true }).click();
      await pollRows(api, token, endpoint, rows =>
        rows.some(row => Number(row.id) === Number(bill.id) && row.status === 'Paid'),
      );
    }
  }
}

async function ensureFinanceDocument(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: FulfillmentState,
  docType: 'QU' | 'PI' | 'CI',
): Promise<any> {
  let docs = await apiRows(api, token, `/finance/documents?project_id=${state.project.id}`);
  let doc = docs.find(row => row.doc_type === docType && row.status !== 'Cancelled');
  if (doc) return doc;

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
  docs = await pollRows(api, token, `/finance/documents?project_id=${state.project.id}`, rows =>
    rows.some(row => row.doc_type === docType && row.status === 'Sent'),
  );
  doc = docs.find(row => row.doc_type === docType && row.status !== 'Cancelled');
  return doc;
}

async function openRecordPayment(page: Page): Promise<void> {
  await goToAdminPage(page, 'Dashboard');
  await page.getByRole('button', { name: 'Record Payment', exact: true }).click();
  await expect(page.getByText('Payment History (ประวัติการรับชำระเงิน)', { exact: true })).toBeVisible();
}

async function recordUploadAndVerifyPayment(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: FulfillmentState,
  phase: 'deposit' | 'balance',
): Promise<any> {
  let payments = await apiRows(api, token, `/finance/payments?project_id=${state.project.id}`);
  let payment = phase === 'deposit'
    ? payments[0]
    : payments.find((row, index) => index > 0 || row.payment_type !== 'Deposit');

  if (!payment) {
    await openRecordPayment(page);
    const amount = phase === 'deposit'
      ? customerDepositAmount
      : Number(state.product.qty) * saleUnitPrice - customerDepositAmount;
    await replaceText(
      page.getByRole('textbox', { name: /ยอดเงินที่ได้รับ/ }),
      amount.toFixed(2),
    );
    await page.getByRole('button', { name: 'Confirm & Record Payment', exact: true }).click();
    payments = await pollRows(api, token, `/finance/payments?project_id=${state.project.id}`, rows =>
      phase === 'deposit' ? rows.length >= 1 : rows.length >= 2,
    );
    payment = phase === 'deposit'
      ? payments[0]
      : payments.find((row, index) => index > 0 || row.payment_type !== 'Deposit');
  }

  if (!payment.slip_file_path || payment.status !== 'Confirmed') {
    await openRecordPayment(page);
    if (!payment.slip_file_path) {
      await uploadThroughFileChooser(
        page,
        page.getByRole('button', { name: 'อัปโหลด', exact: true }).last(),
        uploadFixture,
      );
      payments = await pollRows(api, token, `/finance/payments?project_id=${state.project.id}`, rows =>
        rows.some(row => Number(row.id) === Number(payment.id) && Boolean(row.slip_file_path)),
      );
      payment = payments.find(row => Number(row.id) === Number(payment.id));
    }

    if (payment.status !== 'Confirmed') {
      await page.getByRole('button', { name: 'ยืนยันยอด', exact: true }).last().click();
      payments = await pollRows(api, token, `/finance/payments?project_id=${state.project.id}`, rows =>
        rows.some(row => Number(row.id) === Number(payment.id) && row.status === 'Confirmed'),
      );
      payment = payments.find(row => Number(row.id) === Number(payment.id));
    }
  }
  return payment;
}

async function ensureDeliveredContainer(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: FulfillmentState,
): Promise<void> {
  let containers = await apiRows(api, token, '/containers');
  let container = containers.find(row =>
    (row.projects ?? []).some((project: any) => Number(project.id) === Number(state.project.id)),
  );
  if (!container) {
    await goToAdminPage(page, 'Containers');
    await page.getByRole('button', { name: /Create Container/ }).click();
    await replaceText(
      page.getByRole('textbox', { name: /Container No/ }),
      `E2E-${state.project.project_code}`,
    );
    await replaceText(page.getByRole('textbox', { name: /Vessel Name/ }), 'E2E Ocean Vessel');
    await page
      .getByRole('checkbox', { name: new RegExp(state.project.project_code) })
      .click();
    await page.getByRole('button', { name: 'บันทึก', exact: true }).click();
    containers = await pollRows(api, token, '/containers', rows => rows.length >= 1);
    container = containers.find(row =>
      (row.projects ?? []).some((project: any) => Number(project.id) === Number(state.project.id)),
    ) ?? containers[0];
  }

  state.container = container;
  await goToAdminPage(page, 'Containers');
  await page
    .getByRole('button', { name: new RegExp(`^${container.container_code}\\b`) })
    .click();

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
}

async function ensureContainerStockIn(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: FulfillmentState,
): Promise<void> {
  const movements = await apiRows(api, token, '/inventory/movements');
  const alreadyReceived = movements.some(row =>
    row.reference_type === 'Container' && Number(row.reference_id) === Number(state.container.id),
  );
  if (alreadyReceived) return;

  await goToAdminPage(page, 'Containers');
  await page
    .getByRole('button', { name: new RegExp(`^${state.container.container_code}\\b`) })
    .click();
  await page.getByRole('button', { name: 'ขาเข้าศุลกากร (Customs)', exact: true }).click();
  await page.getByRole('button', { name: /Receive Goods into Warehouse/ }).click();
  await chooseFlutterOption(
    page,
    page.getByRole('button', { name: /Product received/ }),
    state.product.name,
  );
  await replaceText(
    page.getByRole('textbox', { name: /Quantity received/ }),
    state.product.qty.toString(),
  );
  await page.getByRole('button', { name: /Confirm Stock IN/ }).click();
  await pollRows(api, token, '/inventory/movements', rows =>
    rows.some(row =>
      row.reference_type === 'Container' && Number(row.reference_id) === Number(state.container.id),
    ),
  );

  const duplicate = await api.post(`/api/containers/${state.container.id}/route-goods`, {
    headers: authHeaders(token),
    data: {
      project_id: state.project.id,
      product_item_id: state.product.id,
      qty_total_received: state.product.qty,
      routing: [{ type: 'inventory', qty: state.product.qty, warehouse_id: state.warehouse.id }],
    },
  });
  expect(duplicate.status(), 'Duplicate container receipt must be rejected / ต้องกันการรับเข้าซ้ำ').toBe(409);
}

async function ensureDeliveryCompleted(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: FulfillmentState,
): Promise<void> {
  let rounds = await apiRows(api, token, '/delivery/rounds');
  let round = rounds.find(row =>
    (row.items ?? []).some((item: any) => Number(item.project_id) === Number(state.project.id)),
  );
  const deliveryQty = Math.max(1, Number(state.product.qty) - 100);

  if (!round) {
    await goToAdminPage(page, 'Delivery');
    await replaceText(page.getByRole('textbox', { name: 'Driver Name', exact: true }), 'E2E Driver');
    await replaceText(page.getByRole('textbox', { name: 'Vehicle Plate', exact: true }), 'E2E-9000');
    await chooseFlutterOption(
      page,
      page.getByRole('button', { name: /Delivery product 1/ }),
      state.product.name,
    );
    await chooseFlutterOption(
      page,
      page.getByRole('button', { name: /Delivery warehouse 1/ }),
      new RegExp(state.warehouse.name),
    );
    await replaceText(
      page.getByRole('textbox', { name: /Delivery quantity 1/ }),
      deliveryQty.toString(),
    );
    await page.getByText('Confirm Delivery', { exact: true }).click();
    rounds = await pollRows(api, token, '/delivery/rounds', rows => rows.length >= 1);
    round = rounds.find(row =>
      (row.items ?? []).some((item: any) => Number(item.project_id) === Number(state.project.id)),
    );
  }

  state.deliveryRound = round;
  if (round.status === 'Scheduled') {
    const stocksBefore = await apiRows(
      api,
      token,
      `/inventory/warehouses/${state.warehouse.id}/stocks`,
    );
    const before = stocksBefore.find(row => Number(row.product_item_id) === Number(state.product.id));
    expect(Number(before.qty_reserved)).toBe(deliveryQty);

    await goToAdminPage(page, 'Delivery');
    await page.getByRole('button', { name: /Depart/ }).click();
    rounds = await pollRows(api, token, '/delivery/rounds', rows =>
      rows.some(row => Number(row.id) === Number(round.id) && row.status === 'In Transit'),
    );
    round = rounds.find(row => Number(row.id) === Number(round.id));

    const stocksAfter = await apiRows(
      api,
      token,
      `/inventory/warehouses/${state.warehouse.id}/stocks`,
    );
    const after = stocksAfter.find(row => Number(row.product_item_id) === Number(state.product.id));
    expect(Number(after.qty_in_stock)).toBe(Number(state.product.qty) - deliveryQty);
    expect(Number(after.qty_reserved)).toBe(0);

    const duplicateConfirm = await api.patch(`/api/delivery/rounds/${round.id}/confirm`, {
      headers: authHeaders(token),
    });
    expect(duplicateConfirm.status(), 'Duplicate stock deduction must be rejected / ต้องกันการหักสต๊อกซ้ำ').toBe(400);
  }
  if (round.status === 'In Transit') {
    await goToAdminPage(page, 'Delivery');
    await page.getByRole('button', { name: /Complete/ }).click();
    rounds = await pollRows(api, token, '/delivery/rounds', rows =>
      rows.some(row => Number(row.id) === Number(round.id) && row.status === 'Delivered'),
    );
    round = rounds.find(row => Number(row.id) === Number(round.id));
  }
  state.deliveryRound = round;
}

async function verifyReconciliation(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: FulfillmentState,
): Promise<void> {
  const [payments, bills, docs, stocks, movements, rounds] = await Promise.all([
    apiRows(api, token, `/finance/payments?project_id=${state.project.id}`),
    apiRows(api, token, `/suppliers/${state.supplier.id}/bills`),
    apiRows(api, token, `/finance/documents?project_id=${state.project.id}`),
    apiRows(api, token, `/inventory/warehouses/${state.warehouse.id}/stocks`),
    apiRows(api, token, '/inventory/movements'),
    apiRows(api, token, '/delivery/rounds'),
  ]);
  expect(payments.filter(row => row.status === 'Confirmed')).toHaveLength(2);
  expect(bills.filter(row => row.status === 'Paid')).toHaveLength(2);
  expect(new Set(docs.map(row => row.doc_type))).toEqual(new Set(['QU', 'PI', 'CI']));
  expect(stocks.find(row => Number(row.product_item_id) === Number(state.product.id))?.qty_in_stock).toBe(100);
  expect(movements.some(row => row.reference_type === 'Container' && row.movement_type === 'IN')).toBe(true);
  expect(movements.some(row => row.reference_type === 'Delivery' && row.movement_type === 'OUT')).toBe(true);
  expect(rounds.some(row => Number(row.id) === Number(state.deliveryRound.id) && row.status === 'Delivered')).toBe(true);

  await goToAdminPage(page, 'Reports');
  await expect(page.getByText(/Reports|รายงาน/).first()).toBeVisible();
}

export async function runFulfillmentFlow(
  page: Page,
  api: APIRequestContext,
  token: string,
  state: FulfillmentState,
): Promise<void> {
  await test.step('PROC-001 | Approve supplier quotation | อนุมัติใบเสนอราคาซัพพลายเออร์', async () => {
    await approveSupplierQuote(page, api, token, state);
  });
  await test.step('WH-001 | Create the real destination warehouse | สร้างโกดังปลายทางจริง', async () => {
    await ensureWarehouse(page, api, token, state);
  });
  await test.step('AP-001 | Upload and pay supplier deposit bill | อัปโหลดเอกสารและจ่ายบิลมัดจำโรงงาน', async () => {
    await ensureSupplierBillPaid(page, api, token, state, 'Deposit', supplierDepositAmount);
  });
  await test.step('AR-001 | Issue customer quotation and PI | ออกใบเสนอราคาและ PI ให้ลูกค้า', async () => {
    await ensureFinanceDocument(page, api, token, state, 'QU');
    await ensureFinanceDocument(page, api, token, state, 'PI');
  });
  await test.step('PAY-001 | Receive, upload and verify customer deposit | รับมัดจำ อัปโหลดสลิป และยืนยันยอด', async () => {
    await recordUploadAndVerifyPayment(page, api, token, state, 'deposit');
  });
  await test.step('LOG-001 | Create and advance the project container | สร้างตู้และเลื่อนสถานะขนส่งจนถึงคลัง', async () => {
    await ensureDeliveredContainer(page, api, token, state);
  });
  await test.step('STOCK-001 | Receive container goods into warehouse exactly once | รับสินค้าจากตู้เข้าโกดังแบบไม่ซ้ำ', async () => {
    await ensureContainerStockIn(page, api, token, state);
  });
  await test.step('DEL-001 | Reserve stock, depart and complete customer delivery | จองสต๊อก ปล่อยรถ และส่งลูกค้าสำเร็จ', async () => {
    await ensureDeliveryCompleted(page, api, token, state);
  });
  await test.step('AP-002 | Upload and pay supplier balance bill | อัปโหลดเอกสารและจ่ายยอดคงเหลือโรงงาน', async () => {
    await ensureSupplierBillPaid(page, api, token, state, 'Balance', supplierBalanceAmount);
  });
  await test.step('PAY-002 | Receive and verify customer balance | รับและยืนยันยอดคงเหลือลูกค้า', async () => {
    await recordUploadAndVerifyPayment(page, api, token, state, 'balance');
  });
  await test.step('AR-002 | Issue final commercial invoice | ออก Commercial Invoice ฉบับสุดท้าย', async () => {
    await ensureFinanceDocument(page, api, token, state, 'CI');
  });
  await test.step('REC-001 | Reconcile finance, stock and delivery reports | กระทบยอดการเงิน สต๊อก และการจัดส่ง', async () => {
    await verifyReconciliation(page, api, token, state);
  });
}
