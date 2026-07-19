import { defineConfig, devices } from '@playwright/test';
import path from 'node:path';

const rootDir = __dirname;
const phpBin = process.env.PHP_BIN ?? 'C:/xampp/php/php.exe';
const adminBaseUrl = process.env.E2E_ADMIN_URL ?? 'http://127.0.0.1:4173';
const supplierBaseUrl = process.env.E2E_SUPPLIER_URL ?? 'http://localhost:3000';
const apiUrl = process.env.E2E_API_URL ?? 'http://127.0.0.1:8000';

export default defineConfig({
  testDir: './e2e',
  outputDir: './test-results',
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : 2,
  timeout: 60_000,
  expect: { timeout: 10_000 },
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['junit', { outputFile: 'test-results/junit.xml' }],
  ],
  use: {
    actionTimeout: 10_000,
    navigationTimeout: 30_000,
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
    viewport: { width: 1440, height: 1000 },
  },
  webServer: process.env.E2E_EXTERNAL_SERVERS
    ? undefined
    : [
        {
          command: `\"${phpBin}\" artisan serve --host=127.0.0.1 --port=8000`,
          cwd: path.resolve(rootDir, '../ppn-api'),
          url: `${apiUrl}/`,
          reuseExistingServer: true,
          timeout: 30_000,
        },
        {
          command: 'npm run serve:web',
          cwd: rootDir,
          url: adminBaseUrl,
          reuseExistingServer: true,
          timeout: 30_000,
        },
        {
          command: `\"${phpBin}\" -S localhost:3000 -t ../Supplier_ui_moocup/index`,
          cwd: rootDir,
          url: supplierBaseUrl,
          reuseExistingServer: true,
          timeout: 30_000,
        },
      ],
  projects: [
    {
      name: 'admin-chromium',
      testIgnore: [/supplier-portal\.spec\.ts/, /[\\/]e2e[\\/]tests[\\/]/],
      use: {
        ...devices['Desktop Chrome'],
        baseURL: adminBaseUrl,
      },
    },
    {
      name: 'supplier-chromium',
      testMatch: /supplier-portal\.spec\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        baseURL: supplierBaseUrl,
      },
    },
  ],
});
