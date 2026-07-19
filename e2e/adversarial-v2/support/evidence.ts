import type { Page, TestInfo } from '@playwright/test';
import { showVideoCard, type VideoCardKind } from './pacing';

export type CaseClassification =
  | 'CONTRACT-CONFIRMED'
  | 'VALID-ALTERNATIVE'
  | 'POLICY-OBSERVATION'
  | 'EXPECTED-REJECTION'
  | 'ENFORCED-SEQUENCE';

export type CaseMetadata = {
  caseId: string;
  pairId: string;
  classification: CaseClassification;
  method: string;
  expected: string;
  preconditions: string[];
};

export function annotateCase(testInfo: TestInfo, metadata: CaseMetadata): void {
  testInfo.annotations.push(
    { type: 'case_id', description: metadata.caseId },
    { type: 'pair_id', description: metadata.pairId },
    { type: 'classification', description: metadata.classification },
    { type: 'method', description: metadata.method },
    { type: 'expected', description: metadata.expected },
  );
}

export async function attachJson(testInfo: TestInfo, name: string, value: unknown): Promise<void> {
  await testInfo.attach(name, {
    body: Buffer.from(JSON.stringify(value, null, 2), 'utf8'),
    contentType: 'application/json',
  });
}

export async function recordCard(
  page: Page,
  testInfo: TestInfo,
  kind: VideoCardKind,
  title: string,
  lines: string[],
  attachmentName: string,
): Promise<void> {
  await attachJson(testInfo, attachmentName, { kind, title, lines });
  await showVideoCard(page, kind, title, lines);
}

export function collectRuntimeEvidence(page: Page): {
  consoleErrors: string[];
  pageErrors: string[];
  requestFailures: string[];
} {
  const evidence = {
    consoleErrors: [] as string[],
    pageErrors: [] as string[],
    requestFailures: [] as string[],
  };
  page.on('console', message => {
    if (message.type() === 'error') evidence.consoleErrors.push(message.text());
  });
  page.on('pageerror', error => evidence.pageErrors.push(error.stack || error.message));
  page.on('requestfailed', request => {
    evidence.requestFailures.push(
      `${request.method()} ${request.url()} :: ${request.failure()?.errorText ?? 'unknown'}`,
    );
  });
  return evidence;
}

export function sanitizeEvidence(value: string): string {
  return value
    .replace(/Bearer\s+[A-Za-z0-9._~+\/-]+/gi, 'Bearer [REDACTED]')
    .replace(/("?(?:token|password|session_token)"?\s*[:=]\s*")([^"]+)(")/gi, '$1[REDACTED]$3');
}
