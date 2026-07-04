<?php

namespace App\Http\Controllers;

use App\Models\Customer;
use App\Models\ContactPerson;
use App\Models\ShippingAddress;
use App\Models\ActivityLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class CustomerController extends Controller
{
    // GET /api/customers — List + Search + Paginate
    public function index(Request $request): JsonResponse
    {
        $query = Customer::query();

        // Search
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('tax_id', 'like', "%{$search}%");
            });
        }

        // Filters
        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        // Sorting
        $sortBy = $request->get('sort', 'created_at');
        $order = $request->get('order', 'desc');
        $query->orderBy($sortBy, $order);

        // Paginate
        $perPage = $request->get('per_page', 20);
        $items = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $items->items(),
            'meta' => [
                'current_page' => $items->currentPage(),
                'last_page' => $items->lastPage(),
                'per_page' => $items->perPage(),
                'total' => $items->total(),
            ]
        ]);
    }

    // GET /api/customers/{id} — Detail
    public function show($id): JsonResponse
    {
        $customer = Customer::with(['contacts', 'shippingAddresses', 'projects'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $customer
        ]);
    }

    // POST /api/customers — Create
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'type' => 'nullable|in:Enterprise,Mid-Market,SME',
            'status' => 'nullable|in:Active,Inactive',
            'tax_id' => 'nullable|string|max:20',
            'branch' => 'nullable|string|max:100',
            'industry' => 'nullable|string|max:100',
            'lead_source' => 'nullable|in:Facebook Ads,Google Search,Referral,Exhibition,Direct Contact,Other',
            'internal_note' => 'nullable|string',
            'billing_address' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ข้อมูลนำเข้าไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            $customer = DB::transaction(function () use ($request) {
                $data = $request->all();
                $data['created_by'] = auth()->id();
                $customer = Customer::create($data);

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'action' => 'สร้าง Customer',
                    'description' => "สร้างลูกค้า {$customer->name}",
                    'entity_type' => 'customers',
                    'entity_id' => $customer->id,
                ]);

                return $customer;
            });

            return response()->json([
                'success' => true,
                'data' => $customer,
                'message' => 'สร้างลูกค้าสำเร็จ'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'CREATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // PUT /api/customers/{id} — Update
    public function update(Request $request, $id): JsonResponse
    {
        $customer = Customer::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'type' => 'nullable|in:Enterprise,Mid-Market,SME',
            'status' => 'nullable|in:Active,Inactive',
            'tax_id' => 'nullable|string|max:20',
            'branch' => 'nullable|string|max:100',
            'industry' => 'nullable|string|max:100',
            'lead_source' => 'nullable|in:Facebook Ads,Google Search,Referral,Exhibition,Direct Contact,Other',
            'internal_note' => 'nullable|string',
            'billing_address' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ข้อมูลนำเข้าไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            DB::transaction(function () use ($request, $customer) {
                $customer->update($request->all());

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'action' => 'อัปเดต Customer',
                    'description' => "อัปเดตข้อมูลลูกค้า {$customer->name}",
                    'entity_type' => 'customers',
                    'entity_id' => $customer->id,
                ]);
            });

            return response()->json([
                'success' => true,
                'data' => $customer->fresh(),
                'message' => 'อัปเดตข้อมูลลูกค้าสำเร็จ'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'UPDATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // POST /api/customers/{id}/contacts — Add Contact
    public function storeContact(Request $request, $id): JsonResponse
    {
        $customer = Customer::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'role' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'line_id' => 'nullable|string|max:100',
            'other_chat' => 'nullable|string|max:255',
            'is_primary' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ข้อมูลนำเข้าไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            $contact = DB::transaction(function () use ($request, $customer) {
                $isPrimary = $request->boolean('is_primary');

                if ($isPrimary) {
                    ContactPerson::where('customer_id', $customer->id)->update(['is_primary' => false]);
                }

                $data = $request->all();
                $data['customer_id'] = $customer->id;
                $data['is_primary'] = $isPrimary;

                $contact = ContactPerson::create($data);

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'action' => 'สร้าง ContactPerson',
                    'description' => "เพิ่มผู้ติดต่อ {$contact->name} สำหรับลูกค้า {$customer->name}",
                    'entity_type' => 'customers',
                    'entity_id' => $customer->id,
                ]);

                return $contact;
            });

            return response()->json([
                'success' => true,
                'data' => $contact,
                'message' => 'เพิ่มผู้ติดต่อสำเร็จ'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'CREATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // PUT /api/customers/{id}/contacts/{cid} — Update Contact
    public function updateContact(Request $request, $id, $cid): JsonResponse
    {
        $customer = Customer::findOrFail($id);
        $contact = ContactPerson::where('customer_id', $customer->id)->findOrFail($cid);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'role' => 'nullable|string|max:100',
            'phone' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'line_id' => 'nullable|string|max:100',
            'other_chat' => 'nullable|string|max:255',
            'is_primary' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ข้อมูลนำเข้าไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            DB::transaction(function () use ($request, $customer, $contact) {
                if ($request->has('is_primary')) {
                    $isPrimary = $request->boolean('is_primary');
                    if ($isPrimary) {
                        ContactPerson::where('customer_id', $customer->id)->update(['is_primary' => false]);
                    }
                    $contact->is_primary = $isPrimary;
                }

                $contact->update($request->except('is_primary'));

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'action' => 'อัปเดต ContactPerson',
                    'description' => "อัปเดตผู้ติดต่อ {$contact->name} สำหรับลูกค้า {$customer->name}",
                    'entity_type' => 'customers',
                    'entity_id' => $customer->id,
                ]);
            });

            return response()->json([
                'success' => true,
                'data' => $contact->fresh(),
                'message' => 'อัปเดตผู้ติดต่อสำเร็จ'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'UPDATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // DELETE /api/customers/{id}/contacts/{cid} — Delete Contact
    public function destroyContact($id, $cid): JsonResponse
    {
        $customer = Customer::findOrFail($id);
        $contact = ContactPerson::where('customer_id', $customer->id)->findOrFail($cid);

        try {
            DB::transaction(function () use ($customer, $contact) {
                $contact->delete();

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'action' => 'ลบ ContactPerson',
                    'description' => "ลบผู้ติดต่อ {$contact->name} ของลูกค้า {$customer->name}",
                    'entity_type' => 'customers',
                    'entity_id' => $customer->id,
                ]);
            });

            return response()->json([
                'success' => true,
                'message' => 'ลบผู้ติดต่อสำเร็จ'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'DELETE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // POST /api/customers/{id}/addresses — Add Shipping Address
    public function storeAddress(Request $request, $id): JsonResponse
    {
        $customer = Customer::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'label' => 'required|string|max:255',
            'address' => 'required|string',
            'is_default' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ข้อมูลนำเข้าไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            $address = DB::transaction(function () use ($request, $customer) {
                $isDefault = $request->boolean('is_default');

                if ($isDefault) {
                    ShippingAddress::where('customer_id', $customer->id)->update(['is_default' => false]);
                }

                $address = ShippingAddress::create([
                    'customer_id' => $customer->id,
                    'label' => $request->label,
                    'address' => $request->address,
                    'is_default' => $isDefault,
                ]);

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'action' => 'สร้าง ShippingAddress',
                    'description' => "เพิ่มที่อยู่จัดส่ง '{$address->label}' สำหรับลูกค้า {$customer->name}",
                    'entity_type' => 'customers',
                    'entity_id' => $customer->id,
                ]);

                return $address;
            });

            return response()->json([
                'success' => true,
                'data' => $address,
                'message' => 'เพิ่มที่อยู่จัดส่งสำเร็จ'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'CREATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // GET /api/customers/{id}/stats — Customer Stats
    public function stats($id): JsonResponse
    {
        $customer = Customer::findOrFail($id);

        // Calculate Revenue Lifetime (Confirmed Payments)
        $revenueLifetime = DB::table('payments')
            ->where('customer_id', $id)
            ->where('status', 'Confirmed')
            ->sum('amount');

        // Calculate Projects Stats
        $activeProjects = DB::table('projects')
            ->where('customer_id', $id)
            ->whereNotIn('status', ['Delivered', 'Cancelled'])
            ->count();

        $completedProjects = DB::table('projects')
            ->where('customer_id', $id)
            ->where('status', 'Delivered')
            ->count();

        // Calculate Payment On-time (Simplified or standard mock based on data)
        // Count confirmed payments vs total payments
        $totalPayments = DB::table('payments')
            ->where('customer_id', $id)
            ->count();
            
        $confirmedPayments = DB::table('payments')
            ->where('customer_id', $id)
            ->where('status', 'Confirmed')
            ->count();

        $paymentOnTime = $totalPayments > 0 ? round(($confirmedPayments / $totalPayments) * 100) : 100;

        // Customer since
        $customerSince = $customer->created_at ? $customer->created_at->format('Y-m-d') : null;

        return response()->json([
            'success' => true,
            'data' => [
                'revenue_lifetime' => floatval($revenueLifetime),
                'projects_active' => $activeProjects,
                'projects_completed' => $completedProjects,
                'payment_on_time' => $paymentOnTime,
                'customer_since' => $customerSince,
                'has_outstanding' => DB::table('finance_documents')
                    ->where('customer_id', $id)
                    ->whereIn('status', ['Sent', 'Overdue'])
                    ->exists()
            ]
        ]);
    }
}
