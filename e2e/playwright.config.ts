import { defineConfig, devices } from '@playwright/test';

/**
 * PPN GREAT — Playwright E2E Test Configuration
 *
 * ระบบที่ทดสอบ:
 * - Flutter Web Admin: http://localhost:5000
 * - Supplier Portal (PHP): http://localhost:3000
 * - Backend API (Laravel): http://localhost:8000
 */
export default defineConfig({
  testDir: './tests',
  fullyParallel: false,       // Run sequentially — some tests depend on data created by previous ones
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,                 // Single worker for data consistency
  reporter: [
    ['html', { open: 'never' }],
    ['list'],
  ],

  use: {
    baseURL: 'http://localhost:5000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
    // Flutter Web takes time to compile on first load
    launchOptions: {
      slowMo: 100,
    },
  },

  projects: [
    {
      name: 'admin-chromium',
      use: {
        ...devices['Desktop Chrome'],
        baseURL: 'http://localhost:5000',
        viewport: { width: 1920, height: 1080 },
      },
    },
    {
      name: 'supplier-portal',
      testMatch: /16-supplier-portal/,
      use: {
        ...devices['Desktop Chrome'],
        baseURL: 'http://localhost:3000',
        viewport: { width: 1440, height: 900 },
      },
    },
  ],

  // Do NOT auto-start servers — user manages them manually
  // webServer: [...]
});
