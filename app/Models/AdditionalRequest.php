<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AdditionalRequest extends Model
{
    use HasFactory;

    protected $table = 'additional_requests';

    protected $fillable = [
        'project_id',
        'description',
        'cost',
    ];

    protected $casts = [
        'cost' => 'decimal:2',
        'created_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }
}
