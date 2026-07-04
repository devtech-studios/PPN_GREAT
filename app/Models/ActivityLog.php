<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ActivityLog extends Model
{
    protected $table = 'activity_logs';

    // Disabling default Laravel timestamps since we only have created_at
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'project_id',
        'action',
        'description',
        'entity_type',
        'entity_id',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class);
    }
}
