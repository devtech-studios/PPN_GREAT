import { test as base, expect } from '@playwright/test';
import { attachJson, collectRuntimeEvidence } from './evidence';

export const test = base.extend({
  page: async ({ page }, use, testInfo) => {
    const runtime = collectRuntimeEvidence(page);
    await use(page);
    await attachJson(testInfo, 'runtime-evidence', runtime);
  },
});

export { expect };
