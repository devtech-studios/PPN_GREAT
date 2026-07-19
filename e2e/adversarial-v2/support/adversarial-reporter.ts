import fs from 'node:fs';
import path from 'node:path';
import type { FullConfig, FullResult, Reporter, Suite, TestCase, TestResult } from '@playwright/test/reporter';
import { sanitizeEvidence } from './evidence';

type Finding = {
  caseId: string;
  pairId: string;
  title: string;
  expectedClassification: string;
  status: string;
  durationMs: number;
  errors: string[];
  attachments: Array<{ name: string; path?: string; contentType: string }>;
};

function annotation(test: TestCase, type: string): string {
  return test.annotations.find(item => item.type === type)?.description ?? '';
}

function idFromTitle(test: TestCase): string {
  return test.title.match(/\bPAIR-[A-Z]+-\d{3}(?:-[A-Z])?\b/)?.[0] ?? '';
}

export default class AdversarialReporter implements Reporter {
  private rootDir = process.cwd();
  private findings: Finding[] = [];

  onBegin(config: FullConfig, _suite: Suite): void {
    this.rootDir = config.rootDir;
  }

  onTestEnd(test: TestCase, result: TestResult): void {
    const titleCaseId = idFromTitle(test);
    this.findings.push({
      caseId: annotation(test, 'case_id') || titleCaseId || 'UNASSIGNED',
      pairId: annotation(test, 'pair_id') || titleCaseId.replace(/-[A-Z]$/, '') || 'UNPAIRED',
      title: test.titlePath().slice(1).join(' › '),
      expectedClassification: annotation(test, 'classification') || 'UNCLASSIFIED',
      status: result.status,
      durationMs: result.duration,
      errors: result.errors.map(error => sanitizeEvidence(error.stack || error.message || String(error))),
      attachments: result.attachments.map(item => ({
        name: item.name,
        path: item.path ? path.relative(process.cwd(), item.path) : undefined,
        contentType: item.contentType,
      })),
    });
  }

  onEnd(result: FullResult): void {
    const runSlug = process.env.E2E_ADVERSARIAL_PACK?.trim().toLowerCase() || 'all';
    const outputDir = path.resolve(process.cwd(), `test-results-adversarial-v2-${runSlug}`);
    fs.mkdirSync(outputDir, { recursive: true });
    const payload = {
      generatedAt: new Date().toISOString(),
      overallStatus: result.status,
      rootDir: this.rootDir,
      counts: {
        total: this.findings.length,
        passed: this.findings.filter(item => item.status === 'passed').length,
        failed: this.findings.filter(item => item.status === 'failed').length,
        skipped: this.findings.filter(item => item.status === 'skipped').length,
        unpaired: this.findings.filter(item => item.pairId === 'UNPAIRED').length,
      },
      findings: this.findings,
    };
    fs.writeFileSync(path.join(outputDir, 'adversarial-findings.json'), JSON.stringify(payload, null, 2), 'utf8');
    const rows = this.findings.map(item =>
      `| ${item.caseId} | ${item.pairId} | ${item.status} | ${item.expectedClassification} | ${item.title.replace(/\|/g, '\\|')} |`,
    );
    const markdown = [
      '# Adversarial V2 Findings — ผลการทดสอบเคสผิดปกติ', '',
      `Overall Playwright status: \`${result.status}\``, '',
      `Total ${payload.counts.total}; Passed ${payload.counts.passed}; Failed ${payload.counts.failed}; Skipped ${payload.counts.skipped}; Unpaired ${payload.counts.unpaired}`, '',
      '| Case | Pair | Result | Expected classification | Test |',
      '|---|---|---|---|---|', ...rows, '',
      'A failed Playwright assertion is not automatically classified as a product bug. Review its trace, response and database evidence.', '',
    ].join('\n');
    fs.writeFileSync(path.join(outputDir, 'adversarial-findings.md'), markdown, 'utf8');
  }
}
