# 🚀 คู่มือการติดตั้งระบบ PPN GREAT บน Hostatom Plesk (แบบไม่มีสิทธิ์ SSH)

คู่มือนี้สำหรับใช้เป็นคู่มืออ้างอิงขั้นตอนการติดตั้ง (Deploy) ระบบ **PPN GREAT** และ **Supplier Portal** ขึ้นระบบ Plesk Hosting ของ Hostatom ทีละขั้นตอน (Step-by-Step) โดยใช้วิธีควบคุมผ่านหน้าเว็บทั้งหมด (GUI-based) ไม่จำเป็นต้องใช้ Command Line หรือ SSH

---

## 🗺️ แผนผังการจับคู่โดเมนและโฟลเดอร์ปลายทาง

ตรวจสอบให้แน่ใจว่าได้สร้างซับโดเมนเหล่านี้บน Plesk เรียบร้อยแล้ว:

| ซับโดเมน (Subdomain) | วัตถุประสงค์ | โฟลเดอร์ปลายทาง (Document Root) |
|---|---|---|
| **`app.lomnuer.com`** | ระบบตัวจริง - หน้าบ้าน (Flutter Web Production) | `/subdomains/app` |
| **`api.lomnuer.com`** | ระบบตัวจริง - หลังบ้าน (Laravel Production API) | `/subdomains/api/public` |
| **`staging.lomnuer.com`** | ระบบตัวทดสอบ - หน้าบ้าน (Flutter Web Test) | `/subdomains/staging` |
| **`staging-api.lomnuer.com`** | ระบบตัวทดสอบ - หลังบ้าน (Laravel Testing API) | `/subdomains/staging-api/public` |
| **`supplier.lomnuer.com`** | เว็บพอร์ทัลฝั่งโรงงาน (Supplier Portal PHP) | `/subdomains/supplier` |

---

## 🗄️ ขั้นตอนที่ 1: การจัดการฐานข้อมูลบน Plesk

เนื่องจากระบบแยกสภาพแวดล้อมออกจากกันโดยเด็ดขาด ให้สร้างฐานข้อมูล 2 ชุดดังนี้:

### 1.1 สร้างฐานข้อมูลระบบจริง (Production Database)
1. ล็อกอินเข้า Plesk ➡️ เมนู **Databases** (แถบซ้ายมือ)
2. กดปุ่ม **Add Database**
3. กรอกข้อมูลดังนี้:
   * **Database name:** `lomnu_ppn_production`
   * **Related site:** เลือก `api.lomnuer.com`
   * ติ๊กถูกที่ **Create a database user**
   * **Database user name:** `lomnu_ppn_prod`
   * **Password:** กดปุ่ม **Generate** (คัดลอกรหัสผ่านนี้เก็บไว้เพื่อไปใส่ใน `.env`)
   * **Access control:** เลือก **Allow local connections only**
4. กดปุ่ม **Create Database**

### 1.2 สร้างฐานข้อมูลระบบทดสอบ (Testing/Staging Database)
1. ทำตามขั้นตอนเดียวกับด้านบน แต่กรอกข้อมูลดังนี้:
   * **Database name:** `lomnu_ppn_staging`
   * **Related site:** เลือก `staging-api.lomnuer.com`
   * **Database user name:** `lomnu_ppn_stag`
   * **Password:** กดปุ่ม **Generate** (คัดลอกรหัสผ่านนี้เก็บไว้)
2. กดปุ่ม **Create Database**

---

## 💻 ขั้นตอนที่ 2: การเตรียมและบีบอัดไฟล์ในเครื่องคอมพิวเตอร์ของคุณ

### 2.1 บีบอัดระบบหลังบ้าน (Backend - Laravel)
1. เข้าไปที่โฟลเดอร์โครงการหลังบ้านของคุณ: `d:\07_Projects\Work\PNN\ppn-api`
2. คัดลอกไฟล์ `d:\07_Projects\Work\PNN\ppn-api\.env.production` จากนั้นเปลี่ยนชื่อไฟล์ใหม่เป็น `.env` และเปิดขึ้นมาแก้ไข:
   * ใส่รหัสผ่านฐานข้อมูลในส่วนของ `DB_PASSWORD="รหัสฐานข้อมูลจริงที่คัดลอกมาจาก Plesk"`
3. **ลบ** โฟลเดอร์ `vendor/` ออกจากโฟลเดอร์ชั่วคราว (เพื่อไม่ให้ไฟล์ใหญ่และอัปโหลดช้า)
4. เลือกไฟล์และโฟลเดอร์ทั้งหมดใน `ppn-api` ➡️ คลิกขวาเลือก **Compress to ZIP file** ตั้งชื่อว่า `backend_production.zip`
5. ทำซ้ำขั้นตอนเดิมสำหรับตัว Staging/Testing:
   * นำไฟล์ `.env.staging` มาเปลี่ยนชื่อเป็น `.env`
   * ใส่รหัสผ่านฐานข้อมูลทดสอบในช่อง `DB_PASSWORD`
   * บีบอัดไฟล์ทั้งหมดในโฟลเดอร์เป็น `backend_staging.zip`

### 2.2 บิวด์และบีบอัดระบบหน้าบ้าน (Frontend - Flutter Web)
1. เปิด Command Prompt หรือ PowerShell ในโฟลเดอร์หน้าบ้านของคุณ: `d:\07_Projects\Work\PNN\ppn_great`
2. ตรวจสอบให้แน่ใจว่ามีการตั้งค่าปลายทางของ API ชี้ไปยัง Domain จริงเรียบร้อยแล้ว
3. รันคำสั่งคอมไพล์โค้ดสำหรับเว็บ:
   ```bash
   flutter build web --release
   ```
4. เมื่อคำสั่งเสร็จสิ้น ให้เข้าไปที่โฟลเดอร์: `d:\07_Projects\Work\PNN\ppn_great\build\web`
5. เลือกไฟล์ทั้งหมดที่อยู่ **ด้านใน** โฟลเดอร์ `web/` แล้วบีบอัดเป็นไฟล์ ZIP ตั้งชื่อว่า `frontend.zip`

### 2.3 แก้ไขและบีบอัดระบบพอร์ทัลโรงงาน (Supplier Portal)
1. เปิดไฟล์ `d:\07_Projects\Work\PNN\Supplier_ui_moocup\index\index.php`
2. แก้ไขบรรทัดที่ 670 ในโค้ดจาวาสคริปต์:
   * เปลี่ยน `const API_BASE_URL = 'http://localhost:8000/api';` ให้ชี้ไปที่เซิร์ฟเวอร์จริง:
     * ตัวอย่าง: `const API_BASE_URL = 'https://api.lomnuer.com/api';`
3. เข้าไปในโฟลเดอร์ `index/` บีบอัดไฟล์ทั้งหมดข้างในนั้นเป็นไฟล์ ZIP ตั้งชื่อว่า `supplier.zip`

---

## 🌐 ขั้นตอนที่ 3: การอัปโหลดและแตกไฟล์ขึ้นเซิร์ฟเวอร์ผ่าน Plesk

### 3.1 อัปโหลดไฟล์หลังบ้าน (Backend)
1. เข้า Plesk ➡️ เมนู **Websites & Domains**
2. ค้นหาซับโดเมน `api.lomnuer.com` ➡️ คลิกปุ่ม **Files** (ตัวจัดการไฟล์)
3. ระบบจะพาไปยังโฟลเดอร์ `/subdomains/api` ให้กดปุ่ม **Upload** ➡️ เลือกไฟล์ `backend_production.zip`
4. เมื่ออัปโหลดเสร็จ ให้คลิกขวาที่ไฟล์ `backend_production.zip` เลือก **Extract Files**
5. ทำซ้ำแบบเดียวกันสำหรับซับโดเมน `staging-api.lomnuer.com` โดยใช้ไฟล์ `backend_staging.zip` อัปโหลดไปที่โฟลเดอร์ `/subdomains/staging-api`

### 3.2 อัปโหลดไฟล์หน้าบ้าน (Frontend)
1. ที่ Plesk ค้นหาซับโดเมน `app.lomnuer.com` ➡️ คลิกปุ่ม **Files**
2. อัปโหลดไฟล์ `frontend.zip` ขึ้นไปในโฟลเดอร์ `/subdomains/app` และกดแตกซิป (Extract)
3. ทำซ้ำแบบเดียวกันกับซับโดเมน `staging.lomnuer.com` โดยอัปโหลดไฟล์ `frontend.zip` ไปยังโฟลเดอร์ `/subdomains/staging`

### 3.3 อัปโหลดไฟล์เว็บโรงงาน (Supplier Portal)
1. ที่ Plesk ค้นหาซับโดเมน `supplier.lomnuer.com` ➡️ คลิกปุ่ม **Files**
2. อัปโหลดไฟล์ `supplier.zip` ขึ้นไปในโฟลเดอร์ `/subdomains/supplier` และกดแตกซิป (Extract)

---

## ⚙️ ขั้นตอนที่ 4: การรัน Composer เพื่อติดตั้ง Library หลังบ้าน

เนื่องจากคุณได้ลบโฟลเดอร์ `vendor/` ออกไปตอนบีบอัดไฟล์ ขั้นตอนนี้จะใช้ระบบจัดการของ Plesk ในการดาวน์โหลดและติดตั้งใหม่อย่างเหมาะสม:

1. กลับไปที่หน้าหลักของ Plesk ➡️ หน้าการตั้งค่าของโดเมน `api.lomnuer.com`
2. สังเกตในกลุ่มเมนู **Dev Tools** ด้านขวา ➡️ คลิกที่เมนู **PHP Composer**
3. สังเกตที่ปุ่มหลักด้านบน ➡️ คลิกปุ่ม **Install** หรือ **Update**
4. หน้าต่าง Plesk จะทำงานติดตั้ง Library เบื้องหลังให้จนเสร็จเรียบร้อยโดยไม่ต้องพิมพ์คำสั่งใดๆ
5. ทำซ้ำขั้นตอนนี้กับซับโดเมน `staging-api.lomnuer.com` ด้วยเช่นกัน

---

## 🚀 ขั้นตอนที่ 5: การรันระบบฐานข้อมูลและไฟล์อัปโหลดผ่านเว็บบราวเซอร์

ขั้นตอนสุดท้ายคือการสร้างตารางฐานข้อมูลและสร้างทางเชื่อมต่อสำหรับเก็บรูปภาพ โดยใช้ลิงก์ Artisan Helper พิเศษที่ผมเตรียมไว้ในเว็บบราวเซอร์:

### 5.1 ตั้งค่าระบบตัวจริง (Production)
1. เปิดเว็บบราวเซอร์ของคุณ (เช่น Chrome)
2. เข้าชมลิงก์เพื่อสร้างตารางข้อมูลใน Database:
   👉 `https://api.lomnuer.com/run-artisan?key=ppn_secret_deploy&command=migrate`
   *(หน้าจอควรแสดงผลข้อความ: Executed command: migrate)*
3. เข้าชมลิงก์เพื่อทำ Storage Symlink สำหรับอัปโหลดไฟล์:
   👉 `https://api.lomnuer.com/run-artisan?key=ppn_secret_deploy&command=storage-link`
   *(หน้าจอควรแสดงข้อความ: Storage symlink created successfully!)*

### 5.2 ตั้งค่าระบบตัวทดสอบ (Testing/Staging)
1. เปิดเว็บบราวเซอร์
2. เข้าชมลิงก์เพื่อล้างและสร้างตารางใหม่พร้อมใส่ข้อมูลสมมุติสำหรับการเทสต์:
   👉 `https://staging-api.lomnuer.com/run-artisan?key=ppn_secret_deploy&command=migrate-seed`
   *(หน้าจอควรแสดงผลข้อความ: Database reset and seeded successfully!)*
3. เข้าชมลิงก์เพื่อทำ Storage Symlink:
   👉 `https://staging-api.lomnuer.com/run-artisan?key=ppn_secret_deploy&command=storage-link`
   *(หน้าจอควรแสดงข้อความ: Storage symlink created successfully!)*

---
🎉 **ระบบ PPN GREAT ของคุณได้รับการติดตั้งและพร้อมใช้งานแล้วอย่างสมบูรณ์แบบบน Plesk Hosting!**
