# 🛠️ MCP + Skills สำหรับ PPN GREAT — วิเคราะห์และแนะนำ

> **เป้าหมาย:** ใช้ Antigravity (Claude Opus 4.6) + MCP + Skills ให้ทำงาน Backend เร็วที่สุด

---

## 📌 สารบัญ

1. [MCP คืออะไร? ช่วยยังไง?](#1-mcp-คืออะไร-ช่วยยังไง)
2. [MCP ที่แนะนำสำหรับโปรเจกต์นี้](#2-mcp-ที่แนะนำสำหรับโปรเจกต์นี้)
3. [Skills คืออะไร? ช่วยยังไง?](#3-skills-คืออะไร-ช่วยยังไง)
4. [Skills ที่แนะนำ](#4-skills-ที่แนะนำ)
5. [วิธีติดตั้ง MCP + Skills](#5-วิธีติดตั้ง-mcp--skills)
6. [แผนใช้ MCP + Skills รายวัน](#6-แผนใช้-mcp--skills-รายวัน)
7. [สรุปแนะนำ](#7-สรุปแนะนำ)

---

## 1. MCP คืออะไร? ช่วยยังไง?

### อธิบายง่ายๆ:

```
ปกติ AI ทำได้แค่:
  ✅ อ่านไฟล์ในโปรเจกต์
  ✅ แก้ไขไฟล์
  ✅ รัน Terminal Command

ถ้าเพิ่ม MCP → AI จะทำได้เพิ่ม:
  ✅ เชื่อมต่อ MySQL Database โดยตรง → ดู Table, รัน SQL, ดูข้อมูล
  ✅ เชื่อมต่อ GitHub → Push Code, สร้าง PR
  ✅ เชื่อมต่อ Supabase → จัดการ Database (ถ้าใช้)
  ✅ ค้นหาเอกสาร Laravel → เจอคำตอบเร็วขึ้น
```

### ตัวอย่างจริง:

```
❌ ไม่มี MCP MySQL:
   คุณ: "ดูให้หน่อยว่าตาราง customers มี field อะไรบ้าง"
   AI: "ผมดูไม่ได้ครับ ต้องเปิด phpMyAdmin เอง"

✅ มี MCP MySQL:
   คุณ: "ดูให้หน่อยว่าตาราง customers มี field อะไรบ้าง"
   AI: → รัน SQL: DESCRIBE customers;
   AI: "มี 12 fields ครับ: id, name, type, status, tax_id..."
   AI: → "เจอว่าไม่มี index ที่ column status → ผมเพิ่ม index ให้เลยนะ"
```

---

## 2. MCP ที่แนะนำสำหรับโปรเจกต์นี้

### 🥇 MCP #1: MySQL MCP Server (แนะนำมากที่สุด!)

```
ชื่อ:     @benborla29/mcp-server-mysql
ติดตั้ง:   npx -y @benborla29/mcp-server-mysql
ช่วยอะไร: AI เชื่อมต่อ MySQL โดยตรง → ดูตาราง, รัน SQL, ตรวจ Schema
```

**ช่วยงานอะไรได้:**

| งาน | ก่อน MCP | หลัง MCP |
|-----|---------|---------|
| ดูโครงสร้างตาราง | เปิด phpMyAdmin เอง | AI ดูให้ทันที |
| ตรวจ Migration ตรงกับ DB ไหม | เช็คเอง | AI เช็คให้ |
| ทดสอบ SQL Query | เขียนเองใน phpMyAdmin | สั่ง AI เขียน + รัน |
| หา Bug ข้อมูลผิด | Query เอง | สั่ง AI ค้นหา |
| ใส่ Seed Data | เขียน SQL เอง | สั่ง AI สร้าง + รัน |
| เช็คข้อมูลหลังทดสอบ | เปิด phpMyAdmin ดู | ถาม AI "ข้อมูลเข้าไหม?" |

**⚠️ ข้อจำกัด:**
- ต้องเชื่อมต่อ MySQL ได้จากเครื่อง Dev (localhost หรือ Remote)
- ถ้าอยู่บน Hostatom (Remote) → ต้องเปิด Remote MySQL Access ก่อน
- **แนะนำ:** ใช้กับ Staging DB เท่านั้น (ไม่ใช้กับ Production — ปลอดภัยกว่า)

---

### 🥈 MCP #2: Filesystem MCP (มีในตัวแล้ว)

```
สถานะ: Antigravity มีอยู่แล้ว ไม่ต้องติดตั้งเพิ่ม
ช่วยอะไร: อ่าน/เขียน/แก้ไขไฟล์ในโปรเจกต์
```

**คุณมีอยู่แล้ว!** Antigravity อ่านและแก้ไขไฟล์ได้อยู่แล้ว ✅

---

### 🥉 MCP #3: GitHub MCP (ถ้าใช้ Git)

```
ชื่อ:     @modelcontextprotocol/server-github
ช่วยอะไร: Push/Pull Code, สร้าง Branch, สร้าง PR
```

**ช่วยงานอะไรได้:**
- สั่ง AI commit + push อัตโนมัติ
- สร้าง Branch แยกตาม Feature
- ⚠️ **ถ้ายังไม่ใช้ Git → ข้ามไปก่อน** (ไม่จำเป็นสำหรับ 8 วันแรก)

---

### ❌ MCP ที่ไม่จำเป็นตอนนี้:

| MCP | เหตุผลที่ข้าม |
|-----|-------------|
| Supabase MCP | ไม่ได้ใช้ Supabase แล้ว (เปลี่ยนเป็น MySQL) |
| Docker MCP | ไม่ได้ใช้ Docker (ใช้ Hostatom Hosting) |
| Playwright/Browser MCP | ไม่ต้อง Scrape เว็บ |
| Slack MCP | ไม่เกี่ยวกับโปรเจกต์ |

---

## 3. Skills คืออะไร? ช่วยยังไง?

### อธิบายง่ายๆ:

```
Skill = "คู่มือ" ที่ AI อ่านก่อนทำงาน

เหมือนคุณจ้างช่างมาซ่อมบ้าน:
- ช่างธรรมดา = รู้ทั่วไป แต่ไม่รู้มาตรฐานบ้านคุณ
- ช่างที่อ่านคู่มือบ้านก่อน = รู้ว่าท่อน้ำอยู่ไหน สายไฟวิ่งยังไง ทำถูกตั้งแต่ครั้งแรก

Skill ก็เหมือนกัน — AI อ่านแล้วจะ "เก่งขึ้น" ในงานเฉพาะทาง
```

### Skill อยู่ในรูปไฟล์ SKILL.md:

```markdown
# SKILL.md ตัวอย่าง

## Name
Laravel API Generator

## Description
สร้าง REST API สำหรับ Laravel ตาม Best Practices

## Instructions
1. ทุก Controller ต้อง return JsonResponse
2. ใช้ Form Request สำหรับ Validation
3. ใช้ Resource class สำหรับ Response
4. ใส่ try-catch ทุก method
5. บันทึก Activity Log ทุกการเปลี่ยนแปลง
...
```

---

## 4. Skills ที่แนะนำ

### 🟢 Skill ที่ควรใช้ (ช่วยโปรเจกต์นี้โดยตรง):

#### Skill #1: Laravel REST API Generator

```
ช่วยอะไร: สร้าง Controller + Model + Migration + Routes แบบ Consistent
ที่มา: ค้นหา GitHub "antigravity-skills laravel"
ประโยชน์:
  ✅ Response format เหมือนกันทุก API
  ✅ Validation ครบทุก endpoint
  ✅ Error handling เป็นมาตรฐาน
  ✅ ลดเวลาเขียนโค้ดซ้ำๆ
```

#### Skill #2: Database Optimizer

```
ช่วยอะไร: ตรวจ N+1 Query, แนะนำ Index, Optimize Query
ประโยชน์:
  ✅ API ทำงานเร็วขึ้น
  ✅ เจอปัญหา Performance ก่อน Deploy
```

#### Skill #3: Test Generator

```
ช่วยอะไร: สร้าง Test Case สำหรับ API อัตโนมัติ
ประโยชน์:
  ✅ ทดสอบ API ได้ครบทุก endpoint
  ✅ เจอ Bug ก่อน Deploy
```

#### Skill #4: API Auditor

```
ช่วยอะไร: ตรวจ Security ของ API (SQL Injection, Auth Bypass, CORS ฯลฯ)
ประโยชน์:
  ✅ API ปลอดภัยกว่า
  ✅ ป้องกันโดนแฮก
```

---

### 💡 แต่! สำหรับ 8 วันนี้ ผมแนะนำทำ Skill เอง

**เหตุผล:** Skills จาก Community เป็น Generic — ไม่รู้จัก PPN GREAT

**สิ่งที่ดีกว่า:** ใช้ **MASTER_PROMPT.md** ที่เราสร้างไว้แล้ว!

```
MASTER_PROMPT.md ที่เราสร้าง = "Custom Skill" ที่เฉพาะเจาะจงสำหรับ PPN GREAT
  ✅ รู้จักทุกตาราง (26 ตาราง)
  ✅ รู้จัก ENUM ทุกค่า
  ✅ รู้จัก Naming Convention
  ✅ รู้จัก Response Format
  ✅ รู้จัก API Endpoints ทั้งหมด

Community Skills = "คู่มือทั่วไป" ← ดี แต่ไม่เฉพาะเจาะจง
MASTER_PROMPT.md = "คู่มือเฉพาะ PPN" ← ดีกว่า!
```

---

## 5. วิธีติดตั้ง MCP + Skills

### 5.1 ติดตั้ง MySQL MCP (แนะนำทำเลย!)

#### ขั้นตอน:

**1. เปิด Antigravity Settings:**

ไปที่ Settings ของ Antigravity (ไอคอนเกียร์) → MCP Servers → Add Server

**2. เพิ่ม Configuration:**

ไปที่ไฟล์ settings หรือ MCP config ของ Antigravity:

```json
{
  "mcpServers": {
    "mysql": {
      "command": "npx",
      "args": ["-y", "@benborla29/mcp-server-mysql"],
      "env": {
        "MYSQL_HOST": "localhost",
        "MYSQL_PORT": "3306",
        "MYSQL_USER": "ppn_stag_user",
        "MYSQL_PASS": "your_staging_password",
        "MYSQL_DB": "ppn_staging"
      }
    }
  }
}
```

> ⚠️ **สำคัญ:** ใช้ Staging DB เท่านั้น! ห้ามใช้ Production!

**3. ทดสอบ:**

เปิด Chat ใหม่ → ถาม:
```
"แสดง Table ทั้งหมดใน Database ให้หน่อย"
```

ถ้าเห็น 26 ตาราง = ✅ ทำงานแล้ว!

---

### 5.2 ติดตั้ง Skills

#### วิธีที่ 1: ใช้ MASTER_PROMPT.md (แนะนำ — ทำแล้ว!)

```
คุณมี MASTER_PROMPT.md อยู่แล้ว → นี่คือ Custom Skill ที่ดีที่สุด!
แค่ @ mention ทุกครั้ง → AI จะมี Context ครบ
```

#### วิธีที่ 2: สร้าง SKILL.md ใส่ในโปรเจกต์ (ถ้าอยากให้ AI อ่านอัตโนมัติ)

สร้างโฟลเดอร์ `.agent/skills/` ในโปรเจกต์:

```
ppn-api/
└── .agent/
    └── skills/
        └── ppn-laravel/
            └── SKILL.md
```

เนื้อหาของ SKILL.md:

```markdown
---
name: PPN GREAT Laravel API
description: Skill สำหรับเขียน Backend PPN GREAT ERP
triggers:
  - สร้าง API
  - สร้าง Controller
  - สร้าง Migration
  - แก้ไข endpoint
---

# PPN GREAT Laravel API Skill

## Rules
1. ทุก API Response ต้องใช้ format เดียวกัน:
   { "success": true/false, "data": {...}, "message": "..." }

2. ทุก Controller ต้องมี Validation (Form Request)

3. Naming Convention:
   - Table: snake_case พหูพจน์ (customers)
   - Model: PascalCase เอกพจน์ (Customer)
   - FK: {table}_id (customer_id)

4. ทุกการเปลี่ยนแปลงสำคัญ ต้องบันทึก Activity Log

5. ตัดสต็อก ต้องใช้ DB::transaction() + lockForUpdate()

6. Auto-generate numbers:
   - Project: PPN-001 (ไม่รีเซ็ต)
   - Finance: QU-2026-0001 (รีเซ็ตรายปี)

## Database Schema Reference
ดูไฟล์ Backend_Map.md สำหรับ Schema ละเอียด

## API Endpoints Reference
ดูไฟล์ MASTER_PROMPT.md สำหรับ Endpoints ทั้งหมด
```

#### วิธีที่ 3: ดาวน์โหลด Community Skills จาก GitHub (Optional)

```bash
# ค้นหา Skills สำหรับ Laravel
# GitHub: https://github.com/topics/antigravity-skills

# ติดตั้ง Skills แบบรวม (มีหลายร้อยอัน)
# ⚠️ เลือกเฉพาะที่ต้องใช้ ไม่ต้องลงทั้งหมด
```

**Skills จาก Community ที่น่าสนใจ:**

| Skill | GitHub | ช่วยอะไร |
|-------|--------|---------|
| api-auditor | antigravity-skills | ตรวจ Security ของ API |
| database-optimizer | antigravity-skills | ตรวจ Performance Query |
| test-generator | antigravity-skills | สร้าง Test Cases |
| migration-advisor | antigravity-skills | ตรวจ Migration ปลอดภัย |

---

## 6. แผนใช้ MCP + Skills รายวัน

### วัน 1: Setup

```
□ ติดตั้ง MySQL MCP → เชื่อมต่อ Staging DB
□ วาง SKILL.md ใน .agent/skills/ppn-laravel/
□ ทดสอบ: "แสดง Tables ทั้งหมด" → ต้องเห็น 26 ตาราง
□ ทดสอบ: "DESCRIBE customers" → ต้องเห็น Fields ทั้งหมด
```

### วัน 2-7: ใช้ MCP ช่วยระหว่างพัฒนา

```
ตัวอย่างคำสั่งที่ใช้ MCP ช่วย:

"สร้าง CustomerController แล้วทดสอบเชื่อมต่อ DB ด้วย
 ให้ INSERT ข้อมูลทดสอบ 1 รายการ แล้วดูว่าเข้า DB จริงไหม"

"ดูให้หน่อยว่า foreign key ของ projects → customers ถูกต้องไหม"

"รัน SELECT * FROM projects WHERE status = 'Inquiry' ให้ดู"

"หา Record ที่ customer_id ไม่มีใน customers (orphan records)"

"คำนวณ revenue รายเดือนจาก payments table ให้ดู
 ตรงกับ Report API ที่เขียนไหม"
```

### วัน 8: Testing ด้วย MCP

```
"ตรวจทุกตารางว่ามี Foreign Key ถูกต้อง"
"หา Table ที่ยังไม่มี Index → แนะนำว่าควรเพิ่มตรงไหน"
"ทดสอบ Seed Data → เรียก API → เช็คข้อมูลใน DB ว่าตรงกัน"
```

---

## 7. สรุปแนะนำ

### 🎯 สิ่งที่ต้องทำ (เรียงตามความสำคัญ):

```
1. ⭐⭐⭐ MASTER_PROMPT.md → มีแล้ว ✅ (สำคัญที่สุด!)
   → ใช้ @ mention ทุก Chat ใหม่

2. ⭐⭐⭐ MySQL MCP → ติดตั้งวันแรก
   → AI เชื่อม DB ได้ → ทำงานเร็วขึ้น 30-50%

3. ⭐⭐ SKILL.md ใน .agent/skills/ → สร้างวันแรก
   → AI อ่านอัตโนมัติ ไม่ต้อง @ mention

4. ⭐ PROGRESS.md → มีแล้ว ✅ (ติดตาม Context)
   → เปิด Chat ใหม่ แล้วรู้ว่าทำถึงไหน

5. ☆ Community Skills → Optional
   → api-auditor, test-generator (ถ้ามีเวลา)
```

### 📊 ประมาณการณ์ประหยัดเวลา:

| เครื่องมือ | ไม่ใช้ | ใช้ | ประหยัด |
|-----------|--------|-----|---------|
| MASTER_PROMPT.md | AI ลืม Context ตลอด | AI จำ Context ได้ | ~2 ชม./วัน |
| MySQL MCP | เปิด phpMyAdmin ดูเอง | AI ดูให้ | ~1 ชม./วัน |
| SKILL.md | AI เขียนโค้ดไม่ Consistent | Format เดียวกันหมด | ~30 นาที/วัน |
| PROGRESS.md | งมหาว่าทำถึงไหน | รู้ทันที | ~20 นาที/วัน |
| **รวม** | | | **~3-4 ชม./วัน** |

> 💡 **8 วัน × 3-4 ชม. = ประหยัด ~24-32 ชั่วโมง** เทียบเท่าเพิ่มเวลาทำงาน 3-4 วัน!

---

### ⚠️ สิ่งที่ไม่ต้องทำตอนนี้:

```
❌ ไม่ต้อง: ติดตั้ง MCP เยอะเกินไป → จะสับสน
❌ ไม่ต้อง: ลง Community Skills 100 อัน → เลือกเฉพาะที่ต้องใช้
❌ ไม่ต้อง: ตั้ง MCP เชื่อม Production DB → อันตราย!
❌ ไม่ต้อง: ใช้ Supabase MCP → ไม่ได้ใช้ Supabase แล้ว
```

---

> 📝 **สร้างโดย:** Antigravity AI Assistant  
> **วันที่:** 3 กรกฎาคม 2026
