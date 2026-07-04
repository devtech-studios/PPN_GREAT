import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _searchText = "";
  String _selectedSupplierId = "SUP-001";
  String _activeTab = "Quotes"; // Tab เริ่มต้น: Quotes / Samples / Payments

  // Set สำหรับเก็บบิลที่ถูกติ๊กเลือกเพื่อจ่ายหรือเลื่อน
  final Set<String> _selectedBillIds = {};

  final List<Map<String, dynamic>> _allProjects = [
    {
      "id": "PRJ-009",
      "customer": "Central Group",
      "products": [
        {"name": "ร่มกอล์ฟ 30 นิ้ว", "qty": 1500},
        {"name": "กระบอกน้ำสแตนเลส เลเซอร์โลโก้", "qty": 2000},
        {"name": "ถุงผ้าสปันบอนด์", "qty": 3000},
      ],
    },
    {
      "id": "PRJ-020",
      "customer": "Wongnai",
      "products": [
        {"name": "กระเป๋าเป้สะพายหลัง (Rider Bag)", "qty": 3000},
        {"name": "หมวกแก๊ปสกรีนโลโก้", "qty": 5000},
      ],
    },
    {
      "id": "PRJ-021",
      "customer": "Line Man",
      "products": [
        {"name": "แจ็คเก็ตไรเดอร์ กันน้ำ", "qty": 10000},
      ],
    },
  ];

  // ==========================================
  // Mock Data: เพิ่มข้อมูล Quote & Sample แยกกัน
  // ==========================================
  final List<Map<String, dynamic>> _suppliers = [
    {
      "id": "SUP-001",
      "name": "Guangzhou Bags Factory Co., Ltd.",
      "contact_person": "Mr. Chen Weiting",
      "phone": "+86 138 1234 5678",
      "category": "Textile & Bags",
      "rating": 4.8,
      "pending_quotes": <Map<String, dynamic>>[
        {
          "project_id": "PRJ-001",
          "customer": "Lion (Thailand)",
          "product": "กระเป๋าผ้าคอตตอน 12 ออนซ์",
          "qty": 20000,
          "status": "Waiting Link",
          "specs": "12oz Cotton, 30x40cm, 1 color screen print on 1 side",
          "variations": "1 Design (Green Logo)",
          "target_date": "15 Aug 2026",
          "packing": "Standard Packing (50pcs/carton)",
        },
      ],
      "pending_samples": <Map<String, dynamic>>[
        {
          "project_id": "PRJ-020",
          "customer": "Wongnai",
          "product": "กระเป๋าเป้สะพายหลัง (Rider Bag)",
          "status": "Sample Sent",
          "specs":
              "ขอเนื้อผ้าตัวอย่าง 3 แบบ (Nylon, Polyester, Canvas) ไม่ต้องสกรีนลาย",
          "cost": "Free",
          "tracking_no": "SF1234567890",
          "expected_date": "28 May 2026",
        },
      ],
      "pending_bills": <Map<String, dynamic>>[
        {
          "id": "BILL-011",
          "project_id": "PRJ-001",
          "product": "กระเป๋าผ้าคอตตอน 12 ออนซ์",
          "type": "Deposit (30%)",
          "amount_thb": 125000.0,
          "due_month": "May 2026",
          "status": "Pending",
          "pi_uploaded": true,
          "invoice_uploaded": false,
        },
      ],
    },
    {
      "id": "SUP-002",
      "name": "Shenzhen Electronics Hub",
      "contact_person": "Ms. Lin",
      "phone": "+86 139 9876 5432",
      "category": "Electronics & Gadgets",
      "rating": 4.5,
      "pending_quotes": <Map<String, dynamic>>[
        {
          "project_id": "PRJ-009",
          "customer": "Central Group",
          "product": "กระบอกน้ำสแตนเลส เลเซอร์โลโก้",
          "qty": 2000,
          "status": "Link Sent",
          "specs": "500ml Stainless Steel 304, Laser Engrave 1 position",
          "variations": "2 Colors (Black, White)",
          "target_date": "10 Sep 2026",
          "packing": "Individual White Box",
        },
      ],
      "pending_samples": <Map<String, dynamic>>[],
      "pending_bills": <Map<String, dynamic>>[],
    },
    {
      "id": "SUP-003",
      "name": "Yiwu Premium Gifts",
      "contact_person": "Mr. Wang",
      "phone": "+86 137 5555 4444",
      "category": "Premium Gifts & Umbrellas",
      "rating": 4.9,
      "pending_quotes": <Map<String, dynamic>>[
        {
          "project_id": "PRJ-009",
          "customer": "Central Group",
          "product": "ร่มกอล์ฟ 30 นิ้ว",
          "qty": 1500,
          "status": "Price Filled", // 🌟 ซัพส่งราคามาแล้ว
          "quoted_price": 3.5, // USD
          "currency": "USD",
          "lead_time": "30 วัน",
          "moq": 1000,
          "remark":
              "Price includes 1 color screen print. +0.15 for extra color.",
          "specs": "30 Inch Golf Umbrella, Fiberglass frame, Pongee fabric",
          "variations": "1 Color (Navy Blue)",
          "target_date": "25 Aug 2026",
          "packing": "Standard Packing",
        },
      ],
      "pending_samples": <Map<String, dynamic>>[
        {
          "project_id": "PRJ-009",
          "customer": "Central Group",
          "product": "ร่มกอล์ฟ 30 นิ้ว",
          "status": "Waiting Supplier", // 🌟 รอซัพตอบกลับเรื่องส่งตัวอย่าง
          "specs":
              "ขอตัวอย่างร่มกอล์ฟ 30 นิ้ว โครงไฟเบอร์กลาส (ร่มเปล่า ไม่ต้องสกรีนโลโก้) จำนวน 1 คัน",
          "cost": "TBD",
          "tracking_no": "-",
          "expected_date": "-",
        },
      ],
      "pending_bills": <Map<String, dynamic>>[
        {
          "id": "BILL-088",
          "project_id": "PRJ-009",
          "product": "ร่มกอล์ฟ 30 นิ้ว",
          "type": "Deposit (20%)",
          "amount_thb": 36000.0,
          "due_month": "May 2026",
          "status": "Pending",
          "pi_uploaded": true,
          "invoice_uploaded": true,
        },
      ],
    },
  ];

  List<Map<String, dynamic>> _getFilteredSuppliers() {
    if (_searchText.isEmpty) return _suppliers;
    return _suppliers
        .where(
          (s) => s['name'].toString().toLowerCase().contains(
            _searchText.toLowerCase(),
          ),
        )
        .toList();
  }

  void _showSuccessBanner(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4A9062), // Green Banner
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuppliers = _getFilteredSuppliers();
    Map<String, dynamic> selectedSupplier;

    if (filteredSuppliers.isEmpty) {
      selectedSupplier = _suppliers[0];
    } else {
      selectedSupplier = filteredSuppliers.firstWhere(
        (s) => s['id'] == _selectedSupplierId,
        orElse: () => filteredSuppliers[0],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: รายชื่อ Suppliers
          // ==========================================
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    top: 32,
                    right: 16,
                    bottom: 16,
                  ),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Color(0xFF86868B),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Back",
                            style: TextStyle(
                              color: Color(0xFF86868B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Suppliers",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF5B7BD5),
                        ),
                        tooltip: "Add New Supplier",
                        onPressed: () => _showAddSupplierDialog(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchText = val),
                    decoration: InputDecoration(
                      hintText: "ค้นหาชื่อโรงงาน...",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF86868B),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      final sup = filteredSuppliers[index];
                      final isSelected = _selectedSupplierId == sup['id'];

                      // 🌟 แจ้งเตือนรวมทั้งหมด
                      int pendingQuotesCount =
                          (sup['pending_quotes'] as List).length;
                      int pendingSamplesCount = (sup['pending_samples'] as List)
                          .where((s) => s['status'] != 'Approved')
                          .length;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSupplierId = sup['id'];
                            _selectedBillIds.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFAEC4FA).withOpacity(0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFAEC4FA)
                                  : Colors.grey.withOpacity(0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sup['category'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFF5B7BD5)
                                          : const Color(0xFF86868B),
                                    ),
                                  ),
                                  if (pendingQuotesCount > 0 ||
                                      pendingSamplesCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDE2E4),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "$pendingQuotesCount Quotes, $pendingSamplesCount Samples",
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFFD97781),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                sup['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1D1D1F),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Color(0xFFF2C94C),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${sup['rating']} Rating",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF86868B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 2. RIGHT PANEL: รายละเอียด / Quotes / Samples / Payments
          // ==========================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAE4F2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    selectedSupplier['category'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF86868B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Tooltip(
                                  message:
                                      "Rating based on delivery time, product quality, and communication.",
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 18,
                                        color: Color(0xFFF2C94C),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${selectedSupplier['rating']}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D1D1F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedSupplier['name'],
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D1D1F),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: Color(0xFF86868B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedSupplier['contact_person'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 18,
                                  color: Color(0xFF86868B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedSupplier['phone'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildButton(
                        "Edit Supplier",
                        Colors.white,
                        const Color(0xFF1D1D1F),
                        isOutlined: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // --- 🌟 ระบบ Tabs สลับ 3 เมนู (Quotes / Samples / Payments) ---
                  Container(
                    width: 550,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTab(
                          "Quotes",
                          "ขอราคา (Quotes)",
                          Icons.request_quote_outlined,
                        ),
                        _buildTab(
                          "Samples",
                          "ขอตัวอย่าง (Samples)",
                          Icons.science_outlined,
                        ),
                        _buildTab(
                          "Payments",
                          "รอบบิลจ่ายเงิน (AP)",
                          Icons.payments_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // แสดงเนื้อหาตาม Tab ที่เลือก
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _activeTab == "Quotes"
                        ? _buildQuotesSection(selectedSupplier)
                        : _activeTab == "Samples"
                        ? _buildSamplesSection(selectedSupplier)
                        : _buildPaymentsSection(selectedSupplier),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TAB 1: QUOTES SECTION (ขอราคา)
  // =========================================================
  Widget _buildQuotesSection(Map<String, dynamic> selectedSupplier) {
    return Column(
      key: const ValueKey("Quotes"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Price Quote Requests",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "รายการสินค้าที่ต้องการให้โรงงานนี้ประเมินราคา",
                  style: TextStyle(fontSize: 14, color: Color(0xFF86868B)),
                ),
              ],
            ),
            _buildButton(
              "+ Request Quote",
              const Color(0xFF1D1D1F),
              Colors.white,
              onTap: () =>
                  _showRequestDialog(context, selectedSupplier, "Quote"),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if ((selectedSupplier['pending_quotes'] as List).isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: Text(
                "ยังไม่มีรายการขอราคาจากโรงงานนี้",
                style: TextStyle(color: Color(0xFF86868B)),
              ),
            ),
          )
        else
          ...(selectedSupplier['pending_quotes'] as List).map((req) {
            bool isFilled = req['status'] == "Price Filled";
            bool isApproved = req['status'] == "Approved";
            bool isSent = req['status'] == "Link Sent";

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              req['project_id'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B7BD5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "• ${req['customer']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF86868B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req['product'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Quantity: ${req['qty']} pcs (At least 2 steps required)",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF86868B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🌟 Standard Requirement Info Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E2E2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Standard Requirements:",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Specs: ${req['specs'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                "Variations: ${req['variations'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                "Target Date: ${req['target_date'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                "Packing: ${req['packing'] ?? 'Standard Packing'}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "* FOC is not included in the quotation",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFD97781),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Status",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? const Color(0xFFB7E4C7).withOpacity(0.3)
                                : (isFilled
                                      ? const Color(0xFFFDE2E4).withOpacity(0.5)
                                      : (isSent
                                            ? const Color(0xFFEAE4F2)
                                            : const Color(0xFFF4F5F7))),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req['status'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isApproved
                                  ? const Color(0xFF4A9062)
                                  : (isFilled
                                        ? const Color(0xFFD97781)
                                        : const Color(0xFF86868B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Unit Cost (ทุน)",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (isFilled || isApproved)
                              ? "${req['currency'] ?? 'USD'} ${req['quoted_price'].toStringAsFixed(2)}"
                              : "-",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (isFilled || isApproved)
                                ? const Color(0xFF1D1D1F)
                                : const Color(0xFFB4B4B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isApproved)
                            _buildButton(
                              "✓ Approved (Ready for PI)",
                              const Color(0xFFF4F5F7),
                              const Color(0xFF4A9062),
                              onTap: () {},
                            )
                          else if (isFilled)
                            _buildButton(
                              "Review & Resubmit",
                              const Color(0xFF1D1D1F),
                              Colors.white,
                              icon: Icons.edit_document,
                              onTap: () => _showReviewQuoteDialog(context, req),
                            )
                          else ...[
                            _buildButton(
                              "Supplier Session Link",
                              isSent ? Colors.white : const Color(0xFFAEC4FA),
                              isSent
                                  ? const Color(0xFF1D1D1F)
                                  : const Color(0xFF1D1D1F),
                              isOutlined: isSent,
                              icon: Icons.link_rounded,
                              onTap: () => _showGenerateLinkDialog(
                                context,
                                selectedSupplier['id'],
                                req,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildButton(
                              "Manual Input",
                              Colors.white,
                              const Color(0xFF86868B),
                              isOutlined: true,
                              icon: Icons.keyboard_alt_outlined,
                              onTap: () => _showManualInputDialog(context, req),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // =========================================================
  // TAB 2: SAMPLES SECTION (ขอตัวอย่าง)
  // =========================================================
  Widget _buildSamplesSection(Map<String, dynamic> selectedSupplier) {
    return Column(
      key: const ValueKey("Samples"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Sample Requests",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "รายการตัวอย่างสินค้าที่ร้องขอไปทางโรงงาน",
                  style: TextStyle(fontSize: 14, color: Color(0xFF86868B)),
                ),
              ],
            ),
            _buildButton(
              "+ Request Sample",
              const Color(0xFF1D1D1F),
              Colors.white,
              onTap: () =>
                  _showRequestDialog(context, selectedSupplier, "Sample"),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if ((selectedSupplier['pending_samples'] as List).isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: Text(
                "ยังไม่มีรายการขอตัวอย่างจากโรงงานนี้",
                style: TextStyle(color: Color(0xFF86868B)),
              ),
            ),
          )
        else
          ...(selectedSupplier['pending_samples'] as List).map((req) {
            bool isSent = req['status'] == "Sample Sent";

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              req['project_id'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(
                                  0xFFEC4899,
                                ), // ใช้สีชมพูแยกจาก Quote
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "• ${req['customer']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF86868B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req['product'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF2F8), // Pink background
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFBCFE8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Sample Details:",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF831843),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Specs: ${req['specs'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9D174D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Sample Cost: ${req['cost'] ?? 'TBD'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9D174D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Status",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSent
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF4F5F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req['status'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSent
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF86868B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tracking Info",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "No: ${req['tracking_no']}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSent
                                ? const Color(0xFF1D1D1F)
                                : const Color(0xFFB4B4B8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ETA: ${req['expected_date']}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isSent)
                            _buildButton(
                              "✓ Sample Received",
                              const Color(0xFFF4F5F7),
                              const Color(0xFF4A9062),
                              onTap: () {
                                setState(() {
                                  req['status'] = "Approved";
                                });
                                _showSuccessBanner(
                                  "Sample marked as received.",
                                );
                              },
                            )
                          else
                            _buildButton(
                              "Update Tracking",
                              Colors.white,
                              const Color(0xFF1D1D1F),
                              isOutlined: true,
                              icon: Icons.local_shipping_outlined,
                              onTap: () {
                                // TODO: Modal update tracking
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // =========================================================
  // TAB 3: PAYMENTS SECTION (บัญชีเจ้าหนี้ สิ้นเดือน)
  // =========================================================
  Widget _buildPaymentsSection(Map<String, dynamic> selectedSupplier) {
    List pendingBills = (selectedSupplier['pending_bills'] as List)
        .where((b) => b['status'] == 'Pending')
        .toList();

    double totalSelectedAmount = 0;
    for (var bill in pendingBills) {
      if (_selectedBillIds.contains(bill['id'])) {
        totalSelectedAmount += bill['amount_thb'];
      }
    }

    return Column(
      key: const ValueKey("Payments"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Monthly Accounts Payable (ตัดจ่ายซัพพลายเออร์)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "รวบรวมบิล Deposit และ Balance เพื่อทำเรื่องจ่ายออกทีเดียวช่วงสิ้นเดือน",
              style: TextStyle(fontSize: 14, color: Color(0xFF86868B)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (pendingBills.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Color(0xFF4A9062),
                ),
                SizedBox(height: 16),
                Text(
                  "ยอดเยี่ยม! ไม่มีรอบบิลค้างชำระสำหรับโรงงานนี้",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A9062),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ...pendingBills.map((bill) {
            bool isSelected = _selectedBillIds.contains(bill['id']);
            bool isDeposit = bill['type'].toString().contains("Deposit");
            bool piUploaded = bill['pi_uploaded'] ?? false;
            bool invUploaded = bill['invoice_uploaded'] ?? false;

            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedBillIds.remove(bill['id']);
                  } else {
                    _selectedBillIds.add(bill['id']);
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFAEC4FA).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFAEC4FA)
                        : Colors.grey.withOpacity(0.15),
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    // Checkbox
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF5B7BD5)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF5B7BD5)
                              : const Color(0xFFE2E2E2),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),

                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                bill['project_id'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF86868B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDeposit
                                      ? const Color(0xFFFDE2E4)
                                      : const Color(0xFFEAE4F2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  bill['type'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDeposit
                                        ? const Color(0xFFD97781)
                                        : const Color(0xFF6B4CA4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {},
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: Color(0xFF86868B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bill['product'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🌟 Documents Warning
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Documents",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF86868B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                piUploaded
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                                size: 14,
                                color: piUploaded
                                    ? const Color(0xFF4A9062)
                                    : const Color(0xFFD97781),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "PI",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: piUploaded
                                      ? const Color(0xFF4A9062)
                                      : const Color(0xFFD97781),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                invUploaded
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                                size: 14,
                                color: invUploaded
                                    ? const Color(0xFF4A9062)
                                    : const Color(0xFFD97781),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Invoice",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: invUploaded
                                      ? const Color(0xFF4A9062)
                                      : const Color(0xFFD97781),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Due Month",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF86868B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bill['due_month'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Amount (THB)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF86868B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "฿ ${bill['amount_thb'].toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: _selectedBillIds.isEmpty
                  ? const Color(0xFFF4F5F7)
                  : const Color(0xFF1D1D1F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selected Bills: ${_selectedBillIds.length}",
                      style: TextStyle(
                        color: _selectedBillIds.isEmpty
                            ? const Color(0xFF86868B)
                            : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "฿ ${totalSelectedAmount.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: _selectedBillIds.isEmpty
                            ? const Color(0xFFB4B4B8)
                            : Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildButton(
                      "เลื่อนบิลไปเดือนหน้า",
                      _selectedBillIds.isEmpty
                          ? Colors.white
                          : const Color(0xFF333333),
                      _selectedBillIds.isEmpty
                          ? const Color(0xFFB4B4B8)
                          : Colors.white,
                      isOutlined: _selectedBillIds.isEmpty,
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    _buildButton(
                      "Pay Selected Bills",
                      _selectedBillIds.isEmpty
                          ? const Color(0xFFE2E2E2)
                          : const Color(0xFFAEC4FA),
                      _selectedBillIds.isEmpty
                          ? const Color(0xFF86868B)
                          : const Color(0xFF1D1D1F),
                      onTap: () {
                        if (_selectedBillIds.isEmpty) return;
                        setState(() {
                          for (var bill in pendingBills) {
                            if (_selectedBillIds.contains(bill['id'])) {
                              bill['status'] = "Paid";
                            }
                          }
                          _selectedBillIds.clear();
                        });
                        _showSuccessBanner(
                          "บันทึกการโอนเงินออกให้ซัพพลายเออร์สำเร็จ",
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================
  // HELPER WIDGETS & DIALOGS
  // =========================================================

  Widget _buildTab(String id, String title, IconData icon) {
    bool isActive = _activeTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? (id == "Samples"
                          ? const Color(0xFFEC4899)
                          : const Color(0xFF5B7BD5))
                    : const Color(0xFF86868B),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF1D1D1F)
                      : const Color(0xFF86868B),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    String title,
    Color bgColor,
    Color textColor, {
    IconData? icon,
    bool isOutlined = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isOutlined
              ? Border.all(color: const Color(0xFFE2E2E2))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  void _showAddSupplierDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Add New Supplier",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Company / Factory Name",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Contact Person",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "Phone / WeChat ID",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF86868B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D1F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Save Supplier",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 ฟอร์มขอราคา/ขอตัวอย่าง รวมในตัวเดียว
  // 🌟 ฟอร์มขอราคา/ขอตัวอย่าง รวมในตัวเดียว
  void _showRequestDialog(
    BuildContext context,
    Map<String, dynamic> supplier,
    String type, // "Quote" หรือ "Sample"
  ) {
    String? selectedProjectId;
    List<Map<String, dynamic>> productsInProject = [];
    List<bool> selectedProducts = [];
    // 🌟 สร้าง List ของ TextEditingController เพื่อให้ปรับแก้ Qty ได้
    List<TextEditingController> qtyControllers = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              type == "Quote" ? "Request Price Quote" : "Request Sample",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "1. เลือกโปรเจกต์ของลูกค้า",
                    style: TextStyle(
                      color: type == "Quote"
                          ? const Color(0xFF86868B)
                          : const Color(0xFFEC4899),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    hint: const Text("Select Project"),
                    initialValue: selectedProjectId,
                    items: _allProjects
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p['id'],
                            child: Text("${p['id']} - ${p['customer']}"),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedProjectId = val;
                        var prj = _allProjects.firstWhere(
                          (p) => p['id'] == val,
                        );

                        // เคลียร์และสร้าง Controller ใหม่ทุกครั้งที่เปลี่ยนโปรเจกต์
                        productsInProject = List<Map<String, dynamic>>.from(
                          prj['products'],
                        );
                        selectedProducts = List<bool>.filled(
                          productsInProject.length,
                          false,
                        );
                        qtyControllers = productsInProject
                            .map(
                              (p) => TextEditingController(
                                text: p['qty'].toString(),
                              ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (selectedProjectId != null) ...[
                    Text(
                      type == "Quote"
                          ? "2. ติ๊กเลือกสินค้าและระบุจำนวนที่ต้องการให้ซัพประเมินราคา:"
                          : "2. ติ๊กเลือกเฉพาะสินค้าที่ต้องการให้โรงงานนี้ทำ:",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF86868B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E2E2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: List.generate(productsInProject.length, (
                          index,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: CheckboxListTile(
                              title: Text(
                                productsInProject[index]['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              // 🌟 ถ้าเป็น Quote โชว์ช่องให้ปรับแก้ Qty ได้ ถ้าเป็น Sample โชว์ Text ธรรมดา
                              subtitle: type == "Quote"
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          const Text(
                                            "Req. Qty: ",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          SizedBox(
                                            width: 100,
                                            height: 32,
                                            child: TextFormField(
                                              controller: qtyControllers[index],
                                              keyboardType:
                                                  TextInputType.number,
                                              enabled:
                                                  selectedProducts[index], // กรอกได้ต่อเมื่อติ๊กเลือก
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                filled: true,
                                                fillColor:
                                                    selectedProducts[index]
                                                    ? Colors.white
                                                    : const Color(0xFFF4F5F7),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      "Qty: ${productsInProject[index]['qty']}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                              value: selectedProducts[index],
                              activeColor: type == "Quote"
                                  ? const Color(0xFF5B7BD5)
                                  : const Color(0xFFEC4899),
                              onChanged: (bool? val) {
                                setDialogState(
                                  () => selectedProducts[index] = val ?? false,
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Color(0xFF86868B)),
                ),
              ),
              ElevatedButton(
                onPressed:
                    (selectedProjectId == null ||
                        !selectedProducts.contains(true))
                    ? null
                    : () {
                        setState(() {
                          var prj = _allProjects.firstWhere(
                            (p) => p['id'] == selectedProjectId,
                          );
                          for (int i = 0; i < productsInProject.length; i++) {
                            if (selectedProducts[i]) {
                              // 🌟 ใช้ Qty จากช่องที่กรอก (หรือถ้าไม่ได้กรอกใช้ของเดิม)
                              int finalQty =
                                  int.tryParse(qtyControllers[i].text) ??
                                  productsInProject[i]['qty'];

                              if (type == "Quote") {
                                (supplier['pending_quotes'] as List).add(
                                  <String, dynamic>{
                                    "project_id": prj['id'],
                                    "customer": prj['customer'],
                                    "product": productsInProject[i]['name'],
                                    "qty": finalQty, // 🌟 จำนวนใหม่ที่อัปเดต
                                    "status": "Waiting Link",
                                    "specs": "Standard specifications",
                                    "target_date": "TBD",
                                    "packing": "Standard Packing",
                                  },
                                );
                              } else {
                                // Sample
                                (supplier['pending_samples'] as List)
                                    .add(<String, dynamic>{
                                      "project_id": prj['id'],
                                      "customer": prj['customer'],
                                      "product": productsInProject[i]['name'],
                                      "status": "Waiting Supplier",
                                      "specs": "ขอตัวอย่างตามสเปก",
                                      "cost": "TBD",
                                      "tracking_no": "-",
                                      "expected_date": "-",
                                    });
                              }
                            }
                          }
                        });
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D1D1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Add Request",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🌟 Single Session Link
  void _showGenerateLinkDialog(
    BuildContext context,
    String supplierId,
    Map<String, dynamic> req,
  ) {
    String dummyUrl =
        "https://supplier.ppngreat.com/session/${supplierId.toLowerCase()}";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAEC4FA).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      color: Color(0xFF5B7BD5),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Supplier Portal Link",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "คัดลอกลิงก์เซสชันเดียวนี้ส่งให้โรงงาน ระบบจะรวบรวมรายการขอราคาทั้งหมดของโรงงานนี้ไว้ในหน้าเดียว:",
                style: TextStyle(color: Color(0xFF86868B), fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E2E2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dummyUrl,
                        style: const TextStyle(
                          color: Color(0xFF5B7BD5),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: dummyUrl));
                        Navigator.pop(context);
                        _showSuccessBanner(
                          "ลิงก์เซสชันถูกคัดลอก และสถานะอัปเดตเป็นส่งลิงก์แล้ว",
                        );
                        setState(() {
                          req['status'] = "Link Sent";
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D1D1F),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Copy",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F5F7),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 Manual Input Quote Dialog
  void _showManualInputDialog(BuildContext context, Map<String, dynamic> req) {
    String currency = "USD";
    String price = "";
    String leadTime = "";
    String moq = "";
    String remark = "";
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Manual Quote Input",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "กรอกใบเสนอราคาด้วยตนเอง (กรณีโรงงานไม่สะดวกใช้ลิงก์)",
                    style: TextStyle(color: Color(0xFF86868B)),
                  ),
                  const Divider(height: 48),

                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Currency",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: currency,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: ["USD", "THB", "CNY"]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setDialogState(() => currency = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Unit Price",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              onChanged: (val) => price = val,
                              decoration: InputDecoration(
                                hintText: "0.00",
                                errorText: errorText, // Inline validation error
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Lead Time",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              onChanged: (val) => leadTime = val,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "MOQ",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              onChanged: (val) => moq = val,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Remarks",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        onChanged: (val) => remark = val,
                        maxLines: 2,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF4F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (price.isEmpty) {
                            setDialogState(
                              () => errorText = "Price is required",
                            );
                            return;
                          }
                          // ยืนยันก่อนเซฟ
                          showDialog(
                            context: context,
                            builder: (confirmCtx) => AlertDialog(
                              title: const Text("Confirm Submission?"),
                              content: const Text(
                                "Once confirmed, the adjustment can't be made. You can only request a re-quote.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(confirmCtx),
                                  child: const Text("Back"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1D1D1F),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      req['status'] = "Price Filled";
                                      req['currency'] = currency;
                                      req['quoted_price'] =
                                          double.tryParse(price) ?? 0.0;
                                      req['lead_time'] = leadTime;
                                      req['moq'] = int.tryParse(moq) ?? 0;
                                      req['remark'] = remark;
                                    });
                                    Navigator.pop(confirmCtx); // Close confirm
                                    Navigator.pop(
                                      context,
                                    ); // Close manual input
                                    _showSuccessBanner(
                                      "Manual quote submitted successfully.",
                                    );
                                  },
                                  child: const Text(
                                    "Confirm & Submit",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D1D1F),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          "Save Quote",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showReviewQuoteDialog(BuildContext context, Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Review Supplier Quote",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "ตรวจสอบราคาและเงื่อนไขที่โรงงานเสนอมา",
                style: TextStyle(color: Color(0xFF86868B), fontSize: 14),
              ),
              const Divider(height: 48, color: Color(0xFFF4F5F7)),
              Row(
                children: [
                  const Text(
                    "Product: ",
                    style: TextStyle(color: Color(0xFF86868B), fontSize: 13),
                  ),
                  Text(
                    req['product'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    "Quantity: ",
                    style: TextStyle(color: Color(0xFF86868B), fontSize: 13),
                  ),
                  Text(
                    "${req['qty']} pcs",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E2E2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Unit Cost (ราคาต้นทุน)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "${req['currency'] ?? 'USD'} ${req['quoted_price'].toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFE2E2E2)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Lead Time (ระยะเวลาผลิต)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text("${req['lead_time']}"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "MOQ (ขั้นต่ำการผลิต)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text("${req['moq']} pcs"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Remarks (หมายเหตุจากโรงงาน):",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${req['remark']}",
                          style: const TextStyle(
                            color: Color(0xFFD97781),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 🌟 Revise & Resubmit logic
                        Navigator.pop(context);
                        setState(() => req['status'] = "Need Revision");
                        _showSuccessBanner(
                          "Requested revision. Supplier can now update the quote.",
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFD97781)),
                        ),
                      ),
                      child: const Text(
                        "Need Revision",
                        style: TextStyle(
                          color: Color(0xFFD97781),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          req['status'] = "Approved";
                        });
                        _showSuccessBanner("Quote Approved!");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D1D1F),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Approve & Accept",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
