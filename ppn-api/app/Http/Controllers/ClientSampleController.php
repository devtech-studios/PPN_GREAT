<?php

namespace App\Http\Controllers;

use App\Models\ClientSample;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class ClientSampleController extends Controller
{
    // GET /api/samples — List all samples, filter by status
    public function index(Request $request): JsonResponse
    {
        $query = ClientSample::query()->with(['project', 'productItem']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        $samples = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $samples
        ]);
    }

    // GET /api/samples/project/{pid} — Get samples for a specific project
    public function getByProject($pid): JsonResponse
    {
        $samples = ClientSample::where('project_id', $pid)
            ->with('productItem')
            ->orderBy('attempt', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $samples
        ]);
    }

    // POST /api/samples — Create client sample request
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'project_id' => 'required|exists:projects,id',
            'product_item_id' => 'nullable|exists:product_items,id',
            'sample_type' => 'required|in:Pre-production Sample,Material Swatch,3D Printed Mockup,Other',
            'origin' => 'required|in:China,In-Stock',
            'supplier_name' => 'nullable|string|max:255',
            'china_tracking' => 'nullable|string|max:100',
            'local_courier' => 'nullable|string|max:100',
            'local_tracking' => 'nullable|string|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        return DB::transaction(function () use ($request) {
            $projectId = $request->input('project_id');
            $productItemId = $request->input('product_item_id');

            // Calculate attempt count for this project/product item
            $existingAttempts = ClientSample::where('project_id', $projectId);
            if ($productItemId) {
                $existingAttempts->where('product_item_id', $productItemId);
            }
            $attemptCount = $existingAttempts->count() + 1;

            $sample = ClientSample::create([
                'project_id' => $projectId,
                'product_item_id' => $productItemId,
                'sample_code' => 'TEMP_CODE', // Will update below
                'attempt' => $attemptCount,
                'sample_type' => $request->input('sample_type'),
                'origin' => $request->input('origin'),
                'supplier_name' => $request->input('supplier_name'),
                'status' => $request->input('origin') === 'China' ? 'Waiting from China' : 'Received from China',
                'china_tracking' => $request->input('china_tracking'),
                'local_courier' => $request->input('local_courier'),
                'local_tracking' => $request->input('local_tracking'),
            ]);

            // Update sample code with padded ID
            $sample->sample_code = 'SMP-' . str_pad($sample->id, 3, '0', STR_PAD_LEFT);
            $sample->save();

            return response()->json([
                'success' => true,
                'data' => $sample
            ], 201);
        });
    }

    // PUT /api/samples/{id} — Update sample details
    public function update(Request $request, $id): JsonResponse
    {
        $sample = ClientSample::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'sample_type' => 'sometimes|required|in:Pre-production Sample,Material Swatch,3D Printed Mockup,Other',
            'origin' => 'sometimes|required|in:China,In-Stock',
            'supplier_name' => 'nullable|string|max:255',
            'china_tracking' => 'nullable|string|max:100',
            'local_courier' => 'nullable|string|max:100',
            'local_tracking' => 'nullable|string|max:100',
            'sent_date' => 'nullable|date',
            'feedback' => 'nullable|string',
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

    // PATCH /api/samples/{id}/status — Change sample status
    public function status(Request $request, $id): JsonResponse
    {
        $sample = ClientSample::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:Waiting from China,Received from China,Sent to Client,Delivered to Client,Approved,Rejected',
            'feedback' => 'nullable|string',
            'sent_date' => 'nullable|date'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $sample->status = $request->input('status');
        
        if ($request->has('feedback')) {
            $sample->feedback = $request->input('feedback');
        }

        if ($request->has('sent_date')) {
            $sample->sent_date = $request->input('sent_date');
        } elseif ($request->input('status') === 'Sent to Client' && !$sample->sent_date) {
            $sample->sent_date = now()->toDateString();
        }

        $sample->save();

        return response()->json([
            'success' => true,
            'data' => $sample
        ]);
    }
}
