# PPN GREAT — Database Migration Skill

## Description
Skill สำหรับสร้าง Laravel Migration สำหรับระบบ PPN GREAT
ใช้เมื่อ: สร้าง Migration, แก้ไข Table, เพิ่ม Column, สร้าง Index

## Rules

### 1. ทุก Migration ต้องมี timestamps
```php
$table->timestamps(); // created_at + updated_at
```

### 2. Foreign Key ต้องใส่เสมอ + กำหนด ON DELETE
```php
// ถ้าลบ Parent แล้ว Child ต้องลบด้วย:
$table->foreignId('customer_id')->constrained()->cascadeOnDelete();

// ถ้าลบ Parent แล้ว Child SET NULL:
$table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
```

### 3. ENUM ใช้ค่าตามที่กำหนด — ห้ามเปลี่ยน!

```php
// Project Status (7 ค่า)
$table->enum('status', [
    'Inquiry', 'Sample', 'Production', 'Shipping',
    'Distributing', 'Delivered', 'Cancelled'
])->default('Inquiry');

// Finance Doc Type (3 ค่า — ⚠️ CI รอลูกค้ายืนยัน)
$table->enum('doc_type', ['QU', 'PI', 'DP']);

// Finance Doc Status (5 ค่า)
$table->enum('status', [
    'Draft', 'Sent', 'Paid', 'Overdue', 'Cancelled'
])->default('Draft');

// User Role (ใช้ VARCHAR แทน ENUM — เพิ่ม Role ใหม่ทีหลังได้โดยไม่ต้องแก้ Migration!)
$table->string('role', 50)->default('super_admin');
// ตอนนี้มีแค่ super_admin — ลูกค้าจะส่ง Role อื่นมาเพิ่มภายหลัง

// Payment Status (2 ค่า)
$table->enum('status', [
    'Pending Verification', 'Confirmed'
])->default('Pending Verification');

// Currency (2 ค่า — ใช้เฉพาะฝั่ง Supplier เท่านั้น!)
$table->enum('currency', ['USD', 'THB'])->default('USD');
// ฝั่งลูกค้า (Finance Docs) ไม่ต้องมี currency field — THB อย่างเดียว
```

### 4. ตัวเลขเงินใช้ DECIMAL(14,2)
```php
$table->decimal('total_amount', 14, 2)->default(0);
$table->decimal('unit_price', 12, 2)->default(0);
```

### 5. UNIQUE Constraint สำหรับ Code/Doc Number
```php
$table->string('project_code', 20)->unique();
$table->string('doc_no', 30)->unique();
$table->string('session_token', 100)->unique()->nullable();
```

### 6. Index สำหรับ Column ที่ค้นหาบ่อย
```php
$table->index('status');
$table->index('customer_id');
$table->index(['project_id', 'status']);
```

## Database Schema Reference

### ตาราง users (⚠️ ใช้ VARCHAR สำหรับ role — เพิ่ม Role ทีหลังได้โดยไม่ต้องแก้ Migration)
```php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('email')->unique();
    $table->string('password');
    $table->string('full_name');
    $table->string('role', 50)->default('super_admin'); // ใช้ VARCHAR แทน ENUM!
    $table->string('phone', 50)->nullable();
    $table->boolean('is_active')->default(true);
    $table->timestamp('last_login_at')->nullable();
    $table->timestamps();
});
```

### ตาราง customers
```php
Schema::create('customers', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->enum('type', ['Enterprise', 'Mid-Market', 'SME'])->default('SME');
    $table->enum('status', ['Active', 'Inactive'])->default('Active');
    $table->string('tax_id', 20)->nullable();
    $table->string('branch', 100)->nullable();
    $table->string('industry', 100)->nullable();
    $table->enum('lead_source', ['Facebook Ads','Google Search','Referral','Exhibition','Direct Contact','Other'])->nullable();
    $table->text('internal_note')->nullable();
    $table->text('billing_address')->nullable();
    $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
    $table->timestamps();
    $table->index('status');
    $table->index('type');
});
```

### ตาราง projects
```php
Schema::create('projects', function (Blueprint $table) {
    $table->id();
    $table->string('project_code', 20)->unique();
    $table->foreignId('customer_id')->constrained();
    $table->foreignId('contact_person_id')->nullable()->constrained()->nullOnDelete();
    $table->enum('status', ['Inquiry','Sample','Production','Shipping','Distributing','Delivered','Cancelled'])->default('Inquiry');
    $table->tinyInteger('step')->unsigned()->default(0);
    $table->tinyInteger('priority')->unsigned()->default(0);
    $table->boolean('is_repeat_order')->default(false);
    $table->date('target_date')->nullable();
    $table->decimal('order_value', 14, 2)->default(0);
    $table->text('usage_location')->nullable();
    $table->enum('credit_term', ['Advance','15 Days','30 Days','45 Days','60 Days'])->default('30 Days');
    $table->boolean('deposit_paid')->default(false);
    $table->boolean('balance_paid')->default(false);
    $table->boolean('ocpb_passed')->default(false);
    $table->boolean('shipping_mark_ready')->default(false);
    $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
    $table->timestamps();
    $table->index('status');
    $table->index('customer_id');
});
```

(ตารางที่เหลือดู Backend_Map.md สำหรับ SQL Schema ละเอียด)
