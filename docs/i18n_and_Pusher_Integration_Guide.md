# 📘 คู่มือการใช้งานระบบรองรับ 2 ภาษา (i18n) และระบบแจ้งเตือน Real-time (Pusher Integration)
**ระบบ PPN GREAT ERP - Import Operation Platform**

---

## 📌 สารบัญ (Table of Contents)
1. [เรื่องที่ 1: ระบบรองรับ 2 ภาษา (Bilingual i18n Localization System)](#เรื่องที่-1-ระบบรองรับ-2-ภาษา-bilingual-i18n-localization-system)
   - [1.1 โครงสร้างสถาปัตยกรรมและไฟล์ทรัพยากร (ARB Resources)](#11-โครงสร้างสถาปัตยกรรมและไฟล์ทรัพยากร-arb-resources)
   - [1.2 การจัดการสถานะภาษาแบบถาวร (LocaleProvider & SharedPreferences)](#12-การจัดการสถานะภาษาแบบถาวร-localeprovider--sharedpreferences)
   - [1.3 ปุ่มสลับภาษาและการนำไปใช้งานบน UI (Widget Integration)](#13-ปุ่มสลับภาษาและการนำไปใช้งานบน-ui-widget-integration)
   - [1.4 คำแนะนำสำหรับการเพิ่มหรือแก้ไขคำแปลในอนาคต (How to Maintain)](#14-คำแนะนำสำหรับการเพิ่มหรือแก้ไขคำแปลในอนาคต-how-to-maintain)
2. [เรื่องที่ 2: ระบบสื่อสารข้อมูลแบบ Real-time (Pusher Channels Integration)](#เรื่องที่-2-ระบบสื่อสารข้อมูลแบบ-real-time-pusher-channels-integration)
   - [2.1 การตั้งค่าฝั่งหลังบ้าน (Laravel API Backend - `ppn-api`)](#21-การตั้งค่าฝั่งหลังบ้าน-laravel-api-backend---ppn-api)
   - [2.2 คลาส Event และการยิงสัญญาณ (ShouldBroadcastNow & Routes)](#22-คลาส-event-และการยิงสัญญาณ-shouldbroadcastnow--routes)
   - [2.3 การตั้งค่าฝั่งหน้าบ้าน (Flutter Web Frontend - `ppn_great`)](#23-การตั้งค่าฝั่งหน้าบ้าน-flutter-web-frontend---ppn_great)
   - [2.4 ขั้นตอนการทดสอบยิงสัญญาณ Real-time (Verification & Debugging)](#24-ขั้นตอนการทดสอบยิงสัญญาณ-real-time-verification--debugging)
3. [เรื่องที่ 3: ตารางจำแนกและวิเคราะห์เชิงลึก API Endpoints (Real-time vs Non-Real-time Matrix)](#เรื่องที่-3-ตารางจำแนกและวิเคราะห์เชิงลึก-api-endpoints-real-time-vs-non-real-time-matrix)
   - [3.1 ตารางจำแนก API Endpoints ทั้งหมดในระบบ (API Classification Matrix)](#31-ตารางจำแนก-api-endpoints-ทั้งหมดในระบบ-api-classification-matrix)
   - [3.2 การวิเคราะห์เชิงลึก: ทำไมเส้น API เหล่านี้ถึงต้องเป็น Real-time? (Architectural Rationale)](#32-การวิเคราะห์เชิงลึก-ทำไมเส้น-api-เหล่านี้ถึงต้องเป็น-real-time-architectural-rationale)

---

# 1. 🌐 เรื่องที่ 1: ระบบรองรับ 2 ภาษา (Bilingual i18n Localization System)

ระบบรองรับสองภาษา (ภาษาไทยเป็นภาษาเริ่มต้น และภาษาอังกฤษเป็นภาษาทางเลือก) ถูกออกแบบให้เป็นระบบ Localization มาตรฐานของ Flutter โดยมีการบันทึกค่าภาษาลงใน `SharedPreferences` เพื่อให้คงสถานะเดิมไว้เสมอเมื่อผู้ใช้งานเปิดแอปขึ้นมาใหม่

### 1.1 โครงสร้างสถาปัตยกรรมและไฟล์ทรัพยากร (ARB Resources)

* **ไฟล์คอนฟิกูเรชัน (`l10n.yaml`)**:
  ```yaml
  arb-dir: lib/l10n
  template-arb-file: app_th.arb
  output-localization-file: app_localizations.dart
  nullable-getter: true
  ```
* **ไฟล์คลังคำแปล (Resource Bundles)**:
  * `lib/l10n/app_th.arb`: คลังข้อความภาษาไทย (ภาษาหลัก)
  * `lib/l10n/app_en.arb`: คลังข้อความภาษาอังกฤษ (ภาษาทางเลือก)

#### ตัวอย่างโครงสร้างไฟล์ `app_th.arb`:
```json
{
  "@@locale": "th",
  "appTitle": "PPN GREAT",
  "dashboardGreeting": "สวัสดี คุณ {name} 👋",
  "@dashboardGreeting": {
    "placeholders": {
      "name": { "type": "String" }
    }
  },
  "projects": "โปรเจกต์",
  "samples": "ตัวอย่างสินค้า",
  "artwork": "อาร์ตเวิร์ก",
  "containers": "ตู้คอนเทนเนอร์",
  "activeProjectsHeader": "โปรเจกต์ที่กำลังดำเนินการ",
  "quickActionsHeader": "ทางลัดดำเนินการ",
  "cashflowHeader": "ภาพรวมกระแสเงินสด",
  "upcomingScheduleHeader": "กำหนดการเร็วๆ นี้"
}
```

---

### 1.2 การจัดการสถานะภาษาแบบถาวร (LocaleProvider & SharedPreferences)

ไฟล์ `lib/core/locale/locale_provider.dart` ทำหน้าที่บริหารจัดการ State การสลับภาษา และซิงก์ข้อมูลกับ `SharedPreferences`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  Locale _locale = const Locale('th');

  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';

  LocaleProvider() {
    loadSavedLocale();
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(_localeKey);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, newLocale.languageCode);
  }

  void toggleLanguage() {
    if (_locale.languageCode == 'th') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('th'));
    }
  }
}

final localeProvider = LocaleProvider();
```

---

### 1.3 ปุ่มสลับภาษาและการนำไปใช้งานบน UI (Widget Integration)

#### 1. Widget ปุ่มสลับภาษา (`lib/shared/widgets/language_switch_button.dart`):
ออกแบบในสไตล์ **TH | EN** Pill Badge Design:

```dart
import 'package:flutter/material.dart';
import 'package:ppn_great/core/locale/locale_provider.dart';

class LanguageSwitchButton extends StatelessWidget {
  const LanguageSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeProvider,
      builder: (context, _) {
        final isEn = localeProvider.isEnglish;
        return GestureDetector(
          onTap: () => localeProvider.toggleLanguage(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBadge("TH", !isEn),
                const SizedBox(width: 4),
                _buildBadge("EN", isEn),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2563EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: active ? Colors.white : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
```

#### 2. วิธีการเรียกใช้คำแปลใน Widget หน้าจอต่างๆ:
ใช้ `S.of(context)!` ดึงคำแปลที่ตรงกับภาษาปัจจุบัน:
```dart
import 'package:ppn_great/l10n/app_localizations.dart';

// ตัวอย่างการดึงข้อความ:
Text(S.of(context)!.activeProjectsHeader)
Text(S.of(context)!.cardBudget)
Text(S.of(context)!.btnCreateNewProject)
```

---

### 1.4 คำแนะนำสำหรับการเพิ่มหรือแก้ไขคำแปลในอนาคต (How to Maintain)

เมื่อต้องการเพิ่มข้อความใหม่ในระบบ ให้ทำตาม 3 ขั้นตอนดังนี้:
1. เพิ่มคีย์ใน `lib/l10n/app_th.arb` (ภาษาไทย)
2. เพิ่มคีย์ที่มีชื่อเดียวกันใน `lib/l10n/app_en.arb` (ภาษาอังกฤษ)
3. เปิด Terminal แล้วสั่งรันคำสั่งเจเนอเรตโค้ด:
   ```bash
   flutter gen-l10n
   ```

---

# 2. ⚡ เรื่องที่ 2: ระบบสื่อสารข้อมูลแบบ Real-time (Pusher Channels Integration)

ระบบ Real-time Notifications ช่วยให้แอปพลิเคชันสามารถรับส่งสัญญาณแจ้งเตือนระหว่างหลังบ้าน (Laravel) และหน้าบ้าน (Flutter Web) ได้ทันทีในเวลา 0.1 วินาที โดยไม่ต้องกด Refresh หน้าจอ

### 2.1 การตั้งค่าฝั่งหลังบ้าน (Laravel API Backend - `ppn-api`)

#### 1. ติดตั้งแพ็กเกจ Pusher PHP SDK:
```bash
C:\xampp\php\php.exe composer.phar require pusher/pusher-php-server --ignore-platform-reqs
```

#### 2. กำหนดค่าคอนฟิกใน `ppn-api/.env`:
```ini
BROADCAST_CONNECTION=pusher
BROADCAST_DRIVER=pusher

PUSHER_APP_ID=2179947
PUSHER_APP_KEY=4a413d88db5afa161283
PUSHER_APP_SECRET=7dc23ed8e8d1ecf91d1e
PUSHER_APP_CLUSTER=ap1
PUSHER_SCHEME=https
```

#### 3. สร้างไฟล์ตั้งค่า `config/broadcasting.php`:
```php
<?php

return [
    'default' => env('BROADCAST_CONNECTION', 'pusher'),

    'connections' => [
        'pusher' => [
            'driver' => 'pusher',
            'key' => env('PUSHER_APP_KEY'),
            'secret' => env('PUSHER_APP_SECRET'),
            'app_id' => env('PUSHER_APP_ID'),
            'options' => [
                'cluster' => env('PUSHER_APP_CLUSTER', 'ap1'),
                'useTLS' => true,
            ],
        ],
        'log' => ['driver' => 'log'],
        'null' => ['driver' => 'null'],
    ],
];
```

---

### 2.2 คลาส Event และการยิงสัญญาณ (ShouldBroadcastNow & Routes)

#### 1. สร้าง Event Class (`app/Events/MyEvent.php`):
```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MyEvent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    public function __construct($message = 'hello world')
    {
        $this->message = $message;
    }

    public function broadcastOn(): array
    {
        return ['my-channel'];
    }

    public function broadcastAs(): string
    {
        return 'my-event';
    }
}
```

#### 2. สร้าง Route สำหรับยิงทดสอบ (`routes/api.php`):
```php
Route::get('test-pusher', function () {
    event(new \App\Events\MyEvent('Hello from PPN GREAT API!'));
    return response()->json([
        'success' => true,
        'message' => 'Pusher event broadcasted successfully!'
    ]);
});
```

---

### 2.3 การตั้งค่าฝั่งหน้าบ้าน (Flutter Web Frontend - `ppn_great`)

#### 1. เพิ่ม Pusher JS Client SDK ใน `web/index.html`:
```html
<script src="https://js.pusher.com/8.4.0/pusher.min.js"></script>
<script>
  window.initPusherNotification = function(appKey, cluster) {
    if (window.pusherClient) return;
    window.pusherClient = new Pusher(appKey, { cluster: cluster });
    var channel = window.pusherClient.subscribe('my-channel');
    channel.bind('my-event', function(data) {
      console.log('[Pusher Web] Event Received:', data);
      if (window.onPusherEventReceived) {
        window.onPusherEventReceived(JSON.stringify(data));
      }
    });
  };
</script>
```

#### 2. สร้าง Pusher Service (`lib/core/services/pusher_service.dart`):
```dart
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class PusherService {
  static final PusherService instance = PusherService._internal();
  PusherService._internal();

  bool _initialized = false;

  void initPusher({
    String appKey = "4a413d88db5afa161283",
    String cluster = "ap1",
    Function(String message)? onMessageReceived,
  }) {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      try {
        js.context['onPusherEventReceived'] = (String data) {
          debugPrint("[Pusher Flutter] Event payload: $data");
          if (onMessageReceived != null) {
            onMessageReceived(data);
          }
        };

        js.context.callMethod('initPusherNotification', [appKey, cluster]);
        debugPrint("[Pusher Service] Initialized Pusher Real-time Client!");
      } catch (e) {
        debugPrint("[Pusher Service Error] $e");
      }
    }
  }
}
```

---

### 2.4 ขั้นตอนการทดสอบยิงสัญญาณ Real-time (Verification & Debugging)

1. **เปิด Pusher Dashboard**: เข้าไปยังหน้าแอป `ppn-great-staging` แล้วเปิดเมนู **`Debug Console`**
2. **เรียกยิง API ทดสอบ**: เปิดเบราว์เซอร์หรือยิงเรียก Endpoint:
   ```http
   GET http://localhost:8000/api/test-pusher
   ```
3. **ตรวจสอบผลลัพธ์**:
   - **API Response**: `{"success": true, "message": "Pusher event broadcasted successfully!"}`
   - **Pusher Debug Console**: แสดงรายการ **API Message** สัญญาณ `my-event` บน Channel `my-channel` ทันทีใน 0.1 วินาที! 🚀

---

# 3. ⚡📊 เรื่องที่ 3: ตารางจำแนกและวิเคราะห์เชิงลึก API Endpoints (Real-time vs Non-Real-time Matrix)

## 3.1 ตารางจำแนก API Endpoints ทั้งหมดในระบบ (API Classification Matrix)

| โมดูล (Module) | API Endpoint | HTTP Method | ประเภทการทำงาน (Type) | เหตุผลและวัตถุประสงค์เชิงธุรกิจ (Business Rationale & Trigger) | สัญญาณ Broadcast (Pusher Event & Channel) |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **Authentication** | `/api/auth/login` | POST | 🔴 Non-Real-time | รับ Token เข้าใช้งานส่วนบุคคล ไม่จำเป็นต้องแจ้งเตือนผู้อื่น | - |
| | `/api/auth/logout` | POST | 🔴 Non-Real-time | ทำลาย Token เซสชันส่วนตัว | - |
| | `/api/auth/me` | GET | 🔴 Non-Real-time | ดึงโปรไฟล์ผู้ใช้งานปัจจุบัน | - |
| **Customers** | `/api/customers` | GET / POST | 🟢 Real-time (POST) | เมื่อมีการเพิ่มลูกค้าใหม่ ต้องแจ้งเตือนทีมขายและผู้บริหารทราบ | Channel: `customers-channel`<br>Event: `customer-created` |
| | `/api/customers/{id}` | GET / PUT | 🔴 Non-Real-time | แก้ไขข้อมูลทั่วไปของลูกค้า | - |
| | `/api/customers/{id}/contacts` | POST / PUT / DELETE | 🔴 Non-Real-time | จัดการผู้ติดต่อ | - |
| **Projects** | `/api/projects` | GET / POST | 🟢 Real-time (POST) | เมื่อเปิดโปรเจกต์ใหม่ ต้องกระจายข้อมูลให้ทีมจัดซื้อและสเปกเกอร์รับทราบ | Channel: `projects-channel`<br>Event: `project-created` |
| | `/api/projects/{id}/status` | PATCH | 🟢 Real-time (PATCH) | **[วิกฤต!]** เปลี่ยนสถานะโปรเจกต์ (Inquiry ➔ Deposit ➔ Production ➔ Shipping) ต้องอัปเดต Pipeline บน Dashboard ของทีมงานทุกคนทันทีใน <0.1 วินาทีโดยไม่ต้องกด Refresh | Channel: `projects-channel`<br>Event: `project-status-updated` |
| | `/api/projects/{id}/upload-po` | POST | 🟢 Real-time (POST) | เมื่อลูกค้าแนบไฟล์ PO ต้องแจ้งเตือนฝ่ายการเงินให้ออกใบแจ้งหนี้มัดจำ (PI) ทันที | Channel: `projects-channel`<br>Event: `po-uploaded` |
| **Suppliers & Quotes** | `/api/suppliers` | GET / POST / PUT | 🔴 Non-Real-time | จัดการรายชื่อโรงงานคู่ค้า | - |
| | `/api/suppliers/{id}/quotes/generate-link` | POST | 🔴 Non-Real-time | สร้างลิงก์ส่งให้โรงงาน | - |
| | `/api/supplier/portal/quotes/{qid}/submit` | POST | 🟢 Real-time (POST) | **[วิกฤต!]** เมื่อโรงงานที่จีนกรอกราคาทุนกลับมาจาก Supplier Portal ต้องเด้งแจ้งเตือนฝ่ายจัดซื้อ (Purchasing Agent) ทันที เพื่อทำใบเสนอราคาให้ลูกค้าอย่างรวดเร็ว | Channel: `quotes-channel`<br>Event: `supplier-quote-submitted` |
| **Samples & Artwork** | `/api/suppliers/{id}/samples/{sid}/status` | PATCH | 🟢 Real-time (PATCH) | อัปเดตสถานะตัวอย่างสินค้า (ผ่าน/ไม่ผ่าน) ส่งสัญญาณให้ทีมขายแจ้งลูกค้า | Channel: `samples-channel`<br>Event: `sample-status-updated` |
| | `/api/artworks/upload` | POST | 🟢 Real-time (POST) | อัปโหลดไฟล์อาร์ตเวิร์กใหม่ แจ้งเตือนฝ่ายกราฟิกและทีมขาย | Channel: `artwork-channel`<br>Event: `artwork-uploaded` |
| | `/api/artworks/{id}/status` | PATCH | 🟢 Real-time (PATCH) | **[วิกฤต!]** ลูกค้าอนุมัติหรือสั่งแก้ไขแบบอาร์ตเวิร์ก ต้องแจ้งเตือนฝ่ายผลิตทันทีเพื่อเริ่มหรือชะลอการสกรีน | Channel: `artwork-channel`<br>Event: `artwork-approval-changed` |
| **Finance & Payments** | `/api/suppliers/{id}/bills/{bid}/pay` | PATCH | 🟢 Real-time (PATCH) | เมื่อจ่ายเงินมัดจำ/ยอดคงเหลือให้โรงงานแล้ว ต้องอัปเดตกระแสเงินสด (AP Cashflow) บน Dashboard ผู้บริหาร | Channel: `finance-channel`<br>Event: `supplier-bill-paid` |
| | `/api/finance/payments` | POST | 🟢 Real-time (POST) | **[วิกฤต!]** ลูกค้าโอนเงินมัดจำหรือยอดคงเหลือเข้ามา ต้องแจ้งเตือนฝ่ายบัญชีให้ตรวจสอบสลิป | Channel: `finance-channel`<br>Event: `payment-recorded` |
| | `/api/finance/payments/{id}/verify` | PATCH | 🟢 Real-time (PATCH) | **[วิกฤต!]** ฝ่ายบัญชียืนยันสลิปเงินเข้าแล้ว ต้องปลดล็อกสถานะโปรเจกต์ให้เข้าสู่ขั้นตอนผลิต (Production) ทันที | Channel: `finance-channel`<br>Event: `payment-verified` |
| **Logistics & Warehouses** | `/api/containers/{id}/step` | PATCH | 🟢 Real-time (PATCH) | **[วิกฤต!]** อัปเดตสถานะตู้สินค้า (เรือออกจากจีน ➔ ถึงท่าเรือไทย ➔ ผ่านพิธีการศุลกากร ➔ ถึงคลังสินค้า) ต้องแจ้งเตือนผู้จัดการคลังสินค้าและฝ่ายจัดส่งเตรียมรับของ | Channel: `logistics-channel`<br>Event: `container-step-updated` |
| | `/api/inventory/receive` | POST | 🟢 Real-time (POST) | สินค้าเข้าคลัง (บางพลี/รังสิต) อัปเดตยอดสต็อกบนระบบแบบ Real-time | Channel: `inventory-channel`<br>Event: `inventory-received` |
| | `/api/delivery/rounds/{id}/complete` | PATCH | 🟢 Real-time (PATCH) | ส่งของให้ลูกค้าเรียบร้อยแล้ว ต้องแจ้งเตือนฝ่ายขายและออกใบเสร็จรับเงิน/ใบกำกับภาษี | Channel: `delivery-channel`<br>Event: `delivery-completed` |
| **Dashboard** | `/api/dashboard/summary` | GET | 🔴 Non-Real-time | ดึงสรุปตัวเลขสถิติภาพรวม | - |
| | `/api/dashboard/activities` | GET | 🟢 Real-time Auto-Push | ประวัติกิจกรรมใหม่จะถูกผลัก (Push) มาต่อท้าย Activity Log บนหน้าจอทันทีที่มีการขยับตัวของโปรเจกต์ | Channel: `dashboard-channel`<br>Event: `activity-log-appended` |

---

## 3.2 การวิเคราะห์เชิงลึก: ทำไมเส้น API เหล่านี้ถึงต้องเป็น Real-time? (Architectural Rationale)

### 1. ความรวดเร็วในกระบวนการทำงานแบบเชื่อมโยงกัน (Cross-Departmental Workflow Agility)
ในธุรกิจนำเข้าสินค้าพรีเมียม การทำงานเป็นแบบ **Chain Reaction (ปฏิกิริยาลูกซ้อน)** ระหว่าง 5 แผนกหลัก (ฝ่ายขาย ➔ ฝ่ายจัดซื้อ ➔ ฝ่ายการเงิน ➔ ฝ่ายผลิต/อาร์ตเวิร์ก ➔ ฝ่ายโลจิสติกส์/คลังสินค้า):
* **ตัวอย่าง**: เมื่อฝ่ายการเงินกดอนุมัติสลิปโอนเงิน (`PATCH /api/finance/payments/{id}/verify`) ระบบจะส่ง WebSocket ไปปลดล็อกให้ฝ่ายจัดซื้อและฝ่ายอาร์ตเวิร์กเห็นทันทีว่าเงินเข้าแล้ว ทำให้สั่งผลิตโรงงานที่จีนได้ในวันเดียวกัน **ประหยัดเวลาชะลอการผลิตไปได้ 1-2 วันเต็ม**

### 2. ลดการสลับหน้าจอและการกด Refresh (Zero Latency Experience)
หากไม่มีระบบ Real-time ทีมงานต้องกดปุ่ม Refresh (F5) หรือโทรศัพท์สอบถามกันตลอดเวลาว่า *"เงินเข้ายัง?"*, *"โรงงานตอบราคายัง?"*, *"เรือถึงท่าเรือหรือยัง?"*
* **การใช้ Pusher Real-time**: ทำให้หน้าจอ Dashboard และ Kanban Board ของทีมงานทุกคนอัปเดตเองโดยอัตโนมัติ (Zero Latency Sync) เมื่อมีคนใดคนหนึ่งอัปเดตข้อมูล

### 3. ป้องกันการทำงานซ้ำซ้อนและข้อมูลขัดแย้ง (Data Race & Duplicate Prevention)
เมื่อมีผู้จัดการหรือทีมขายหลายคนใช้งานระบบพร้อมกัน:
* หากมีการเปลี่ยนสถานะโปรเจกต์ (`PATCH /api/projects/{id}/status`) หรือแย่งจองตู้สินค้า (`PATCH /api/containers/{id}/step`) การส่งสัญญาณ Real-time จะเปลี่ยนสีและสถานะบนหน้าจอของทุกคนในเสี้ยววินาที ป้องกันไม่ให้มีใครกดซ้ำหรือทำงานซ้อนกัน

### 4. การตอบสนองคู่ค้าต่างประเทศทันที (Supplier Portal Integration)
โรงงานคู่ค้าที่จีนใช้งาน Supplier Portal เมื่อโรงงานกรอกราคาสินค้า (`POST /api/supplier/portal/quotes/{qid}/submit`) สัญญาณจะวิ่งข้ามประเทศผ่าน Pusher Cluster `ap1` (Singapore) เข้ามาเด้งแจ้งเตือนบนหน้าจอฝ่ายจัดซื้อในไทยทันที ทำให้เสนอกลับไปหาลูกค้าได้ไวกว่าคู่แข่ง
