<?php

namespace App\Http\Controllers;

use App\Models\FinanceDocument;
use App\Models\FinanceDocItem;
use App\Models\Project;
use App\Services\DocNumberService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class FinanceDocController extends Controller
{
    // GET /api/finance/documents
    public function index(Request $request): JsonResponse
    {
        $query = FinanceDocument::query()->with(['customer', 'items']);

        if ($request->filled('doc_type')) {
            $query->where('doc_type', $request->input('doc_type'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('project_id')) {
            $query->where('project_id', $request->input('project_id'));
        }

        $docs = $query->orderBy('doc_no', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $docs
        ]);
    }

    // GET /api/finance/documents/{id}
    public function show($id): JsonResponse
    {
        $doc = FinanceDocument::with(['items', 'customer', 'project'])->findOrFail($id);
        return response()->json([
            'success' => true,
            'data' => $doc
        ]);
    }

    // POST /api/finance/documents
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'project_id' => 'required|exists:projects,id',
            'doc_type' => 'required|in:QU,PI,DP,CI',
            'issue_date' => 'required|date',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.item_name' => 'required|string|max:255',
            'items.*.qty' => 'required|integer|min:1',
            'items.*.unit_price' => 'required|numeric|min:0'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        return DB::transaction(function () use ($request) {
            $project = Project::findOrFail($request->input('project_id'));
            $docType = $request->input('doc_type');
            $issueDate = Carbon::parse($request->input('issue_date'));

            // Calculate Due Date based on project credit term
            $creditTerm = $project->credit_term; // e.g. "30 Days", "Advance"
            $dueDate = $this->calculateDueDate($issueDate, $creditTerm);

            // Auto-generate document number
            $docNo = DocNumberService::generate($docType);

            // Create document (total_amount will be updated below)
            $doc = FinanceDocument::create([
                'doc_no' => $docNo,
                'project_id' => $project->id,
                'customer_id' => $project->customer_id,
                'doc_type' => $docType,
                'status' => 'Draft',
                'total_amount' => 0,
                'credit_term' => $creditTerm,
                'issue_date' => $issueDate->toDateString(),
                'due_date' => $dueDate->toDateString(),
                'notes' => $request->input('notes'),
                'created_by' => auth()->id()
            ]);

            $totalAmount = 0;
            foreach ($request->input('items') as $itemData) {
                $qty = intval($itemData['qty']);
                $unitPrice = floatval($itemData['unit_price']);
                $totalPrice = $qty * $unitPrice;
                $totalAmount += $totalPrice;

                FinanceDocItem::create([
                    'finance_document_id' => $doc->id,
                    'item_name' => $itemData['item_name'],
                    'qty' => $qty,
                    'unit_price' => $unitPrice,
                    'total_price' => $totalPrice
                ]);
            }

            // Update total amount of document
            $doc->total_amount = $totalAmount;
            $doc->save();

            return response()->json([
                'success' => true,
                'data' => $doc->load('items')
            ], 201);
        });
    }

    // PUT /api/finance/documents/{id}
    public function update(Request $request, $id): JsonResponse
    {
        $doc = FinanceDocument::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'issue_date' => 'nullable|date',
            'notes' => 'nullable|string',
            'items' => 'nullable|array|min:1',
            'items.*.item_name' => 'required|string|max:255',
            'items.*.qty' => 'required|integer|min:1',
            'items.*.unit_price' => 'required|numeric|min:0'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        return DB::transaction(function () use ($request, $doc) {
            if ($request->filled('issue_date')) {
                $issueDate = Carbon::parse($request->input('issue_date'));
                $dueDate = $this->calculateDueDate($issueDate, $doc->credit_term);
                $doc->issue_date = $issueDate->toDateString();
                $doc->due_date = $dueDate->toDateString();
            }

            if ($request->has('notes')) {
                $doc->notes = $request->input('notes');
            }

            if ($request->filled('items')) {
                // Delete existing items
                $doc->items()->delete();

                $totalAmount = 0;
                foreach ($request->input('items') as $itemData) {
                    $qty = intval($itemData['qty']);
                    $unitPrice = floatval($itemData['unit_price']);
                    $totalPrice = $qty * $unitPrice;
                    $totalAmount += $totalPrice;

                    FinanceDocItem::create([
                        'finance_document_id' => $doc->id,
                        'item_name' => $itemData['item_name'],
                        'qty' => $qty,
                        'unit_price' => $unitPrice,
                        'total_price' => $totalPrice
                    ]);
                }

                $doc->total_amount = $totalAmount;
            }

            $doc->save();

            return response()->json([
                'success' => true,
                'data' => $doc->load('items')
            ]);
        });
    }

    // PATCH /api/finance/documents/{id}/status
    public function status(Request $request, $id): JsonResponse
    {
        $doc = FinanceDocument::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:Draft,Sent,Paid,Overdue,Cancelled'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $doc->status = $request->input('status');
        $doc->save();

        return response()->json([
            'success' => true,
            'data' => $doc
        ]);
    }

    /**
     * Helper method to calculate Due Date
     */
    private function calculateDueDate(Carbon $issueDate, ?string $creditTerm): Carbon
    {
        $dueDate = clone $issueDate;

        if ($creditTerm === 'Advance') {
            return $dueDate;
        }

        if (preg_match('/(\d+)\s+Days/i', $creditTerm ?? '', $matches)) {
            $days = intval($matches[1]);
            return $dueDate->addDays($days);
        }

        // Default: 30 Days
        return $dueDate->addDays(30);
    }

    // GET /api/finance/supplier-bills
    public function supplierBills(Request $request): JsonResponse
    {
        $query = \App\Models\SupplierBill::query()->with('supplier');

        if ($request->filled('project_id')) {
            $query->where('project_id', $request->input('project_id'));
        }

        $bills = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $bills
        ]);
    }
}
