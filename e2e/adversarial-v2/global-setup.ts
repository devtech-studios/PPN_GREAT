import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const frozenV1Hashes: Record<string, string> = {
  'playwright.realistic.config.ts': '32ECA79D8DD391B5F0CF3AEA41CFBD4DE1D97497F0897A5D99FA8A81BBEF5781',
  'scripts/run-realistic-e2e-video.ps1': '119B917FBF67F0902EAD8C4D11DD005A1EE534D70ECD30EC33C7C61AD098B838',
  'e2e/realistic/global-setup.ts': '5A049CAE199525E8A657CB7FF67658FC2EF066C680CA1EF117B8AF073283C607',
  'e2e/realistic/realistic-business-cycle.spec.ts': '5255D1E956E6AFF5D9D97FCAD8B6817A6CD181CBA4231BB5A048DC13BFA9E54D',
  'e2e/realistic/fulfillment-flow.ts': 'DAB68ADD8BDE5349DCA0497842016E5FD266B1DA0CD5EB05B680FBBA7A4C7C33',
  'e2e/realistic/fulfillment-resume.spec.ts': '3D1A3EB15700CC43672A870169BEAA055CA4427C3DCDFE30C96DCFFB845E269C',
};

function sha256(filePath: string): string {
  return createHash('sha256').update(fs.readFileSync(filePath)).digest('hex').toUpperCase();
}

export default function prepareAdversarialV2(): void {
  const rootDir = path.resolve(__dirname, '../..');
  for (const [relativePath, expectedHash] of Object.entries(frozenV1Hashes)) {
    const actualHash = sha256(path.resolve(rootDir, relativePath));
    if (actualHash !== expectedHash) {
      throw new Error(
        `V1-FREEZE-VIOLATION: ${relativePath}\nExpected ${expectedHash}\nReceived ${actualHash}`,
      );
    }
  }

  if (process.env.E2E_ALLOW_DATABASE_RESET !== '1') {
    throw new Error('V2 is destructive. Set E2E_ALLOW_DATABASE_RESET=1 explicitly.');
  }
  const database = process.env.E2E_RESET_DATABASE?.trim();
  if (database !== 'ppn_e2e') {
    throw new Error(`V2 only permits ppn_e2e; received ${database || '<empty>'}.`);
  }

  const phpBin = process.env.PHP_BIN ?? 'C:/xampp/php/php.exe';
  execFileSync(
    phpBin,
    ['artisan', 'ppn:e2e-reset', '--database=ppn_e2e', '--yes'],
    {
      cwd: path.resolve(rootDir, '../ppn-api'),
      env: {
        ...process.env,
        APP_ENV: 'local',
        DB_DATABASE: 'ppn_e2e',
        E2E_ALLOW_DATABASE_RESET: 'true',
        E2E_ALLOWED_RESET_DATABASES: 'ppn_e2e',
      },
      stdio: 'inherit',
    },
  );
}
