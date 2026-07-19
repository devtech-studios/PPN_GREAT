import { expect, type Locator, type Page } from '@playwright/test';

/**
 * Upload through the browser's real file chooser. This keeps the test on the
 * same path as a user clicking a Flutter "Choose File" button while avoiding
 * OS-dialog automation, which Playwright intentionally does not support.
 */
export async function uploadThroughFileChooser(
  page: Page,
  trigger: Locator,
  filePath: string,
): Promise<void> {
  await expect(trigger).toBeVisible();
  const [chooser] = await Promise.all([
    page.waitForEvent('filechooser'),
    trigger.click(),
  ]);
  await chooser.setFiles(filePath);
}
