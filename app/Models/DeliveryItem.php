<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryItem extends Model
{
    protected $table = 'delivery_items';

    protected $fillable = [
        'dispatch_round_id',
        'project_id',
        'product_item_id',
        'customer_name',
        'delivery_address',
        'qty_to_deliver',
        'warehouse_id',
        'notes',
    ];

    protected $casts = [
        'qty_to_deliver' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function dispatchRound(): BelongsTo
    {
        return $this->belongsTo(DispatchRound::class, 'dispatch_round_id');
    }

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }

    public function productItem(): BelongsTo
    {
        return $this->belongsTo(ProductItem::class);
    }

    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }
}
