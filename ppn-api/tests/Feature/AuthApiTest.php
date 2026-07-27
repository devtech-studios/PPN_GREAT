<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // รัน Seeder เติมข้อมูลตั้งต้น เช่น บัญชี Super Admin
        $this->seed();
    }

    /**
     * ทดสอบเข้าสู่ระบบสำเร็จ (Login Successful)
     */
    public function test_login_successful(): void
    {
        $response = $this->postJson('/api/auth/login', [
            'email' => 'admin@ppngreat.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'success',
                     'data' => [
                         'token',
                         'token_type',
                         'expires_in',
                         'user' => [
                             'id',
                             'email',
                             'full_name',
                             'role',
                         ]
                     ],
                     'message'
                 ])
                 ->assertJsonPath('success', true);
    }

    /**
     * ทดสอบการเข้าสู่ระบบล้มเหลว (Login Failed)
     */
    public function test_login_failed_with_invalid_credentials(): void
    {
        $response = $this->postJson('/api/auth/login', [
            'email' => 'admin@ppngreat.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401)
                 ->assertJsonPath('success', false)
                 ->assertJsonPath('error.message', 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    }

    /**
     * ทดสอบการดึงข้อมูล Profile ของตนเองสำเร็จ (Get Profile)
     */
    public function test_get_current_user_profile(): void
    {
        // 1. เข้าสู่ระบบเพื่อดึง Token
        $loginResponse = $this->postJson('/api/auth/login', [
            'email' => 'admin@ppngreat.com',
            'password' => 'password123',
        ]);

        $token = $loginResponse->json('data.token');

        // 2. เรียกดูโปรไฟล์พร้อมแนบ Token
        $response = $this->withHeader('Authorization', "Bearer $token")
                         ->getJson('/api/auth/me');

        $response->assertStatus(200)
                 ->assertJsonPath('success', true)
                 ->assertJsonPath('data.email', 'admin@ppngreat.com');
    }

    /**
     * ทดสอบการล็อกเอาท์สำเร็จ (Logout)
     */
    public function test_logout_successful(): void
    {
        $loginResponse = $this->postJson('/api/auth/login', [
            'email' => 'admin@ppngreat.com',
            'password' => 'password123',
        ]);

        $token = $loginResponse->json('data.token');

        $response = $this->withHeader('Authorization', "Bearer $token")
                         ->postJson('/api/auth/logout');

        $response->assertStatus(200)
                 ->assertJsonPath('success', true)
                 ->assertJsonPath('message', 'ออกจากระบบสำเร็จ');

        // ตรวจสอบว่า Token เดิมใช้งานอีกไม่ได้
        $meResponse = $this->withHeader('Authorization', "Bearer $token")
                           ->getJson('/api/auth/me');
        $meResponse->assertStatus(401);
    }
}
