<?php

namespace Database\Seeders;

use App\Models\Supplier;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Minimal local-only baseline for the realistic Playwright journey.
 *
 * Identity 1: Admin authenticates through the users table.
 * Identity 2: Supplier exists in suppliers and receives a portal token only
 *             after the admin creates a quote request during the journey.
 */
class E2eBaselineSeeder extends Seeder
{
    public function run(): void
    {
        User::query()->create([
            'email' => env('E2E_ADMIN_EMAIL', 'admin@ppngreat.com'),
            'password' => Hash::make(env('E2E_ADMIN_PASSWORD', 'password123')),
            'full_name' => 'Playwright Super Admin',
            'role' => 'super_admin',
            'phone' => '0800000001',
            'is_active' => true,
        ]);

        Supplier::query()->create([
            'name' => env('E2E_SUPPLIER_NAME', 'Guangzhou E2E Supplier'),
            'category' => 'General Merchandise',
            'contact_person' => 'Playwright Supplier Contact',
            'phone' => '+86-000-000-0000',
            'wechat' => env('E2E_SUPPLIER_WECHAT', 'ppn_supplier_e2e'),
            'email' => env('E2E_SUPPLIER_USERNAME', 'supplier@ppngreat.local'),
            'location' => 'Guangzhou, China',
            'rating' => 5.0,
            'notes' => 'Local-only realistic E2E baseline identity',
            'is_active' => true,
        ]);
    }
}
