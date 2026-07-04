<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SupplierSample extends Model
{
    use HasFactory;

    protected $table = 'supplier_samples';

    protected $fillable = [
        'supplier_id',
        'project_id',
        'product_name',
        'customer_name',
        'status',
        'specs',
        'cost',
        'tracking_no',
        'expected_date',
    ];

    protected $casts = [
        'expected_date' => 'date',
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
}
