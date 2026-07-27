<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. สร้าง Default Shop (ID=1) และ Default Branch (ID=1) สำหรับข้อมูลที่มีอยู่เดิม
        $now = now();
        $shopId = DB::table('shops')->insertGetId([
            'name' => 'PPN GREAT Headquarter',
            'code' => 'HQ001',
            'owner_user_id' => 1,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $branchId = DB::table('branches')->insertGetId([
            'shop_id' => $shopId,
            'code' => 'HQ-BANGKOK',
            'name' => 'สำนักงานใหญ่ (HQ)',
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        // ให้สิทธิ์ User 1 เป็น Super Admin ใน Shop 1 / Branch 1
        DB::table('user_shop_permissions')->insertOrIgnore([
            'user_id' => 1,
            'shop_id' => $shopId,
            'role' => 'super_admin',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('user_branch_permissions')->insertOrIgnore([
            'user_id' => 1,
            'shop_id' => $shopId,
            'branch_id' => $branchId,
            'role' => 'branch_manager',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        // 2. รายชื่อตารางระดับ Shop เท่านั้น (Shop Level)
        $shopOnlyTables = ['customers', 'suppliers'];
        foreach ($shopOnlyTables as $tableName) {
            if (Schema::hasTable($tableName) && !Schema::hasColumn($tableName, 'shop_id')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->unsignedBigInteger('shop_id')->default(1)->after('id');
                    $table->index('shop_id');
                });
            }
        }

        // 3. รายชื่อตารางระดับ Shop และ Branch (Shop & Branch Level)
        $branchTables = [
            'projects',
            'product_items',
            'quote_requests',
            'supplier_bills',
            'supplier_samples',
            'client_samples',
            'artwork_logs',
            'finance_documents',
            'payments',
            'containers',
            'warehouses',
            'stock_items',
            'stock_movements',
            'dispatch_rounds',
            'delivery_items',
            'activity_logs',
        ];

        foreach ($branchTables as $tableName) {
            if (Schema::hasTable($tableName)) {
                Schema::table($tableName, function (Blueprint $table) use ($tableName) {
                    if (!Schema::hasColumn($tableName, 'shop_id')) {
                        $table->unsignedBigInteger('shop_id')->default(1)->after('id');
                    }
                    if (!Schema::hasColumn($tableName, 'branch_id')) {
                        $table->unsignedBigInteger('branch_id')->default(1)->after('shop_id');
                    }
                    $table->index(['shop_id', 'branch_id']);
                });
            }
        }

        // 4. อัปเดตตาราง users ให้มี default shop/branch
        if (Schema::hasTable('users')) {
            Schema::table('users', function (Blueprint $table) {
                if (!Schema::hasColumn('users', 'shop_id')) {
                    $table->unsignedBigInteger('shop_id')->default(1)->nullable()->after('id');
                }
                if (!Schema::hasColumn('users', 'default_branch_id')) {
                    $table->unsignedBigInteger('default_branch_id')->default(1)->nullable()->after('shop_id');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $branchTables = [
            'projects',
            'product_items',
            'quote_requests',
            'supplier_bills',
            'supplier_samples',
            'client_samples',
            'artwork_logs',
            'finance_documents',
            'payments',
            'containers',
            'warehouses',
            'stock_items',
            'stock_movements',
            'dispatch_rounds',
            'delivery_items',
            'activity_logs',
        ];

        foreach ($branchTables as $tableName) {
            if (Schema::hasTable($tableName)) {
                Schema::table($tableName, function (Blueprint $table) use ($tableName) {
                    if (Schema::hasColumn($tableName, 'branch_id')) {
                        $table->dropColumn('branch_id');
                    }
                    if (Schema::hasColumn($tableName, 'shop_id')) {
                        $table->dropColumn('shop_id');
                    }
                });
            }
        }

        $shopOnlyTables = ['customers', 'suppliers'];
        foreach ($shopOnlyTables as $tableName) {
            if (Schema::hasTable($tableName) && Schema::hasColumn($tableName, 'shop_id')) {
                Schema::table($tableName, function (Blueprint $table) {
                    $table->dropColumn('shop_id');
                });
            }
        }

        if (Schema::hasTable('users')) {
            Schema::table('users', function (Blueprint $table) {
                if (Schema::hasColumn('users', 'default_branch_id')) {
                    $table->dropColumn('default_branch_id');
                }
                if (Schema::hasColumn('users', 'shop_id')) {
                    $table->dropColumn('shop_id');
                }
            });
        }
    }
};
