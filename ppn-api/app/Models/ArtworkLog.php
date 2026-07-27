<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ArtworkLog extends Model
{
    use HasFactory;

    protected $table = 'artwork_logs';

    protected $fillable = [
        'project_id',
        'product_item_id',
        'artwork_code',
        'attempt',
        'version',
        'source',
        'status',
        'file_name',
        'file_path',
        'feedback',
    ];

    protected $casts = [
        'attempt' => 'integer',
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
