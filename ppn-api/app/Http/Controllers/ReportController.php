<?php

namespace App\Http\Controllers;

use App\Models\Project;
use App\Models\Payment;
use App\Models\SupplierBill;
use App\Models\FinanceDocument;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

class ReportController extends Controller
{
    // GET /api/reports/financial-summary — Revenue, COGS, Profit, Margin%
    public function financialSummary(): JsonResponse
    {
        $revenue = Payment::where('status', 'Confirmed')->sum('amount');
        $cogs = SupplierBill::where('status', 'Paid')->sum('amount');
        $profit = $revenue - $cogs;
        $margin = $revenue > 0 ? ($profit / $revenue) * 100 : 0.00;

        return response()->json([
            'success' => true,
            'data' => [
                'total_revenue' => round($revenue, 2),
                'total_cogs' => round($cogs, 2),
                'gross_profit' => round($profit, 2),
                'margin_percentage' => round($margin, 2)
            ]
        ]);
    }

    // GET /api/reports/operational-summary — Active Projects, Avg Lead Time, On-time%
    public function operationalSummary(): JsonResponse
    {
        $activeProjects = Project::whereNotIn('status', ['Delivered', 'Cancelled'])->count();
        $totalDelivered = Project::where('status', 'Delivered')->count();
        
        // Calculate on-time rate based on target_date vs actual completion date (updated_at of Delivered status)
        $onTimeDelivered = Project::where('status', 'Delivered')
            ->where(function($q) {
                $q->whereNull('target_date')
                  ->orWhereColumn('updated_at', '<=', 'target_date');
            })->count();

        $onTimeRate = $totalDelivered > 0 ? ($onTimeDelivered / $totalDelivered) * 100 : 100.00;

        // Mock average lead time or calculate from completed projects if dates exist (e.g. default 30 days)
        $avgLeadTimeDays = 30; 

        return response()->json([
            'success' => true,
            'data' => [
                'active_projects_count' => $activeProjects,
                'completed_projects_count' => $totalDelivered,
                'on_time_delivery_rate' => round($onTimeRate, 2),
                'avg_lead_time_days' => $avgLeadTimeDays
            ]
        ]);
    }

    // GET /api/reports/revenue-by-month — Monthly breakdown (6 months)
    public function revenueByMonth(): JsonResponse
    {
        $sixMonthsAgo = Carbon::now()->subMonths(5)->startOfMonth()->toDateString();

        $isSqlite = \DB::connection()->getDriverName() === 'sqlite';
        $formatExpr = $isSqlite 
            ? "strftime('%Y-%m', payment_date) as month_period" 
            : "DATE_FORMAT(payment_date, '%Y-%m') as month_period";

        $rawPayments = Payment::where('status', 'Confirmed')
            ->where('payment_date', '>=', $sixMonthsAgo)
            ->selectRaw("$formatExpr, SUM(amount) as total")
            ->groupBy('month_period')
            ->orderBy('month_period', 'asc')
            ->get();

        $chartData = [];
        for ($i = 5; $i >= 0; $i--) {
            $monthStr = Carbon::now()->subMonths($i)->format('Y-m');
            $found = $rawPayments->firstWhere('month_period', $monthStr);
            $chartData[] = [
                'month' => $monthStr,
                'revenue' => $found ? round(floatval($found->total), 2) : 0.00
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $chartData
        ]);
    }

    // GET /api/reports/profit-by-project — Profit breakdown per project
    public function profitByProject(): JsonResponse
    {
        $projects = Project::with('customer')->orderBy('created_at', 'desc')->get()->map(function($project) {
            $revenue = Payment::where('project_id', $project->id)->where('status', 'Confirmed')->sum('amount');
            $cogs = SupplierBill::where('project_id', $project->id)->where('status', 'Paid')->sum('amount');
            $profit = $revenue - $cogs;
            $margin = $revenue > 0 ? ($profit / $revenue) * 100 : 0.00;

            return [
                'project_id' => $project->id,
                'project_code' => $project->project_code,
                'customer_name' => $project->customer ? $project->customer->name : 'N/A',
                'revenue' => round($revenue, 2),
                'cogs' => round($cogs, 2),
                'profit' => round($profit, 2),
                'margin_percentage' => round($margin, 2)
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $projects
        ]);
    }
}
