<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use App\Models\Project;
use App\Models\FinanceDocument;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;

class PaymentController extends Controller
{
    // GET /api/finance/payments
    public function index(Request $request): JsonResponse
    {
        $query = Payment::query()->with(['customer', 'project', 'financeDocument']);

        if ($request->filled('project_id')) {
            $query->where('project_id', $request->input('project_id'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        $payments = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $payments
        ]);
    }

    // POST /api/finance/payments
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'project_id' => 'required|exists:projects,id',
            'finance_document_id' => 'nullable|exists:finance_documents,id',
            'payment_type' => 'required|in:Deposit,Balance,Full',
            'amount' => 'required|numeric|min:0',
            'method' => 'required|in:Bank Transfer,Cheque,Cash,Other',
            'payment_date' => 'required|date',
            'notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $project = Project::findOrFail($request->input('project_id'));

        $payment = Payment::create([
            'project_id' => $project->id,
            'finance_document_id' => $request->input('finance_document_id'),
            'customer_id' => $project->customer_id,
            'payment_type' => $request->input('payment_type'),
            'amount' => $request->input('amount'),
            'method' => $request->input('method'),
            'payment_date' => $request->input('payment_date'),
            'status' => 'Pending Verification',
            'notes' => $request->input('notes')
        ]);

        return response()->json([
            'success' => true,
            'data' => $payment
        ], 201);
    }

    // PATCH /api/finance/payments/{id}/verify — Verify and confirm payment
    public function verify(Request $request, $id): JsonResponse
    {
        $payment = Payment::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:Confirmed'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        return DB::transaction(function () use ($payment) {
            $payment->status = 'Confirmed';
            $payment->verified_by = auth()->id();
            $payment->verified_at = now();
            $payment->save();

            // A deposit must not mark the entire document as Paid. Reconcile all
            // confirmed payments linked to this document and close it only when
            // the accumulated amount covers the document total.
            if ($payment->finance_document_id) {
                $doc = FinanceDocument::find($payment->finance_document_id);
                if ($doc) {
                    $confirmedTotal = Payment::where('finance_document_id', $doc->id)
                        ->where('status', 'Confirmed')
                        ->sum('amount');
                    if ($confirmedTotal >= $doc->total_amount) {
                        $doc->status = 'Paid';
                        $doc->save();
                    }
                }
            }

            // Update project attributes based on payment type
            $project = Project::find($payment->project_id);
            if ($project) {
                if ($payment->payment_type === 'Deposit') {
                    $project->deposit_paid = true;
                } elseif ($payment->payment_type === 'Balance' || $payment->payment_type === 'Full') {
                    $project->balance_paid = true;
                }
                $project->save();
            }

            return response()->json([
                'success' => true,
                'message' => 'ตรวจสอบและยืนยันการรับชำระเงินโอนของลูกค้าเรียบร้อย',
                'data' => $payment
            ]);
        });
    }

    // POST /api/finance/payments/{id}/upload-slip — Upload payment slip
    public function uploadSlip(Request $request, $id): JsonResponse
    {
        $payment = Payment::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'file' => 'required|file|max:10240' // max 10MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $file = $request->file('file');
        
        // Save file storage path
        $path = $file->store('public/slips');
        $publicPath = Storage::url($path);

        $payment->slip_file_path = $publicPath;
        $payment->save();

        return response()->json([
            'success' => true,
            'message' => 'อัปโหลดสลิปหลักฐานการชำระเงินเรียบร้อย',
            'data' => $payment
        ]);
    }

    // GET /api/finance/payments/file/{filename} — Serve payment slip with CORS headers
    public function serveFile($filename)
    {
        $path = storage_path('app/public/slips/' . $filename);
        if (!file_exists($path)) {
            abort(404);
        }
        return response()->file($path, [
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, OPTIONS',
            'Access-Control-Allow-Headers' => 'Content-Type, Authorization',
        ]);
    }
}
