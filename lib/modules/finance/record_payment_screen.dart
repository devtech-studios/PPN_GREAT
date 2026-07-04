import 'package:flutter/material.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({super.key});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  String _searchText = "";
  String _selectedProjectId = "PRJ-009";

  // ใช้ TextEditingController เพื่อไม่ให้ Cursor หลุดโฟกัสเวลาพิมพ์
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: "26 May 2026",
  );

  String _paymentMethod = "Bank Transfer (โอนเงิน)";

  // Mock Data
  final List<Map<String, dynamic>> _billingProjects = [
    {
      "id": "PRJ-009",
      "customer": "Central Group",
      "invoice_no": "CI-2605-012",
      "grand_total": 450000.0,
      "paid_amount": 100000.0,
      "status": "Partial",
      "products": [
        {"name": "ร่มกอล์ฟ 30 นิ้ว", "qty": 1500, "price": 150.0},
        {"name": "กระบอกน้ำสแตนเลส", "qty": 2000, "price": 85.0},
      ],
      "history": <Map<String, dynamic>>[
        {
          "round": "มัดจำ (Deposit)",
          "amount": 100000.0,
          "date": "10 May 2026",
          "method": "Bank Transfer",
        },
      ],
    },
    {
      "id": "PRJ-001",
      "customer": "Lion (Thailand)",
      "invoice_no": "CI-2605-015",
      "grand_total": 1819000.0,
      "paid_amount": 0.0,
      "status": "Unpaid",
      "products": [
        {"name": "กระเป๋าผ้าคอตตอน 12 ออนซ์", "qty": 20000, "price": 85.0},
      ],
      "history": <Map<String, dynamic>>[],
    },
    {
      "id": "PRJ-010",
      "customer": "AIS",
      "invoice_no": "CI-2604-099",
      "grand_total": 1284000.0,
      "paid_amount": 1284000.0,
      "status": "Paid",
      "products": [
        {"name": "เสื้อโปโลพนักงาน สีเขียว", "qty": 10000, "price": 120.0},
      ],
      "history": <Map<String, dynamic>>[
        {
          "round": "มัดจำ (Deposit)",
          "amount": 600000.0,
          "date": "20 Apr 2026",
          "method": "Bank Transfer",
        },
        {
          "round": "งวดสุดท้าย (Final)",
          "amount": 684000.0,
          "date": "25 May 2026",
          "method": "Cheque",
        },
      ],
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredProjects() {
    if (_searchText.isEmpty) return _billingProjects;
    return _billingProjects
        .where(
          (p) =>
              p['customer'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ||
              p['id'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _getFilteredProjects();
    Map<String, dynamic> selectedProject = filteredProjects.firstWhere(
      (p) => p['id'] == _selectedProjectId,
      orElse: () => _billingProjects[0],
    );

    double balanceDue =
        selectedProject['grand_total'] - selectedProject['paid_amount'];
    double progress =
        selectedProject['paid_amount'] / selectedProject['grand_total'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: รายการรอรับชำระ
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    "Receive Payments",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
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
                      hintText: "ค้นหาลูกค้า, รหัสโปรเจกต์...",
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
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final p = filteredProjects[index];
                      final isSelected = _selectedProjectId == p['id'];

                      Color statusColor = const Color(0xFFD97781);
                      Color statusBg = const Color(0xFFFDE2E4).withOpacity(0.5);
                      if (p['status'] == 'Partial') {
                        statusColor = const Color(0xFFD08A2A);
                        statusBg = const Color(0xFFFDF3E1);
                      } else if (p['status'] == 'Paid') {
                        statusColor = const Color(0xFF4A9062);
                        statusBg = const Color(0xFFB7E4C7).withOpacity(0.3);
                      }

                      return InkWell(
                        onTap: () => setState(() {
                          _selectedProjectId = p['id'];
                          _amountController
                              .clear(); // รีเซ็ตฟอร์มเวลาเปลี่ยนโปรเจกต์
                        }),
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
                                    p['id'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFF5B7BD5)
                                          : const Color(0xFF86868B),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p['status'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p['customer'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1D1D1F),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "INV: ${p['invoice_no']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF86868B),
                                ),
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
          // 2. RIGHT PANEL: รายละเอียดและการรับเงิน
          // ==========================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Record Payment",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D1D1F),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "รับชำระเงิน: ${selectedProject['id']} - ${selectedProject['customer']}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF5B7BD5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if ((selectedProject['history'] as List).isNotEmpty)
                        _buildButton(
                          "Preview Receipt (A4)",
                          Colors.white,
                          const Color(0xFF5B7BD5),
                          icon: Icons.receipt_long_outlined,
                          isOutlined: true,
                          onTap: () {
                            _showReceiptPreviewDialog(context, selectedProject);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- ส่วน Summary Cards ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryBox(
                          "ยอดเรียกเก็บรวม (Grand Total)",
                          "฿ ${selectedProject['grand_total'].toStringAsFixed(2)}",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryBox(
                          "รับชำระแล้ว (Paid Amount)",
                          "฿ ${selectedProject['paid_amount'].toStringAsFixed(2)}",
                          color: const Color(0xFF4A9062),
                          bgColor: const Color(0xFFB7E4C7).withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // กล่อง Balance Due ทำ OnTap เพื่อดึงข้อมูลเข้าฟอร์ม
                      Expanded(
                        child: _buildSummaryBox(
                          "ยอดคงค้าง (คลิกเพื่อดึงยอด)",
                          "฿ ${balanceDue.toStringAsFixed(2)}",
                          color: const Color(0xFFD97781),
                          bgColor: const Color(0xFFFDE2E4).withOpacity(0.5),
                          onTap: () {
                            // พอกดปุ๊บ เติมตัวเลขใส่ Controller ทันที
                            setState(() {
                              _amountController.text = balanceDue
                                  .toStringAsFixed(2);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress Bar
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A9062),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "รับชำระแล้ว ${(progress * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF86868B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // --- ฟอร์มบันทึกรับเงิน (ซ่อนถ้าจ่ายครบแล้ว) ---
                  if (balanceDue > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "บันทึกรับชำระเงินงวดใหม่ (Record New Payment)",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Divider(height: 48, color: Color(0xFFF4F5F7)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // จำนวนเงิน (ใช้ Controller)
                              Expanded(
                                flex: 3,
                                child: _buildEditableField(
                                  "ยอดเงินที่ได้รับ (THB) *",
                                  "0.00",
                                  controller: _amountController,
                                  isNumber: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // ช่องทางการรับชำระ
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "ช่องทางการชำระเงิน *",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _paymentMethod,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFF4F5F7),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      items:
                                          [
                                                "Bank Transfer (โอนเงิน)",
                                                "Cheque (เช็ค)",
                                                "Cash (เงินสด)",
                                              ]
                                              .map(
                                                (m) => DropdownMenuItem<String>(
                                                  value: m,
                                                  child: Text(m),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (val) =>
                                          setState(() => _paymentMethod = val!),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // วันที่ (ใช้ Controller)
                              Expanded(
                                flex: 2,
                                child: _buildEditableField(
                                  "วันที่โอน/รับเช็ค *",
                                  "",
                                  controller: _dateController,
                                  icon: Icons.calendar_today,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "อัปโหลดสลิปหรือหลักฐานการจ่ายเงิน (Slip/Proof of Payment)",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F5F7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFAEC4FA).withOpacity(0.5),
                                width: 1.5,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 28,
                                  color: Color(0xFF5B7BD5),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Click or Drag & Drop slip image here",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5B7BD5),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: _buildButton(
                              "Confirm & Record Payment",
                              const Color(0xFF1D1D1F),
                              Colors.white,
                              onTap: () {
                                double payAmount =
                                    double.tryParse(_amountController.text) ??
                                    0.0;
                                if (payAmount <= 0 || payAmount > balanceDue) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "ยอดเงินไม่ถูกต้อง หรือเกินยอดคงค้าง",
                                      ),
                                      backgroundColor: Color(0xFFD97781),
                                    ),
                                  );
                                  return;
                                }

                                setState(() {
                                  // บวกยอดที่จ่าย
                                  selectedProject['paid_amount'] += payAmount;

                                  // อัปเดตสถานะ
                                  if (selectedProject['paid_amount'] >=
                                      selectedProject['grand_total']) {
                                    selectedProject['status'] = "Paid";
                                  } else {
                                    selectedProject['status'] = "Partial";
                                  }

                                  // เก็บลงประวัติ
                                  (selectedProject['history'] as List).add(<
                                    String,
                                    dynamic
                                  >{
                                    "round":
                                        "งวดที่ ${(selectedProject['history'] as List).length + 1}",
                                    "amount": payAmount,
                                    "date": _dateController.text,
                                    "method": _paymentMethod,
                                  });

                                  _amountController.clear(); // ล้างช่องตัวเลข
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "✓ บันทึกรับชำระเงินเรียบร้อยแล้ว",
                                    ),
                                    backgroundColor: Color(0xFF4A9062),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB7E4C7).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.verified,
                            color: Color(0xFF4A9062),
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "โปรเจกต์นี้รับชำระเงินครบถ้วนแล้ว (Fully Paid)",
                            style: TextStyle(
                              color: Color(0xFF4A9062),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // --- ตารางประวัติรับชำระเงิน ---
                  const Text(
                    "Payment History (ประวัติการรับชำระเงิน)",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    ),
                    child: (selectedProject['history'] as List).isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                "ยังไม่มีประวัติการโอนเงิน",
                                style: TextStyle(color: Color(0xFF86868B)),
                              ),
                            ),
                          )
                        : DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF7F9FC),
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "รายการ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "วันที่ชำระ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "ช่องทาง",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "ยอดเงิน",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: (selectedProject['history'] as List).map((
                              hist,
                            ) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      hist['round'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(hist['date'])),
                                  DataCell(Text(hist['method'])),
                                  DataCell(
                                    Text(
                                      "฿ ${hist['amount'].toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A9062),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HELPER WIDGETS
  // =========================================================

  Widget _buildSummaryBox(
    String label,
    String value, {
    Color color = const Color(0xFF1D1D1F),
    Color bgColor = const Color(0xFFF4F5F7),
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          // ถ้ามี onTap ให้โชว์กรอบนิดนึงเวลากดจะได้ดูออกว่าเป็นปุ่ม
          border: onTap != null
              ? Border.all(color: color.withOpacity(0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // เปลี่ยนมารับ TextEditingController
  Widget _buildEditableField(
    String label,
    String hint, {
    TextEditingController? controller,
    bool isNumber = false,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: icon != null
                ? Icon(icon, size: 18, color: const Color(0xFF86868B))
                : null,
            filled: true,
            fillColor: const Color(0xFFF4F5F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isOutlined
              ? Border.all(color: const Color(0xFFAEC4FA))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // RECEIPT / TAX INVOICE PREVIEW (A4)
  // =========================================================

  void _showReceiptPreviewDialog(
    BuildContext context,
    Map<String, dynamic> project,
  ) {
    double subtotal = project['grand_total'] / 1.07;
    double vat = project['grand_total'] - subtotal;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black26,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: 794,
              height: 1123,
              padding: const EdgeInsets.all(72.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "PPN GREAT CO., LTD.",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "123/45 ซอยสุขุมวิท, แขวงคลองเตย, เขตคลองเตย\nกรุงเทพมหานคร 10110\nTax ID: 0105556000123",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF86868B),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "RECEIPT / TAX INVOICE",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.5,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                          const Text(
                            "ใบเสร็จรับเงิน / ใบกำกับภาษี",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF86868B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Doc No: RE-2605-999\nDate: 26 May 2026\nRef INV: ${project['invoice_no']}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1D1D1F),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  const Text(
                    "RECEIVED FROM / ได้รับเงินจาก:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF86868B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    project['customer'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const Text(
                    "Bangkok, Thailand",
                    style: TextStyle(fontSize: 13, color: Color(0xFF86868B)),
                  ),
                  const SizedBox(height: 48),

                  Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF1D1D1F),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 5,
                          child: Text(
                            "DESCRIPTION / รายการชำระเงิน",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "AMOUNT (THB)",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            "ชำระค่าสินค้าตามเอกสารอ้างอิง ${project['invoice_no']}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "฿ ${project['paid_amount'].toStringAsFixed(2)}",
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 48, color: Color(0xFFE2E2E2)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 320,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Subtotal / ยอดก่อนภาษี",
                                  style: TextStyle(
                                    color: Color(0xFF86868B),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "฿ ${subtotal.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "VAT (7%)",
                                  style: TextStyle(
                                    color: Color(0xFF86868B),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "฿ ${vat.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(color: Color(0xFFF4F5F7)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "TOTAL RECEIVED",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                                Text(
                                  "฿ ${project['paid_amount'].toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF5B7BD5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Close Preview",
                            style: TextStyle(
                              color: Color(0xFF86868B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 180,
                            height: 1,
                            color: const Color(0xFF86868B),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Authorized Signature / ผู้รับเงิน",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF86868B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
