import { defineConfig } from '@playwright/test';
import baseConfig from './playwright.config';

/** Record every test, including passing tests, without replacing normal artifacts. */
export default defineConfig({
  ...baseConfig,
  outputDir: './test-results-video',
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report-video', open: 'never' }],
    ['junit', { outputFile: 'test-results-video/junit.xml' }],
  ],
  use: {
    ...baseConfig.use,
    video: 'on',
  },
});
