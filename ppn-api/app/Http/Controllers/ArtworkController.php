<?php

namespace App\Http\Controllers;

use App\Models\ArtworkLog;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ArtworkController extends Controller
{
    // GET /api/artworks — List all artworks
    public function index(Request $request): JsonResponse
    {
        $query = ArtworkLog::query()->with(['project', 'productItem']);

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        $artworks = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $artworks
        ]);
    }

    // GET /api/artworks/project/{pid} — Get artworks for a specific project
    public function getByProject($pid): JsonResponse
    {
        $artworks = ArtworkLog::where('project_id', $pid)
            ->with('productItem')
            ->orderBy('attempt', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $artworks
        ]);
    }

    // POST /api/artworks — Upload/Add new artwork log
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'project_id' => 'required|exists:projects,id',
            'product_item_id' => 'nullable|exists:product_items,id',
            'version' => 'required|string|max:50',
            'source' => 'required|in:In-house Designer,Freelance,Customer Provided,Supplier',
            'file_name' => 'required|string|max:255',
            'file_path' => 'required|string|max:500',
            'feedback' => 'nullable|string',
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

            // Calculate attempt count
            $existingAttempts = ArtworkLog::where('project_id', $projectId);
            if ($productItemId) {
                $existingAttempts->where('product_item_id', $productItemId);
            }
            $attemptCount = $existingAttempts->count() + 1;

            $artwork = ArtworkLog::create([
                'project_id' => $projectId,
                'product_item_id' => $productItemId,
                'artwork_code' => 'TEMP_ART_CODE', // Will update below
                'attempt' => $attemptCount,
                'version' => $request->input('version'),
                'source' => $request->input('source'),
                'status' => 'Awaiting Approval',
                'file_name' => $request->input('file_name'),
                'file_path' => $request->input('file_path'),
                'feedback' => $request->input('feedback'),
            ]);

            $artwork->artwork_code = 'ART-' . str_pad($artwork->id, 3, '0', STR_PAD_LEFT);
            $artwork->save();

            return response()->json([
                'success' => true,
                'data' => $artwork
            ], 201);
        });
    }

    // PUT /api/artworks/{id} — Update artwork log details
    public function update(Request $request, $id): JsonResponse
    {
        $artwork = ArtworkLog::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'version' => 'sometimes|required|string|max:50',
            'source' => 'sometimes|required|in:In-house Designer,Freelance,Customer Provided,Supplier',
            'file_name' => 'sometimes|required|string|max:255',
            'file_path' => 'sometimes|required|string|max:500',
            'feedback' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $artwork->update($request->all());

        return response()->json([
            'success' => true,
            'data' => $artwork
        ]);
    }

    // PATCH /api/artworks/{id}/status — Update artwork status
    public function status(Request $request, $id): JsonResponse
    {
        $artwork = ArtworkLog::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:Awaiting Approval,Reviewing,Need Revision,Rejected,Approved by Client,Approved by Supplier',
            'feedback' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $artwork->status = $request->input('status');
        if ($request->has('feedback')) {
            $artwork->feedback = $request->input('feedback');
        }
        $artwork->save();

        return response()->json([
            'success' => true,
            'data' => $artwork
        ]);
    }

    // PATCH /api/artworks/{id}/feedback — Submit customer review feedback
    public function feedback(Request $request, $id): JsonResponse
    {
        $artwork = ArtworkLog::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:Need Revision,Approved by Client,Rejected',
            'feedback' => 'required|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $artwork->status = $request->input('status');
        $artwork->feedback = $request->input('feedback');
        $artwork->save();

        return response()->json([
            'success' => true,
            'message' => 'บันทึกความเห็นของลูกค้าต่อแบบอาร์ตเวิร์กสำเร็จ',
            'data' => $artwork
        ]);
    }

    // POST /api/artworks/upload — Upload design file
    public function upload(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|file|max:20480' // max 20MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $file = $request->file('file');
        
        // Save file to storage/app/public/artworks using public disk
        $path = $file->store('artworks', 'public');
        $publicPath = Storage::url($path);

        return response()->json([
            'success' => true,
            'file_name' => $file->getClientOriginalName(),
            'file_path' => $publicPath
        ]);
    }

    // GET /api/artworks/file/{filename} — Serve artwork file with CORS headers
    public function serveFile($filename)
    {
        $path = storage_path('app/public/artworks/' . $filename);
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
