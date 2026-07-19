import { expect, type Page, type Response } from '@playwright/test';
import { env } from '../../support/env';
import { openFlutterApp } from '../../support/flutter';

export async function openLogin(page: Page): Promise<void> {
  await openFlutterApp(page);
  await expect(page.getByText('Sign In', { exact: true })).toBeVisible();
}

export async function fillLogin(
  page: Page,
  email = env.adminEmail,
  password = env.adminPassword,
): Promise<void> {
  const fields = page.getByRole('textbox');
  await expect(fields.first()).toBeVisible();
  // Flutter Web's semantics text fields can report a successful `fill()` while
  // the TextEditingController still contains an empty value. Keyboard input is
  // the proven interaction path used by the frozen V1 suite.
  await fields.first().click();
  await fields.first().pressSequentially(email);
  await fields.nth(1).click();
  await fields.nth(1).pressSequentially(password);
}

export async function submitLogin(page: Page): Promise<Response> {
  const responsePromise = page.waitForResponse(response =>
    response.url().endsWith('/api/auth/login') && response.request().method() === 'POST',
  );
  await page.getByText('Sign In', { exact: true }).click();
  return responsePromise;
}

export async function loginThroughUi(page: Page): Promise<Response> {
  await openLogin(page);
  await fillLogin(page);
  const response = await submitLogin(page);
  await expect(page.getByText('Dashboard', { exact: true }).first()).toBeVisible({ timeout: 30_000 });
  return response;
}
