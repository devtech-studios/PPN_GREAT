<?php

namespace App\Traits;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Schema;

trait BelongsToTenant
{
    /**
     * Boot the BelongsToTenant trait.
     */
    protected static function bootBelongsToTenant(): void
    {
        static::creating(function ($model) {
            if (!$model->shop_id && request()->header('X-Shop-Id')) {
                $model->shop_id = (int) request()->header('X-Shop-Id');
            } elseif (!$model->shop_id && session()->has('authorized_shop_id')) {
                $model->shop_id = session('authorized_shop_id');
            } elseif (!$model->shop_id) {
                $model->shop_id = 1;
            }

            if (Schema::hasColumn($model->getTable(), 'branch_id')) {
                if (!$model->branch_id && request()->header('X-Branch-Id')) {
                    $model->branch_id = (int) request()->header('X-Branch-Id');
                } elseif (!$model->branch_id && session()->has('active_branch_id')) {
                    $model->branch_id = session('active_branch_id');
                } elseif (!$model->branch_id) {
                    $model->branch_id = 1;
                }
            }
        });

        static::addGlobalScope('tenant_scope', function (Builder $builder) {
            $shopId = request()->header('X-Shop-Id') ?? session('authorized_shop_id');
            $branchId = request()->header('X-Branch-Id') ?? session('active_branch_id');

            if ($shopId) {
                $builder->where($builder->getModel()->getTable() . '.shop_id', $shopId);
            }

            if ($branchId && Schema::hasColumn($builder->getModel()->getTable(), 'branch_id')) {
                $builder->where($builder->getModel()->getTable() . '.branch_id', $branchId);
            }
        });
    }
}
