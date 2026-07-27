<?php

namespace App\Http\Controllers;

use App\Models\Supplier;
use App\Models\SupplierBill;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class SupplierBillController extends Controller
{
    // GET /api/suppliers/{id}/bills
    public function index($supplierId): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);
        $bills = SupplierBill::where('supplier_id', $supplier->id)
            ->with('project')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $bills
        ]);
    }

    // POST /api/suppliers/{id}/bills
    public function store(Request $request, $supplierId): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);

        $validator = Validator::make($request->all(), [
            'project_id' => 'required|exists:projects,id',
            'product_name' => 'required|string|max:255',
            'bill_type' => 'required|in:Deposit,Balance,Full Payment',
            'amount' => 'required|numeric|min:0',
            'currency' => 'required|in:USD,THB',
            'due_month' => 'nullable|string|max:20'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $bill = SupplierBill::create([
            'supplier_id' => $supplier->id,
            'project_id' => $request->input('project_id'),
            'product_name' => $request->input('product_name'),
            'bill_type' => $request->input('bill_type'),
            'amount' => $request->input('amount'),
            'currency' => $request->input('currency'),
            'due_month' => $request->input('due_month'),
            'status' => 'Pending'
        ]);

        return response()->json([
            'success' => true,
            'data' => $bill
        ], 201);
    }

    // PATCH /api/suppliers/{id}/bills/{bid}/pay — Record payment to factory
    public function pay(Request $request, $supplierId, $bid): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);
        $bill = SupplierBill::where('supplier_id', $supplier->id)->findOrFail($bid);

        $bill->status = 'Paid';
        $bill->paid_at = now();
        $bill->save();

        return response()->json([
            'success' => true,
            'message' => 'บันทึกการชำระเงินค่ามัดจำ/ผลิตให้โรงงานเรียบร้อย',
            'data' => $bill
        ]);
    }

    // POST /api/suppliers/{id}/bills/{bid}/upload — Upload PI or Invoice
    public function upload(Request $request, $supplierId, $bid): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);
        $bill = SupplierBill::where('supplier_id', $supplier->id)->findOrFail($bid);

        $validator = Validator::make($request->all(), [
            'file_type' => 'required|in:pi,invoice',
            'file' => 'required|file|max:10240' // max 10MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $fileType = $request->input('file_type');
        $file = $request->file('file');
        
        // Save file storage path
        $path = $file->store('public/bills');
        $publicPath = Storage::url($path);

        if ($fileType === 'pi') {
            $bill->pi_uploaded = true;
            $bill->pi_file_path = $publicPath;
        } else {
            $bill->invoice_uploaded = true;
            $bill->invoice_file_path = $publicPath;
        }
        
        $bill->save();

        return response()->json([
            'success' => true,
            'message' => 'อัปโหลดไฟล์เอกสารประกอบสำเร็จ',
            'data' => $bill
        ]);
    }
}
