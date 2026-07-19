import { expect, type Locator, type Page, type Request } from '@playwright/test';
import { env } from './env';

/** Flutter Web renders most controls through semantics. Activate it before locating controls. */
export async function enableFlutterSemantics(page: Page): Promise<void> {
  const placeholder = page.locator('flt-semantics-placeholder');
  await page.locator('flt-glass-pane').waitFor({ state: 'attached', timeout: 20_000 });
  await placeholder.waitFor({ state: 'attached', timeout: 10_000 }).catch(() => undefined);
  if (await placeholder.count()) {
    await placeholder.evaluate(element => (element as HTMLElement).click());
  }
  await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 10_000 });
  await page.waitForTimeout(250);
}

export async function openFlutterApp(page: Page): Promise<void> {
  await page.goto('/');
  await enableFlutterSemantics(page);
  await expect(page.getByText('PPN GREAT', { exact: true }).first()).toBeVisible();
}

export async function loginAsAdmin(page: Page): Promise<void> {
  await openFlutterApp(page);
  if (await page.getByText('Dashboard', { exact: true }).count()) return;

  const textboxes = page.getByRole('textbox');
  await expect(textboxes.first()).toBeVisible();
  await textboxes.first().click();
  await textboxes.first().pressSequentially(env.adminEmail);
  await textboxes.nth(1).click();
  await textboxes.nth(1).pressSequentially(env.adminPassword);
  await page.getByText('Sign In', { exact: true }).click();
  await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible({ timeout: 20_000 });
}

export async function goToAdminPage(page: Page, menuText: string | RegExp): Promise<void> {
  await loginAsAdmin(page);
  const menu = page.getByText(menuText, { exact: typeof menuText === 'string' }).first();
  await expect(menu).toBeVisible();
  await clickAndWaitForApiIdle(page, menu);
}

/**
 * Start tracking before the click so route changes never dispose a Flutter
 * widget while one of that screen's API requests is still completing.
 */
export async function clickAndWaitForApiIdle(
  page: Page,
  locator: Locator,
  options: { quietMs?: number; timeoutMs?: number } = {},
): Promise<void> {
  const quietMs = options.quietMs ?? 500;
  const timeoutMs = options.timeoutMs ?? 20_000;
  const pending = new Set<Request>();
  let lastActivity = Date.now();

  const isApiRequest = (request: Request): boolean => request.url().includes('/api/');
  const onRequest = (request: Request): void => {
    if (!isApiRequest(request)) return;
    pending.add(request);
    lastActivity = Date.now();
  };
  const onRequestDone = (request: Request): void => {
    if (!pending.delete(request)) return;
    lastActivity = Date.now();
  };

  page.on('request', onRequest);
  page.on('requestfinished', onRequestDone);
  page.on('requestfailed', onRequestDone);

  try {
    await locator.click();
    const deadline = Date.now() + timeoutMs;
    while (Date.now() < deadline) {
      if (pending.size === 0 && Date.now() - lastActivity >= quietMs) return;
      await page.waitForTimeout(100);
    }

    throw new Error(`API requests did not become idle within ${timeoutMs}ms (${pending.size} pending)`);
  } finally {
    page.off('request', onRequest);
    page.off('requestfinished', onRequestDone);
    page.off('requestfailed', onRequestDone);
  }
}

export async function clickVisible(locator: Locator): Promise<void> {
  await expect(locator).toBeVisible();
  await locator.click();
}

export function collectRuntimeFailures(page: Page, context?: () => string): string[] {
  const failures: string[] = [];
  const prefix = (): string => (context ? `[${context()}] ` : '');
  page.on('pageerror', error => {
    failures.push(`${prefix()}pageerror: ${error.stack?.trim() || error.message}`);
  });
  page.on('console', message => {
    if (message.type() === 'error') failures.push(`${prefix()}console: ${message.text()}`);
  });
  return failures;
}

export function expectNoRuntimeFailures(failures: string[]): void {
  expect(failures, failures.join('\n')).toEqual([]);
}
