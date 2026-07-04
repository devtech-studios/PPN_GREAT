# 📖 คู่มือใช้งาน Skills — สำหรับคนที่ไม่เคยใช้มาก่อน

---

## 🤔 Skill คืออะไร? (อธิบาย 30 วินาที)

```
Skill = ไฟล์ SKILL.md ที่สอน AI ว่า "ต้องทำยังไง"

เปรียบเทียบ:
  ❌ ไม่มี Skill → จ้างช่างมาทำงาน โดยไม่บอกอะไรเลย → ทำผิดเยอะ
  ✅ มี Skill   → จ้างช่างมา + ให้คู่มือโปรเจกต์ → ทำถูกตั้งแต่แรก
```

---

## 📂 โครงสร้างที่สร้างให้แล้ว

```
d:\07_Projects\Work\PNN\ppn_great\
└── .agent/
    └── skills/
        ├── ppn-laravel-api/       ← Skill หลัก (ใช้ทุก endpoint)
        │   └── SKILL.md              - Response Format
        │                              - Naming Convention
        │                              - Controller/Model Template
        │                              - ENUM ทั้งหมด
        │                              - API Endpoints 81 อัน
        │
        ├── ppn-database/          ← Skill สร้าง Migration
        │   └── SKILL.md              - Migration Template
        │                              - ENUM ค่าที่ถูกต้อง
        │                              - FK Rules
        │                              - Schema ตัวอย่าง
        │
        ├── ppn-stock/             ← Skill ตัดสต็อก (⚠️ จุดตาย!)
        │   └── SKILL.md              - Atomic Transaction
        │                              - lockForUpdate
        │                              - StockMovement Log
        │                              - รับเข้าคลัง
        │
        └── ppn-finance/           ← Skill การเงิน
            └── SKILL.md              - Auto-generate เลขเอกสาร
                                       - คำนวณ Due Date
                                       - สร้าง QU/PI/DP/CI
```

---

## 🚀 วิธีใช้งาน

### วิธีที่ 1: AI อ่านอัตโนมัติ (ไม่ต้องทำอะไรเพิ่ม!)

```
เพียงแค่ไฟล์ SKILL.md อยู่ในโฟลเดอร์ .agent/skills/
→ Antigravity จะอ่านมันอัตโนมัติ!
→ คุณไม่ต้องทำอะไรเลย แค่สั่งงานตามปกติ
```

**ตัวอย่าง:**

```
คุณ: "สร้าง CustomerController ให้ฉัน"

AI จะ:
  1. อ่าน ppn-laravel-api/SKILL.md อัตโนมัติ
  2. ใช้ Response Format ตาม Skill
  3. ใช้ Naming Convention ตาม Skill
  4. ใส่ Activity Log ตาม Skill
  5. ใส่ Validation ตาม Skill
```

### วิธีที่ 2: สั่ง AI อ่านโดยตรง (ถ้าอยากให้ชัวร์)

```
คุณ: "อ่าน @.agent/skills/ppn-laravel-api/SKILL.md แล้วสร้าง CustomerController ให้ฉัน"
```

### วิธีที่ 3: ใช้กับโมดูลเฉพาะ

```
งาน Migration:
"อ่าน @.agent/skills/ppn-database/SKILL.md แล้วสร้าง Migration สำหรับตาราง customers"

งานตัดสต็อก:
"อ่าน @.agent/skills/ppn-stock/SKILL.md แล้วเขียน Delivery Confirm API ที่ตัดสต็อก"

งานการเงิน:
"อ่าน @.agent/skills/ppn-finance/SKILL.md แล้วเขียน Finance Document API"
```

---

## 📋 สรุป Skills ทั้ง 4 อัน

| Skill | ไฟล์ | ใช้เมื่อ | สิ่งที่ AI จะทำตาม |
|-------|------|---------|-------------------|
| **ppn-laravel-api** | `.agent/skills/ppn-laravel-api/SKILL.md` | ทุก endpoint | Response Format, Naming, Template, ENUM |
| **ppn-database** | `.agent/skills/ppn-database/SKILL.md` | สร้าง Migration | ENUM ค่าถูกต้อง, FK Rules, Schema |
| **ppn-stock** | `.agent/skills/ppn-stock/SKILL.md` | ตัดสต็อก/รับเข้า | Transaction, lockForUpdate, Movement |
| **ppn-finance** | `.agent/skills/ppn-finance/SKILL.md` | สร้างเอกสาร/เลขเอกสาร | DocNumber, DueDate, QU/PI/DP/CI |

---

## 💡 เคล็ดลับ

### 1. ไม่ต้อง @ ทุกไฟล์ Skill ในทุก Chat

```
✅ Skills อยู่ใน .agent/skills/ → AI อ่านอัตโนมัติ
✅ ไม่ต้อง @ mention → ประหยัด Context

⚠️ แต่ถ้า AI ทำผิด → ค่อย @ mention ให้ชัดเจน
```

### 2. MASTER_PROMPT.md vs SKILL.md ต่างกันยังไง?

```
MASTER_PROMPT.md:
  - ใช้สำหรับ: สรุปภาพรวมทั้งโปรเจกต์
  - ต้อง @ mention เอง
  - เหมาะกับ: เปิด Chat ใหม่ให้ AI เข้าใจ Context

SKILL.md:
  - ใช้สำหรับ: กฎเฉพาะทาง (แยกตามหัวข้อ)
  - AI อ่านอัตโนมัติ (ถ้าอยู่ใน .agent/skills/)
  - เหมาะกับ: ควบคุมคุณภาพโค้ดที่ AI เขียน
```

### 3. เพิ่ม Skill ใหม่ได้ตลอด

```
ถ้าเจอปัญหาซ้ำๆ เช่น:
  - AI ลืมใส่ Activity Log → เพิ่มใน Skill
  - AI ใช้ชื่อ Column ผิด → เพิ่มใน Skill
  - AI ลืม Validate → เพิ่มใน Skill

แค่แก้ไฟล์ SKILL.md → ครั้งถัดไป AI จะทำตาม!
```

### 4. ถ้าอยากให้ Skill ใช้ได้ทุกโปรเจกต์

```
ย้ายไปไว้ที่:
C:\Users\USER\.gemini\antigravity\skills\

แทนที่จะอยู่ใน .agent/skills/ ของโปรเจกต์

แต่สำหรับ PPN GREAT → ไว้ในโปรเจกต์ดีกว่า (เฉพาะทาง)
```

---

## ✅ Checklist เริ่มต้น

```
✅ สร้าง .agent/skills/ppn-laravel-api/SKILL.md แล้ว
✅ สร้าง .agent/skills/ppn-database/SKILL.md แล้ว
✅ สร้าง .agent/skills/ppn-stock/SKILL.md แล้ว
✅ สร้าง .agent/skills/ppn-finance/SKILL.md แล้ว

□ ทดสอบ: สั่ง AI สร้าง Controller → ดูว่า AI ใช้ Response Format ถูกไหม
□ ทดสอบ: สั่ง AI สร้าง Migration → ดูว่า ENUM ค่าถูกไหม
□ ถ้า AI ทำผิด → แก้ SKILL.md → ลองใหม่
```

---

> 📝 **สร้างโดย:** Antigravity AI Assistant  
> **วันที่:** 3 กรกฎาคม 2026
