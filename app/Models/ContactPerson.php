<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ContactPerson extends Model
{
    use HasFactory;

    protected $table = 'contact_persons';

    protected $fillable = [
        'customer_id',
        'name',
        'role',
        'phone',
        'email',
        'line_id',
        'other_chat',
        'is_primary',
    ];

    protected $casts = [
        'is_primary' => 'boolean',
        'created_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
