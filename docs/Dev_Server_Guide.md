# 🖥️ คู่มือจัดการ Dev Server — PPN GREAT

> **เอกสารนี้อธิบายวิธีเปิด / ปิด / รีสตาร์ท เซิร์ฟเวอร์สำหรับการพัฒนา**
> รวมถึงวิธีวิเคราะห์ปัญหาเบื้องต้นเมื่อระบบหน้าบ้านหรือหลังบ้านไม่ทำงาน
>
> **อัปเดตล่าสุด:** 11 กรกฎาคม 2026

---

## 📋 สารบัญ

1. [ภาพรวมระบบ](#-ภาพรวมระบบ)
2. [เปิดเซิร์ฟเวอร์ (Start)](#-เปิดเซิร์ฟเวอร์-start)
3. [ปิดเซิร์ฟเวอร์ (Stop / Kill)](#-ปิดเซิร์ฟเวอร์-stop--kill)
4. [รีสตาร์ทเซิร์ฟเวอร์ (Restart)](#-รีสตาร์ทเซิร์ฟเวอร์-restart)
5. [Hot Reload / Hot Restart](#-hot-reload--hot-restart)
6. [วิเคราะห์ปัญหา (Troubleshooting)](#-วิเคราะห์ปัญหา-troubleshooting)
7. [Quick Reference Card](#-quick-reference-card)

---

## 🏗️ ภาพรวมระบบ

โปรเจกต์ PPN GREAT ใช้เซิร์ฟเวอร์ 2 ตัวทำงานคู่กัน:

```
┌─────────────────────────────────────────────────┐
│                เบราว์เซอร์ (Chrome)                │
│            http://127.0.0.1:5000                 │
└──────────────┬──────────────────┬────────────────┘
               │ (แสดงหน้าจอ)         │ (เรียก API)
               ▼                      ▼
┌──────────────────────┐  ┌──────────────────────────┐
│  Flutter Web Server  │  │   Laravel API Server     │
│  Port: 5000          │  │   Port: 8000             │
│  (หน้าบ้าน/Frontend) │  │   (หลังบ้าน/Backend)     │
│                      │  │                          │
│  📁 ppn_great/       │  │  📁 ppn-api/             │
└──────────────────────┘  └─────────┬────────────────┘
                                    │
                                    ▼
                          ┌──────────────────┐
                          │   MySQL Database │
                          │   (XAMPP/MySQL)   │
                          │   Port: 3306     │
                          └──────────────────┘
```

| เซิร์ฟเวอร์ | โฟลเดอร์ | URL | หน้าที่ |
|---|---|---|---|
| **Flutter Web** | `d:\07_Projects\Work\PNN\ppn_great` | `http://127.0.0.1:5000` | แสดงหน้าจอ UI ให้ผู้ใช้ |
| **Laravel API** | `d:\07_Projects\Work\PNN\ppn-api` | `http://127.0.0.1:8000` | จัดการข้อมูล / เชื่อมต่อ Database |
| **MySQL** | XAMPP | `localhost:3306` | เก็บข้อมูลทั้งหมด |

> [!IMPORTANT]
> **ต้องเปิดทั้ง 3 ตัว** ถึงจะใช้งานได้ครบ:
> MySQL (XAMPP) → Laravel API → Flutter Web

---

## 🟢 เปิดเซิร์ฟเวอร์ (Start)

### ขั้นตอนที่ 0: เปิด MySQL (ถ้ายังไม่ได้เปิด)

เปิดแอป **XAMPP Control Panel** แล้วกดปุ่ม **Start** ที่แถว **MySQL**

### ขั้นตอนที่ 1: เปิด Laravel API Server

เปิด **Terminal / PowerShell** แล้วรันคำสั่ง:

```powershell
# เข้าโฟลเดอร์ API
cd d:\07_Projects\Work\PNN\ppn-api

# สตาร์ทเซิร์ฟเวอร์ API
C:\xampp\php\php.exe artisan serve
```

**ผลลัพธ์ที่ถูกต้อง:**
```
INFO  Server running on [http://127.0.0.1:8000].
Press Ctrl+C to stop the server
```

> [!TIP]
> ถ้าเห็นคำว่า `Server running on [http://127.0.0.1:8000]` แสดงว่า API พร้อมใช้งานแล้ว

### ขั้นตอนที่ 2: เปิด Flutter Web Server

เปิด **Terminal / PowerShell อีกหน้าต่างหนึ่ง** (ห้ามใช้หน้าต่างเดียวกับ API) แล้วรันคำสั่ง:

```powershell
# เข้าโฟลเดอร์ Flutter
cd d:\07_Projects\Work\PNN\ppn_great

# สตาร์ทเซิร์ฟเวอร์ Flutter Web
d:\flutter\bin\flutter.bat run -d web-server --web-port=5000
```

**ผลลัพธ์ที่ถูกต้อง (รอประมาณ 30-60 วินาที):**
```
Launching lib\main.dart on Web Server in debug mode...
lib\main.dart is being served at http://localhost:5000

Flutter run key commands.
r Hot reload.
R Hot restart.
```

### ขั้นตอนที่ 3: เปิดเบราว์เซอร์

เปิด Chrome แล้วเข้า: **http://127.0.0.1:5000**

---

## 🔴 ปิดเซิร์ฟเวอร์ (Stop / Kill)

### วิธีที่ 1: ปิดแบบปกติ (Graceful Stop)

**ใช้สำหรับ:** ปิดเซิร์ฟเวอร์ที่รันอยู่ใน Terminal ตรงหน้า

```
กดปุ่ม Ctrl + C ในหน้าต่าง Terminal ที่เซิร์ฟเวอร์นั้นกำลังรันอยู่
```

- กด `Ctrl + C` ใน Terminal ของ **Laravel** → ปิด API Server
- กด `q` แล้ว Enter หรือ `Ctrl + C` ใน Terminal ของ **Flutter** → ปิด Flutter Web Server

### วิธีที่ 2: บังคับปิด (Force Kill) — เมื่อหาหน้าต่าง Terminal ไม่เจอ

**ใช้สำหรับ:** เซิร์ฟเวอร์ค้าง หรือปิดหน้าต่าง Terminal ไปแล้วแต่ Port ยังถูกใช้งานอยู่

#### Kill Laravel API (Port 8000):
```powershell
# ดูว่า Process ไหนใช้ Port 8000 อยู่
netstat -ano | findstr :8000

# ผลลัพธ์ตัวอย่าง:
# TCP  0.0.0.0:8000  0.0.0.0:0  LISTENING  12345
#                                           ^^^^^ นี่คือ PID

# Kill ด้วย PID ที่ได้
taskkill /PID 12345 /F
```

#### Kill Flutter Web (Port 5000):
```powershell
# ดูว่า Process ไหนใช้ Port 5000 อยู่
netstat -ano | findstr :5000

# Kill ด้วย PID
taskkill /PID <หมายเลข PID> /F
```

#### Kill ทุก Process ของ PHP (กรณีฉุกเฉิน):
```powershell
taskkill /IM php.exe /F
```

#### Kill ทุก Process ของ Dart (กรณีฉุกเฉิน):
```powershell
taskkill /IM dart.exe /F
```

> [!WARNING]
> การใช้ `taskkill /IM php.exe /F` จะ Kill **ทุก PHP process** ในเครื่อง
> ใช้เฉพาะกรณีที่แน่ใจว่าไม่มี PHP อื่นรันอยู่

---

## 🔄 รีสตาร์ทเซิร์ฟเวอร์ (Restart)

### รีสตาร์ท Laravel API

```powershell
# ขั้นตอนที่ 1: ปิดเซิร์ฟเวอร์เก่า
# กด Ctrl+C ใน Terminal ที่ Laravel รันอยู่

# ขั้นตอนที่ 2: เปิดใหม่
cd d:\07_Projects\Work\PNN\ppn-api
C:\xampp\php\php.exe artisan serve
```

### รีสตาร์ท Flutter Web (แบบธรรมดา)

```powershell
# ขั้นตอนที่ 1: ปิดเซิร์ฟเวอร์เก่า
# กด q แล้ว Enter (หรือ Ctrl+C) ใน Terminal ที่ Flutter รันอยู่

# ขั้นตอนที่ 2: เปิดใหม่
cd d:\07_Projects\Work\PNN\ppn_great
d:\flutter\bin\flutter.bat run -d web-server --web-port=5000
```

### รีสตาร์ท Flutter Web (แบบ Clean Build — ล้างแคชทั้งหมด)

**ใช้เมื่อ:** หน้าจอขาวค้าง / โหลดไม่ขึ้น / แก้โค้ดแล้วไม่เปลี่ยน

```powershell
# ขั้นตอนที่ 1: ปิดเซิร์ฟเวอร์เก่า
# กด q แล้ว Enter (หรือ Ctrl+C)

# ขั้นตอนที่ 2: ล้าง Build Cache
cd d:\07_Projects\Work\PNN\ppn_great
d:\flutter\bin\flutter.bat clean

# ขั้นตอนที่ 3: ดาวน์โหลด Dependencies ใหม่
d:\flutter\bin\flutter.bat pub get

# ขั้นตอนที่ 4: เปิดเซิร์ฟเวอร์ใหม่
d:\flutter\bin\flutter.bat run -d web-server --web-port=5000
```

> [!TIP]
> **Clean Build ใช้เวลานานกว่าปกติ** (ประมาณ 30-60 วินาที) แต่จะแก้ปัญหาแคชเก่าค้างได้ 100%

---

## ⚡ Hot Reload / Hot Restart

**ใช้ในระหว่างพัฒนา** เมื่อแก้ไขโค้ด Flutter แล้วต้องการเห็นผลทันทีโดยไม่ต้องปิด-เปิดเซิร์ฟเวอร์ใหม่

| คำสั่ง | วิธีใช้ | ความเร็ว | ผลลัพธ์ |
|---|---|---|---|
| **Hot Reload** | กดปุ่ม `r` (ตัวเล็ก) ใน Terminal ที่ Flutter รันอยู่ | ~1 วินาที | อัปเดตเฉพาะส่วนที่เปลี่ยน แต่ **เก็บ state เดิมไว้** (เช่น ข้อมูลในฟอร์ม ยังอยู่) |
| **Hot Restart** | กดปุ่ม `R` (ตัวใหญ่) ใน Terminal ที่ Flutter รันอยู่ | ~2-3 วินาที | รีเซ็ตแอปทั้งหมด **state หายหมด** (กลับไปหน้า Login ใหม่) |

### ตัวอย่างการใช้:

```
# กรณี: แก้สี ปุ่ม ข้อความ → ใช้ Hot Reload (เร็ว ไม่เสีย State)
กด r แล้ว Enter

# กรณี: แก้ Logic, เพิ่ม field ใหม่, แก้ constructor → ใช้ Hot Restart
กด R แล้ว Enter
```

**ผลลัพธ์ใน Terminal:**
```
Performing hot reload...                                           1.2s
Reloaded 1 of 600 libraries in 1,200ms.

# หรือ

Performing hot restart...                                          2.5s
Restarted application in 2,500ms.
```

> [!NOTE]
> หลังจาก Hot Restart ต้อง **Refresh เบราว์เซอร์ (F5)** ด้วยเสมอ
> เพราะ Flutter Web จะ Build ไฟล์ใหม่ แต่เบราว์เซอร์ยังแคชไฟล์เก่าอยู่

---

## 🔍 วิเคราะห์ปัญหา (Troubleshooting)

### ❌ ปัญหาที่ 1: หน้าจอขาว (White Screen) — โหลดไม่ขึ้น

**อาการ:**
- เปิด `http://127.0.0.1:5000` แล้วเห็นหน้าจอขาวเปล่า
- มีแถบโหลดสีฟ้าค้างอยู่ที่ขอบบนสุดของ Chrome
- ไอคอน Tab ของ Chrome หมุนวนไม่หยุด

**สาเหตุที่เป็นไปได้:**

| สาเหตุ | วิธีตรวจ | วิธีแก้ |
|---|---|---|
| **Chrome Network Throttling เปิดอยู่** | ดูที่แถบด้านบนของ DevTools ว่ามีคำว่า "4G แบบช้า" หรือ "Slow 3G" ไหม | เปลี่ยนเป็น "ไม่มีการควบคุม" (No throttling) |
| **Build Cache เก่าค้าง** | เปิด Console (F12) ดูว่ามี Error สีแดงไหม | ทำ Clean Build (ดูหัวข้อรีสตาร์ทแบบ Clean Build ด้านบน) |
| **Flutter Server ไม่ได้รัน** | ดูใน Terminal ว่ามีคำว่า `is being served at http://localhost:5000` ไหม | สตาร์ท Flutter Server ใหม่ |
| **Port 5000 ถูกใช้ซ้ำ** | รัน `netstat -ano \| findstr :5000` | Kill process เก่า แล้วรันใหม่ |

**ขั้นตอนแก้ไขทีละขั้น:**

```
ขั้นที่ 1: กด Ctrl+Shift+R (Hard Reload) ในเบราว์เซอร์
        ↓ ยังขาวอยู่?
ขั้นที่ 2: ปิดแท็บเก่า → เปิดแท็บใหม่ → เข้า http://127.0.0.1:5000
        ↓ ยังขาวอยู่?
ขั้นที่ 3: เช็ค Chrome DevTools → ปิด Network Throttling
        ↓ ยังขาวอยู่?
ขั้นที่ 4: Kill Flutter Server → flutter clean → pub get → run ใหม่
        ↓ ยังขาวอยู่?
ขั้นที่ 5: Kill ทั้ง API + Flutter → Restart ทั้งหมด
```

---

### ❌ ปัญหาที่ 2: "Connection Refused" หรือ "ไม่สามารถเข้าถึงเว็บไซต์นี้ได้"

**อาการ:**
- Chrome แสดงข้อความ `ERR_CONNECTION_REFUSED`
- หน้าจอเป็นหน้าขาวพร้อมข้อความ Error ของ Chrome

**วิธีแก้:**
```powershell
# 1. ตรวจสอบว่า Flutter Server รันอยู่ไหม
netstat -ano | findstr :5000
# ถ้าไม่มีอะไรขึ้น = ไม่ได้รัน → ให้สตาร์ทใหม่

# 2. ตรวจสอบว่า API Server รันอยู่ไหม
netstat -ano | findstr :8000
# ถ้าไม่มีอะไรขึ้น = ไม่ได้รัน → ให้สตาร์ทใหม่
```

---

### ❌ ปัญหาที่ 3: กดปุ่มแล้วไม่ตอบสนอง / ข้อมูลไม่โหลด

**อาการ:**
- หน้าจอขึ้นมาแล้ว แต่กดปุ่มต่าง ๆ ไม่มีอะไรเกิดขึ้น
- ตารางข้อมูลว่างเปล่า

**วิธีวิเคราะห์:**
```
ขั้นที่ 1: กด F12 เปิด Chrome DevTools
ขั้นที่ 2: คลิกแท็บ "คอนโซล" (Console)
ขั้นที่ 3: ดูว่ามีข้อความสีแดง (Error) อะไรบ้าง
```

**ตัวอย่าง Error ที่พบบ่อย:**

| Error ที่เห็นใน Console | ความหมาย | วิธีแก้ |
|---|---|---|
| `CORS policy: No 'Access-Control-Allow-Origin'` | API ไม่อนุญาต Cross-Origin | เช็ก `.env` ของ Laravel ว่ามี CORS config ถูกต้อง |
| `Failed to fetch` หรือ `net::ERR_CONNECTION_REFUSED` | API Server ไม่ได้รัน | สตาร์ท Laravel API Server |
| `401 Unauthorized` | Token หมดอายุ หรือ ยังไม่ Login | กด Logout แล้ว Login ใหม่ |
| `404 Not Found` | URL ของ API ผิด | เช็ก Route ใน `routes/api.php` |
| `500 Internal Server Error` | โค้ด PHP มีบั๊ก | ดูไฟล์ `ppn-api/storage/logs/laravel.log` |

---

### ❌ ปัญหาที่ 4: "Port already in use" / พอร์ตซ้ำ

**อาการ:**
```
Failed to listen on 127.0.0.1:8000 (reason: An attempt was made to access a socket in a way forbidden by its access permissions.)
```

**วิธีแก้:**
```powershell
# หา Process ที่ใช้ Port อยู่
netstat -ano | findstr :8000

# Kill มัน
taskkill /PID <หมายเลข PID> /F

# แล้วสตาร์ทใหม่
C:\xampp\php\php.exe artisan serve
```

---

### ❌ ปัญหาที่ 5: "SQLSTATE[HY000] [2002]" Database เชื่อมต่อไม่ได้

**อาการ:**
```
SQLSTATE[HY000] [2002] No connection could be made because the target machine actively refused it
```

**วิธีแก้:**
1. เปิด **XAMPP Control Panel**
2. ดูที่แถว **MySQL** → ถ้ายังไม่ขึ้นสีเขียว ให้กดปุ่ม **Start**
3. รอจนขึ้นสีเขียว แล้วลองใหม่

---

### ❌ ปัญหาที่ 6: แก้โค้ดแล้วแต่หน้าจอไม่เปลี่ยน

**อาการ:**
- แก้ไขโค้ด Flutter เสร็จ แต่หน้าเว็บยังแสดงผลเหมือนเดิม

**วิธีแก้ (เรียงจากเร็ว → ช้า):**
```
1. กด r (Hot Reload) → Refresh เบราว์เซอร์ (F5)
2. กด R (Hot Restart) → Refresh เบราว์เซอร์ (F5)
3. Ctrl+Shift+R (Hard Reload เบราว์เซอร์)
4. flutter clean → pub get → run ใหม่
```

---

## 📌 Quick Reference Card

### 🟢 เปิดทุกอย่าง (Start All)
```powershell
# Terminal 1 — API
cd d:\07_Projects\Work\PNN\ppn-api
C:\xampp\php\php.exe artisan serve

# Terminal 2 — Flutter
cd d:\07_Projects\Work\PNN\ppn_great
d:\flutter\bin\flutter.bat run -d web-server --web-port=5000
```

### 🔴 ปิดทุกอย่าง (Stop All)
```powershell
# Terminal 1 — กด Ctrl+C
# Terminal 2 — กด q แล้ว Enter (หรือ Ctrl+C)
```

### 🔄 รีสตาร์ทแบบ Clean (Nuclear Option)
```powershell
# Kill ทุกอย่าง
taskkill /IM php.exe /F
taskkill /IM dart.exe /F

# Clean + Restart Flutter
cd d:\07_Projects\Work\PNN\ppn_great
d:\flutter\bin\flutter.bat clean
d:\flutter\bin\flutter.bat pub get
d:\flutter\bin\flutter.bat run -d web-server --web-port=5000

# Restart API (Terminal ใหม่)
cd d:\07_Projects\Work\PNN\ppn-api
C:\xampp\php\php.exe artisan serve
```

### 🩺 เช็กสถานะ
```powershell
# เช็กว่า API รันอยู่ไหม
netstat -ano | findstr :8000

# เช็กว่า Flutter รันอยู่ไหม
netstat -ano | findstr :5000

# เช็กว่า MySQL รันอยู่ไหม
netstat -ano | findstr :3306
```

### 📋 ดู Laravel Error Log
```powershell
# ดู Error ล่าสุดของ Laravel
Get-Content d:\07_Projects\Work\PNN\ppn-api\storage\logs\laravel.log -Tail 50
```

---

## 💡 เคล็ดลับสำคัญ

> [!TIP]
> **เปิดเซิร์ฟเวอร์เสมอเมื่อเริ่มงาน:** เปิด XAMPP (MySQL) → Laravel API → Flutter Web ตามลำดับ

> [!TIP]
> **ก่อนเริ่มงานทุกครั้ง** ลองเข้า `http://127.0.0.1:5000` ดูก่อนว่าหน้าจอขึ้นไหม ถ้าไม่ขึ้นให้ตรวจสอบเซิร์ฟเวอร์ตามขั้นตอนด้านบน

> [!WARNING]
> **อย่าเปิด Network Throttling ใน Chrome DevTools ค้างไว้!**
> ถ้าเปิดอยู่ จะทำให้โหลดช้ามากเพราะ Flutter Web Debug มีไฟล์ขนาดใหญ่ ~27MB
> ตรวจสอบโดยดูที่แถบด้านบนของ DevTools ว่าเขียนว่า "ไม่มีการควบคุม" หรือไม่

> [!CAUTION]
> **อย่าปิด Terminal ที่เซิร์ฟเวอร์รันอยู่!**
> ถ้าปิดหน้าต่าง Terminal โดยไม่ได้กด Ctrl+C ก่อน Process จะยังคงค้างอยู่ในพื้นหลัง
> และจะทำให้เกิดปัญหา "Port already in use" เมื่อต้องการสตาร์ทใหม่
