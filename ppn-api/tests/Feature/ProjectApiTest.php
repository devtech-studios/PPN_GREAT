<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Project;
use App\Models\ProductItem;
use App\Models\AdditionalRequest;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProjectApiTest extends TestCase
{
    use RefreshDatabase;

    private string $token;
    private Customer $customer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();

        // 1. เข้าสู่ระบบเพื่อรับ Token
        $loginResponse = $this->postJson('/api/auth/login', [
            'email' => 'admin@ppngreat.com',
            'password' => 'password123',
        ]);
        $this->token = $loginResponse->json('data.token');

        // 2. สร้างลูกค้าจำลองสำหรับโครงการ
        $this->customer = Customer::create([
            'name' => 'SCG Group',
            'type' => 'Enterprise',
            'tax_id' => '1111111111111'
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
     * ทดสอบการสร้างโปรเจกต์สำเร็จพร้อมการรันรหัสอัตโนมัติ (PPN-001, PPN-002)
     */
    public function test_create_projects_with_auto_code_generation(): void
    {
        // สร้างโปรเจกต์แรก
        $response1 = $this->postJson('/api/projects', [
            'customer_id' => $this->customer->id,
            'status' => 'Inquiry',
            'order_value' => 350000.00
        ], $this->getHeaders());

        $response1->assertStatus(201)
                  ->assertJsonPath('data.project_code', 'PPN-001');

        // สร้างโปรเจกต์สอง
        $response2 = $this->postJson('/api/projects', [
            'customer_id' => $this->customer->id,
            'status' => 'Inquiry',
            'order_value' => 120000.00
        ], $this->getHeaders());

        $response2->assertStatus(201)
                  ->assertJsonPath('data.project_code', 'PPN-002');
    }

    /**
     * ทดสอบการแก้ไขข้อมูลโครงการ (PUT /api/projects/{id})
     */
    public function test_update_project(): void
    {
        $project = Project::create([
            'project_code' => 'PPN-001',
            'customer_id' => $this->customer->id,
            'status' => 'Inquiry',
            'order_value' => 10000.00
        ]);

        $response = $this->putJson("/api/projects/{$project->id}", [
            'order_value' => 15000.00
        ], $this->getHeaders());

        $response->assertStatus(200)
                 ->assertJsonPath('data.order_value', '15000.00');
    }

    /**
     * ทดสอบเปลี่ยนสถานะโครงการและบันทึก Log อัตโนมัติ (PATCH /api/projects/{id}/status)
     */
    public function test_patch_project_status_and_activity_log(): void
    {
        $project = Project::create([
            'project_code' => 'PPN-001',
            'customer_id' => $this->customer->id,
            'status' => 'Inquiry'
        ]);

        // เปลี่ยนสเตตัสเป็น Sample
        $response = $this->patchJson("/api/projects/{$project->id}/status", [
            'status' => 'Sample'
        ], $this->getHeaders());

        $response->assertStatus(200)
                 ->assertJsonPath('data.status', 'Sample');

        // ตรวจสอบว่าระบบสร้าง Log อัปเดตสถานะอัตโนมัติ
        $this->assertDatabaseHas('activity_logs', [
            'project_id' => $project->id,
            'action' => 'เปลี่ยนสถานะ',
            'description' => 'เปลี่ยนสถานะจาก Inquiry เป็น Sample'
        ]);
    }

    /**
     * ทดสอบการเพิ่มและจัดการรายการสินค้าในโครงการ (POST/PUT products)
     */
    public function test_product_items_management(): void
    {
        $project = Project::create([
            'project_code' => 'PPN-001',
            'customer_id' => $this->customer->id,
            'status' => 'Inquiry'
        ]);

        // 1. เพิ่มสินค้า
        $responseAdd = $this->postJson("/api/projects/{$project->id}/products", [
            'name' => 'กระเป๋าผ้าแคนวาสสีธรรมชาติ',
            'qty' => 5000,
            'specs' => 'ขนาด 12x14 นิ้ว'
        ], $this->getHeaders());

        $responseAdd->assertStatus(201);
        $productId = $responseAdd->json('data.id');

        // 2. อัปเดตสินค้า
        $responseUpdate = $this->putJson("/api/projects/{$project->id}/products/{$productId}", [
            'qty' => 5500,
            'specs' => 'ขนาด 12x14 นิ้ว สกรีน 1 สี'
        ], $this->getHeaders());

        $responseUpdate->assertStatus(200)
                       ->assertJsonPath('data.qty', 5500);
    }

    /**
     * ทดสอบการเพิ่มความต้องการเพิ่มเติม (POST /api/projects/{id}/additional-requests)
     */
    public function test_add_additional_request(): void
    {
        $project = Project::create([
            'project_code' => 'PPN-001',
            'customer_id' => $this->customer->id,
            'status' => 'Inquiry'
        ]);

        $response = $this->postJson("/api/projects/{$project->id}/additional-requests", [
            'description' => 'ขอรับตัวอย่างเนื้อผ้าจริง',
            'cost' => 500.00
        ], $this->getHeaders());

        $response->assertStatus(201);
        $this->assertDatabaseHas('additional_requests', [
            'project_id' => $project->id,
            'description' => 'ขอรับตัวอย่างเนื้อผ้าจริง',
            'cost' => 500.00
        ]);
    }

    /**
     * ทดสอบการดึงข้อมูลประวัติกิจกรรม (GET /api/projects/{id}/logs)
     */
    public function test_get_project_activity_logs(): void
    {
        $project = Project::create([
            'project_code' => 'PPN-001',
            'customer_id' => $this->customer->id,
            'status' => 'Inquiry'
        ]);

        // สร้าง Log ตัวแรกด้วยการจำลอง
        \App\Models\ActivityLog::create([
            'user_id' => 1,
            'project_id' => $project->id,
            'action' => 'สร้าง Project',
            'description' => 'สร้างโปรเจกต์ใหม่'
        ]);

        // อัปเดตข้อมูลเพื่อสร้าง Log
        $this->patchJson("/api/projects/{$project->id}/status", [
            'status' => 'Sample'
        ], $this->getHeaders());

        $response = $this->getJson("/api/projects/{$project->id}/logs", $this->getHeaders());

        $response->assertStatus(200)
                 ->assertJsonCount(2, 'data') // 1 จากการสร้างโปรเจกต์ และ 1 จากการเปลี่ยนสเตตัส
                 ->assertJsonPath('data.0.action', 'เปลี่ยนสถานะ');
    }
}
