<?php

namespace Tests\Feature;

use App\Models\Customer;
use App\Models\Project;
use App\Models\ProductItem;
use App\Models\Warehouse;
use App\Models\Container;
use App\Models\DispatchRound;
use App\Models\ClientSample;
use App\Models\ArtworkLog;
use App\Models\StockItem;
use App\Models\StockMovement;
use App\Models\DeliveryItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LogisticsApiTest extends TestCase
{
    use RefreshDatabase;

    private string $token;
    private Project $project;
    private ProductItem $productItem;
    private Warehouse $warehouse;

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

        // 2. เตรียมข้อมูลตั้งต้น
        $customer = Customer::create([
            'name' => 'CP ALL Public Company',
            'type' => 'Enterprise',
            'tax_id' => '3333333333333'
        ]);

        $this->project = Project::create([
            'project_code' => 'PPN-001',
            'customer_id' => $customer->id,
            'status' => 'Inquiry',
            'credit_term' => '30 Days'
        ]);

        $this->productItem = ProductItem::create([
            'project_id' => $this->project->id,
            'name' => 'หมวก CP พรีเมียมสีเขียว',
            'qty' => 5000
        ]);

        // คลังสินค้าเริ่มต้น (ใน Seeder มักสร้างโรงแรกไว้แล้ว แต่สร้างใหม่เพื่อความ determinism ในการเทส)
        $this->warehouse = Warehouse::create([
            'name' => 'คลังใหญ่ PPN คลองหลวง',
            'location' => 'ปทุมธานี',
            'is_active' => true
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
     * 1. ทดสอบการจัดการตัวอย่างชิ้นงานลูกค้า (Client Samples)
     */
    public function test_client_samples_tracking(): void
    {
        // สร้างครั้งที่ 1 (Attempt 1)
        $response1 = $this->postJson('/api/samples', [
            'project_id' => $this->project->id,
            'product_item_id' => $this->productItem->id,
            'sample_type' => 'Pre-production Sample',
            'origin' => 'China',
            'supplier_name' => 'Guangzhou Factory'
        ], $this->getHeaders());

        $response1->assertStatus(201)
                  ->assertJsonPath('data.sample_code', 'SMP-001')
                  ->assertJsonPath('data.attempt', 1)
                  ->assertJsonPath('data.status', 'Waiting from China');

        $sampleId = $response1->json('data.id');

        // ปรับเป็นจัดส่งให้ลูกค้า และปฏิเสธ (Rejected)
        $this->patchJson("/api/samples/{$sampleId}/status", [
            'status' => 'Rejected',
            'feedback' => 'วัสดุแข็งไปนิดนึง ขอเปลี่ยนเป็นผ้าคอตตอน 100%'
        ], $this->getHeaders())
             ->assertStatus(200)
             ->assertJsonPath('data.status', 'Rejected')
             ->assertJsonPath('data.feedback', 'วัสดุแข็งไปนิดนึง ขอเปลี่ยนเป็นผ้าคอตตอน 100%');

        // ขอชิ้นตัวอย่างครั้งที่ 2 (Attempt 2 ต้องเพิ่มขึ้นอัตโนมัติ)
        $response2 = $this->postJson('/api/samples', [
            'project_id' => $this->project->id,
            'product_item_id' => $this->productItem->id,
            'sample_type' => 'Pre-production Sample',
            'origin' => 'China',
            'supplier_name' => 'Guangzhou Factory'
        ], $this->getHeaders());

        $response2->assertStatus(201)
                  ->assertJsonPath('data.attempt', 2);
    }

    /**
     * 2. ทดสอบการอนุมัติแบบและการส่งความเห็นแก้ไขอาร์ตเวิร์ก (Artwork logs)
     */
    public function test_artworks_approval_and_feedback(): void
    {
        // 1. เพิ่ม Artwork
        $response = $this->postJson('/api/artworks', [
            'project_id' => $this->project->id,
            'product_item_id' => $this->productItem->id,
            'version' => 'v1.0',
            'source' => 'In-house Designer',
            'file_name' => 'cp_cap_design_v1.pdf',
            'file_path' => 'public/artworks/cp_cap_design_v1.pdf'
        ], $this->getHeaders());

        $response->assertStatus(201)
                 ->assertJsonPath('data.artwork_code', 'ART-001')
                 ->assertJsonPath('data.attempt', 1)
                 ->assertJsonPath('data.status', 'Awaiting Approval');

        $artId = $response->json('data.id');

        // 2. ลูกค้าส่งคอมเมนต์แก้อาร์ตเวิร์ก (Feedback)
        $this->patchJson("/api/artworks/{$artId}/feedback", [
            'status' => 'Need Revision',
            'feedback' => 'ขอปรับขนาดโลโก้ CP ใหญ่ขึ้นอีก 10%'
        ], $this->getHeaders())
             ->assertStatus(200)
             ->assertJsonPath('data.status', 'Need Revision')
             ->assertJsonPath('data.feedback', 'ขอปรับขนาดโลโก้ CP ใหญ่ขึ้นอีก 10%');
    }

    /**
     * 3. ทดสอบ Container และ API จัดสรรแบ่งส่วนสินค้าตู้คอนเทนเนอร์ (route-goods)
     * 90% ส่งลูกค้าตรง (Direct Delivery) | 10% นำสต็อกเข้าคลัง (Inventory)
     */
    public function test_container_arrival_and_split_goods_routing(): void
    {
        // 1. สร้างใบ Container
        $cResponse = $this->postJson('/api/containers', [
            'container_no' => 'MSKU99887766',
            'vessel_name' => 'Maersk Thailand',
            'port_origin' => 'Guangzhou Port',
            'port_destination' => 'Laem Chabang Port',
            'project_ids' => [$this->project->id]
        ], $this->getHeaders());

        $cResponse->assertStatus(201)
                  ->assertJsonPath('data.status', 'Factory to Port');

        $containerId = $cResponse->json('data.id');

        // ปรับสถานะเป็นมาถึงไทย (Delivered)
        $this->patchJson("/api/containers/{$containerId}/step", [
            'status' => 'Delivered'
        ], $this->getHeaders())->assertStatus(200);

        // 2. รัน API จัดสรรแบ่งส่วนสินค้าตู้คอนเทนเนอร์ (วิเคราะห์ตามที่หัวหน้า First แนะนำ)
        // รับของ 1000 ชิ้น: ส่งมอบตรง 900 ชิ้น, เข้าคลังสินค้ากลาง 100 ชิ้น
        $routeResponse = $this->postJson("/api/containers/{$containerId}/route-goods", [
            'project_id' => $this->project->id,
            'product_item_id' => $this->productItem->id,
            'qty_total_received' => 1000,
            'routing' => [
                [
                    'type' => 'direct_delivery',
                    'qty' => 900,
                    'delivery_address' => 'คลังปลายทางลูกค้า CP สุวรรณภูมิ'
                ],
                [
                    'type' => 'inventory',
                    'qty' => 100,
                    'warehouse_id' => $this->warehouse->id
                ]
            ]
        ], $this->getHeaders());

        $routeResponse->assertStatus(200)
                      ->assertJsonCount(1, 'data.direct_deliveries')
                      ->assertJsonCount(1, 'data.stock_in_movements');

        // ตรวจสอบว่าสินค้า 10% ได้รับเข้าคลังสินค้ากลางจริง
        $this->assertDatabaseHas('stock_items', [
            'warehouse_id' => $this->warehouse->id,
            'product_item_id' => $this->productItem->id,
            'qty_in_stock' => 100
        ]);

        // ตรวจสอบประวัติบันทึกนำเข้าสต็อก (Movement IN)
        $this->assertDatabaseHas('stock_movements', [
            'movement_type' => 'IN',
            'qty' => 100,
            'reference_type' => 'Container',
            'reference_id' => $containerId
        ]);

        // ตรวจสอบใบจัดส่งด่วนตรง (Direct Delivery)
        $this->assertDatabaseHas('delivery_items', [
            'project_id' => $this->project->id,
            'product_item_id' => $this->productItem->id,
            'qty_to_deliver' => 900,
            'warehouse_id' => null // ส่งตรง ไม่ผ่านคลัง
        ]);
    }

    /**
     * 4. ทดสอบความปลอดภัยของสต็อก (Stock Reservation & Automatic Transactional Deduction)
     * ยืนยันว่าการจองและการตัดสต็อกของรอบรถจัดส่งทำงานสมบูรณ์ สต็อกไม่ติดลบ
     */
    public function test_delivery_round_reservation_and_stock_deduction(): void
    {
        // 1. เพิ่มยอดสินค้าเข้าคลังเริ่มต้น 500 ชิ้น เพื่อไว้ทดสอบจัดส่งออก
        $stockItem = StockItem::create([
            'warehouse_id' => $this->warehouse->id,
            'product_item_id' => $this->productItem->id,
            'project_id' => $this->project->id,
            'qty_in_stock' => 500,
            'qty_reserved' => 0
        ]);

        // 2. วางแผนสร้างรอบจัดส่งของ 300 ชิ้น (สร้างรอบ Scheduled) -> ยอดจอง (reserved) ต้องขยับเพิ่มขึ้น
        $roundResponse = $this->postJson('/api/delivery/rounds', [
            'dispatch_date' => now()->toDateString(),
            'driver_name' => 'นายสมจิต ใจดี',
            'vehicle_plate' => 'กข-9999',
            'items' => [
                [
                    'project_id' => $this->project->id,
                    'product_item_id' => $this->productItem->id,
                    'qty_to_deliver' => 300,
                    'delivery_address' => 'ร้าน 7-Eleven สาขาลาดพร้าว',
                    'warehouse_id' => $this->warehouse->id
                ]
            ]
        ], $this->getHeaders());

        $roundResponse->assertStatus(201);
        $roundId = $roundResponse->json('data.id');

        // เช็คว่าระบบทำการจอง (Reserved) สต็อกไว้แล้ว 300 ชิ้น
        $this->assertDatabaseHas('stock_items', [
            'id' => $stockItem->id,
            'qty_in_stock' => 500,
            'qty_reserved' => 300
        ]);

        // 3. กดยืนยันปล่อยรอบจัดส่ง (PATCH confirm -> In Transit) -> ระบบต้องหักสต็อกและยอดจองอัตโนมัติ
        $this->patchJson("/api/delivery/rounds/{$roundId}/confirm", [], $this->getHeaders())
             ->assertStatus(200);

        // เช็คว่าสต็อกคงเหลือหักไป 300 ชิ้นจริง (เหลือ 200) และยอดจองต้องกลับมาเป็น 0
        $this->assertDatabaseHas('stock_items', [
            'id' => $stockItem->id,
            'qty_in_stock' => 200,
            'qty_reserved' => 0
        ]);

        // ตรวจสอบประวัติตัดสต็อกออก (Movement OUT)
        $this->assertDatabaseHas('stock_movements', [
            'stock_item_id' => $stockItem->id,
            'movement_type' => 'OUT',
            'qty' => 300,
            'reference_type' => 'Delivery',
            'reference_id' => $roundId
        ]);
    }
}
