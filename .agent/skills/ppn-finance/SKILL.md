# PPN GREAT — Finance & Document Numbering Skill

## Description
Skill สำหรับระบบการเงิน: สร้างเอกสาร QU/PI/DP/CI, คำนวณ Due Date, Auto-generate เลขเอกสาร
ใช้เมื่อ: เขียนโค้ดเกี่ยวกับ Finance, Payment, Invoice, เลขเอกสาร

## Auto-generate เลขเอกสาร

### DocNumberService — ป้องกัน Race Condition:

```php
<?php

namespace App\Services;

use App\Models\FinanceDocument;
use Illuminate\Support\Facades\DB;

class DocNumberService
{
    public static function generate(string $type): string
    {
        return DB::transaction(function () use ($type) {
            $year = date('Y');

            // Lock เพื่อป้องกัน 2 คนสร้างเลขเดียวกัน
            $lastDoc = FinanceDocument::where('doc_type', $type)
                ->whereYear('created_at', $year)
                ->orderBy('id', 'desc')
                ->lockForUpdate()
                ->first();

            $nextNumber = $lastDoc
                ? intval(substr($lastDoc->doc_no, -4)) + 1
                : 1;

            return sprintf('%s-%s-%04d', $type, $year, $nextNumber);
        });
    }
}
```

**ผลลัพธ์:**
```
DocNumberService::generate('QU') → "QU-2026-0001"
DocNumberService::generate('QU') → "QU-2026-0002"  (ถัดไปอัตโนมัติ)
DocNumberService::generate('PI') → "PI-2026-0001"  (นับแยกตามประเภท)
```

## คำนวณ Due Date จาก Credit Term

```php
use Carbon\Carbon;

$issueDate = Carbon::parse($request->issue_date);
$creditTerm = $project->credit_term;

$dueDate = match($creditTerm) {
    'Advance'  => $issueDate,
    '15 Days'  => $issueDate->copy()->addDays(15),
    '30 Days'  => $issueDate->copy()->addDays(30),
    '45 Days'  => $issueDate->copy()->addDays(45),
    '60 Days'  => $issueDate->copy()->addDays(60),
    default    => $issueDate->copy()->addDays(30),
};
```

⚠️ **ใช้ ->copy()** ก่อน addDays() เพราะ Carbon mutate object เดิม!

## สร้าง Finance Document Flow

```php
public function store(StoreFinanceDocRequest $request): JsonResponse
{
    try {
        $doc = DB::transaction(function () use ($request) {
            $project = Project::findOrFail($request->project_id);

            // 1. Auto-generate doc_no
            $docNo = DocNumberService::generate($request->doc_type);

            // 2. คำนวณ due_date
            $issueDate = Carbon::parse($request->issue_date);
            $dueDate = match($project->credit_term) {
                'Advance'  => $issueDate,
                '15 Days'  => $issueDate->copy()->addDays(15),
                '30 Days'  => $issueDate->copy()->addDays(30),
                '45 Days'  => $issueDate->copy()->addDays(45),
                '60 Days'  => $issueDate->copy()->addDays(60),
                default    => $issueDate->copy()->addDays(30),
            };

            // 3. สร้างเอกสาร
            $doc = FinanceDocument::create([
                'doc_no' => $docNo,
                'project_id' => $request->project_id,
                'customer_id' => $project->customer_id,
                'doc_type' => $request->doc_type,
                'status' => 'Draft',
                'credit_term' => $project->credit_term,
                'issue_date' => $request->issue_date,
                'due_date' => $dueDate,
                'notes' => $request->notes,
                'created_by' => auth()->id(),
            ]);

            // 4. สร้างรายการ
            $totalAmount = 0;
            foreach ($request->items as $item) {
                $totalPrice = $item['qty'] * $item['unit_price'];
                $totalAmount += $totalPrice;

                FinanceDocItem::create([
                    'finance_document_id' => $doc->id,
                    'item_name' => $item['item_name'],
                    'qty' => $item['qty'],
                    'unit_price' => $item['unit_price'],
                    'total_price' => $totalPrice,
                ]);
            }

            // 5. อัปเดตยอดรวม
            $doc->update(['total_amount' => $totalAmount]);

            // 6. Activity Log
            ActivityLog::create([
                'user_id' => auth()->id(),
                'project_id' => $request->project_id,
                'action' => "สร้างเอกสาร {$request->doc_type}",
                'description' => "สร้าง {$docNo} ยอด " . number_format($totalAmount, 2) . " บาท",
                'entity_type' => 'finance_document',
                'entity_id' => $doc->id,
            ]);

            return $doc;
        });

        return response()->json([
            'success' => true,
            'data' => $doc->load('items'),
            'message' => "สร้างเอกสาร {$doc->doc_no} สำเร็จ"
        ], 201);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'error' => ['code' => 'CREATE_FAILED', 'message' => $e->getMessage()]
        ], 500);
    }
}
```

## กฎสำคัญ:
1. **เลขเอกสาร:** ห้ามซ้ำ! ใช้ lockForUpdate ใน Transaction
2. **Due Date:** คำนวณอัตโนมัติจาก Credit Term
3. **Total Amount:** SUM จาก items ไม่ใช่กรอกเอง
4. **แก้ไขได้เฉพาะ Draft:** ถ้า status ไม่ใช่ Draft → ห้ามแก้ → return 422
5. **QU/PI/DP/CI ต่างกันยังไง:**
   - QU = ใบเสนอราคา (ก่อนตกลง)
   - PI = แจ้งหนี้ (หลังตกลง ก่อนผลิต)
   - DP = ใบเสร็จมัดจำ (หลังจ่ายมัดจำ)
   - CI = ใบกำกับสินค้า (หลังส่งของ เก็บเงินที่เหลือ)
