<?php

namespace Tests\Feature;

use App\Models\Supplier;
use App\Models\QuoteRequest;
use App\Models\SupplierSample;
use App\Models\SupplierBill;
use App\Models\Customer;
use App\Models\Project;
use App\Models\ProductItem;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class SupplierApiTest extends TestCase
{
    use RefreshDatabase;

    private string $token;
    private Project $project;
    private ProductItem $productItem;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();

        // 1. รับ JWT Token
        $loginResponse = $this->postJson('/api/auth/login', [
            'email' => 'admin@ppngreat.com',
            'password' => 'password123',
        ]);
        $this->token = $loginResponse->json('data.token');

        // 2. สร้างข้อมูลทดสอบเบื้องต้น
        $customer = Customer::create([
            'name' => 'SCG Group',
            'type' => 'Enterprise',
            'tax_id' => '1111111111111'
        ]);

        $this->project = Project::create([
            'project_code' => 'PPN-001',
            'customer_id' => $customer->id,
            'status' => 'Inquiry',
            'credit_term' => '30 Days'
        ]);

        $this->productItem = ProductItem::create([
            'project_id' => $this->project->id,
            'name' => 'หมวก SCG พรีเมียม',
            'qty' => 1000
        ]);
    }

    private function getHeaders(): array
    {
        return [
            'Authorization' => "Bearer {$this->token}",
            'Accept' => 'application/json',
        ];
    }

    /**
     * ทดสอบ CRUD ซัพพลายเออร์สำเร็จ
     */
    public function test_supplier_crud(): void
    {
        // 1. Create
        $response = $this->postJson('/api/suppliers', [
            'name' => 'โรงงานกระเป๋าเจริญรุ่งเรือง',
            'category' => 'Bags',
            'contact_person' => 'คุณเฮง',
            'phone' => '089-999-8888',
            'email' => 'heng@bagsfactory.com',
            'rating' => 4.5
        ], $this->getHeaders());

        $response->assertStatus(201)
                 ->assertJsonPath('data.name', 'โรงงานกระเป๋าเจริญรุ่งเรือง');

        $supplierId = $response->json('data.id');

        // 2. Read Detail
        $this->getJson("/api/suppliers/{$supplierId}", $this->getHeaders())
             ->assertStatus(200)
             ->assertJsonPath('data.category', 'Bags');

        // 3. Update
        $this->putJson("/api/suppliers/{$supplierId}", [
            'name' => 'โรงงานกระเป๋าเจริญรุ่งเรือง จำกัด',
            'category' => 'Premium Bags'
        ], $this->getHeaders())
             ->assertStatus(200)
             ->assertJsonPath('data.name', 'โรงงานกระเป๋าเจริญรุ่งเรือง จำกัด')
             ->assertJsonPath('data.category', 'Premium Bags');

        // 4. List & Search
        $this->getJson('/api/suppliers?search=เจริญรุ่งเรือง', $this->getHeaders())
             ->assertStatus(200)
             ->assertJsonCount(1, 'data');
    }

    /**
     * ทดสอบระบบใบเสนอราคาและ Self-Service Link ของซัพพลายเออร์
     */
    public function test_supplier_quote_request_and_self_service(): void
    {
        $supplier = Supplier::create(['name' => 'โรงงานหมวกแฟชั่น']);

        // 1. สร้าง Quote Request
        $response = $this->postJson("/api/suppliers/{$supplier->id}/quotes", [
            'project_id' => $this->project->id,
            'product_item_id' => $this->productItem->id,
            'product_name' => 'หมวก SCG พรีเมียม',
            'qty' => 1000,
            'specs' => 'ปักโลโก้ SCG ด้านหน้า'
        ], $this->getHeaders());

        $response->assertStatus(201)
                 ->assertJsonPath('data.status', 'Waiting Link');

        $quoteId = $response->json('data.id');

        // 2. ออกลิงก์เสนอราคาโรงงาน (Generate Link)
        $linkResponse = $this->postJson("/api/suppliers/{$supplier->id}/quotes/{$quoteId}/generate-link", [], $this->getHeaders());
        $linkResponse->assertStatus(200)
                     ->assertJsonPath('data.status', 'Link Sent');

        $token = $linkResponse->json('data.session_token');
        $this->assertNotNull($token);

        // 3. โรงงานป้อนราคาเสนอผ่านลิงก์สาธารณะ (Public fill price) - ไม่ใช้สิทธิ์ล็อกอิน (ป้อนทั้ง Mass และ Sample ตาม UI)
        $publicResponse = $this->putJson("/api/quotes/public/{$token}", [
            'quoted_price' => 75.50,
            'currency' => 'THB',
            'lead_time' => '15 วันหลังจบมัดจำ',
            'moq' => 500,
            'sample_price' => 15.00,
            'sample_lead_time' => '7 วัน',
            'sample_condition' => 'Refundable',
            'remark' => 'ราคาพิเศษโปรโมชั่นปีนี้'
        ]);

        $publicResponse->assertStatus(200)
                       ->assertJsonPath('data.status', 'Price Filled')
                       ->assertJsonPath('data.quoted_price', '75.50')
                       ->assertJsonPath('data.sample_price', '15.00')
                       ->assertJsonPath('data.sample_condition', 'Refundable');

        // 4. ผู้จัดซื้อขอกลับไปแก้ไขราคาเสนอใหม่ (PATCH Needs Revision + buyer_note)
        $this->patchJson("/api/suppliers/{$supplier->id}/quotes/{$quoteId}/status", [
            'status' => 'Needs Revision',
            'buyer_note' => 'ขอราคาที่ $11.00 เพื่อแข่งขันกับเจ้าอื่นได้'
        ], $this->getHeaders())
             ->assertStatus(200)
             ->assertJsonPath('data.status', 'Needs Revision')
             ->assertJsonPath('data.buyer_note', 'ขอราคาที่ $11.00 เพื่อแข่งขันกับเจ้าอื่นได้');

        // 5. ตรวจสอบว่าหลังจากทำเสนอราคาสำเร็จ Token จะใช้ซ้ำไม่ได้อีก (ต้อง 404)
        $this->putJson("/api/quotes/public/{$token}", [
            'quoted_price' => 80.00,
            'currency' => 'THB',
            'lead_time' => '20 วัน',
            'moq' => 500
        ])->assertStatus(404);
    }

    /**
     * ทดสอบระบบจัดส่งตัวอย่างชิ้นงานโรงงาน (Supplier Samples)
     */
    public function test_supplier_samples(): void
    {
        $supplier = Supplier::create(['name' => 'โรงงานผลิตหมวก']);

        // 1. เพิ่มตัวอย่างชิ้นงานใหม่
        $response = $this->postJson("/api/suppliers/{$supplier->id}/samples", [
            'project_id' => $this->project->id,
            'product_name' => 'หมวก SCG พรีเมียมสีแดง',
            'specs' => 'ผ้าคอตตอนเนื้อนุ่ม',
            'cost' => '500 THB',
            'tracking_no' => 'TH0123456789'
        ], $this->getHeaders());

        $response->assertStatus(201)
                 ->assertJsonPath('data.status', 'Waiting Supplier');

        $sampleId = $response->json('data.id');

        // 2. ปรับสถานะเป็น Sample Sent
        $this->patchJson("/api/suppliers/{$supplier->id}/samples/{$sampleId}/status", [
            'status' => 'Sample Sent'
        ], $this->getHeaders())
             ->assertStatus(200)
             ->assertJsonPath('data.status', 'Sample Sent');
    }

    /**
     * ทดสอบยอดบิลค้างชำระโรงงานและการจ่ายมัดจำ (Supplier Bills)
     */
    public function test_supplier_bills_and_documents_upload(): void
    {
        Storage::fake('local');
        $supplier = Supplier::create(['name' => 'โรงงานสกรีนผ้า']);

        // 1. บันทึกยอดบิลขอเบิกเงินจากโรงงาน
        $response = $this->postJson("/api/suppliers/{$supplier->id}/bills", [
            'project_id' => $this->project->id,
            'product_name' => 'หมวก SCG พรีเมียม',
            'bill_type' => 'Deposit',
            'amount' => 25000.00,
            'currency' => 'THB',
            'due_month' => '2026-07'
        ], $this->getHeaders());

        $response->assertStatus(201)
                 ->assertJsonPath('data.status', 'Pending');

        $billId = $response->json('data.id');

        // 2. อัปโหลดเอกสารประกอบ PI
        $file = UploadedFile::fake()->create('proforma_invoice.pdf', 500);
        $this->postJson("/api/suppliers/{$supplier->id}/bills/{$billId}/upload", [
            'file_type' => 'pi',
            'file' => $file
        ], $this->getHeaders())
             ->assertStatus(200)
             ->assertJsonPath('data.pi_uploaded', true);

        // 3. จ่ายเงินให้ซัพพลายเออร์สำเร็จ
        $payResponse = $this->patchJson("/api/suppliers/{$supplier->id}/bills/{$billId}/pay", [], $this->getHeaders());
        $payResponse->assertStatus(200)
                    ->assertJsonPath('data.status', 'Paid');
        $this->assertNotNull($payResponse->json('data.paid_at'));
    }
}
