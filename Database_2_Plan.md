# 🗄️ แผนการจัดการ Database 2 ชุด — Production vs Staging

> **เอกสารนี้อธิบายให้เข้าใจง่ายๆ** ว่าทำไมต้องมี 2 Database และทำจริงยังไง

---

## 🤔 ทำไมต้อง 2 Database?

### ปัญหาถ้ามีแค่ 1 Database:

```
สมมติคุณมี Database อันเดียว → ทั้งระบบจริง + ทดสอบ ใช้อันเดียวกัน

😱 สิ่งที่จะเกิดขึ้น:
├── คุณทดสอบ "ลบ Project" → Project จริงของลูกค้าหายไป!
├── คุณทดสอบ "ตัดสต็อก" → สต็อกจริงลดลง ทั้งที่ของยังอยู่!
├── คุณทดสอบ "ออก Invoice" → ลูกค้าได้รับบิลปลอม!
└── คุณทดสอบ "ลบ Customer" → ข้อมูลลูกค้าจริงหาย!
```

### วิธีแก้: แยก Database 2 ชุด

```
┌─────────────────────────────┐     ┌─────────────────────────────┐
│  🟢 Database #1             │     │  🟡 Database #2             │
│  PRODUCTION (ตัวจริง)        │     │  STAGING (ตัวทดสอบ)         │
│                             │     │                             │
│  ข้อมูลลูกค้าจริง             │     │  ข้อมูล Dummy / ข้อมูลจำลอง  │
│  ออกบิลจริง                  │     │  ทดสอบทุกอย่างได้เลย         │
│  สต็อกจริง                   │     │  ลบ / แก้ / ทำพังได้ ไม่กระทบ │
│                             │     │                             │
│  ❌ ห้ามทดสอบตรงนี้!          │     │  ✅ ทดสอบตรงนี้!             │
│  ❌ ห้ามลองลบ / แก้           │     │  ✅ ลบ แก้ ล้าง ได้หมด       │
└─────────────────────────────┘     └─────────────────────────────┘
           ↑                                    ↑
    ลูกค้าใช้ตัวนี้                     ทีมพัฒนาใช้ตัวนี้
    (เข้าผ่าน ppngreat.com)           (เข้าผ่าน staging.ppngreat.com)
```

---

## 📖 อธิบายแบบเปรียบเทียบให้เข้าใจง่าย

ให้นึกภาพว่าคุณเปิดร้านอาหาร:

| | Production (ห้องครัวจริง) | Staging (ห้องครัวซ้อม) |
|--|--------------------------|----------------------|
| **ใช้ทำอะไร** | ทำอาหารขายลูกค้าจริง | ทดลองสูตรใหม่ / ฝึกพ่อครัวใหม่ |
| **วัตถุดิบ** | ของจริง ราคาแพง | ของถูก ลองผิดลองถูกได้ |
| **ถ้าทำพัง** | ลูกค้าด่า ร้านเจ๊ง | ไม่เป็นไร ลองใหม่ |
| **ใครใช้** | พ่อครัว (ทีม Operation) | พ่อครัวฝึกหัด (ทีม Dev) |

**Database ก็เหมือนกันเลย:**

| | Production DB | Staging DB |
|--|---------------|------------|
| **ข้อมูล** | ลูกค้าจริง (AIS, Lion, Tesla) | ข้อมูลจำลอง (ลูกค้าเทส, ลูกค้า AAA) |
| **ใช้ทำอะไร** | ระบบ PPN GREAT ที่พนักงานใช้ทุกวัน | Dev ทดสอบ Feature ใหม่ |
| **ถ้าทำพัง** | ❌ บริษัทเสียหาย | ✅ ไม่เป็นไร ล้างแล้วใส่ข้อมูลใหม่ |
| **URL** | `ppngreat.com` | `staging.ppngreat.com` |

---

## 🏗️ ภาพรวมสถาปัตยกรรม

```
                    ┌──────────────────────────────────────────────────────┐
                    │                    Supabase                         │
                    │                                                    │
                    │  ┌──────────────────┐   ┌──────────────────┐       │
                    │  │  Project #1      │   │  Project #2      │       │
                    │  │  ppn-production  │   │  ppn-staging     │       │
                    │  │                  │   │                  │       │
                    │  │ ┌──────────────┐ │   │ ┌──────────────┐ │       │
                    │  │ │ PostgreSQL   │ │   │ │ PostgreSQL   │ │       │
                    │  │ │ (ข้อมูลจริง)  │ │   │ │ (ข้อมูลจำลอง) │ │       │
                    │  │ └──────────────┘ │   │ └──────────────┘ │       │
                    │  │ ┌──────────────┐ │   │ ┌──────────────┐ │       │
                    │  │ │ Auth         │ │   │ │ Auth         │ │       │
                    │  │ │ (User จริง)   │ │   │ │ (User ทดสอบ)  │ │       │
                    │  │ └──────────────┘ │   │ └──────────────┘ │       │
                    │  │ ┌──────────────┐ │   │ ┌──────────────┐ │       │
                    │  │ │ Storage      │ │   │ │ Storage      │ │       │
                    │  │ │ (ไฟล์จริง)    │ │   │ │ (ไฟล์ทดสอบ)   │ │       │
                    │  │ └──────────────┘ │   │ └──────────────┘ │       │
                    │  └──────────────────┘   └──────────────────┘       │
                    │         ↑                        ↑                 │
                    └─────────┼────────────────────────┼─────────────────┘
                              │                        │
                    ┌─────────┴──────┐      ┌──────────┴──────┐
                    │  Flutter Web   │      │  Flutter Web    │
                    │  (Production)  │      │  (Staging)      │
                    │                │      │                 │
                    │  พนักงาน PPN    │      │  ทีม Dev        │
                    │  ใช้งานจริง      │      │  ทดสอบ Feature  │
                    └────────────────┘      └─────────────────┘
```

---

## 📋 แผนการทำงานแบบ Step-by-Step

### Phase 1: สร้าง Supabase Project 2 อัน

#### Step 1.1: สร้าง Production Project

```
1. เปิด https://supabase.com → Login
2. กด "New Project"
3. ตั้งค่า:
   ├── Organization: PPN
   ├── Project Name: ppn-production
   ├── Database Password: (ตั้งรหัสแข็งๆ จดไว้!)
   ├── Region: Southeast Asia (Singapore)
   └── Plan: Free (เริ่มต้น) หรือ Pro (ถ้าบริษัทจ่าย)
4. กด "Create Project" → รอสร้างเสร็จ
5. จดไว้:
   ├── Project URL: https://xxxxx.supabase.co
   └── Anon Key: eyJxxxxxxxx...
```

#### Step 1.2: สร้าง Staging Project

```
1. กด "New Project" อีกครั้ง
2. ตั้งค่า:
   ├── Organization: PPN
   ├── Project Name: ppn-staging        ← ชื่อต่างกัน!
   ├── Database Password: (ตั้งรหัสอื่น)
   ├── Region: Southeast Asia (Singapore) ← Region เดียวกัน
   └── Plan: Free
3. กด "Create Project"
4. จดไว้:
   ├── Project URL: https://yyyyy.supabase.co  ← URL ต่างกัน!
   └── Anon Key: eyJyyyyyyy...                 ← Key ต่างกัน!
```

**ตอนนี้คุณมี 2 Project บน Supabase แล้ว:**

| | Production | Staging |
|--|-----------|---------|
| Project Name | ppn-production | ppn-staging |
| URL | `https://xxxxx.supabase.co` | `https://yyyyy.supabase.co` |
| Anon Key | `eyJxxx...` | `eyJyyy...` |

---

### Phase 2: สร้างตาราง Database (ทำทั้ง 2 อัน เหมือนกัน)

> ⚠️ **สำคัญ:** ตาราง (Schema) ใน Production และ Staging **ต้องเหมือนกันทุกประการ!**  
> แต่ **ข้อมูลข้างใน** ต่างกันได้

#### Step 2.1: เขียน SQL สร้างตาราง (Migration File)

สร้างไฟล์ SQL ที่ใช้สร้างตารางทั้งหมด เช่น:

```sql
-- ================================
-- ไฟล์นี้ใช้ RUN ทั้ง Production และ Staging
-- ================================

-- 1. ตาราง Users (ผู้ใช้งานระบบ)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('owner', 'sales', 'procurement', 'finance', 'warehouse', 'admin')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. ตาราง Customers (ลูกค้า)
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT CHECK (type IN ('Enterprise', 'Mid-Market', 'SME')),
    status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive')),
    tax_id TEXT,
    branch TEXT,
    industry TEXT,
    lead_source TEXT,
    internal_note TEXT,
    billing_address TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. ตาราง Contact Persons (ผู้ติดต่อ)
CREATE TABLE contact_persons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    role TEXT,
    phone TEXT,
    email TEXT,
    line_id TEXT,
    other_chat TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. ตาราง Projects (โปรเจกต์)
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_code TEXT NOT NULL UNIQUE,  -- เช่น "PPN-001"
    customer_id UUID REFERENCES customers(id),
    status TEXT DEFAULT 'Inquiry' CHECK (status IN (
        'Inquiry', 'Sample', 'Production', 'Shipping', 'Distributing', 'Delivered', 'Cancelled'
    )),
    step INTEGER DEFAULT 0,
    priority INTEGER DEFAULT 0,  -- 0=ปกติ, 1=สำคัญ, 2=ด่วน
    is_repeat_order BOOLEAN DEFAULT false,
    target_date DATE,
    order_value DECIMAL(12,2),
    usage_location TEXT,
    credit_term TEXT DEFAULT '30 Days',
    deposit_paid BOOLEAN DEFAULT false,
    balance_paid BOOLEAN DEFAULT false,
    ocpb_passed BOOLEAN DEFAULT false,
    shipping_mark_ready BOOLEAN DEFAULT false,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ... (ตารางอื่นๆ ต่อ)
```

#### Step 2.2: RUN SQL ทั้ง 2 ที่

```
1. เปิด Supabase Dashboard → ppn-production → SQL Editor → วาง SQL → Run ✅
2. เปิด Supabase Dashboard → ppn-staging → SQL Editor → วาง SQL เดียวกัน → Run ✅
```

**ผลลัพธ์:** ทั้ง 2 Database มีตารางเหมือนกัน แต่ข้อมูลว่างเปล่า

---

### Phase 3: ใส่ข้อมูลจำลอง (เฉพาะ Staging)

#### Step 3.1: ใส่ Seed Data ใน Staging เท่านั้น

```sql
-- ================================
-- ⚠️ RUN เฉพาะ STAGING เท่านั้น!
-- ================================

-- ใส่ User ทดสอบ
INSERT INTO users (email, full_name, role) VALUES
('admin@test.com', 'แอดมิน ทดสอบ', 'admin'),
('sales@test.com', 'เซลส์ ทดสอบ', 'sales'),
('finance@test.com', 'การเงิน ทดสอบ', 'finance'),
('warehouse@test.com', 'คลัง ทดสอบ', 'warehouse');

-- ใส่ลูกค้าจำลอง
INSERT INTO customers (name, type, status, industry) VALUES
('บริษัท ทดสอบ A จำกัด', 'Enterprise', 'Active', 'Technology'),
('บริษัท ทดสอบ B จำกัด', 'Mid-Market', 'Active', 'Retail'),
('ร้านทดสอบ C', 'SME', 'Active', 'Food');

-- ใส่ Project จำลอง
INSERT INTO projects (project_code, customer_id, status, step, target_date, order_value) VALUES
('TEST-001', (SELECT id FROM customers WHERE name = 'บริษัท ทดสอบ A จำกัด'), 'Inquiry', 0, '2026-09-01', 150000),
('TEST-002', (SELECT id FROM customers WHERE name = 'บริษัท ทดสอบ B จำกัด'), 'Production', 2, '2026-08-15', 280000);
```

> 💡 **Production ไม่ต้องใส่ข้อมูลจำลอง** — ข้อมูลจะเข้ามาจากการใช้งานจริงของพนักงาน

---

### Phase 4: ตั้งค่า Flutter App ให้สลับ Database ได้

#### Step 4.1: สร้างไฟล์ Config

```dart
// lib/config/environment.dart

class AppConfig {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);

  // ============ PRODUCTION ============
  static const String _prodSupabaseUrl = 'https://xxxxx.supabase.co';
  static const String _prodSupabaseKey = 'eyJxxx...';

  // ============ STAGING ============
  static const String _stagingSupabaseUrl = 'https://yyyyy.supabase.co';
  static const String _stagingSupabaseKey = 'eyJyyy...';

  // ============ ใช้ตัวนี้ในโค้ด ============
  static String get supabaseUrl => isProduction ? _prodSupabaseUrl : _stagingSupabaseUrl;
  static String get supabaseKey => isProduction ? _prodSupabaseKey : _stagingSupabaseKey;
}
```

#### Step 4.2: ใช้ใน main.dart

```dart
// lib/main.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,    // ← ดึงจาก Config อัตโนมัติ
    anonKey: AppConfig.supabaseKey,
  );

  runApp(const MyApp());
}
```

#### Step 4.3: วิธีสลับ Environment ตอนรัน

```bash
# 🟡 รัน Staging (ทดสอบ) — ค่าเริ่มต้น
flutter run -d chrome

# 🟢 รัน Production (ตัวจริง)
flutter run -d chrome --dart-define=PRODUCTION=true

# 🟢 Build Production (สร้างไฟล์ Deploy)
flutter build web --dart-define=PRODUCTION=true
```

**ผลลัพธ์:**

```
flutter run -d chrome                              → ใช้ Staging DB (ข้อมูลจำลอง)
flutter run -d chrome --dart-define=PRODUCTION=true → ใช้ Production DB (ข้อมูลจริง)
```

---

## 🔄 Workflow การทำงานจริงของทีม Dev

### วงจรการพัฒนา Feature ใหม่:

```
┌────────────────────────────────────────────────────────────────────┐
│                                                                    │
│  1. พัฒนาบนเครื่อง Dev                                              │
│     └── ใช้ Staging DB (ข้อมูลจำลอง)                                │
│         └── ทดสอบ → แก้บัก → ทดสอบ → ผ่าน ✅                        │
│                                                                    │
│  2. Deploy ขึ้น Staging Server                                      │
│     └── ให้หัวหน้าหรือ QA ทดสอบ                                      │
│         └── ทดสอบบน staging.ppngreat.com                            │
│             └── ถ้ามีบัก → กลับไปขั้นตอน 1                           │
│             └── ถ้าผ่าน ✅ → ไปขั้นตอน 3                             │
│                                                                    │
│  3. Deploy ขึ้น Production Server                                   │
│     └── Build ด้วย --dart-define=PRODUCTION=true                   │
│         └── Deploy ขึ้น ppngreat.com                                │
│             └── พนักงาน PPN ใช้งานจริง                               │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

### ตัวอย่างสถานการณ์จริง:

#### สถานการณ์: "คุณต้องเพิ่มฟีเจอร์ลบ Project"

```
❌ ถ้ามี DB เดียว:
   คุณเขียนโค้ดลบ Project → ทดสอบลบ PRJ-001 → ของจริงของ Lion หายไป!

✅ ถ้ามี 2 DB:
   1. เขียนโค้ดบนเครื่อง → ต่อ Staging DB
   2. ทดสอบลบ TEST-001 → ข้อมูลจำลองหาย (ไม่เป็นไร!)
   3. เจอบัก: ลบ Project แล้ว Invoice ยังค้างอยู่ → แก้โค้ด
   4. ทดสอบอีกครั้ง → ผ่าน ✅
   5. Deploy ขึ้น Production → ใช้ได้จริง ไม่มีบัก
```

#### สถานการณ์: "คุณต้องทดสอบระบบตัดสต็อก"

```
✅ บน Staging DB:
   1. ใส่สต็อกจำลอง: ร่ม 100 คัน (ข้อมูลปลอม)
   2. ทดสอบ Dispatch → ตัดสต็อก 50 → เหลือ 50 ✅
   3. ทดสอบ Dispatch อีก 60 → ควรแจ้ง "ของไม่พอ" → ✅
   4. ล้างข้อมูล → ใส่ใหม่ → ทดสอบเคสอื่น

   ⭐ ไม่กระทบสต็อกจริงของบริษัทเลย!
```

---

## 📊 สรุปเปรียบเทียบ 2 Database

| หัวข้อ | 🟢 Production | 🟡 Staging |
|--------|--------------|-----------|
| **ชื่อ Project** | ppn-production | ppn-staging |
| **ข้อมูล** | ข้อมูลจริงของลูกค้า/บริษัท | ข้อมูลจำลอง (Dummy) |
| **ใครใช้** | พนักงาน PPN | ทีม Dev / QA |
| **URL เว็บ** | ppngreat.com | staging.ppngreat.com |
| **ลบ/แก้ข้อมูลได้ไหม** | ❌ ระวังมาก! | ✅ ได้เต็มที่ |
| **ล้างข้อมูลทั้งหมดได้ไหม** | ❌ ห้ามเด็ดขาด! | ✅ ล้างแล้วใส่ใหม่ได้ |
| **ตาราง (Schema)** | เหมือนกัน ✅ | เหมือนกัน ✅ |
| **Deploy เมื่อไหร่** | เมื่อ Feature ทดสอบผ่านแล้ว | ทุกครั้งที่พัฒนาเสร็จ |

---

## ⚠️ กฎสำคัญที่ต้องจำ

### ❌ สิ่งที่ห้ามทำ:
1. **ห้ามทดสอบบน Production** — ถ้าพัง ข้อมูลจริงเสียหาย
2. **ห้ามใช้ Production Key ตอน dev** — ตั้งค่า Staging เป็นค่าเริ่มต้น
3. **ห้ามใส่ข้อมูลจริงใน Staging** — ข้อมูลลูกค้าจริงเป็นความลับ

### ✅ สิ่งที่ต้องทำ:
1. **แก้ Schema ต้องทำทั้ง 2 ที่** — เพิ่มตาราง/คอลัมน์ ต้อง Run ทั้ง Production + Staging
2. **ใช้ Migration File** — เขียน SQL เป็นไฟล์ ไม่ใช่พิมพ์ตรงใน Dashboard
3. **Staging ต้องมีข้อมูลจำลองเสมอ** — ล้างแล้วต้องใส่ Seed Data ใหม่

---

## 🔧 เทียบกับภาพ phpMyAdmin ของหัวหน้า

จากภาพที่หัวหน้าส่งมา (phpMyAdmin บน Hostatom):

```
ภาพหัวหน้าแสดง:
├── Database: wansign_app       ← นี่คือ "Production" (ตัวจริง)
│   ├── attendance
│   ├── branches (2 rows: สำนักงานใหญ่, สำนักงานรอง)
│   ├── jobs
│   ├── job_logs
│   ├── job_mechanics
│   ├── shops
│   ├── users
│   ├── work_orders
│   └── work_status
│
└── (หัวหน้าจะมีอีก DB) ← นี่คือ "Staging" (ตัวทดสอบ)
    ├── attendance         ← ตารางเหมือนกัน
    ├── branches          ← แต่ข้อมูลเป็น Dummy
    ├── jobs
    └── ...
```

**หัวหน้าใช้ MySQL + phpMyAdmin** แต่ **Concept เดียวกัน** กับที่เราจะทำบน Supabase (PostgreSQL):

| หัวหน้า (MySQL) | เรา (Supabase) |
|----------------|----------------|
| phpMyAdmin | Supabase Dashboard |
| wansign_app (Production) | ppn-production |
| wansign_app_staging (Staging) | ppn-staging |
| Hostatom Hosting | Supabase Cloud |

---

## 📝 Checklist ก่อนเริ่มงาน

```
□ 1. สร้าง Supabase Account (ถ้ายังไม่มี)
□ 2. สร้าง Project #1: ppn-production
□ 3. สร้าง Project #2: ppn-staging
□ 4. เขียน Migration SQL สร้างตาราง
□ 5. RUN SQL บน Production
□ 6. RUN SQL เดียวกันบน Staging
□ 7. ใส่ Seed Data (ข้อมูลจำลอง) เฉพาะ Staging
□ 8. สร้าง environment.dart ใน Flutter
□ 9. ทดสอบเชื่อมต่อ Staging → ได้ ✅
□ 10. ทดสอบเชื่อมต่อ Production → ได้ ✅
□ 11. ตั้งค่า Staging เป็น Default (ป้องกันอุบัติเหตุ)
```

---

> 📝 **สร้างโดย:** Antigravity AI Assistant  
> **วันที่:** 3 กรกฎาคม 2026
