<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class QuoteRequestRevision extends Model
{
    use HasFactory;

    protected $table = 'quote_request_revisions';

    protected $fillable = [
        'quote_request_id',
        'actor',
        'quoted_price',
        'currency',
        'lead_time',
        'moq',
        'sample_price',
        'sample_lead_time',
        'sample_condition',
        'remark',
        'buyer_note',
    ];

    protected $casts = [
        'quoted_price' => 'decimal:2',
        'moq' => 'integer',
        'sample_price' => 'decimal:2',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function quoteRequest(): BelongsTo
    {
        return $this->belongsTo(QuoteRequest::class, 'quote_request_id');
    }
}
