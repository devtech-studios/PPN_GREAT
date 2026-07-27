<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardReportTest extends TestCase
{
    use RefreshDatabase;

    protected string $token;

    protected function setUp(): void
    {
        parent::setUp();
        // รัน Seeder หลักก่อน จากนั้นตามด้วย DummyDataSeeder สำหรับการทดสอบ Dashboard & Reports
        $this->seed();
        $this->seed(\Database\Seeders\DummyDataSeeder::class);

        // เข้าสู่ระบบเป็นผู้ดูแลระบบเพื่อเก็บ Token ไว้ใช้ในหัวข้อต่างๆ
        $loginResponse = $this->postJson('/api/auth/login', [
            'email' => 'admin@ppngreat.com',
            'password' => 'password123',
        ]);
        $this->token = $loginResponse->json('data.token');
    }

    /**
     * ทดสอบ API สรุปข้อมูล Dashboard
     */
    public function test_get_dashboard_summary(): void
    {
        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
                         ->getJson('/api/dashboard/summary');

        $response->assertStatus(200)
                 ->assertJsonPath('success', true)
                 ->assertJsonStructure([
                     'success',
                     'data' => [
                         'active_projects_count',
                         'revenue_mtd',
                         'pending_payments_amount',
                         'low_stock_alerts_count'
                     ]
                 ]);
    }

    /**
     * ทดสอบ API กิจกรรมล่าสุด Dashboard
     */
    public function test_get_dashboard_activities(): void
    {
        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
                         ->getJson('/api/dashboard/activities');

        $response->assertStatus(200)
                 ->assertJsonPath('success', true)
                 ->assertJsonStructure([
                     'success',
                     'data'
                 ]);
    }

    /**
     * ทดสอบ API กราฟรายได้ Dashboard
     */
    public function test_get_dashboard_revenue_chart(): void
    {
        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
                         ->getJson('/api/dashboard/revenue-chart');

        $response->assertStatus(200)
                 ->assertJsonPath('success', true)
                 ->assertJsonStructure([
                     'success',
                     'data' => [
                         '*' => ['month', 'total']
                     ]
                 ]);
    }

    /**
     * ทดสอบ API สรุปรายงานการเงิน
     */
    public function test_get_financial_report_summary(): void
    {
        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
                         ->getJson('/api/reports/financial-summary');

        $response->assertStatus(200)
                 ->assertJsonPath('success', true)
                 ->assertJsonStructure([
                     'success',
                     'data' => [
                         'total_revenue',
                         'total_cogs',
                         'gross_profit',
                         'margin_percentage'
                     ]
                 ]);
    }

    /**
     * ทดสอบ API สรุปรายงานการดำเนินการ
     */
    public function test_get_operational_report_summary(): void
    {
        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
                         ->getJson('/api/reports/operational-summary');

        $response->assertStatus(200)
                 ->assertJsonPath('success', true)
                 ->assertJsonStructure([
                     'success',
                     'data' => [
                         'active_projects_count',
                         'completed_projects_count',
                         'on_time_delivery_rate',
                         'avg_lead_time_days'
                     ]
                 ]);
    }

    /**
     * ทดสอบ API กำไรแยกตามรายโปรเจกต์
     */
    public function test_get_profit_by_project_report(): void
    {
        $response = $this->withHeader('Authorization', "Bearer {$this->token}")
                         ->getJson('/api/reports/profit-by-project');

        $response->assertStatus(200)
                 ->assertJsonPath('success', true)
                 ->assertJsonStructure([
                     'success',
                     'data' => [
                         '*' => [
                             'project_id',
                             'project_code',
                             'customer_name',
                             'revenue',
                             'cogs',
                             'profit',
                             'margin_percentage'
                         ]
                     ]
                 ]);
    }
}
