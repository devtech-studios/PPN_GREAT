import { defineConfig, devices } from '@playwright/test';
import path from 'node:path';
import baseConfig from './playwright.config';

const adminBaseUrl = process.env.E2E_ADMIN_URL ?? 'http://127.0.0.1:4174';
const apiUrl = process.env.E2E_API_URL ?? 'http://127.0.0.1:8001';
const supplierBaseUrl = process.env.E2E_SUPPLIER_URL ?? 'http://localhost:3001';
const phpBin = process.env.PHP_BIN ?? 'C:/xampp/php/php.exe';
const resumeMode = process.env.E2E_REALISTIC_MODE === 'resume';

export default defineConfig({
  ...baseConfig,
  testDir: './e2e',
  testMatch: resumeMode
    ? /fulfillment-resume\.spec\.ts/
    : /realistic-business-cycle\.spec\.ts/,
  globalSetup: resumeMode
    ? undefined
    : path.resolve(__dirname, 'e2e/realistic/global-setup.ts'),
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 20 * 60_000,
  outputDir: './test-results-realistic',
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report-realistic', open: 'never' }],
    ['junit', { outputFile: 'test-results-realistic/junit.xml' }],
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
    actionTimeout: 20_000,
    navigationTimeout: 45_000,
    screenshot: 'on',
    trace: 'on',
    video: 'on',
    viewport: { width: 1440, height: 1000 },
  },
  projects: [
    {
      name: 'realistic-local-chromium | เส้นทางธุรกิจจริงบน Local',
      use: {
        ...devices['Desktop Chrome'],
        baseURL: adminBaseUrl,
        viewport: { width: 1440, height: 1000 },
      },
    },
  ],
});
