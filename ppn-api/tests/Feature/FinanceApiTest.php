<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Project;
use App\Models\FinanceDocument;
use App\Models\Payment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;
use Carbon\Carbon;

class FinanceApiTest extends TestCase
{
    use RefreshDatabase;

    private string $token;
    private Project $project;
    private Customer $customer;

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

        // 2. สร้างข้อมูลตั้งต้น
        $this->customer = Customer::create([
            'name' => 'PTT Public Company',
            'type' => 'Enterprise',
            'tax_id' => '2222222222222'
        ]);

        $this->project = Project::create([
            'project_code' => 'PPN-001',
            'customer_id' => $this->customer->id,
            'status' => 'Inquiry',
            'credit_term' => '15 Days' // ⚠️ เพื่อใช้ทดสอบการคำนวณ Due Date
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
     * ทดสอบออกเอกสารการเงิน (Finance Document QU/PI/DP) อัตโนมัติ
     */
    public function test_create_finance_document_with_calculations(): void
    {
        $issueDate = Carbon::today()->toDateString();
        $expectedDueDate = Carbon::today()->addDays(15)->toDateString(); // เครดิตเทอม 15 วัน

        // 1. สร้างเอกสารใบเสนอราคา (QU)
        $response = $this->postJson('/api/finance/documents', [
            'project_id' => $this->project->id,
            'doc_type' => 'QU',
            'issue_date' => $issueDate,
            'notes' => 'ใบเสนอราคาพิเศษ SCG',
            'items' => [
                [
                    'item_name' => 'หมวกพรีเมียมสีแดง',
                    'qty' => 1000,
                    'unit_price' => 150.00
                ],
                [
                    'item_name' => 'กระเป๋าผ้าแคนวาส',
                    'qty' => 500,
                    'unit_price' => 200.00
                ]
            ]
        ], $this->getHeaders());

        // ผลรวมรวม: (1000 * 150) + (500 * 200) = 150,000 + 100,000 = 250,000.00
        $response->assertStatus(201)
                 ->assertJsonPath('data.doc_no', 'QU-' . date('Y') . '-0001')
                 ->assertJsonPath('data.total_amount', '250000.00')
                 ->assertJsonPath('data.due_date', "{$expectedDueDate}T00:00:00.000000Z")
                 ->assertJsonPath('data.status', 'Draft');

        $docId = $response->json('data.id');

        // 2. ปรับปรุงรายการสินค้าในเอกสาร
        $updateResponse = $this->putJson("/api/finance/documents/{$docId}", [
            'issue_date' => $issueDate,
            'items' => [
                [
                    'item_name' => 'หมวกพรีเมียมสีแดง',
                    'qty' => 1200, // อัปเดตจำนวน
                    'unit_price' => 150.00
                ]
            ]
        ], $this->getHeaders());

        // ยอดรวมใหม่: 1200 * 150 = 180,000.00
        $updateResponse->assertStatus(200)
                       ->assertJsonPath('data.total_amount', '180000.00')
                       ->assertJsonCount(1, 'data.items');

        // 3. เปลี่ยนสถานะเอกสาร
        $this->patchJson("/api/finance/documents/{$docId}/status", [
            'status' => 'Sent'
        ], $this->getHeaders())
             ->assertStatus(200)
             ->assertJsonPath('data.status', 'Sent');
    }

    /**
     * ทดสอบบันทึกการรับเงินจากลูกค้า (Payments) และระบบอนุมัติ (Verify)
     */
    public function test_payments_recording_and_verification_rules(): void
    {
        Storage::fake('local');

        // 1. สร้างเอกสาร PI ไว้รอจ่ายมัดจำ
        $doc = FinanceDocument::create([
            'doc_no' => 'PI-2026-0001',
            'project_id' => $this->project->id,
            'customer_id' => $this->customer->id,
            'doc_type' => 'PI',
            'status' => 'Sent',
            'total_amount' => 50000.00,
            'issue_date' => Carbon::today()->toDateString(),
            'due_date' => Carbon::today()->addDays(15)->toDateString()
        ]);

        // 2. ลูกค้าส่งสลิปโอนมัดจำเข้ามาในระบบ
        $response = $this->postJson('/api/finance/payments', [
            'project_id' => $this->project->id,
            'finance_document_id' => $doc->id,
            'payment_type' => 'Deposit',
            'amount' => 50000.00,
            'method' => 'Bank Transfer',
            'payment_date' => Carbon::today()->toDateString(),
            'notes' => 'โอนค่ามัดจำโครงการ 50%'
        ], $this->getHeaders());

        $response->assertStatus(201)
                 ->assertJsonPath('data.status', 'Pending Verification');

        $paymentId = $response->json('data.id');

        // 3. อัปโหลดรูปภาพสลิปหลักฐานโอนเงิน
        $file = UploadedFile::fake()->create('payment_slip.jpg', 500);
        $uploadResponse = $this->postJson("/api/finance/payments/{$paymentId}/upload-slip", [
            'file' => $file
        ], $this->getHeaders());
        $uploadResponse->assertStatus(200);
        $this->assertNotNull($uploadResponse->json('data.slip_file_path'));

        // 4. เจ้าหน้าที่ตรวจสอบยอดสลิปเงินเข้าจริง แล้วกดยืนยันการเงิน (Verify)
        $verifyResponse = $this->patchJson("/api/finance/payments/{$paymentId}/verify", [
            'status' => 'Confirmed'
        ], $this->getHeaders());

        $verifyResponse->assertStatus(200)
                       ->assertJsonPath('data.status', 'Confirmed');
        $this->assertNotNull($verifyResponse->json('data.verified_at'));

        // 5. ตรวจสอบว่าหลังจากจ่ายเงินและอนุมัติแล้ว:
        // - เอกสารใบแจ้งหนี้ (PI) ลิงก์ไว้จะถูกเปลี่ยนสเตตัสเป็น Paid โดยอัตโนมัติ
        $this->assertDatabaseHas('finance_documents', [
            'id' => $doc->id,
            'status' => 'Paid'
        ]);

        // - ตัว Project ที่ลิงก์ไว้จะถูกอัปเดตสเตตัส deposit_paid เป็น true โดยอัตโนมัติ
        $this->assertDatabaseHas('projects', [
            'id' => $this->project->id,
            'deposit_paid' => 1
        ]);
    }
}
