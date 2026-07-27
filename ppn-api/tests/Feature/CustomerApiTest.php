<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\ContactPerson;
use App\Models\ShippingAddress;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CustomerApiTest extends TestCase
{
    use RefreshDatabase;

    private string $token;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();

        // รับ Token สำหรับยิงทดสอบ API ที่ติดสิทธิ์
        $loginResponse = $this->postJson('/api/auth/login', [
            'email' => 'admin@ppngreat.com',
            'password' => 'password123',
        ]);
        $this->token = $loginResponse->json('data.token');
    }

    private function getHeaders(): array
    {
        return [
            'Authorization' => "Bearer {$this->token}",
            'Accept' => 'application/json',
        ];
    }

    /**
     * ทดสอบสร้างลูกค้าใหม่สำเร็จ (POST /api/customers)
     */
    public function test_create_customer_successful(): void
    {
        $response = $this->postJson('/api/customers', [
            'name' => 'บริษัท ปูนซิเมนต์ไทย จำกัด (มหาชน)',
            'type' => 'Enterprise',
            'tax_id' => '0105556000123',
            'industry' => 'Construction',
            'phone' => '02-586-3333',
            'email' => 'info@scg.com',
        ], $this->getHeaders());

        $response->assertStatus(201)
                 ->assertJsonPath('success', true)
                 ->assertJsonPath('data.name', 'บริษัท ปูนซิเมนต์ไทย จำกัด (มหาชน)');

        $this->assertDatabaseHas('customers', [
            'tax_id' => '0105556000123'
        ]);
    }

    /**
     * ทดสอบการดึงรายการลูกค้าสำเร็จ (GET /api/customers)
     */
    public function test_get_customers_list(): void
    {
        // สร้างลูกค้าจำลอง 2 ราย
        Customer::create([
            'name' => 'SCG Chemicals',
            'type' => 'Enterprise',
            'tax_id' => '1111111111111'
        ]);
        Customer::create([
            'name' => 'PTT Public Company',
            'type' => 'Enterprise',
            'tax_id' => '2222222222222'
        ]);

        $response = $this->getJson('/api/customers?search=SCG', $this->getHeaders());

        $response->assertStatus(200)
                 ->assertJsonPath('success', true)
                 ->assertJsonCount(1, 'data')
                 ->assertJsonPath('data.0.name', 'SCG Chemicals');
    }

    /**
     * ทดสอบอัปเดตข้อมูลลูกค้าสำเร็จ (PUT /api/customers/{id})
     */
    public function test_update_customer(): void
    {
        $customer = Customer::create([
            'name' => 'SCG Group',
            'type' => 'Enterprise',
            'tax_id' => '1111111111111'
        ]);

        $response = $this->putJson("/api/customers/{$customer->id}", [
            'name' => 'SCG Group PLC',
            'type' => 'Enterprise',
            'industry' => 'Construction'
        ], $this->getHeaders());

        $response->assertStatus(200)
                 ->assertJsonPath('data.name', 'SCG Group PLC')
                 ->assertJsonPath('data.industry', 'Construction');
    }

    /**
     * ทดสอบจัดการผู้ติดต่อหลักของลูกค้า (POST/PUT/DELETE contacts)
     */
    public function test_contact_person_operations(): void
    {
        $customer = Customer::create([
            'name' => 'SCG Group',
            'type' => 'Enterprise',
            'tax_id' => '1111111111111'
        ]);

        // 1. เพิ่มผู้ติดต่อคนแรกเป็นผู้ติดต่อหลัก (Primary)
        $responseAdd = $this->postJson("/api/customers/{$customer->id}/contacts", [
            'name' => 'คุณสมชาย รักชาติ',
            'position' => 'ผู้จัดการฝ่ายจัดซื้อ',
            'phone' => '081-234-5678',
            'is_primary' => true
        ], $this->getHeaders());

        $responseAdd->assertStatus(201);
        $contactId = $responseAdd->json('data.id');

        $this->assertDatabaseHas('contact_persons', [
            'id' => $contactId,
            'is_primary' => 1
        ]);

        // 2. อัปเดตข้อมูลผู้ติดต่อ
        $responseUpdate = $this->putJson("/api/customers/{$customer->id}/contacts/{$contactId}", [
            'name' => 'คุณสมชาย รักชาติไทย',
            'position' => 'ผู้อำนวยการจัดซื้อ'
        ], $this->getHeaders());

        $responseUpdate->assertStatus(200)
                       ->assertJsonPath('data.name', 'คุณสมชาย รักชาติไทย');

        // 3. ลบผู้ติดต่อ
        $responseDelete = $this->deleteJson("/api/customers/{$customer->id}/contacts/{$contactId}", [], $this->getHeaders());
        $responseDelete->assertStatus(200);

        $this->assertDatabaseMissing('contact_persons', [
            'id' => $contactId
        ]);
    }

    /**
     * ทดสอบการเพิ่มที่อยู่จัดส่งสินค้า (POST /api/customers/{id}/addresses)
     */
    public function test_add_shipping_address(): void
    {
        $customer = Customer::create([
            'name' => 'SCG Group',
            'type' => 'Enterprise',
            'tax_id' => '1111111111111'
        ]);

        $response = $this->postJson("/api/customers/{$customer->id}/addresses", [
            'label' => 'คลังสินค้า SCG 1',
            'address' => '1 ถ.ปูนซิเมนต์ไทย แขวงบางซื่อ เขตบางซื่อ กรุงเทพฯ 10800',
            'is_default' => true
        ], $this->getHeaders());

        $response->assertStatus(201);
        $this->assertDatabaseHas('shipping_addresses', [
            'customer_id' => $customer->id,
            'label' => 'คลังสินค้า SCG 1'
        ]);
    }

    /**
     * ทดสอบการเรียกดู KPI สถิติสรุปของลูกค้า (GET /api/customers/{id}/stats)
     */
    public function test_get_customer_statistics(): void
    {
        $customer = Customer::create([
            'name' => 'SCG Group',
            'type' => 'Enterprise',
            'tax_id' => '1111111111111'
        ]);

        $response = $this->getJson("/api/customers/{$customer->id}/stats", $this->getHeaders());

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'success',
                     'data' => [
                         'revenue_lifetime',
                         'projects_active',
                         'projects_completed',
                         'payment_on_time',
                         'customer_since',
                         'has_outstanding'
                     ]
                 ]);
    }
}
