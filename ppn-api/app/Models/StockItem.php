<?php

namespace App\Models;

use App\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class StockItem extends Model
{
    use HasFactory, BelongsToTenant;

    protected $table = 'stock_items';

    protected $fillable = [
        'shop_id',
        'branch_id',
        'warehouse_id',
        'product_item_id',
        'project_id',
        'qty_in_stock',
        'qty_reserved',
        'location_in_warehouse',
        'last_received_at',
    ];

    protected $casts = [
        'qty_in_stock' => 'integer',
        'qty_reserved' => 'integer',
        'last_received_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }

    public function productItem(): BelongsTo
    {
        return $this->belongsTo(ProductItem::class);
    }

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }

    public function movements(): HasMany
    {
        return $this->hasMany(StockMovement::class);
    }
}
