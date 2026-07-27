<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('ppn:e2e-reset {--database=} {--yes}', function () {
    $actualDatabase = (string) DB::connection()->getDatabaseName();
    $requestedDatabase = trim((string) $this->option('database'));
    $allowedDatabases = array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env('E2E_ALLOWED_RESET_DATABASES', 'ppn_e2e'))
    )));

    if (! app()->environment('local')) {
        $this->error('BLOCKED: ppn:e2e-reset is available only when APP_ENV=local.');
        return self::FAILURE;
    }

    if (! filter_var(env('E2E_ALLOW_DATABASE_RESET', false), FILTER_VALIDATE_BOOL)) {
        $this->error('BLOCKED: set E2E_ALLOW_DATABASE_RESET=true explicitly.');
        return self::FAILURE;
    }

    if (! $this->option('yes')) {
        $this->error('BLOCKED: pass --yes to acknowledge that all business data will be deleted.');
        return self::FAILURE;
    }

    if ($requestedDatabase === '' || $requestedDatabase !== $actualDatabase) {
        $this->error("BLOCKED: --database must exactly match the connected database [{$actualDatabase}].");
        return self::FAILURE;
    }

    if (! in_array($actualDatabase, $allowedDatabases, true)) {
        $this->error('BLOCKED: database is not in E2E_ALLOWED_RESET_DATABASES.');
        return self::FAILURE;
    }

    $this->warn("Resetting local database [{$actualDatabase}] to the two-identity E2E baseline...");
    $exitCode = Artisan::call('migrate:fresh', [
        '--force' => true,
        '--seeder' => Database\Seeders\E2eBaselineSeeder::class,
    ]);
    $this->output->write(Artisan::output());

    if ($exitCode !== self::SUCCESS) {
        $this->error("migrate:fresh failed with exit code {$exitCode}.");
        return $exitCode;
    }

    $this->info(sprintf(
        'Baseline ready: users=%d, suppliers=%d, customers=%d, projects=%d.',
        DB::table('users')->count(),
        DB::table('suppliers')->count(),
        DB::table('customers')->count(),
        DB::table('projects')->count(),
    ));

    return self::SUCCESS;
})->purpose('DESTRUCTIVE local-only reset for the realistic Playwright journey');
