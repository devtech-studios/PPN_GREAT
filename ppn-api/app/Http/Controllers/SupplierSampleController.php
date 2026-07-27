<?php

namespace App\Http\Controllers;

use App\Models\Supplier;
use App\Models\SupplierSample;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class SupplierSampleController extends Controller
{
    // GET /api/suppliers/{id}/samples
    public function index($supplierId): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);
        $samples = SupplierSample::where('supplier_id', $supplier->id)
            ->with('project')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $samples
        ]);
    }

    // POST /api/suppliers/{id}/samples
    public function store(Request $request, $supplierId): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);

        $validator = Validator::make($request->all(), [
            'project_id' => 'required|exists:projects,id',
            'product_name' => 'required|string|max:255',
            'specs' => 'nullable|string',
            'cost' => 'nullable|string|max:50',
            'tracking_no' => 'nullable|string|max:100',
            'expected_date' => 'nullable|date'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $project = Project::find($request->input('project_id'));
        $customerName = $project->customer ? $project->customer->name : null;

        $sample = SupplierSample::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project->id,
            'product_name' => $request->input('product_name'),
            'customer_name' => $customerName,
            'specs' => $request->input('specs'),
            'cost' => $request->input('cost', 'TBD'),
            'tracking_no' => $request->input('tracking_no'),
            'expected_date' => $request->input('expected_date'),
            'status' => 'Waiting Supplier'
        ]);

        return response()->json([
            'success' => true,
            'data' => $sample
        ], 201);
    }

    // PUT /api/suppliers/{id}/samples/{sid}
    public function update(Request $request, $supplierId, $sid): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);
        $sample = SupplierSample::where('supplier_id', $supplier->id)->findOrFail($sid);

        $validator = Validator::make($request->all(), [
            'product_name' => 'sometimes|required|string|max:255',
            'specs' => 'nullable|string',
            'cost' => 'nullable|string|max:50',
            'tracking_no' => 'nullable|string|max:100',
            'expected_date' => 'nullable|date',
            'status' => 'nullable|in:Waiting Supplier,Sample Sent,Approved'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $sample->update($request->all());

        return response()->json([
            'success' => true,
            'data' => $sample
        ]);
    }

    // PATCH /api/suppliers/{id}/samples/{sid}/status
    public function status(Request $request, $supplierId, $sid): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);
        $sample = SupplierSample::where('supplier_id', $supplier->id)->findOrFail($sid);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:Waiting Supplier,Sample Sent,Approved'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $sample->status = $request->input('status');
        $sample->save();

        return response()->json([
            'success' => true,
            'data' => $sample
        ]);
    }
}
