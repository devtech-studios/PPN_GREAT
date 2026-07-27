<?php

namespace App\Http\Controllers;

use App\Models\Supplier;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class SupplierController extends Controller
{
    // GET /api/suppliers
    public function index(Request $request): JsonResponse
    {
        $query = Supplier::query();

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('contact_person', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if ($request->filled('category')) {
            $query->where('category', $request->input('category'));
        }

        $suppliers = $query->orderBy('name', 'asc')->get();

        return response()->json([
            'success' => true,
            'data' => $suppliers
        ]);
    }

    // GET /api/suppliers/{id}
    public function show($id): JsonResponse
    {
        $supplier = Supplier::findOrFail($id);
        return response()->json([
            'success' => true,
            'data' => $supplier
        ]);
    }

    // POST /api/suppliers
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'category' => 'nullable|string|max:100',
            'contact_person' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:100',
            'wechat' => 'nullable|string|max:100',
            'email' => 'nullable|email|max:255',
            'location' => 'nullable|string|max:255',
            'rating' => 'nullable|numeric|min:0|max:5',
            'notes' => 'nullable|string',
            'is_active' => 'nullable|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $supplier = Supplier::create($request->all());

        return response()->json([
            'success' => true,
            'data' => $supplier
        ], 201);
    }

    // PUT /api/suppliers/{id}
    public function update(Request $request, $id): JsonResponse
    {
        $supplier = Supplier::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'category' => 'nullable|string|max:100',
            'contact_person' => 'nullable|string|max:255',
            'phone' => 'nullable|string|max:100',
            'wechat' => 'nullable|string|max:100',
            'email' => 'nullable|email|max:255',
            'location' => 'nullable|string|max:255',
            'rating' => 'nullable|numeric|min:0|max:5',
            'notes' => 'nullable|string',
            'is_active' => 'nullable|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $supplier->update($request->all());

        return response()->json([
            'success' => true,
            'data' => $supplier
        ]);
    }
}
