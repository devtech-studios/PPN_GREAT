<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class QuoteRequest extends Model
{
    use HasFactory;

    protected $table = 'quote_requests';

    protected $fillable = [
        'supplier_id',
        'project_id',
        'product_item_id',
        'customer_name',
        'product_name',
        'qty',
        'specs',
        'variations',
        'target_date',
        'packing',
        'status',
        'quoted_price',
        'currency',
        'lead_time',
        'moq',
        'remark',
        'session_token',
    ];

    protected $casts = [
        'qty' => 'integer',
        'target_date' => 'date',
        'quoted_price' => 'decimal:2',
        'moq' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function supplier(): BelongsTo
    {
        return $this->belongsTo(Supplier::class);
    }

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }

    public function productItem(): BelongsTo
    {
        return $this->belongsTo(ProductItem::class);
    }
}
