<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SupplierBill extends Model
{
    use HasFactory;

    protected $table = 'supplier_bills';

    protected $fillable = [
        'supplier_id',
        'project_id',
        'product_name',
        'bill_type',
        'amount',
        'currency',
        'due_month',
        'status',
        'pi_uploaded',
        'pi_file_path',
        'invoice_uploaded',
        'invoice_file_path',
        'paid_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'pi_uploaded' => 'boolean',
        'invoice_uploaded' => 'boolean',
        'paid_at' => 'datetime',
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
