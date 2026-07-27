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
        'sample_price',
        'sample_lead_time',
        'sample_condition',
        'buyer_note',
        'remark',
        'session_token',
    ];

    protected $casts = [
        'qty' => 'integer',
        'target_date' => 'date',
        'quoted_price' => 'decimal:2',
        'moq' => 'integer',
        'sample_price' => 'decimal:2',
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

    public function revisions()
    {
        return $this->hasMany(QuoteRequestRevision::class, 'quote_request_id')->orderBy('created_at', 'desc');
    }
}
