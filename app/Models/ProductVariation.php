<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductVariation extends Model
{
    use HasFactory;

    protected $table = 'product_variations';

    protected $fillable = [
        'product_item_id',
        'variation_name',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function productItem(): BelongsTo
    {
        return $this->belongsTo(ProductItem::class);
    }
}
