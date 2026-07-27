<?php

namespace App\Services;

use App\Models\FinanceDocument;
use Illuminate\Support\Facades\DB;

class DocNumberService
{
    /**
     * Generate a unique document number for QU, PI, DP
     * Format: [doc_type]-[year]-[4 digit sequence] (e.g. QU-2026-0001)
     */
    public static function generate(string $docType): string
    {
        $year = date('Y');
        
        // Use a transaction lock to prevent race conditions
        return DB::transaction(function () use ($docType, $year) {
            $lastDoc = FinanceDocument::where('doc_type', $docType)
                ->where('doc_no', 'like', "{$docType}-{$year}-%")
                ->orderBy('doc_no', 'desc')
                ->lockForUpdate()
                ->first();

            $sequence = 1;
            if ($lastDoc) {
                // Extract sequence number
                $parts = explode('-', $lastDoc->doc_no);
                if (count($parts) === 3) {
                    $sequence = intval($parts[2]) + 1;
                }
            }

            $paddedSequence = str_pad($sequence, 4, '0', STR_PAD_LEFT);
            return "{$docType}-{$year}-{$paddedSequence}";
        });
    }
}
