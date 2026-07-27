<?php

namespace Database\Seeders;

use App\Models\Supplier;
use App\Models\Project;
use App\Models\ProductItem;
use App\Models\QuoteRequest;
use App\Models\QuoteRequestRevision;
use App\Models\SupplierSample;
use App\Models\SupplierBill;
use Illuminate\Database\Seeder;
use Carbon\Carbon;

class GuangzhouSupplierSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Fetch or create Guangzhou Textile Corp supplier
        $supplier = Supplier::where('id', 2)->first();
        if (!$supplier) {
            $supplier = Supplier::updateOrCreate(
                ['name' => 'Guangzhou Textile Corp'],
                [
                    'category' => 'Premium Gifts',
                    'contact_person' => 'Mr. Li',
                    'phone' => '+86-138-8888-8888',
                    'wechat' => 'li_wechat_32',
                    'email' => 'li@guangzhou-textile-corp.com',
                    'location' => 'Guangzhou, China',
                    'rating' => 4.5
                ]
            );
        } else {
            // Ensure proper credentials for login
            $supplier->update([
                'wechat' => 'li_wechat_32',
                'email' => 'li@guangzhou-textile-corp.com',
            ]);
        }

        // 2. Fetch dummy projects (PPN-001, PPN-002, PPN-003)
        $project1 = Project::where('project_code', 'PPN-001')->first() ?? Project::first();
        $project2 = Project::where('project_code', 'PPN-002')->first() ?? Project::first();
        $project3 = Project::where('project_code', 'PPN-003')->first() ?? Project::first();

        // 3. Clear existing requests for this supplier to start fresh
        QuoteRequest::where('supplier_id', $supplier->id)->delete();
        SupplierSample::where('supplier_id', $supplier->id)->delete();
        // Delete only bills we will re-create, keeping general seed if needed
        SupplierBill::where('supplier_id', $supplier->id)->where('product_name', '!=', 'กระเป๋าผ้าแคนวาส Central Eco')->delete();

        // ==========================================
        // 4. Seed Quote Requests & Revisions
        // ==========================================

        // Quote 1: Pending (Waiting Link)
        $item1 = ProductItem::create([
            'project_id' => $project1->id,
            'name' => 'เสื้อโปโลพนักงาน AIS อุ่นใจ',
            'qty' => 3000,
            'specs' => 'ผ้า Micro TK, ปักโลโก้อุ่นใจที่หน้าอกและแขน'
        ]);

        QuoteRequest::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project1->id,
            'product_item_id' => $item1->id,
            'customer_name' => 'AIS (Advanced Info Service)',
            'product_name' => $item1->name,
            'qty' => 3000,
            'specs' => $item1->specs,
            'status' => 'Waiting Link',
            'session_token' => 'token_polo_ais'
        ]);

        // Quote 2: Needs Revision (Negotiation)
        $item2 = ProductItem::create([
            'project_id' => $project2->id,
            'name' => 'ถุงผ้าหูรูดลายพิเศษ Central',
            'qty' => 5000,
            'specs' => 'ผ้าสปันบอนด์ 80g, สกรีนสีแดง 1 ด้าน'
        ]);

        $q2 = QuoteRequest::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project2->id,
            'product_item_id' => $item2->id,
            'customer_name' => 'Central Group',
            'product_name' => $item2->name,
            'qty' => 5000,
            'specs' => $item2->specs,
            'status' => 'Needs Revision',
            'session_token' => 'token_spunbond_central',
            'quoted_price' => 1.50,
            'currency' => 'USD',
            'lead_time' => '30 Days',
            'moq' => 3000,
            'sample_price' => 0.00,
            'sample_lead_time' => '7 Days',
            'sample_condition' => 'Free',
            'remark' => 'ลดสุดๆ ได้แค่นี้ครับสำหรับยอด 5000 ชิ้น',
            'buyer_note' => 'ราคาเป้าหมายจัดซื้อจัดจ้างต้องการชิ้นละ USD 1.20 รบกวนโรงงานประเมินต้นทุนใหม่อีกรอบครับ'
        ]);

        // Seed Revisions for Quote 2
        QuoteRequestRevision::create([
            'quote_request_id' => $q2->id,
            'actor' => 'supplier',
            'quoted_price' => 1.50,
            'currency' => 'USD',
            'lead_time' => '30 Days',
            'moq' => 3000,
            'sample_price' => 0.00,
            'sample_lead_time' => '7 Days',
            'sample_condition' => 'Free',
            'remark' => 'ลดสุดๆ ได้แค่นี้ครับสำหรับยอด 5000 ชิ้น',
            'created_at' => Carbon::now()->subDays(2)
        ]);

        QuoteRequestRevision::create([
            'quote_request_id' => $q2->id,
            'actor' => 'buyer',
            'buyer_note' => 'ราคาเป้าหมายจัดซื้อจัดจ้างต้องการชิ้นละ USD 1.20 รบกวนโรงงานประเมินต้นทุนใหม่อีกรอบครับ',
            'created_at' => Carbon::now()->subDays(1)
        ]);

        // Quote 3: Price Filled
        $item3 = ProductItem::create([
            'project_id' => $project3->id,
            'name' => 'ซองหนังพรีเมียมกุญแจ Tesla',
            'qty' => 1000,
            'specs' => 'หนังเทียม PU ดำด้ายแดง พิมพ์ตราสัญลักษณ์ Tesla'
        ]);

        $q3 = QuoteRequest::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project3->id,
            'product_item_id' => $item3->id,
            'customer_name' => 'Tesla Thailand',
            'product_name' => $item3->name,
            'qty' => 1000,
            'specs' => $item3->specs,
            'status' => 'Price Filled',
            'session_token' => 'token_leather_tesla',
            'quoted_price' => 3.20,
            'currency' => 'USD',
            'lead_time' => '25 Days',
            'moq' => 1000,
            'sample_price' => 20.00,
            'sample_lead_time' => '5 Days',
            'sample_condition' => 'Refundable',
            'remark' => 'แถมกล่องบรรจุภัณฑ์มาตรฐานฟรี สกรีนโลโก้ที่กล่องได้ครับ'
        ]);

        QuoteRequestRevision::create([
            'quote_request_id' => $q3->id,
            'actor' => 'supplier',
            'quoted_price' => 3.20,
            'currency' => 'USD',
            'lead_time' => '25 Days',
            'moq' => 1000,
            'sample_price' => 20.00,
            'sample_lead_time' => '5 Days',
            'sample_condition' => 'Refundable',
            'remark' => 'แถมกล่องบรรจุภัณฑ์มาตรฐานฟรี สกรีนโลโก้ที่กล่องได้ครับ',
            'created_at' => Carbon::now()->subHours(5)
        ]);

        // Quote 4: Approved
        $item4 = ProductItem::create([
            'project_id' => $project3->id,
            'name' => 'หมวกแก๊ปพนักงาน Tesla',
            'qty' => 2000,
            'specs' => 'หมวกสีดำ ปักตรา Tesla สีขาวด้านหน้า'
        ]);

        $q4 = QuoteRequest::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project3->id,
            'product_item_id' => $item4->id,
            'customer_name' => 'Tesla Thailand',
            'product_name' => $item4->name,
            'qty' => 2000,
            'specs' => $item4->specs,
            'status' => 'Approved',
            'session_token' => 'token_cap_tesla',
            'quoted_price' => 2.00,
            'currency' => 'USD',
            'lead_time' => '15 Days',
            'moq' => 1000,
            'sample_price' => 10.00,
            'sample_lead_time' => '3 Days',
            'sample_condition' => 'Free',
            'remark' => 'งานปักเนี๊ยบพิเศษตามแบบลูกค้า'
        ]);

        QuoteRequestRevision::create([
            'quote_request_id' => $q4->id,
            'actor' => 'supplier',
            'quoted_price' => 2.00,
            'currency' => 'USD',
            'lead_time' => '15 Days',
            'moq' => 1000,
            'sample_price' => 10.00,
            'sample_lead_time' => '3 Days',
            'sample_condition' => 'Free',
            'remark' => 'งานปักเนี๊ยบพิเศษตามแบบลูกค้า',
            'created_at' => Carbon::now()->subDays(4)
        ]);


        // ==========================================
        // 5. Seed Supplier Samples (ใบขอสินค้าตัวอย่าง)
        // ==========================================

        // Sample 1: Waiting Supplier
        SupplierSample::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project3->id,
            'product_name' => $item4->name, // Hat
            'customer_name' => 'Tesla Thailand',
            'status' => 'Waiting Supplier',
            'specs' => 'ปักโลโก้สีขาวตาม AI ไฟล์ตัวอย่าง',
            'cost' => 'Free (ฟรี)',
            'expected_date' => Carbon::now()->addDays(6)->toDateString()
        ]);

        // Sample 2: Sample Sent
        SupplierSample::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project2->id,
            'product_name' => $item2->name, // Spunbond bag
            'customer_name' => 'Central Group',
            'status' => 'Sample Sent',
            'specs' => 'ผ้าสปันบอนด์ 80g สกรีนสีแดงตัวอย่าง',
            'cost' => 'Free (ฟรี)',
            'tracking_no' => 'SF-EXPRESS-776655',
            'expected_date' => Carbon::now()->addDays(2)->toDateString()
        ]);

        // Sample 3: Approved
        SupplierSample::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project1->id,
            'product_name' => $item1->name, // Polo
            'customer_name' => 'AIS (Advanced Info Service)',
            'status' => 'Approved',
            'specs' => 'เสื้อสีเขียวปักโลโก้อุ่นใจ',
            'cost' => 'TBD',
            'expected_date' => Carbon::now()->subDays(10)->toDateString()
        ]);


        // ==========================================
        // 6. Seed Supplier Bills
        // ==========================================

        // Bill 1: Paid Full Payment
        SupplierBill::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project1->id,
            'product_name' => $item1->name,
            'bill_type' => 'Full Payment',
            'amount' => 150000.00,
            'currency' => 'USD',
            'due_month' => Carbon::now()->subDays(10)->format('Y-m'),
            'status' => 'Paid',
            'pi_uploaded' => true,
            'pi_file_path' => '/uploads/bills/pi_ais_polo.pdf',
            'invoice_uploaded' => true,
            'invoice_file_path' => '/uploads/bills/inv_ais_polo.pdf',
            'paid_at' => Carbon::now()->subDays(10)
        ]);

        // Ensure we also log a new pending one for Spunbond Bag Balance
        SupplierBill::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project2->id,
            'product_name' => $item2->name,
            'bill_type' => 'Balance',
            'amount' => 12000.00,
            'currency' => 'USD',
            'due_month' => Carbon::now()->addDays(25)->format('Y-m'),
            'status' => 'Pending'
        ]);
    }
}
