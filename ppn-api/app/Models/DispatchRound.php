<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DispatchRound extends Model
{
    use HasFactory;

    protected $table = 'dispatch_rounds';

    protected $fillable = [
        'dispatch_code',
        'dispatch_date',
        'driver_name',
        'vehicle_plate',
        'status',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'dispatch_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function deliveryItems(): HasMany
    {
        return $this->hasMany(DeliveryItem::class, 'dispatch_round_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(DeliveryItem::class, 'dispatch_round_id');
    }
}
