<?php

namespace App\Services;

use App\Models\Project;
use Illuminate\Support\Facades\DB;

class ProjectCodeService
{
    /**
     * Generate the next unique project code (e.g., PPN-001, PPN-002).
     * Uses table lock (lockForUpdate) to prevent race conditions.
     *
     * @return string
     */
    public static function generateNextCode(): string
    {
        return DB::transaction(function () {
            // Get the last project code using write lock
            $lastProject = Project::orderBy('id', 'desc')
                ->lockForUpdate()
                ->first();

            if (!$lastProject) {
                return 'PPN-001';
            }

            $lastCode = $lastProject->project_code; // e.g. PPN-001
            $parts = explode('-', $lastCode);
            
            if (count($parts) < 2) {
                return 'PPN-001';
            }

            $number = intval($parts[1]);
            $nextNumber = $number + 1;

            return sprintf('PPN-%03d', $nextNumber);
        });
    }
}
