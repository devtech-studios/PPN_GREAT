<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Warehouse;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SuperAdminOnlySeeder extends Seeder
{
    public function run(): void
    {
        // 1. Super Admin User
        $admin = User::first();
        if (!$admin) {
            $admin = User::create([
                'email' => 'admin@ppngreat.com',
                'password' => bcrypt('password123'),
                'full_name' => 'Super Admin',
                'role' => 'super_admin',
                'phone' => '0812345678',
                'is_active' => true,
            ]);
        }

        // 2. Default Warehouse
        Warehouse::firstOrCreate([
            'name' => 'บางพลี',
        ], [
            'location' => 'คลังสินค้าบางพลี จ.สมุทรปราการ',
            'is_active' => true,
        ]);

        // 3. Default Shop Permissions if table exists
        if (Schema::hasTable('user_shop_permissions')) {
            DB::table('user_shop_permissions')->insertOrIgnore([
                'user_id' => $admin->id,
                'shop_id' => 1,
                'role' => 'super_admin',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        if (Schema::hasTable('user_branch_permissions')) {
            DB::table('user_branch_permissions')->insertOrIgnore([
                'user_id' => $admin->id,
                'shop_id' => 1,
                'branch_id' => 1,
                'role' => 'branch_manager',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }
}
