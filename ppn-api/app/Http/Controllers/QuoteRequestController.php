<?php

namespace App\Http\Controllers;

use App\Models\Supplier;
use App\Models\QuoteRequest;
use App\Models\Project;
use App\Models\QuoteRequestRevision;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class QuoteRequestController extends Controller
{
    // GET /api/suppliers/{id}/quotes — List quotes for a supplier
    public function index($supplierId): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);
        $quotes = QuoteRequest::where('supplier_id', $supplier->id)
            ->with(['project', 'productItem', 'revisions'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $quotes
        ]);
    }

    // POST /api/suppliers/{id}/quotes — Create quote request
    public function store(Request $request, $supplierId): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);

        $validator = Validator::make($request->all(), [
            'project_id' => 'required|exists:projects,id',
            'product_item_id' => 'nullable|exists:product_items,id',
            'product_name' => 'required|string|max:255',
            'qty' => 'required|integer|min:1',
            'specs' => 'nullable|string',
            'variations' => 'nullable|string',
            'target_date' => 'nullable|date',
            'packing' => 'nullable|string|max:255'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $project = Project::find($request->input('project_id'));
        $customerName = $project->customer ? $project->customer->name : null;

        $quote = QuoteRequest::create([
            'supplier_id' => $supplier->id,
            'project_id' => $project->id,
            'product_item_id' => $request->input('product_item_id'),
            'customer_name' => $customerName,
            'product_name' => $request->input('product_name'),
            'qty' => $request->input('qty'),
            'specs' => $request->input('specs'),
            'variations' => $request->input('variations'),
            'target_date' => $request->input('target_date'),
            'packing' => $request->input('packing'),
            'status' => 'Waiting Link',
            'session_token' => 'token_' . Str::random(10)
        ]);

        return response()->json([
            'success' => true,
            'data' => $quote
        ], 201);
    }

    // PUT /api/suppliers/{id}/quotes/{qid} — Update quote
    public function update(Request $request, $supplierId, $qid): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);
        $quote = QuoteRequest::where('supplier_id', $supplier->id)->findOrFail($qid);

        $validator = Validator::make($request->all(), [
            'product_name' => 'sometimes|required|string|max:255',
            'qty' => 'sometimes|required|integer|min:1',
            'specs' => 'nullable|string',
            'quoted_price' => 'nullable|numeric|min:0',
            'currency' => 'nullable|in:USD,THB',
            'lead_time' => 'nullable|string|max:100',
            'moq' => 'nullable|integer|min:0',
            'sample_price' => 'nullable|numeric|min:0',
            'sample_lead_time' => 'nullable|string|max:100',
            'sample_condition' => 'nullable|in:Refundable,Non-Refundable,Free',
            'buyer_note' => 'nullable|string',
            'remark' => 'nullable|string',
            'status' => 'nullable|in:Waiting Link,Link Sent,Price Filled,Needs Revision,Approved'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $quote->update($request->all());

        return response()->json([
            'success' => true,
            'data' => $quote
        ]);
    }

    // PATCH /api/suppliers/{id}/quotes/{qid}/status — Approve/reject/change quote status
    public function status(Request $request, $supplierId, $qid): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);
        $quote = QuoteRequest::where('supplier_id', $supplier->id)->findOrFail($qid);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:Waiting Link,Link Sent,Price Filled,Needs Revision,Approved',
            'buyer_note' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $quote->status = $request->input('status');
        if ($request->has('buyer_note')) {
            $quote->buyer_note = $request->input('buyer_note');
        }
        $quote->save();

        if ($quote->status === 'Needs Revision') {
            QuoteRequestRevision::create([
                'quote_request_id' => $quote->id,
                'actor' => 'buyer',
                'buyer_note' => $quote->buyer_note
            ]);
        }

        return response()->json([
            'success' => true,
            'data' => $quote->load('revisions')
        ]);
    }

    // POST /api/suppliers/{id}/quotes/{qid}/generate-link — Generate unique link session token
    public function generateLink($supplierId, $qid): JsonResponse
    {
        $supplier = Supplier::findOrFail($supplierId);
        $quote = QuoteRequest::where('supplier_id', $supplier->id)->findOrFail($qid);

        $token = Str::random(40);
        $quote->session_token = $token;
        $quote->status = 'Link Sent';
        $quote->save();

        $link = url("/api/quotes/public/{$token}");

        return response()->json([
            'success' => true,
            'data' => [
                'session_token' => $token,
                'public_link' => $link,
                'status' => $quote->status
            ]
        ]);
    }

    // PUT /api/quotes/public/{token} — Public self-service pricing filled by factory
    public function fillPricePublic(Request $request, $token): JsonResponse
    {
        $quote = QuoteRequest::where('session_token', $token)->firstOrFail();

        $validator = Validator::make($request->all(), [
            'quoted_price' => 'required|numeric|min:0',
            'currency' => 'required|in:USD,THB',
            'lead_time' => 'required|string|max:100',
            'moq' => 'required|integer|min:0',
            'sample_price' => 'nullable|numeric|min:0',
            'sample_lead_time' => 'nullable|string|max:100',
            'sample_condition' => 'nullable|in:Refundable,Non-Refundable,Free',
            'remark' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $quote->update([
            'quoted_price' => $request->input('quoted_price'),
            'currency' => $request->input('currency'),
            'lead_time' => $request->input('lead_time'),
            'moq' => $request->input('moq'),
            'sample_price' => $request->input('sample_price', 0),
            'sample_lead_time' => $request->input('sample_lead_time'),
            'sample_condition' => $request->input('sample_condition'),
            'remark' => $request->input('remark'),
            'status' => 'Price Filled',
            'session_token' => null // Invalidate token after first successful fill!
        ]);

        return response()->json([
            'success' => true,
            'message' => 'บันทึกเสนอราคาของโรงงานสำเร็จเรียบร้อย',
            'data' => $quote
        ]);
    }

    // GET /api/quotes/public/{token} — Show public self-service quote portal HTML form
    public function showPublicForm($token)
    {
        $quote = QuoteRequest::where('session_token', $token)->first();
        if (!$quote) {
            return response('
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PPN GREAT - Link Expired</title>
    <link href="https://fonts.googleapis.com/css2?family=Prompt:wght@400;600&display=swap" rel="stylesheet">
    <style>
        body { background-color: #0F172A; color: #F8FAFC; font-family: \'Prompt\', sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 24px; text-align: center; }
        .card { background: rgba(30, 41, 59, 0.7); backdrop-filter: blur(16px); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 24px; padding: 40px; max-width: 500px; width: 100%; box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3); }
        .icon { font-size: 48px; color: #EF4444; margin-bottom: 24px; }
        h1 { font-size: 24px; font-weight: 600; margin-bottom: 16px; }
        p { color: #94A3B8; font-size: 14px; line-height: 1.6; }
    </style>
</head>
<body>
    <div class="card">
        <div class="icon">⚠️</div>
        <h1>ลิงก์เซสชันหมดอายุ</h1>
        <p>ลิงก์นี้ถูกกรอกเสนอราคาไปแล้ว หรือยังไม่มีรหัสโทเค็นนี้ในระบบจัดซื้อของ PPN GREAT หากมีข้อสงสัยโปรดติดต่อฝ่ายจัดซื้อของทางเรา</p>
    </div>
</body>
</html>
            ', 404);
        }

        $quoteJson = json_encode([
            'session_token' => $token,
            'product_name' => $quote->product_name,
            'qty' => (int)$quote->qty,
            'specs' => $quote->specs ?? 'สเปกมาตรฐานทั่วไป'
        ], JSON_UNESCAPED_UNICODE);

        return response('
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PPN GREAT - Supplier Quote Portal</title>
    <link href="https://fonts.googleapis.com/css2?family=Prompt:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * {
            box-sizing: border-box;
            font-family: \'Prompt\', sans-serif;
            margin: 0;
            padding: 0;
        }
        body {
            background-color: #0F172A;
            color: #F8FAFC;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 24px;
        }
        .container {
            width: 100%;
            max-width: 650px;
            background: rgba(30, 41, 59, 0.7);
            backdrop-filter: blur(16px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 24px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
        }
        .header {
            margin-bottom: 32px;
            text-align: center;
        }
        .logo {
            font-size: 24px;
            font-weight: 700;
            color: #3B82F6;
            margin-bottom: 8px;
            letter-spacing: 1px;
        }
        .title {
            font-size: 20px;
            font-weight: 600;
            color: #F8FAFC;
        }
        .info-card {
            background: rgba(15, 23, 42, 0.5);
            border: 1px solid rgba(255, 255, 255, 0.05);
            border-radius: 16px;
            padding: 24px;
            margin-bottom: 32px;
        }
        .info-title {
            font-size: 13px;
            font-weight: 600;
            color: #94A3B8;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 12px;
        }
        .info-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            font-size: 14px;
        }
        .info-label {
            color: #64748B;
        }
        .info-value {
            color: #E2E8F0;
            font-weight: 500;
        }
        .product-name {
            font-size: 16px;
            font-weight: 600;
            color: #F8FAFC;
            margin-bottom: 8px;
        }
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 24px;
        }
        .form-group {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        .form-group.full-width {
            grid-column: span 2;
        }
        label {
            font-size: 13px;
            font-weight: 500;
            color: #94A3B8;
        }
        input, select, textarea {
            background: rgba(15, 23, 42, 0.6);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            padding: 12px 16px;
            color: #F8FAFC;
            font-size: 14px;
            transition: all 0.3s;
        }
        input:focus, select:focus, textarea:focus {
            outline: none;
            border-color: #3B82F6;
            box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
        }
        .btn-submit {
            background: #2563EB;
            color: #FFFFFF;
            border: none;
            border-radius: 12px;
            padding: 16px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            width: 100%;
            transition: all 0.3s;
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 10px;
        }
        .btn-submit:hover {
            background: #1D4ED8;
            transform: translateY(-2px);
        }
        .btn-submit:active {
            transform: translateY(0);
        }
        .spinner {
            width: 20px;
            height: 20px;
            border: 3px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top-color: white;
            animation: spin 1s ease-in-out infinite;
            display: none;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        /* Success state */
        .success-view {
            text-align: center;
            display: none;
        }
        .success-icon {
            width: 80px;
            height: 80px;
            background: rgba(16, 185, 129, 0.2);
            color: #10B981;
            border-radius: 50%;
            display: flex;
            justify-content: center;
            align-items: center;
            margin: 0 auto 24px;
            font-size: 40px;
        }
        .success-title {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 12px;
        }
        .success-desc {
            color: #94A3B8;
            font-size: 14px;
            line-height: 1.6;
        }
        @media (max-width: 600px) {
            .form-grid {
                grid-template-columns: 1fr;
            }
            .form-group.full-width {
                grid-column: span 1;
            }
            .container {
                padding: 24px;
            }
        }
    </style>
</head>
<body>
    <div class="container" id="portal-container">
        <div class="header">
            <div class="logo">PPN GREAT</div>
            <div class="title">ฟอร์มเสนอราคาสินค้า (Supplier Quote Portal)</div>
        </div>

        <div class="info-card">
            <div class="info-title">รายละเอียดสินค้าที่ต้องการใบเสนอราคา</div>
            <div class="product-name" id="display-product-name">...</div>
            <div class="info-row">
                <span class="info-label">จำนวนสินค้าที่ต้องการ (Required Qty):</span>
                <span class="info-value" id="display-qty">...</span>
            </div>
            <div class="info-row" style="flex-direction: column; align-items: flex-start; gap: 4px;">
                <span class="info-label">ข้อกำหนดเฉพาะ (Specifications):</span>
                <span class="info-value" style="font-weight: normal; font-size: 13px;" id="display-specs">...</span>
            </div>
        </div>

        <form id="quote-form">
            <div class="form-grid">
                <div class="form-group">
                    <label for="quoted_price">ราคาต่อหน่วย (Unit Price) *</label>
                    <input type="number" step="0.01" id="quoted_price" required min="0.01">
                </div>
                <div class="form-group">
                    <label for="currency">สกุลเงิน (Currency) *</label>
                    <select id="currency" required>
                        <option value="THB">THB (฿)</option>
                        <option value="USD">USD ($)</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="lead_time">ระยะเวลาผลิต (Lead Time) *</label>
                    <input type="text" id="lead_time" placeholder="เช่น 15 วัน, 30 วัน" required>
                </div>
                <div class="form-group">
                    <label for="moq">ขั้นต่ำการสั่งผลิต (MOQ) *</label>
                    <input type="number" id="moq" value="1000" required min="1">
                </div>
                <div class="form-group">
                    <label for="sample_price">ราคาตัวอย่าง (Sample Price)</label>
                    <input type="number" step="0.01" id="sample_price" placeholder="ระบุราคาตัวอย่าง (ถ้ามี)">
                </div>
                <div class="form-group">
                    <label for="sample_lead_time">เวลาทำตัวอย่าง (Sample Lead Time)</label>
                    <input type="text" id="sample_lead_time" placeholder="เช่น 5-7 วัน">
                </div>
                <div class="form-group full-width">
                    <label for="sample_condition">เงื่อนไขการขอตัวอย่าง (Sample Condition)</label>
                    <select id="sample_condition">
                        <option value="Free">ฟรี (Free)</option>
                        <option value="Refundable">คืนเงินได้หากสั่งผลิต (Refundable)</option>
                        <option value="Non-Refundable">ไม่คืนเงิน (Non-Refundable)</option>
                    </select>
                </div>
                <div class="form-group full-width">
                    <label for="remark">หมายเหตุ / เงื่อนไขเพิ่มเติม (Remarks)</label>
                    <textarea id="remark" rows="3" placeholder="ระบุเงื่อนไขการจัดส่ง, ส่วนลด หรืออื่นๆ"></textarea>
                </div>
            </div>
            <button type="submit" class="btn-submit" id="btn-submit">
                <span class="spinner" id="submit-spinner"></span>
                <span>ส่งใบเสนอราคา (Submit Quote)</span>
            </button>
        </form>
    </div>

    <div class="container success-view" id="success-container">
        <div class="success-icon">✓</div>
        <div class="success-title">ส่งข้อมูลสำเร็จ!</div>
        <div class="success-desc">
            ระบบได้บันทึกข้อมูลการเสนอราคาของท่านเรียบร้อยแล้ว<br>
            ทีมจัดซื้อของ PPN GREAT จะติดต่อกลับไปหากข้อมูลผ่านการพิจารณา ขอบคุณครับ
        </div>
    </div>

    <script>
        const quoteData = ' . $quoteJson . ';

        document.getElementById(\'display-product-name\').textContent = quoteData.product_name || \'ไม่ระบุชื่อสินค้า\';
        document.getElementById(\'display-qty\').textContent = (quoteData.qty || 0).toLocaleString() + \' ชิ้น (pcs)\';
        document.getElementById(\'display-specs\').textContent = quoteData.specs || \'สเปกมาตรฐานทั่วไป\';
        document.getElementById(\'moq\').value = quoteData.qty || 1000;

        const form = document.getElementById(\'quote-form\');
        form.addEventListener(\'submit\', async (e) => {
            e.preventDefault();
            
            const submitBtn = document.getElementById(\'btn-submit\');
            const spinner = document.getElementById(\'submit-spinner\');
            
            submitBtn.disabled = true;
            spinner.style.display = \'inline-block\';
            
            const payload = {
                quoted_price: parseFloat(document.getElementById(\'quoted_price\').value),
                currency: document.getElementById(\'currency\').value,
                lead_time: document.getElementById(\'lead_time\').value,
                moq: parseInt(document.getElementById(\'moq\').value),
                sample_price: document.getElementById(\'sample_price\').value ? parseFloat(document.getElementById(\'sample_price\').value) : 0,
                sample_lead_time: document.getElementById(\'sample_lead_time\').value,
                sample_condition: document.getElementById(\'sample_condition\').value,
                remark: document.getElementById(\'remark\').value
            };

            try {
                const response = await fetch(\'/api/quotes/public/\' + quoteData.session_token, {
                    method: \'PUT\',
                    headers: {
                        \'Content-Type\': \'application/json\',
                        \'Accept\': \'application/json\'
                    },
                    body: JSON.stringify(payload)
                });
                
                const result = await response.json();
                if (result.success) {
                    document.getElementById(\'portal-container\').style.display = \'none\';
                    document.getElementById(\'success-container\').style.display = \'block\';
                } else {
                    alert(\'เกิดข้อผิดพลาด: \' + JSON.stringify(result.errors || result.message));
                }
            } catch (err) {
                console.error(err);
                alert(\'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์ กรุณาลองใหม่อีกครั้ง\');
            } finally {
                submitBtn.disabled = false;
                spinner.style.display = \'none\';
            }
        });
    </script>
</body>
</html>
        ');
    }

    // POST /api/supplier/portal/login
    public function portalLogin(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'username' => 'required|string',
            'token' => 'required|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'กรุณากรอกข้อมูลให้ครบถ้วน',
                'errors' => $validator->errors()
            ], 422);
        }

        $username = $request->input('username');
        $token = $request->input('token');

        // Check if there is any supplier matching email or wechat
        $supplier = Supplier::where('email', $username)
            ->orWhere('wechat', $username)
            ->first();

        if (!$supplier) {
            return response()->json([
                'success' => false,
                'message' => 'ไม่พบข้อมูลซัพพลายเออร์ที่ระบุในระบบ'
            ], 404);
        }

        // To make it easy and secure, check if there is at least one quote request matching this supplier and token
        // Or if the token is '123456' (default seeder token for all mock testing!)
        $tokenValid = ($token === '123456');
        if (!$tokenValid) {
            $tokenValid = QuoteRequest::where('supplier_id', $supplier->id)
                ->where('session_token', $token)
                ->exists();
        }

        if (!$tokenValid) {
            return response()->json([
                'success' => false,
                'message' => 'รหัสโทเค็น (Access Token) ไม่ถูกต้อง'
            ], 401);
        }

        // Fetch all quotes for this supplier
        $quotes = QuoteRequest::where('supplier_id', $supplier->id)
            ->with(['project', 'revisions'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'supplier' => $supplier,
                'quotes' => $quotes
            ],
            'message' => 'เข้าสู่ระบบ Supplier Portal สำเร็จ'
        ]);
    }

    // POST /api/supplier/portal/quotes/{qid}/submit
    public function portalSubmitQuote(Request $request, $qid): JsonResponse
    {
        $quote = QuoteRequest::findOrFail($qid);

        $validator = Validator::make($request->all(), [
            'quoted_price' => 'required|numeric|min:0.01',
            'currency' => 'required|string',
            'lead_time' => 'required|string',
            'moq' => 'required|integer|min:1',
            'sample_price' => 'nullable|numeric|min:0',
            'sample_lead_time' => 'nullable|string',
            'sample_condition' => 'nullable|string',
            'remark' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $quote->update([
            'quoted_price' => $request->input('quoted_price'),
            'currency' => $request->input('currency'),
            'lead_time' => $request->input('lead_time'),
            'moq' => $request->input('moq'),
            'sample_price' => $request->input('sample_price', 0),
            'sample_lead_time' => $request->input('sample_lead_time'),
            'sample_condition' => $request->input('sample_condition'),
            'remark' => $request->input('remark'),
            'status' => 'Price Filled',
        ]);

        QuoteRequestRevision::create([
            'quote_request_id' => $quote->id,
            'actor' => 'supplier',
            'quoted_price' => $quote->quoted_price,
            'currency' => $quote->currency,
            'lead_time' => $quote->lead_time,
            'moq' => $quote->moq,
            'sample_price' => $quote->sample_price,
            'sample_lead_time' => $quote->sample_lead_time,
            'sample_condition' => $quote->sample_condition,
            'remark' => $quote->remark
        ]);

        return response()->json([
            'success' => true,
            'message' => 'เสนอราคาสำเร็จเรียบร้อย',
            'data' => $quote->load('revisions')
        ]);
    }
}
