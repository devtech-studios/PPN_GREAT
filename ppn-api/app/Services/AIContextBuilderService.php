<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class AIContextBuilderService
{
    /**
     * Build clean, isolated AI Context for LLM prompt strictly scoped by shop_id and branch_id.
     */
    public function buildCleanContext(int $shopId, int $branchId, string $userQuestion): array
    {
        $shop = DB::table('shops')->where('id', $shopId)->first();
        $branch = DB::table('branches')->where('id', $branchId)->where('shop_id', $shopId)->first();

        // 1. ดึงสรุปยอดขายเฉพาะสาขานี้
        $salesSummary = DB::table('projects')
            ->where('shop_id', $shopId)
            ->where('branch_id', $branchId)
            ->selectRaw('count(id) as total_projects, sum(order_value) as total_revenue')
            ->first();

        // 2. ดึงสรุปสต็อกเฉพาะสาขานี้
        $stockSummary = DB::table('stock_items')
            ->where('shop_id', $shopId)
            ->where('branch_id', $branchId)
            ->selectRaw('count(id) as total_items, sum(qty_in_stock) as total_qty')
            ->first();

        return [
            'scope' => [
                'shop_id' => $shopId,
                'shop_name' => $shop->name ?? 'N/A',
                'branch_id' => $branchId,
                'branch_name' => $branch->name ?? 'N/A',
            ],
            'system_instruction' => 'คุณเป็นผู้ช่วยวิเคราะห์ข้อมูลเฉพาะของ ' . ($shop->name ?? '') . ' (' . ($branch->name ?? '') . ') เท่านั้น ห้ามเปิดเผยหรืออ้างอิงข้อมูลร้านอื่นเด็ดขาด',
            'sales_data' => [
                'total_projects' => (int) ($salesSummary->total_projects ?? 0),
                'total_revenue' => (float) ($salesSummary->total_revenue ?? 0),
            ],
            'stock_data' => [
                'total_items' => (int) ($stockSummary->total_items ?? 0),
                'total_qty' => (int) ($stockSummary->total_qty ?? 0),
            ],
            'user_question' => $userQuestion,
        ];
    }
}
