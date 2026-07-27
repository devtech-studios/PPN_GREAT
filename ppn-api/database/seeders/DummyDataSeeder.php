<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Customer;
use App\Models\ContactPerson;
use App\Models\ShippingAddress;
use App\Models\Project;
use App\Models\ProductItem;
use App\Models\Supplier;
use App\Models\QuoteRequest;
use App\Models\SupplierSample;
use App\Models\SupplierBill;
use App\Models\ClientSample;
use App\Models\ArtworkLog;
use App\Models\FinanceDocument;
use App\Models\FinanceDocItem;
use App\Models\Payment;
use App\Models\Container;
use App\Models\Warehouse;
use App\Models\StockItem;
use App\Models\StockMovement;
use App\Models\DispatchRound;
use App\Models\DeliveryItem;
use App\Models\ActivityLog;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Carbon\Carbon;

class DummyDataSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Fetch admin user
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

        // Seed default shop permissions for Admin
        \Illuminate\Support\Facades\DB::table('user_shop_permissions')->insertOrIgnore([
            'user_id' => $admin->id,
            'shop_id' => 1,
            'role' => 'super_admin',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        \Illuminate\Support\Facades\DB::table('user_branch_permissions')->insertOrIgnore([
            'user_id' => $admin->id,
            'shop_id' => 1,
            'branch_id' => 1,
            'role' => 'branch_manager',
            'created_at' => now(),
            'updated_at' => now(),
        ]);


        // Fetch default warehouses
        $warehouseBangplee = Warehouse::where('name', 'บางพลี')->first() ?? Warehouse::create([
            'name' => 'บางพลี',
            'location' => 'คลังสินค้าบางพลี จ.สมุทรปราการ',
            'is_active' => true,
        ]);

        $warehouseRangsit = Warehouse::where('name', 'รังสิต')->first() ?? Warehouse::create([
            'name' => 'รังสิต',
            'location' => 'คลังสินค้ารังสิต จ.ปทุมธานี',
            'is_active' => true,
        ]);

        // 2. Create 5 Customers
        $customerNames = [
            'AIS (Advanced Info Service)',
            'Central Group',
            'Siam Piwat',
            'Lion (Thailand)',
            'Tesla Thailand'
        ];

        $customers = [];
        foreach ($customerNames as $name) {
            $customer = Customer::create([
                'name' => $name,
                'type' => 'Enterprise',
                'status' => 'Active',
                'tax_id' => '123456789012' . rand(0, 9),
                'branch' => 'สำนักงานใหญ่',
                'industry' => 'Retail & Telecom',
                'lead_source' => 'Direct Contact',
                'billing_address' => '123 ถ.พหลโยธิน แขวงสามเสนใน เขตพญาไท กรุงเทพฯ',
                'created_by' => $admin->id
            ]);

            // Add contact person
            ContactPerson::create([
                'customer_id' => $customer->id,
                'name' => 'คุณนฤมล ใจดี',
                'role' => 'Marketing Manager',
                'phone' => '089-999-8888',
                'email' => 'contact@' . Str::slug($name) . '.com',
                'is_primary' => true
            ]);

            // Add shipping address
            ShippingAddress::create([
                'customer_id' => $customer->id,
                'label' => 'คลังสินค้ากลางบางนา',
                'address' => '99/9 หมู่ 4 ถ.บางนา-ตราด กม.18 จ.สมุทรปราการ',
                'is_default' => true
            ]);

            $customers[] = $customer;
        }

        // 3. Create Suppliers
        $suppliers = [];
        $supplierNames = ['Yiwu Premium Gifts', 'Guangzhou Textile Corp', 'Shenzhen Cables Factory'];
        foreach ($supplierNames as $sName) {
            $suppliers[] = Supplier::create([
                'name' => $sName,
                'category' => 'Premium Gifts',
                'contact_person' => 'Mr. Li',
                'phone' => '+86-138-8888-8888',
                'wechat' => 'li_wechat_' . rand(1, 99),
                'email' => 'li@' . Str::slug($sName) . '.com',
                'location' => 'Guangzhou, China',
                'rating' => 4.5
            ]);
        }

        // 4. Create Projects
        // Project 1: AIS Umbrellas (Delivered & Paid!)
        $project1 = Project::create([
            'project_code' => 'PPN-001',
            'customer_id' => $customers[0]->id,
            'status' => 'Delivered',
            'step' => 5,
            'priority' => 1,
            'is_repeat_order' => false,
            'target_date' => Carbon::now()->subDays(5)->toDateString(),
            'order_value' => 450000.00,
            'usage_location' => 'กรุงเทพฯ',
            'credit_term' => '30 Days',
            'deposit_paid' => true,
            'balance_paid' => true,
            'ocpb_passed' => true,
            'shipping_mark_ready' => true,
            'created_by' => $admin->id
        ]);

        $item1 = ProductItem::create([
            'project_id' => $project1->id,
            'name' => 'ร่มพับ 2 ตอน พรีเมียม AIS',
            'qty' => 3000,
            'specs' => 'สีเขียวสลับขาว, โลโก้อุ่นใจ 2 จุด, ขนาด 21 นิ้ว'
        ]);

        // Record Payments for Project 1 (Deposit 50% & Balance 50%)
        $docQu1 = FinanceDocument::create([
            'doc_no' => 'QU-' . Carbon::now()->format('Y') . '-0001',
            'project_id' => $project1->id,
            'customer_id' => $customers[0]->id,
            'doc_type' => 'QU',
            'status' => 'Paid',
            'total_amount' => 450000.00,
            'credit_term' => '30 Days',
            'issue_date' => Carbon::now()->subDays(45)->toDateString(),
            'due_date' => Carbon::now()->subDays(15)->toDateString(),
            'created_by' => $admin->id
        ]);

        FinanceDocItem::create([
            'finance_document_id' => $docQu1->id,
            'item_name' => $item1->name,
            'qty' => 3000,
            'unit_price' => 150.00,
            'total_price' => 450000.00
        ]);

        $paymentDep1 = Payment::create([
            'project_id' => $project1->id,
            'finance_document_id' => $docQu1->id,
            'customer_id' => $customers[0]->id,
            'payment_type' => 'Deposit',
            'amount' => 225000.00,
            'method' => 'Bank Transfer',
            'payment_date' => Carbon::now()->subDays(40)->toDateString(),
            'status' => 'Confirmed',
            'verified_by' => $admin->id,
            'verified_at' => Carbon::now()->subDays(40)
        ]);

        $paymentBal1 = Payment::create([
            'project_id' => $project1->id,
            'finance_document_id' => $docQu1->id,
            'customer_id' => $customers[0]->id,
            'payment_type' => 'Balance',
            'amount' => 225000.00,
            'method' => 'Bank Transfer',
            'payment_date' => Carbon::now()->subDays(5)->toDateString(),
            'status' => 'Confirmed',
            'verified_by' => $admin->id,
            'verified_at' => Carbon::now()->subDays(5)
        ]);

        // Paid Supplier Bills for Project 1 (COGS)
        SupplierBill::create([
            'supplier_id' => $suppliers[0]->id,
            'project_id' => $project1->id,
            'product_name' => $item1->name,
            'bill_type' => 'Full Payment',
            'amount' => 300000.00,
            'due_month' => Carbon::now()->subDays(30)->format('Y-m'),
            'status' => 'Paid',
            'paid_at' => Carbon::now()->subDays(30)
        ]);


        // Project 2: Central Group Canvas Bags (Production status)
        $project2 = Project::create([
            'project_code' => 'PPN-002',
            'customer_id' => $customers[1]->id,
            'status' => 'Production',
            'step' => 3,
            'priority' => 2,
            'is_repeat_order' => true,
            'target_date' => Carbon::now()->addDays(25)->toDateString(),
            'order_value' => 600000.00,
            'usage_location' => 'กรุงเทพฯ',
            'credit_term' => '30 Days',
            'deposit_paid' => true,
            'balance_paid' => false,
            'ocpb_passed' => false,
            'shipping_mark_ready' => false,
            'created_by' => $admin->id
        ]);

        $item2 = ProductItem::create([
            'project_id' => $project2->id,
            'name' => 'กระเป๋าผ้าแคนวาส Central Eco',
            'qty' => 5000,
            'specs' => 'ผ้าหนา 14 ออนซ์, ขนาด 12x14 นิ้ว, พิมพ์ลายสิ่งแวดล้อม'
        ]);

        // PI document for Project 2 (Deposit Paid)
        $docPi2 = FinanceDocument::create([
            'doc_no' => 'PI-' . Carbon::now()->format('Y') . '-0002',
            'project_id' => $project2->id,
            'customer_id' => $customers[1]->id,
            'doc_type' => 'PI',
            'status' => 'Paid',
            'total_amount' => 300000.00, // Deposit amount
            'credit_term' => '30 Days',
            'issue_date' => Carbon::now()->subDays(20)->toDateString(),
            'due_date' => Carbon::now()->addDays(10)->toDateString(),
            'created_by' => $admin->id
        ]);

        FinanceDocItem::create([
            'finance_document_id' => $docPi2->id,
            'item_name' => $item2->name,
            'qty' => 5000,
            'unit_price' => 60.00,
            'total_price' => 300000.00
        ]);

        Payment::create([
            'project_id' => $project2->id,
            'finance_document_id' => $docPi2->id,
            'customer_id' => $customers[1]->id,
            'payment_type' => 'Deposit',
            'amount' => 300000.00,
            'method' => 'Bank Transfer',
            'payment_date' => Carbon::now()->subDays(18)->toDateString(),
            'status' => 'Confirmed',
            'verified_by' => $admin->id,
            'verified_at' => Carbon::now()->subDays(18)
        ]);

        // Supplier bill pending for Project 2
        SupplierBill::create([
            'supplier_id' => $suppliers[1]->id,
            'project_id' => $project2->id,
            'product_name' => $item2->name,
            'bill_type' => 'Deposit',
            'amount' => 200000.00,
            'due_month' => Carbon::now()->addDays(5)->format('Y-m'),
            'status' => 'Pending'
        ]);


        // Project 3: Tesla EV Chargers (Inquiry status, waiting quotes)
        $project3 = Project::create([
            'project_code' => 'PPN-003',
            'customer_id' => $customers[4]->id,
            'status' => 'Inquiry',
            'step' => 0,
            'priority' => 2,
            'is_repeat_order' => false,
            'target_date' => Carbon::now()->addDays(60)->toDateString(),
            'order_value' => 800000.00,
            'usage_location' => 'กรุงเทพฯ',
            'credit_term' => 'Advance',
            'deposit_paid' => false,
            'balance_paid' => false,
            'created_by' => $admin->id
        ]);

        $item3 = ProductItem::create([
            'project_id' => $project3->id,
            'name' => ' EV Charger Case PPN Premium',
            'qty' => 1000,
            'specs' => 'กล่องเคสชาร์จรถไฟฟ้ารองรับตราสัญลักษณ์ Tesla'
        ]);

        // Quote request waiting for Yiwu Gifts
        QuoteRequest::create([
            'supplier_id' => $suppliers[0]->id,
            'project_id' => $project3->id,
            'product_item_id' => $item3->id,
            'customer_name' => $customers[4]->name,
            'product_name' => $item3->name,
            'qty' => 1000,
            'specs' => $item3->specs,
            'status' => 'Waiting Link',
            'session_token' => 'token_' . Str::random(10)
        ]);


        // 5. Seed stock in central warehouse (Warehouse 1: Bangplee)
        // Add 500 cups in stock
        $stockCup = StockItem::create([
            'warehouse_id' => $warehouseBangplee->id,
            'product_item_id' => $item1->id,
            'project_id' => $project1->id,
            'qty_in_stock' => 500,
            'qty_reserved' => 0,
            'location_in_warehouse' => 'Rack B-1'
        ]);

        StockMovement::create([
            'stock_item_id' => $stockCup->id,
            'movement_type' => 'IN',
            'qty' => 500,
            'reference_type' => 'Manual',
            'reference_id' => null,
            'notes' => 'ตั้งค่าสต็อกสินค้าคงคลังเบื้องต้น',
            'created_by' => $admin->id
        ]);

        // 6. Create some Activity Logs
        ActivityLog::create([
            'user_id' => $admin->id,
            'project_id' => $project1->id,
            'action' => 'จัดส่งสำเร็จ',
            'description' => "จัดส่งสินค้าให้ลูกค้า AIS รหัส {$project1->project_code} เรียบร้อยแล้ว",
            'entity_type' => 'project',
            'entity_id' => $project1->id
        ]);

        ActivityLog::create([
            'user_id' => $admin->id,
            'project_id' => $project2->id,
            'action' => 'ยืนยันใบแจ้งหนี้ PI',
            'description' => "ลูกค้ายืนยันยอดมัดจำใบ PI-2026-0002 ของ {$project2->project_code}",
            'entity_type' => 'project',
            'entity_id' => $project2->id
        ]);
    }
}
