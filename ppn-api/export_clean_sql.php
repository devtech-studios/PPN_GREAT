<?php

/**
 * 📦 สคริปต์สำหรับส่งออกไฟล์ .sql 2 เวอร์ชั่นที่มีเฉพาะข้อมูล Super Admin เท่านั้น
 */

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Artisan;

echo "🚀 กำลังเริ่มสร้างไฟล์ .sql (Super Admin Only)..." . PHP_EOL;

// 1. สร้างฐานข้อมูล ppn_clean_v1 สำหรับเวอร์ชั่นเดิมที่เคยขึ้น Hostatom
DB::statement("DROP DATABASE IF EXISTS ppn_clean_v1");
DB::statement("CREATE DATABASE ppn_clean_v1");

Config::set('database.connections.mysql.database', 'ppn_clean_v1');
DB::purge('mysql');
DB::reconnect('mysql');

// รัน Migrations เดิมของ v1 (ข้าม migration 2026_07_27)
$migrationFiles = [
    '0001_01_01_000000_create_users_table.php',
    '0001_01_01_000001_create_cache_table.php',
    '0001_01_01_000002_create_jobs_table.php',
    '2026_07_04_000001_create_customers_and_contacts_tables.php',
    '2026_07_04_000002_create_projects_and_products_tables.php',
    '2026_07_04_000003_create_suppliers_and_procurement_tables.php',
    '2026_07_04_000004_create_samples_and_artwork_tables.php',
    '2026_07_04_000005_create_finance_and_payments_tables.php',
    '2026_07_04_000006_create_logistics_and_inventory_tables.php',
    '2026_07_04_000007_create_activity_logs_table.php',
    '2026_07_15_141935_add_po_file_to_projects_table.php',
    '2026_07_15_141947_add_po_file_to_projects_table.php',
    '2026_07_15_160234_create_quote_request_revisions_table.php',
];

foreach ($migrationFiles as $file) {
    $path = database_path('migrations/' . $file);
    if (file_exists($path)) {
        $migration = require $path;
        $migration->up();
    }
}

// Seed ข้อมูลเฉพาะ Super Admin
$seeder = new \Database\Seeders\SuperAdminOnlySeeder();
$seeder->run();

// Dump ไฟล์ SQL เวอร์ชั่น v1 (Hostatom Plesk เดิม)
$dumpCmdV1 = "C:\\xampp\\mysql\\bin\\mysqldump.exe -u root ppn_clean_v1 > d:\\07_Projects\\Work\\PNN\\ppn_staging_v1_super_admin_only.sql";
exec($dumpCmdV1);
echo "  [PASS] ✓ ส่งออกไฟล์ v1 (Hostatom Plesk) สำเร็จ: d:\\07_Projects\\Work\\PNN\\ppn_staging_v1_super_admin_only.sql" . PHP_EOL;

// 2. สร้างฐานข้อมูล ppn_clean_multi_tenant สำหรับเวอร์ชั่นใหม่ที่มี shop_id / branch_id
DB::statement("DROP DATABASE IF EXISTS ppn_clean_multi_tenant");
DB::statement("CREATE DATABASE ppn_clean_multi_tenant");

Config::set('database.connections.mysql.database', 'ppn_clean_multi_tenant');
DB::purge('mysql');
DB::reconnect('mysql');

Artisan::call('migrate', ['--force' => true]);
$seeder->run();

$dumpCmdMT = "C:\\xampp\\mysql\\bin\\mysqldump.exe -u root ppn_clean_multi_tenant > d:\\07_Projects\\Work\\PNN\\ppn_staging_multi_tenant_super_admin_only.sql";
exec($dumpCmdMT);
echo "  [PASS] ✓ ส่งออกไฟล์ Multi-Tenant สำเร็จ: d:\\07_Projects\\Work\\PNN\\ppn_staging_multi_tenant_super_admin_only.sql" . PHP_EOL;

echo "🎉 สร้างไฟล์ SQL สำเร็จครบถ้วน!" . PHP_EOL;
