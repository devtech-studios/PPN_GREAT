<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::create([
            'email' => 'admin@ppngreat.com',
            'password' => bcrypt('password123'),
            'full_name' => 'Super Admin',
            'role' => 'super_admin',
            'phone' => '0812345678',
            'is_active' => true,
        ]);

        \App\Models\Warehouse::create([
            'name' => 'บางพลี',
            'location' => 'คลังสินค้าบางพลี จ.สมุทรปราการ',
            'is_active' => true,
        ]);

        \App\Models\Warehouse::create([
            'name' => 'รังสิต',
            'location' => 'คลังสินค้ารังสิต จ.ปทุมธานี',
            'is_active' => true,
        ]);
    }
}
