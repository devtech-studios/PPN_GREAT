<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClientSample extends Model
{
    use HasFactory;

    protected $table = 'client_samples';

    protected $fillable = [
        'project_id',
        'product_item_id',
        'sample_code',
        'attempt',
        'sample_type',
        'origin',
        'supplier_name',
        'status',
        'sent_date',
        'china_tracking',
        'local_courier',
        'local_tracking',
        'feedback',
    ];

    protected $casts = [
        'attempt' => 'integer',
        'sent_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }

    public function productItem(): BelongsTo
    {
        return $this->belongsTo(ProductItem::class);
    }
}
