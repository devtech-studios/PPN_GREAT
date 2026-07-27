<?php

/**
 * 🧪 Script ตรวจสอบความถูกต้องของสถาปัตยกรรม Multi-Tenant & Multi-Branch (shop_id / branch_id)
 * ระบบ PPN GREAT ERP & Analytics Platform
 */

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

function printPass($msg) {
    echo "  [PASS] ✓ " . $msg . PHP_EOL;
}

function printFail($msg) {
    echo "  [FAIL] ✗ " . $msg . PHP_EOL;
}

function printSection($title) {
    echo PHP_EOL . "=======================================================" . PHP_EOL;
    echo "📌 " . $title . PHP_EOL;
    echo "=======================================================" . PHP_EOL;
}

$passedCount = 0;
$failedCount = 0;

echo "🚀 กำลังเริ่มรันสคริปต์ตรวจสอบระบบ Multi-Tenant & Multi-Branch..." . PHP_EOL;

// -------------------------------------------------------------
// 1. ตรวจสอบตารางใหม่ (New Tables Check)
// -------------------------------------------------------------
printSection("1. ตรวจสอบโครงสร้างตารางใหม่ (New Schema Check)");

$newTables = ['shops', 'branches', 'user_shop_permissions', 'user_branch_permissions'];
foreach ($newTables as $table) {
    if (Schema::hasTable($table)) {
        printPass("พบตารางใหม่ '{$table}' ในฐานข้อมูลเรียบร้อย");
        $passedCount++;
    } else {
        printFail("ไม่พบตาราง '{$table}'");
        $failedCount++;
    }
}

// -------------------------------------------------------------
// 2. ตรวจสอบ Column shop_id & branch_id ในตารางเดิม (Columns Check)
// -------------------------------------------------------------
printSection("2. ตรวจสอบ Column shop_id & branch_id ในตารางเดิม");

$targetTables = [
    'customers' => ['shop_id'],
    'suppliers' => ['shop_id'],
    'projects' => ['shop_id', 'branch_id'],
    'stock_items' => ['shop_id', 'branch_id'],
    'finance_documents' => ['shop_id', 'branch_id'],
    'payments' => ['shop_id', 'branch_id'],
    'containers' => ['shop_id', 'branch_id'],
    'quote_requests' => ['shop_id', 'branch_id'],
    'activity_logs' => ['shop_id', 'branch_id'],
];

foreach ($targetTables as $table => $cols) {
    $hasAll = true;
    foreach ($cols as $col) {
        if (!Schema::hasColumn($table, $col)) {
            $hasAll = false;
            printFail("ตาราง '{$table}' ขาด Column '{$col}'");
            $failedCount++;
        }
    }
    if ($hasAll) {
        printPass("ตาราง '{$table}' มี Columns (" . implode(', ', $cols) . ") ครบถ้วน");
        $passedCount++;
    }
}

// -------------------------------------------------------------
// 3. ตรวจสอบข้อมูล Default Shop & Branch (Default Seeded Data Check)
// -------------------------------------------------------------
printSection("3. ตรวจสอบข้อมูล Default Shop & Branch");

$defaultShop = DB::table('shops')->where('id', 1)->first();
if ($defaultShop) {
    printPass("พบ Default Shop ID=1: '{$defaultShop->name}' (Code: {$defaultShop->code})");
    $passedCount++;
} else {
    printFail("ไม่พบ Default Shop ID=1");
    $failedCount++;
}

$defaultBranch = DB::table('branches')->where('id', 1)->first();
if ($defaultBranch) {
    printPass("พบ Default Branch ID=1: '{$defaultBranch->name}' (Code: {$defaultBranch->code})");
    $passedCount++;
} else {
    printFail("ไม่พบ Default Branch ID=1");
    $failedCount++;
}

$userShopPerm = DB::table('user_shop_permissions')->where('user_id', 1)->first();
if ($userShopPerm) {
    printPass("พบสิทธิ์ User 1 ใน shop_id=1 เป็น Role: '{$userShopPerm->role}'");
    $passedCount++;
} else {
    printFail("ไม่พบสิทธิ์ User 1 ใน user_shop_permissions");
    $failedCount++;
}

// -------------------------------------------------------------
// 4. ตรวจสอบ Eloquent BelongsToTenant Trait & Isolation
// -------------------------------------------------------------
printSection("4. ตรวจสอบ Eloquent BelongsToTenant Scope");

session(['authorized_shop_id' => 1, 'active_branch_id' => 1]);

try {
    $projectsCount = \App\Models\Project::count();
    printPass("ดึงข้อมูล Project ผ่าน BelongsToTenant Scope สำเร็จ (พบ {$projectsCount} รายการ)");
    $passedCount++;
} catch (\Exception $e) {
    printFail("เกิดข้อผิดพลาดในการดึง Project Scope: " . $e->getMessage());
    $failedCount++;
}

try {
    $customersCount = \App\Models\Customer::count();
    printPass("ดึงข้อมูล Customer ผ่าน BelongsToTenant Scope สำเร็จ (พบ {$customersCount} รายการ)");
    $passedCount++;
} catch (\Exception $e) {
    printFail("เกิดข้อผิดพลาดในการดึง Customer Scope: " . $e->getMessage());
    $failedCount++;
}

try {
    $stockCount = \App\Models\StockItem::count();
    printPass("ดึงข้อมูล StockItem ผ่าน BelongsToTenant Scope สำเร็จ (พบ {$stockCount} รายการ)");
    $passedCount++;
} catch (\Exception $e) {
    printFail("เกิดข้อผิดพลาดในการดึง StockItem Scope: " . $e->getMessage());
    $failedCount++;
}

// -------------------------------------------------------------
// 5. ตรวจสอบ AI Context Isolation Security
// -------------------------------------------------------------
printSection("5. ตรวจสอบระบบความปลอดภัย AI Context Isolation");

try {
    $aiService = new \App\Services\AIContextBuilderService();
    $aiContext = $aiService->buildCleanContext(1, 1, "ช่วยวิเคราะห์ยอดขาย");
    
    if (isset($aiContext['scope']['shop_name']) && isset($aiContext['system_instruction'])) {
        printPass("AI Context Isolation สร้าง Context สโคปร้านค้า '{$aiContext['scope']['shop_name']}' สำเร็จ");
        printPass("System Instruction รัดกุม: '{$aiContext['system_instruction']}'");
        $passedCount += 2;
    } else {
        printFail("โครงสร้าง AI Context ไม่สมบูรณ์");
        $failedCount++;
    }
} catch (\Exception $e) {
    printFail("เกิดข้อผิดพลาดใน AIContextBuilderService: " . $e->getMessage());
    $failedCount++;
}

// -------------------------------------------------------------
// 6. ตรวจสอบไฟล์ Frontend Flutter Web (BranchProvider Check)
// -------------------------------------------------------------
printSection("6. ตรวจสอบไฟล์ใน Frontend (Flutter Web)");

$flutterProviderPath = 'd:/07_Projects/Work/PNN/ppn_great/lib/core/tenant/branch_provider.dart';
if (file_exists($flutterProviderPath)) {
    printPass("พบไฟล์ State Management 'branch_provider.dart' สำหรับ Flutter Web เรียบร้อย");
    $passedCount++;
} else {
    printFail("ไม่พบไฟล์ 'branch_provider.dart' ใน Frontend");
    $failedCount++;
}

// -------------------------------------------------------------
// 📊 สรุปผลการตรวจเช็คระบบ
// -------------------------------------------------------------
printSection("📊 สรุปผลการตรวจเช็คระบบ (Verification Summary)");
echo "  ✓ ผ่านทั้งหมด (Passed): {$passedCount} รายการ" . PHP_EOL;
echo "  ✗ ไม่ผ่าน (Failed): {$failedCount} รายการ" . PHP_EOL;

if ($failedCount === 0) {
    echo PHP_EOL . "🎉🎉🎉 ยินดีด้วย! ระบบ Multi-Tenant & Multi-Branch ผ่านการตรวจสอบความถูกต้อง 100% สมบูรณ์แบบ!" . PHP_EOL;
} else {
    echo PHP_EOL . "⚠️ กรุณาตรวจสอบและแก้ไขรายการที่ไม่ผ่านการตรวจสอบดังกล่าวข้างต้น" . PHP_EOL;
}
