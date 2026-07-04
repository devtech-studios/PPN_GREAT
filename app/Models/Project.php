<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Project extends Model
{
    use HasFactory;

    protected $fillable = [
        'project_code',
        'customer_id',
        'contact_person_id',
        'status',
        'step',
        'priority',
        'is_repeat_order',
        'target_date',
        'order_value',
        'usage_location',
        'credit_term',
        'deposit_paid',
        'balance_paid',
        'ocpb_passed',
        'shipping_mark_ready',
        'created_by',
    ];

    protected $casts = [
        'is_repeat_order' => 'boolean',
        'target_date' => 'date',
        'order_value' => 'decimal:2',
        'deposit_paid' => 'boolean',
        'balance_paid' => 'boolean',
        'ocpb_passed' => 'boolean',
        'shipping_mark_ready' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function contactPerson(): BelongsTo
    {
        return $this->belongsTo(ContactPerson::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function productItems(): HasMany
    {
        return $this->hasMany(ProductItem::class);
    }

    public function additionalRequests(): HasMany
    {
        return $this->hasMany(AdditionalRequest::class);
    }

    public function quoteRequests(): HasMany
    {
        return $this->hasMany(QuoteRequest::class);
    }

    public function clientSamples(): HasMany
    {
        return $this->hasMany(ClientSample::class);
    }

    public function artworkLogs(): HasMany
    {
        return $this->hasMany(ArtworkLog::class);
    }

    public function financeDocuments(): HasMany
    {
        return $this->hasMany(FinanceDocument::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function supplierBills(): HasMany
    {
        return $this->hasMany(SupplierBill::class);
    }

    public function activityLogs(): HasMany
    {
        return $this->hasMany(ActivityLog::class);
    }
}
