import { execFileSync } from 'node:child_process';
import path from 'node:path';

export default function resetRealisticLocalDatabase(): void {
  if (process.env.E2E_ALLOW_DATABASE_RESET !== '1') {
    throw new Error(
      'Realistic E2E is destructive. Set E2E_ALLOW_DATABASE_RESET=1 explicitly before running.',
    );
  }

  const database = process.env.E2E_RESET_DATABASE?.trim();
  if (!database) {
    throw new Error('Set E2E_RESET_DATABASE to the exact local database name before running.');
  }

  const phpBin = process.env.PHP_BIN ?? 'C:/xampp/php/php.exe';
  const apiDir = path.resolve(__dirname, '../../../ppn-api');

  execFileSync(
    phpBin,
    ['artisan', 'ppn:e2e-reset', `--database=${database}`, '--yes'],
    {
      cwd: apiDir,
      env: {
        ...process.env,
        E2E_ALLOW_DATABASE_RESET: 'true',
      },
      stdio: 'inherit',
    },
  );
}
