import { Page, expect } from '@playwright/test';

/**
 * PPN GREAT — Auth Helper
 *
 * Reusable login/logout functions for Playwright tests.
 * Flutter Web renders as a canvas + shadow DOM, so we use
 * text-based and role-based selectors where possible.
 */

/** Admin credentials (from database seeder) */
export const ADMIN_CREDENTIALS = {
  email: 'admin@ppngreat.com',
  password: 'password123',
};

/** API Base URL for direct API calls */
export const API_BASE_URL = 'http://localhost:8000/api';

/** JWT token storage key (used by Flutter's SharedPreferences on web) */
let cachedToken: string | null = null;

/**
 * Login as admin via the UI.
 * Waits until the Dashboard sidebar brand "PPN GREAT" is visible.
 */
export async function loginAsAdmin(page: Page): Promise<void> {
  await page.goto('/');

  // Wait for Flutter to finish loading (DDC can take a while)
  await page.waitForTimeout(3000);

  // Fill email
  const emailInput = page.locator('input[type="text"]').first();
  await emailInput.waitFor({ state: 'visible', timeout: 30_000 });
  await emailInput.fill(ADMIN_CREDENTIALS.email);

  // Fill password
  const passwordInput = page.locator('input[type="password"]').first();
  await passwordInput.fill(ADMIN_CREDENTIALS.password);

  // Click Sign In
  await page.locator('button:has-text("Sign In"), [role="button"]:has-text("Sign In")').first().click();

  // Wait for Dashboard to load (sidebar brand text)
  await page.waitForSelector('text=PPN GREAT', { timeout: 30_000 });
  // Additional wait for APIs to settle
  await page.waitForTimeout(2000);
}

/**
 * Login as admin via API and get JWT token (for API-based seeding).
 */
export async function getAdminToken(): Promise<string> {
  if (cachedToken) return cachedToken;

  const response = await fetch(`${API_BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: ADMIN_CREDENTIALS.email,
      password: ADMIN_CREDENTIALS.password,
    }),
  });

  const data = await response.json();
  cachedToken = data.access_token || data.data?.token;
  if (!cachedToken) throw new Error('Failed to get admin token');
  return cachedToken;
}

/**
 * Make an authenticated API request (useful for test setup/teardown).
 */
export async function apiRequest(
  method: string,
  endpoint: string,
  body?: Record<string, unknown>,
): Promise<any> {
  const token = await getAdminToken();
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return response.json();
}

/**
 * Navigate to a specific page via sidebar menu click.
 * Flutter Web uses Navigator.push so we click the menu item text.
 */
export async function navigateTo(page: Page, menuText: string): Promise<void> {
  await page.locator(`text=${menuText}`).first().click();
  await page.waitForTimeout(2000); // Wait for screen transition + API loads
}

/**
 * Logout via the sidebar Log Out button.
 */
export async function logout(page: Page): Promise<void> {
  await page.locator('text=Log Out').first().click();
  // Wait for confirmation dialog
  await page.waitForTimeout(500);
  // Click confirm button
  await page.locator('text=ออกจากระบบ').first().click();
  // Wait for redirect to login
  await page.waitForSelector('text=Sign In', { timeout: 10_000 });
}

/**
 * Wait for a Flutter SnackBar to appear with specific text.
 */
export async function expectSnackBar(page: Page, text: string): Promise<void> {
  await expect(page.locator(`text=${text}`).first()).toBeVisible({ timeout: 10_000 });
}

/**
 * Wait for Flutter dialog and get text content.
 */
export async function expectDialog(page: Page, titleText: string): Promise<void> {
  await expect(page.locator(`text=${titleText}`).first()).toBeVisible({ timeout: 5_000 });
}

/**
 * Click a Flutter ElevatedButton or TextButton by its label text.
 */
export async function clickButton(page: Page, text: string): Promise<void> {
  await page.locator(`text=${text}`).first().click();
  await page.waitForTimeout(500);
}

/**
 * Fill a Flutter TextField that has a specific hint/label text nearby.
 * This is a best-effort approach for Flutter Web where inputs are rendered
 * inside the shadow DOM / flt-semantics tree.
 */
export async function fillField(page: Page, hintOrLabel: string, value: string): Promise<void> {
  // Try to find an input near the label text
  const field = page.locator(`input`).filter({ has: page.locator(`text="${hintOrLabel}"`) }).first();
  if (await field.isVisible()) {
    await field.fill(value);
  } else {
    // Fallback: find the label, then the nearest input
    const label = page.locator(`text=${hintOrLabel}`).first();
    const container = label.locator('..').locator('input').first();
    await container.fill(value);
  }
}
