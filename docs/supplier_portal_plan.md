# แผนการพัฒนา & คู่มือการดีพลอยระบบซัพพลายเออร์ (Supplier Quote Portal)

เอกสารฉบับนี้อธิบายแนวคิดสถาปัตยกรรมระบบสำหรับฝั่งโรงงาน/ซัพพลายเออร์ (Supplier) พร้อมคู่มือการดีพลอยผ่าน Subdomain แยกต่างหากอย่างง่ายที่สุด

---

## 1. การออกแบบสถาปัตยกรรม (No-Login Token Architecture)

ตามที่ทีมงานและฝ่ายจัดซื้อได้วางแผนร่วมกัน ระบบใบเสนอราคาของซัพพลายเออร์จะใช้ระบบ **"ลิงก์โทเค็นแบบใช้งานครั้งเดียว (One-Time Token Link)"** แทนการสมัครสมาชิกและเข้าสู่ระบบด้วย Username/Password ปกติ ด้วยเหตุผลดังนี้:

*   **ลดอุปสรรคในการใช้งาน (Frictionless):** โรงงานต่าง ๆ ไม่ต้องการสมัครบัญชีและกรอกข้อมูลโปรไฟล์ใหม่ การส่งลิงก์กรอกข้อมูลตรง ๆ ทำให้โรงงานพร้อมเสนอราคาทันที
*   **ความปลอดภัยสูง (Secure & Expireable):**
    1. ลิงก์ทุกลิงก์จะถูกเข้ารหัสผ่านโทเค็นสุ่มความยาว 40 ตัวอักษร (`Str::random(40)`)
    2. ทันทีที่โรงงานกรอกข้อมูลเสนอราคาเสร็จและกดส่ง ระบบจะลบโทเค็นออกจากตารางทันที (`session_token = null`) ทำให้ลิงก์นั้นหมดอายุการใช้งานทันที ป้องกันการแอบแก้ไขราคาในภายหลัง
    3. ซัพพลายเออร์คนอื่นจะไม่สามารถมองเห็นข้อมูลสเปก ราคา หรือรายการสั่งซื้อของโรงงานอื่นได้เลย

---

## 2. การจัดการ Subdomain แยก (Supplier Subdomain Routing)

ในเฟสดีพลอยจริง หากต้องการให้ซัพพลายเออร์เห็นว่าเข้าผ่านลิงก์ `supplier.ppn-great.com` แยกออกจากระบบหลัก (`admin.ppn-great.com`) สามารถดำเนินการผ่าน Laravel ได้ง่ายมากโดย**ใช้โค้ดชุดเดียวกัน ไม่ต้องสร้างโปรเจกต์ใหม่** ด้วยวิธี **Laravel Subdomain Routing** ดังนี้:

### การตั้งค่าที่ฝั่ง Backend (Laravel API)
ในไฟล์ `routes/web.php` หรือ `routes/api.php` ให้ประกาศกลุ่มของ Route โดยระบุ Domain ปลายทาง:

```php
// ตัวอย่างการผูก Subdomain ใน Laravel
Route::domain('supplier.ppn-great.com')->group(function () {
    // ลิงก์สาธารณะสำหรับซัพพลายเออร์
    Route::get('quotes/public/{token}', [\App\Http\Controllers\QuoteRequestController::class, 'showPublicForm']);
    Route::put('quotes/public/{token}', [\App\Http\Controllers\QuoteRequestController::class, 'fillPricePublic']);
});
```

*   **ข้อดี:** ระบบหลังบ้าน (Database & Controller) จะแชร์ข้อมูลร่วมกัน 100% โดยที่ซัพพลายเออร์จะเห็น URL สวยงามเป็น `http://supplier.ppn-great.com/quotes/public/{token}` โดยสมบูรณ์

---

## 3. ขั้นตอนการดีพลอยที่ง่ายที่สุด (Simple Deployment Plan)

### ส่วนที่ 1: ระบบหลังบ้าน (Laravel API Backend)
*   **Hosting:** แนะนำ VPS ขนาดเริ่มต้น (เช่น DigitalOcean, Hetzner, AWS LightSail) ราคาประมาณ $5 - $10 ต่อเดือน
*   **Tool ช่วยจัดการ:** แนะนำใช้ **Laravel Forge** หรือ **RunCloud** เพื่อช่วยคอนฟิก Domain, SSL (Let's Encrypt), Nginx, และ Database ได้ในคลิกเดียว
*   **DNS Settings:** ที่ DNS Provider (เช่น Cloudflare, GoDaddy) ให้ชี้ Record ไปที่ไอพีเซิร์ฟเวอร์เดียวกันดังนี้:
    *   `api.ppn-great.com` -> ชี้ไปที่ Server IP
    *   `supplier.ppn-great.com` -> ชี้ไปที่ Server IP (เพื่อใช้ฟอร์มซัพพลายเออร์)

### ส่วนที่ 2: ระบบหน้าบ้านจัดซื้อ (Flutter Web Frontend)
เนื่องจากระบบจัดซื้อของแอดมินเป็น Static Files ทั้งหมด:
*   เมื่อพัฒนาเสร็จให้รันคำสั่ง:
    ```bash
    flutter build web --release
    ```
*   ระบบจะเจนโฟลเดอร์ชื่อ `build/web` ออกมา
*   **การอัปโหลด:** นำไฟล์ทั้งหมดในโฟลเดอร์นี้ไปอัปโหลดขึ้นบริการ Cloud Storage หรือ Static Hosting ที่มี CDN ฟรีและดีพลอยง่าย เช่น:
    *   **Cloudflare Pages** (แนะนำ: ดีพลอยฟรี เร็ว และคอนฟิกโดเมนแถม SSL ฟรีในตัว)
    *   **Vercel / Netlify**
*   **DNS Settings:** ชี้โดเมนหน้าบ้านจัดซื้อ `admin.ppn-great.com` ไปที่บริการ Static Hosting ด้านบน

---

## 4. สถานะปัจจุบัน (ใช้งานได้จริง)
*   **ลิงก์อัตโนมัติ:** เมื่อฝ่ายจัดซื้อกดปุ่มสร้างลิงก์ ระบบหลังบ้านจะเจนลิงก์ตาม Request URL จริงให้อัตโนมัติ (ผ่านฟังก์ชัน `url()`)
*   **การกรอกข้อมูล:** เมื่อเปิดลิงก์บนเบราว์เซอร์ จะมีฟอร์มเว็บสวยงามที่พัฒนาด้วย HTML/CSS โทนสีมืด (Dark Mode / Glassmorphism) ให้ซัพพลายเออร์กรอกและกดส่งข้อมูลได้สำเร็จเรียบร้อยแล้ว
