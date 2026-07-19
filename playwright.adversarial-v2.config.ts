import { defineConfig, devices } from '@playwright/test';
import path from 'node:path';
import baseConfig from './playwright.config';

const adminBaseUrl = process.env.E2E_ADMIN_URL ?? 'http://127.0.0.1:4174';
const apiUrl = process.env.E2E_API_URL ?? 'http://127.0.0.1:8001';
const supplierBaseUrl = process.env.E2E_SUPPLIER_URL ?? 'http://localhost:3001';
const phpBin = process.env.PHP_BIN ?? 'C:/xampp/php/php.exe';
const selectedPack = process.env.E2E_ADVERSARIAL_PACK?.trim().toLowerCase();
const runSlug = selectedPack || 'all';

export default defineConfig({
  ...baseConfig,
  testDir: './e2e/adversarial-v2',
  testMatch: selectedPack
    ? new RegExp(`${selectedPack}\\.paired\\.spec\\.ts$`, 'i')
    : /.*\.paired\.spec\.ts/,
  globalSetup: path.resolve(__dirname, 'e2e/adversarial-v2/global-setup.ts'),
  fullyParallel: false,
  workers: 1,
  retries: 0,
  maxFailures: 0,
  timeout: 30 * 60_000,
  expect: { timeout: 20_000 },
  outputDir: `./test-results-adversarial-v2-${runSlug}`,
  reporter: [
    ['list'],
    ['html', { outputFolder: `playwright-report-adversarial-v2-${runSlug}`, open: 'never' }],
    ['junit', { outputFile: `test-results-adversarial-v2-${runSlug}/junit.xml` }],
    [path.resolve(__dirname, 'e2e/adversarial-v2/support/adversarial-reporter.ts')],
  ],
  webServer: [
    {
      command: `\"${phpBin}\" artisan serve --host=127.0.0.1 --port=8001`,
      cwd: path.resolve(__dirname, '../ppn-api'),
      url: `${apiUrl}/`,
      reuseExistingServer: false,
      timeout: 30_000,
    },
    {
      command: 'http-server build/web -p 4174 -c-1',
      cwd: __dirname,
      url: adminBaseUrl,
      reuseExistingServer: false,
      timeout: 30_000,
    },
    {
      command: `\"${phpBin}\" -S localhost:3001 -t ../Supplier_ui_moocup/index`,
      cwd: __dirname,
      url: supplierBaseUrl,
      reuseExistingServer: false,
      timeout: 30_000,
    },
  ],
  use: {
    ...baseConfig.use,
    actionTimeout: 30_000,
    navigationTimeout: 60_000,
    screenshot: 'on',
    trace: 'on',
    video: 'on',
    viewport: { width: 1440, height: 1000 },
    launchOptions: { slowMo: 1_000 },
  },
  projects: [
    {
      name: 'adversarial-v2-desktop | เคสผิดปกติ V2 บน Desktop',
      use: {
        ...devices['Desktop Chrome'],
        baseURL: adminBaseUrl,
        viewport: { width: 1440, height: 1000 },
        launchOptions: { slowMo: 1_000 },
      },
    },
  ],
});
