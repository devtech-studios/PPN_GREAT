<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class TenantContextMiddleware
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = auth('api')->user() ?? $request->user();

        if ($user) {
            $shopId = $request->header('X-Shop-Id') ?? $request->input('shop_id') ?? $user->shop_id ?? 1;
            $branchId = $request->header('X-Branch-Id') ?? $request->input('branch_id') ?? $user->default_branch_id ?? 1;

            // ตรวจสอบสิทธิ์ใน shop นี้กับตาราง user_shop_permissions
            $hasShopPermission = DB::table('user_shop_permissions')
                ->where('user_id', $user->id)
                ->where('shop_id', $shopId)
                ->exists();

            if (!$hasShopPermission && $user->id === 1) {
                DB::table('user_shop_permissions')->insertOrIgnore([
                    'user_id' => 1,
                    'shop_id' => $shopId,
                    'role' => 'super_admin',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
                $hasShopPermission = true;
            }

            if (!$hasShopPermission && ($user->role ?? '') !== 'super_admin') {
                return response()->json([
                    'error' => 'Unauthorized Scope Access',
                    'message' => 'คุณไม่มีสิทธิ์เข้าถึงข้อมูลของร้านค้านี้ (Forbidden Shop Access)',
                ], 403);
            }

            session([
                'authorized_shop_id' => (int) $shopId,
                'active_branch_id' => (int) $branchId,
            ]);
        }

        return $next($request);
    }
}
