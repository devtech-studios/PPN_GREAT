<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Container extends Model
{
    use HasFactory;

    protected $fillable = [
        'container_code',
        'container_no',
        'vessel_name',
        'port_origin',
        'port_destination',
        'status',
        'factory_departure',
        'domestic_tracking',
        'port_arrival_china',
        'etd',
        'eta',
        'actual_arrival',
        'customs_cleared',
        'customs_date',
        'warehouse_arrival',
        'notes',
    ];

    protected $casts = [
        'factory_departure' => 'date',
        'port_arrival_china' => 'date',
        'etd' => 'date',
        'eta' => 'date',
        'actual_arrival' => 'date',
        'customs_cleared' => 'boolean',
        'customs_date' => 'date',
        'warehouse_arrival' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function projects(): BelongsToMany
    {
        return $this->belongsToMany(Project::class, 'container_projects');
    }
}
