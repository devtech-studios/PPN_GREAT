<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductFile extends Model
{
    use HasFactory;

    protected $table = 'product_files';

    protected $fillable = [
        'product_item_id',
        'file_type',
        'file_name',
        'file_path',
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
