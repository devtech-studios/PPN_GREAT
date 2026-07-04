# PPN GREAT — Stock Management Skill

## Description
Skill สำหรับจัดการสต็อก ตัดสต็อก รับเข้าคลัง ของระบบ PPN GREAT
ใช้เมื่อ: เขียนโค้ดเกี่ยวกับ Inventory, Stock, Delivery, ตัดสต็อก

## ⚠️ CRITICAL RULE: ตัดสต็อกต้องอยู่ใน Transaction เสมอ!

### ตัดสต็อก (Dispatch Confirm) — โค้ดที่ถูกต้อง:

```php
public function confirm($id): JsonResponse
{
    $dispatch = DispatchRound::with('items')->findOrFail($id);

    if ($dispatch->status !== 'Scheduled') {
        return response()->json([
            'success' => false,
            'error' => ['code' => 'INVALID_STATUS', 'message' => 'รอบส่งนี้ยืนยันแล้ว']
        ], 422);
    }

    try {
        DB::transaction(function () use ($dispatch) {
            foreach ($dispatch->items as $item) {
                // 1. Lock row ป้องกัน Race Condition
                $stock = StockItem::where([
                    'product_item_id' => $item->product_item_id,
                    'warehouse_id' => $item->warehouse_id,
                ])->lockForUpdate()->first();

                // 2. เช็คสต็อกเพียงพอ
                if (!$stock || $stock->qty_in_stock < $item->qty_to_deliver) {
                    throw new \Exception("สต็อกไม่เพียงพอสำหรับ: {$item->product_item_id}");
                }

                // 3. ตัดสต็อก
                $stock->decrement('qty_in_stock', $item->qty_to_deliver);

                // 4. บันทึก Movement Log
                StockMovement::create([
                    'stock_item_id' => $stock->id,
                    'movement_type' => 'OUT',
                    'qty' => $item->qty_to_deliver,
                    'reference_type' => 'dispatch_round',
                    'reference_id' => $dispatch->id,
                    'created_by' => auth()->id(),
                ]);
            }

            // 5. อัปเดตสถานะ Dispatch
            $dispatch->update(['status' => 'In Transit']);
        });

        return response()->json([
            'success' => true,
            'message' => 'ยืนยันรอบส่งและตัดสต็อกเรียบร้อย'
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'error' => ['code' => 'STOCK_ERROR', 'message' => $e->getMessage()]
        ], 422);
    }
}
```

### รับเข้าคลัง (Stock Receive):

```php
public function receive(Request $request): JsonResponse
{
    $validated = $request->validate([
        'warehouse_id' => 'required|exists:warehouses,id',
        'product_item_id' => 'required|exists:product_items,id',
        'project_id' => 'required|exists:projects,id',
        'qty' => 'required|integer|min:1',
    ]);

    DB::transaction(function () use ($validated) {
        // 1. หาหรือสร้าง StockItem
        $stock = StockItem::firstOrCreate(
            [
                'warehouse_id' => $validated['warehouse_id'],
                'product_item_id' => $validated['product_item_id'],
                'project_id' => $validated['project_id'],
            ],
            ['qty_in_stock' => 0, 'qty_reserved' => 0]
        );

        // 2. เพิ่มสต็อก
        $stock->increment('qty_in_stock', $validated['qty']);
        $stock->update(['last_received_at' => now()]);

        // 3. บันทึก Movement
        StockMovement::create([
            'stock_item_id' => $stock->id,
            'movement_type' => 'IN',
            'qty' => $validated['qty'],
            'reference_type' => 'manual_receive',
            'notes' => $request->notes,
            'created_by' => auth()->id(),
        ]);
    });

    return response()->json([
        'success' => true,
        'message' => 'รับสินค้าเข้าคลังเรียบร้อย'
    ]);
}
```

### กฎสำคัญ:
1. **ทุกครั้งที่สต็อกเปลี่ยน → ต้องสร้าง StockMovement** (เพื่อตรวจสอบย้อนหลัง)
2. **ตัดสต็อก → lockForUpdate()** (ป้องกัน 2 คนตัดพร้อมกัน)
3. **เช็คก่อนตัด → qty_in_stock >= qty_to_deliver** (ห้ามติดลบ!)
4. **ทั้งหมดต้องอยู่ใน DB::transaction()** (ถ้าพัง → rollback ทั้งหมด)
