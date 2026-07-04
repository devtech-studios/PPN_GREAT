# 🔀 PPN GREAT — Git Workflow Guide สำหรับทีม

> **เป้าหมาย:** ทุกคนในทีม push โค้ดโดยไม่ชนกัน  
> **Repo:** `devtech-studios/PPN_GREAT`

---

## 📌 โครงสร้าง Branch

```
main              ← 🔒 Branch หลัก (Production-ready)
│                    ห้าม push ตรง! ต้อง Merge ผ่าน PR เท่านั้น
│
├── frontend      ← 💙 Flutter Web (Frontend code)
│                    ทีม Frontend ทำงานตรงนี้
│
└── backend       ← 🟢 Laravel API (Backend code)
                     ทีม Backend ทำงานตรงนี้
```

### กฎสำคัญ:

```
✅ ทำงานบน branch ตัวเอง (frontend / backend)
✅ Merge เข้า main ผ่าน Pull Request เท่านั้น
❌ ห้าม push ตรงเข้า main!
❌ ห้ามทำงานบน main โดยตรง!
```

---

## 🚀 วิธีทำงาน (Step-by-step)

### สำหรับทีม Frontend (Flutter)

```bash
# 1. Clone repo (ครั้งแรกเท่านั้น)
git clone https://github.com/devtech-studios/PPN_GREAT.git
cd PPN_GREAT

# 2. สลับไป branch frontend
git checkout frontend

# 3. เขียนโค้ด... แก้ไขไฟล์...

# 4. เช็คว่าแก้อะไรบ้าง
git status

# 5. เพิ่มไฟล์ที่แก้
git add .

# 6. Commit (ใส่ข้อความบอกว่าทำอะไร)
git commit -m "feat: เพิ่มหน้า Customer List"

# 7. Push ขึ้น GitHub
git push origin frontend
```

### สำหรับทีม Backend (Laravel)

```bash
# 1. Clone repo (ครั้งแรก)
git clone https://github.com/devtech-studios/PPN_GREAT.git
cd PPN_GREAT

# 2. สลับไป branch backend
git checkout backend

# 3. เขียนโค้ด Laravel...

# 4. Commit + Push
git add .
git commit -m "feat: สร้าง CustomerController + Migration"
git push origin backend
```

---

## 🔄 การ Merge เข้า main

### เมื่อไหร่ต้อง Merge?

```
✅ เมื่อ Feature เสร็จ + ทดสอบแล้ว
✅ เมื่อจบแต่ละ Phase (25%, 50%, 75%, 100%)
✅ เมื่อต้องรวม Frontend + Backend เข้าด้วยกัน
```

### วิธี Merge (ผ่าน Pull Request):

```bash
# 1. Push โค้ดล่าสุดของ branch ก่อน
git push origin frontend  # หรือ backend

# 2. ไปที่ GitHub → สร้าง Pull Request
#    จาก: frontend → เข้า: main
#    หรือ: backend → เข้า: main

# 3. Review + Approve → กด Merge

# 4. หลัง Merge → ดึงโค้ดล่าสุดกลับมา
git checkout frontend
git pull origin main
```

---

## 📝 Commit Message Convention

ใช้ Prefix บอกประเภทงาน:

```
feat:     เพิ่ม Feature ใหม่           feat: สร้างหน้า Dashboard
fix:      แก้ Bug                     fix: แก้ Login ไม่ได้
refactor: ปรับโครงสร้างโค้ด            refactor: แยก Service class
docs:     แก้เอกสาร                   docs: อัปเดต README
style:    แก้ UI/CSS                  style: ปรับสี Sidebar
chore:    งานทั่วไป                    chore: อัปเดต dependencies
test:     เพิ่ม Test                   test: เพิ่ม test CustomerAPI
```

### ตัวอย่าง Commit ที่ดี:

```
✅ feat: เพิ่ม CustomerController + CRUD endpoints
✅ fix: แก้ stock ตัดซ้ำเมื่อกด confirm 2 ครั้ง
✅ feat: สร้าง Migration 26 ตาราง
✅ style: ปรับ responsive หน้า Project Detail

❌ แก้โค้ด            ← ไม่บอกว่าแก้อะไร
❌ update             ← ไม่มีรายละเอียด
❌ asdflkjasdf        ← ??
```

---

## 📂 โครงสร้าง Folder ใน Repo

```
PPN_GREAT/
├── .gitignore
├── README.md
├── Git_Workflow_Guide.md        ← ไฟล์นี้
├── Phase_Progress.md            ← ติดตาม 4 Phase
│
├── [Flutter Frontend Files]     ← branch: frontend
│   ├── lib/
│   ├── assets/
│   ├── web/
│   ├── test/
│   ├── pubspec.yaml
│   └── analysis_options.yaml
│
└── [Laravel Backend Files]      ← branch: backend (สร้างทีหลัง)
    ├── app/
    ├── config/
    ├── database/
    ├── routes/
    └── ...
```

---

## ⚠️ สถานการณ์ที่ต้องระวัง

### 1. โค้ดชนกัน (Merge Conflict)

```
เกิดขึ้นเมื่อ: 2 คนแก้ไฟล์เดียวกัน บรรทัดเดียวกัน

วิธีป้องกัน:
  ✅ Frontend แก้เฉพาะ lib/, assets/, web/
  ✅ Backend แก้เฉพาะ app/, config/, database/, routes/
  ✅ ถ้าต้องแก้ไฟล์ร่วม (เช่น README.md) → คุยกันก่อน

วิธีแก้ถ้าเกิด Conflict:
  1. git pull origin main
  2. เปิดไฟล์ที่ conflict → จะเห็น <<<<<<< และ >>>>>>>
  3. เลือกว่าจะเอาโค้ดไหน
  4. git add . && git commit -m "fix: resolve merge conflict"
```

### 2. ลืม Pull ก่อน Push

```
วิธีป้องกัน:
  ✅ ก่อน Push → ทำ git pull origin [branch] ก่อนเสมอ!

git pull origin frontend   # ดึงโค้ดล่าสุด
git push origin frontend   # แล้วค่อย Push
```

### 3. Push ไฟล์ที่ไม่ควร Push

```
ไฟล์ที่ไม่ควรอยู่ใน repo:
  ❌ .agent/ (AI Skills — เก็บ local)
  ❌ MASTER_PROMPT.md (AI Context)
  ❌ .env (Credentials)
  ❌ build/ (Flutter build output)
  ❌ vendor/ (Laravel dependencies)

→ ไฟล์เหล่านี้อยู่ใน .gitignore แล้ว ✅
```

---

## 🔑 Quick Reference

```bash
# ดูว่าอยู่ branch ไหน
git branch

# สลับ branch
git checkout frontend
git checkout backend

# ดึงโค้ดล่าสุด
git pull origin frontend

# ดู commit ล่าสุด
git log --oneline -5

# ยกเลิกการแก้ไฟล์ (ก่อน commit)
git checkout -- filename.dart

# ยกเลิก commit ล่าสุด (แต่เก็บไฟล์ไว้)
git reset --soft HEAD~1
```

---

> 📝 **สร้างโดย:** Antigravity AI Assistant  
> **วันที่:** 4 กรกฎาคม 2026
