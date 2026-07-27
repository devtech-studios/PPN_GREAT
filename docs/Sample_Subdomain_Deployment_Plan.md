# 🚀 แผนการขึ้นระบบ (Deployment Plan) บน Subdomain `sample.ppn-great.com`
**โฮสติ้ง Hostatom Plesk Panel | ระบบ PPN GREAT ERP**

---

## 📌 สรุปเป้าหมายการขึ้นระบบ (Deployment Goal)
1. **โดเมนหลัก**: `ppn-great.com` (ลงทะเบียนแล้วบน Hostatom Plesk Panel)
2. **Subdomain สำหรับเดโม**: `sample.ppn-great.com` (สำหรับนำเสนอเดโมแก่ลูกค้า)
3. **โครงสร้างการวางระบบในโดเมนเดียวกัน (ป้องกันปัญหา CORS / Cross-Domain 100%)**:
   - **Frontend (Flutter Web)**: `https://sample.ppn-great.com` (อยู่ที่ Document Root หลักของ Subdomain)
   - **Backend (Laravel API)**: `https://sample.ppn-great.com/api` (สร้างโฟลเดอร์ `api` อยู่ซ้อนภายใน Subdomain)
   - **Database (MySQL)**: ฐานข้อมูลใหม่ `ppn_sample_db` พร้อมไฟล์ SQL เวอร์ชั่น Super Admin Only

---

# 1. 🛠️ ขั้นตอนที่ 1: การเตรียมและขึ้นระบบโดย Developer (คุณ "เหนือ")

### 1.1 การสร้าง Subdomain บน Plesk Panel
1. ล็อกอินเข้า Plesk Panel (`thsv71.hostatom.com:8443`)
2. เข้าเมนู **Websites & Domains** ➔ กดปุ่ม **Add Subdomain**
3. กำหนดค่า:
   - **Subdomain name**: `sample`
   - **Parent domain**: `ppn-great.com`
   - **Document root**: `httpdocs/sample` (หรือ `sample.ppn-great.com`)
4. ตรวจสอบเวอร์ชั่น PHP ให้เป็น **PHP 8.2 หรือสูงกว่า** (เข้าที่ *PHP Settings*)

---

### 1.2 การสร้างฐานข้อมูล (Database) & Import SQL
1. เข้าเมนู **Databases** ใน Plesk Panel ➔ กดปุ่ม **Add Database**
2. กำหนดชื่อและผู้ใช้:
   - **Database name**: `ppng_sample_db` (หรือตาม Plesk กำหนด)
   - **Database user name**: `ppng_sample_user`
   - **Password**: กำหนดรหัสผ่านความปลอดภัยสูง
3. กดปุ่ม **Import Dump**
4. เลือกไฟล์: [`ppn_staging_v1_super_admin_only.sql`](file:///d:/07_Projects/Work/PNN/ppn_staging_v1_super_admin_only.sql) (ไฟล์ SQL เวอร์ชั่น v1 คลีนที่มีเฉพาะ Super Admin) ➔ กด OK เพื่อ Import เข้าฐานข้อมูล

---

### 1.3 การอัปโหลดและตั้งค่า Backend API (`sample.ppn-great.com/api`)
1. เข้าเมนู **Files** (File Manager) ➔ เข้าไปที่โฟลเดอร์ Document Root ของ Subdomain (`httpdocs/sample`)
2. **สร้างโฟลเดอร์ใหม่ชื่อ `api`**
3. อัปโหลดไฟล์ [`backend_staging.zip`](file:///d:/07_Projects/Work/PNN/releases/v1/staging/backend_staging.zip) เข้าไปในโฟลเดอร์ `api` ➔ คลิกขวาแล้วเลือก **Extract Files** (แตกไฟล์ออกทั้งหมด)
4. แก้ไขไฟล์ **`.env`** ในโฟลเดอร์ `api` ให้ตรงกับฐานข้อมูลที่สร้าง:
   ```env
   APP_NAME="PPN GREAT ERP Sample"
   APP_ENV=production
   APP_KEY=base64:YOUR_APP_KEY
   APP_DEBUG=false
   APP_URL=https://sample.ppn-great.com/api

   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=ppng_sample_db
   DB_USERNAME=ppng_sample_user
   DB_PASSWORD=YOUR_DB_PASSWORD
   ```
5. **ตั้งค่า File Permissions**:
   - ตรวจสอบโฟลเดอร์ `storage` และ `bootstrap/cache` ในโฟลเดอร์ `api` ให้มีสิทธิ์เขียนไฟล์ได้ (Permissions: `775` หรือ `777`)
6. **สร้าง/ตรวจสอบไฟล์ `api/.htaccess`** ให้ส่งทุก Request เข้า `public/index.php`:
   ```apache
   <IfModule mod_rewrite.c>
       RewriteEngine On
       RewriteRule ^$ public/ [L]
       RewriteRule (.*) public/$1 [L]
   </IfModule>
   ```

---

### 1.4 การอัปโหลด Frontend (Flutter Web) เพื่อทดสอบเบื้องต้น
1. อัปโหลดไฟล์ [`frontend_staging.zip`](file:///d:/07_Projects/Work/PNN/releases/v1/staging/frontend_staging.zip) เข้าไปที่ Document Root ของ Subdomain (`httpdocs/sample` - นอกโฟลเดอร์ `api`)
2. กด **Extract Files** เพื่อวางไฟล์ Flutter Web (`index.html`, `main.dart.js`, `assets/`, `flutter.js` ฯลฯ)
3. ตรวจสอบไฟล์ `.htaccess` ในระดับ Root สำหรับ Flutter Web SPA Routing:
   ```apache
   <IfModule mod_rewrite.c>
       RewriteEngine On
       RewriteBase /
       RewriteRule ^index\.html$ - [L]
       RewriteCond %{REQUEST_FILENAME} !-f
       RewriteCond %{REQUEST_FILENAME} !-d
       RewriteRule . /index.html [L]
   </IfModule>
   ```
4. ทดสอบเข้าใช้งานผ่านเบราว์เซอร์: `https://sample.ppn-great.com` และล็อกอินด้วย `admin@ppngreat.com` / `password123`

---

# 2. 📋 ขั้นตอนและคู่มือสำหรับ "หัวหน้า" ในการอัปเดต Frontend ล่าสุด

เมื่อหัวหน้าแก้ไขซอร์สโค้ด Flutter (ปิดปุ่มบางฟังก์ชันเรียบร้อย) และต้องการอัปเดต Frontend ขึ้นมาแทนที่ ให้ปฏิบัติตามขั้นตอนดังนี้:

### 📥 ขั้นตอนสำหรับหัวหน้า:
1. **การ Build โค้ด Flutter Web บนเครื่องหัวหน้า**:
   ```bash
   flutter build web --release
   ```
2. **การซิปไฟล์เพื่อเตรียมอัปโหลด**:
   - ให้เข้าไปในโฟลเดอร์ `build/web/`
   - เลือกไฟล์ทั้งหมดภายในโฟลเดอร์ `build/web/` แล้วทำการ Zip เป็นไฟล์ชื่อ `frontend_updated.zip`
3. **การอัปโหลดขึ้น Plesk Panel**:
   - ล็อกอินเข้า Plesk Panel ➔ เข้าไปที่โฟลเดอร์ `httpdocs/sample` (Document Root ของ Subdomain)
   - ⚠️ **คำเตือนสำคัญมาก**: **ห้ามกดลบโฟลเดอร์ `api` เด็ดขาด!**
   - ให้ลบเฉพาะไฟล์/โฟลเดอร์เก่าของ Frontend ออก ได้แก่:
     - โฟลเดอร์ `assets/`, `canvaskit/`
     - ไฟล์ `flutter.js`, `index.html`, `main.dart.js`, `manifest.json`, `version.json`
   - อัปโหลดไฟล์ `frontend_updated.zip` เข้ามาในโฟลเดอร์ `httpdocs/sample` ➔ กด **Extract Files**
4. **ทดสอบผลงาน**:
   - เปิดเบราว์เซอร์เข้า `https://sample.ppn-great.com` กด `Ctrl + F5` (Hard Refresh) เพื่อทดสอบดูปุ่มที่ถูกปิดไว้

---

# 3. ⚠️ จุดเสี่ยงที่ต้องระวัง (Risk Analysis & Pitfalls)

| จุดเสี่ยง (Risk Area) | สาเหตุที่อาจเกิดปัญหา | วิธีป้องกัน & แก้ไข |
| :--- | :--- | :--- |
| **1. CORS Block** | เรียก API ข้ามโดเมนผิดพลาด | วาง API ไว้ใน `sample.ppn-great.com/api` (โดเมนเดียวกัน) ป้องกัน CORS 100% |
| **2. เผลอลบโฟลเดอร์ `api`** | ตอนหัวหน้ามาอัปเดต Frontend แล้วกด Select All ลบไฟล์ทั้งหมด | ย้ำเตือนหัวหน้าว่า **ห้ามลบโฟลเดอร์ `api`** ให้ลบเฉพาะไฟล์ Frontend |
| **3. Base URL ใน Flutter** | Flutter Web ยังชี้ไปที่ `localhost:8000` | ตรวจสอบให้แน่ใจว่า API Base URL ใน Flutter ชี้ไปที่ `https://sample.ppn-great.com/api` |
| **4. สิทธิ์การเขียนไฟล์ (Storage)** | โฟลเดอร์ `storage` และ `bootstrap/cache` ใน `api/` เขียนไฟล์ไม่ได้ | ตั้งค่า File Permissions เป็น `775` หรือ `777` บน Plesk |
| **5. PHP Version ใน Plesk** | Plesk Subdomain ตั้งเป็น PHP 7.x | ปรับ PHP Version ใน Plesk PHP Settings ให้เป็น **PHP 8.2 หรือ 8.3** |
| **6. Browser Cache ค้าง** | หัวหน้าอัปเดตไฟล์ใหม่แล้วแต่หน้าเว็บยังเป็นเวอร์ชั่นเดิม | กด `Ctrl + F5` หรือเปิดใน Incognito Mode เพื่อทดสอบ |

---

# 4. 🧹 ขั้นตอนการลบ Subdomain หลังจบการเดโมแก่ลูกค้า
เมื่อนำเสนอเดโมเสร็จสิ้นและต้องการปิด/ลบ Subdomain `sample.ppn-great.com` ทิ้ง:
1. เข้า Plesk Panel ➔ เมนู **Websites & Domains**
2. ไปที่การ์ด `sample.ppn-great.com` ➔ กดปุ่ม **Remove Subdomain**
3. เข้าเมนู **Databases** ➔ กดลบฐานข้อมูล `ppng_sample_db` ออกจากระบบ
