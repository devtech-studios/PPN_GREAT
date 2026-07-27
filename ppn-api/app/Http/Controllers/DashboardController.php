<?php

namespace App\Http\Controllers;

use App\Models\Project;
use App\Models\Payment;
use App\Models\FinanceDocument;
use App\Models\StockItem;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

class DashboardController extends Controller
{
    // GET /api/dashboard/summary — KPI and counts
    public function summary(): JsonResponse
    {
        $activeProjectsCount = Project::whereNotIn('status', ['Delivered', 'Cancelled'])->count();

        // Confirmed payments in current month
        $startOfMonth = Carbon::now()->startOfMonth()->toDateString();
        $endOfMonth = Carbon::now()->endOfMonth()->toDateString();
        $revenueMtd = Payment::where('status', 'Confirmed')
            ->whereBetween('payment_date', [$startOfMonth, $endOfMonth])
            ->sum('amount');

        // Sum of unpaid finance documents (PI - Proforma Invoice or CI)
        $pendingPaymentsAmount = FinanceDocument::whereIn('doc_type', ['PI', 'CI'])
            ->where('status', '!=', 'Paid')
            ->sum('total_amount');

        // Low stock count (items with stock <= 100)
        $lowStockCount = StockItem::where('qty_in_stock', '<=', 100)->count();

        return response()->json([
            'success' => true,
            'data' => [
                'active_projects_count' => $activeProjectsCount,
                'revenue_mtd' => round($revenueMtd, 2),
                'pending_payments_amount' => round($pendingPaymentsAmount, 2),
                'low_stock_alerts_count' => $lowStockCount
            ]
        ]);
    }

    // GET /api/dashboard/activities — Recent activity logs
    public function activities(): JsonResponse
    {
        $activities = ActivityLog::orderBy('created_at', 'desc')
            ->take(20)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $activities
        ]);
    }

    // GET /api/dashboard/revenue-chart — Monthly revenue
    public function revenueChart(): JsonResponse
    {
        // Fetch monthly confirmed payments for the past 12 months
        $oneYearAgo = Carbon::now()->subMonths(11)->startOfMonth()->toDateString();
        
        $isSqlite = \DB::connection()->getDriverName() === 'sqlite';
        $formatExpr = $isSqlite 
            ? "strftime('%Y-%m', payment_date) as month_period" 
            : "DATE_FORMAT(payment_date, '%Y-%m') as month_period";

        $rawChartData = Payment::where('status', 'Confirmed')
            ->where('payment_date', '>=', $oneYearAgo)
            ->selectRaw("$formatExpr, SUM(amount) as total")
            ->groupBy('month_period')
            ->orderBy('month_period', 'asc')
            ->get();

        // Pad missing months with 0
        $chartData = [];
        for ($i = 11; $i >= 0; $i--) {
            $monthStr = Carbon::now()->subMonths($i)->format('Y-m');
            $found = $rawChartData->firstWhere('month_period', $monthStr);
            $chartData[] = [
                'month' => $monthStr,
                'total' => $found ? round(floatval($found->total), 2) : 0.00
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $chartData
        ]);
    }
}
