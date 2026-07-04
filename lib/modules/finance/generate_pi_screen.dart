import 'dart:ui';
import 'package:flutter/material.dart';

class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class GeneratePIScreen extends StatefulWidget {
  const GeneratePIScreen({super.key});

  @override
  State<GeneratePIScreen> createState() => _GeneratePIScreenState();
}

class _GeneratePIScreenState extends State<GeneratePIScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchText = "";
  String _selectedProjectId = "PPN-001";
  // ignore: unused_field
  dynamic _selectedSupplierQuote;

  // 🌟 Toggle ระดับ Macro: Inbound (ฝั่งลูกค้า) vs Outbound (ฝั่งซัพพลายเออร์)
  bool _isInboundMode = true;

  // สถานะฟอร์มย่อยในโหมด Inbound
  String _activeDocTab = "QU"; // QU, PI, DP, CI

  // Filter Insights
  String _selectedInsightFilter = "All Active";

  // ==========================================
  // Mock Data: เพิ่ม supplier_quotes สำหรับดึงราคาต้นทุน
  // ==========================================
  final List<Map<String, dynamic>> _projects = [
    {
      "id": "PPN-001",
      "customer": "Lion (Thailand)",
      "insight_status": "Need Deposit",
      "supplier_status": "Price Filled",
      "products": [
        {"name": "กระเป๋าผ้าคอตตอน 12 ออนซ์", "qty": 20000, "price": 85.0},
      ],
      "supplier_quotes": [
        {
          "supplier_name": "Guangzhou Bags Factory",
          "rates": {"กระเป๋าผ้าคอตตอน 12 ออนซ์": 55.0},
        },
        {
          "supplier_name": "Yiwu Textile Co.",
          "rates": {"กระเป๋าผ้าคอตตอน 12 ออนซ์": 52.5},
        },
      ],
      "docs": {"QU": true, "PI": true, "DP": false, "CI": false},
      "deposit_amount": 0.0,
      "grand_total": 1819000.0,
      "credit_term": "30 Days",
      "history": [
        {
          "doc_no": "QU-2605-001",
          "type": "Quotation",
          "ver": "V1",
          "date": "15 May 2026",
          "amount": "1,800,000",
          "details": "กระเป๋า 20,000 ใบ @ 90 บาท",
          "products": [
            {"name": "กระเป๋าผ้าคอตตอน 12 ออนซ์", "qty": 20000, "price": 90.0},
          ],
        },
      ],
      "outbound_expenses": [
        {
          "title": "มัดจำค่าสินค้า 30% (โรงงาน Yiwu)",
          "category": "Cost of Goods (COGS)",
          "amount": 250000.0,
          "status": "Paid",
          "date": "20 May 2026",
        },
        {
          "title": "ค่าตรวจสินค้า (QC) ก่อนส่ง",
          "category": "Operation",
          "amount": 5000.0,
          "status": "Pending",
          "date": "05 Jun 2026",
        },
      ],
    },
    {
      "id": "PPN-009",
      "customer": "Central Group",
      "insight_status": "Waiting Credit Term",
      "supplier_status": "Price Filled",
      "products": [
        {"name": "ร่มกอล์ฟ 30 นิ้ว", "qty": 1500, "price": 150.0},
        {"name": "กระบอกน้ำสแตนเลส เลเซอร์โลโก้", "qty": 2000, "price": 85.0},
        {"name": "ถุงผ้าสปันบอนด์", "qty": 3000, "price": 25.0},
      ],
      "supplier_quotes": [
        {
          "supplier_name": "Yiwu Premium Gifts",
          "rates": {
            "ร่มกอล์ฟ 30 นิ้ว": 110.0,
            "กระบอกน้ำสแตนเลส เลเซอร์โลโก้": 60.0,
            "ถุงผ้าสปันบอนด์": 15.0,
          },
        },
      ],
      "docs": {"QU": true, "PI": true, "DP": true, "CI": true},
      "deposit_amount": 100000.0,
      "grand_total": 502900.0,
      "credit_term": "45 Days (Due: 15 Jul 2026)",
      "history": [
        {
          "doc_no": "CI-2605-004",
          "type": "Commercial Invoice",
          "ver": "V1",
          "date": "10 May 2026",
          "amount": "402,900",
          "details": "เรียกเก็บส่วนที่เหลือ",
          "products": [
            {"name": "ร่มกอล์ฟ 30 นิ้ว", "qty": 1500, "price": 150.0},
            {
              "name": "กระบอกน้ำสแตนเลส เลเซอร์โลโก้",
              "qty": 2000,
              "price": 85.0,
            },
            {"name": "ถุงผ้าสปันบอนด์", "qty": 3000, "price": 25.0},
          ],
        },
      ],
      "outbound_expenses": [
        {
          "title": "ค่าผลิตร่มกอล์ฟ (งวด 1)",
          "category": "Cost of Goods (COGS)",
          "amount": 80000.0,
          "status": "Paid",
          "date": "15 May 2026",
        },
        {
          "title": "ค่าขนส่งทางเรือ LCL",
          "category": "Shipping & Logistics",
          "amount": 25000.0,
          "status": "Paid",
          "date": "10 Jun 2026",
        },
        {
          "title": "ภาษีนำเข้าศุลกากร",
          "category": "Tax & Customs",
          "amount": 12500.0,
          "status": "Pending",
          "date": "12 Jun 2026",
        },
      ],
    },
    {
      "id": "PPN-015",
      "customer": "Tesla Thailand",
      "insight_status": "Awaiting PO",
      "supplier_status": "Not Responded",
      "products": [
        {"name": "สายชาร์จ EV พรีเมียม หุ้มสายถัก", "qty": 5000, "price": 0.0},
      ],
      "supplier_quotes": [],
      "docs": {"QU": false, "PI": false, "DP": false, "CI": false},
      "deposit_amount": 0.0,
      "grand_total": 0.0,
      "credit_term": "TBD",
      "history": [],
      "outbound_expenses": [],
    },
  ];

  List<Map<String, dynamic>> _getFilteredProjects() {
    var result = _projects;
    if (_selectedInsightFilter != "All Active") {
      result = result
          .where((p) => p['insight_status'] == _selectedInsightFilter)
          .toList();
    }
    if (_searchText.isNotEmpty) {
      String searchLower = _searchText.toLowerCase();
      result = result
          .where(
            (p) =>
                p['customer'].toString().toLowerCase().contains(searchLower) ||
                p['id'].toString().toLowerCase().contains(searchLower),
          )
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _getFilteredProjects();

    Map<String, dynamic> selectedProject;
    if (filteredProjects.isEmpty) {
      selectedProject = _projects[0]; // Fallback
    } else {
      if (!filteredProjects.any((p) => p['id'] == _selectedProjectId)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedProjectId = filteredProjects[0]['id']);
          }
        });
      }
      selectedProject = filteredProjects.firstWhere(
        (p) => p['id'] == _selectedProjectId,
        orElse: () => filteredProjects[0],
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F9FC),
      // 🌟 ใช้ endDrawer เพื่อซ่อนพวกประวัติเอกสารเอาไว้ขวามือ (กดเรียกค่อยโผล่มา)
      endDrawer: _buildHistoryDrawer(selectedProject),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: Project List + Filters (กว้างขึ้นนิดนึงให้อ่านง่าย)
          // ==========================================
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.withOpacity(0.15),
                  width: 1.5,
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
                    bottom: 8,
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
                    "Finance & Docs",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),

                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedInsightFilter,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.sort,
                              size: 16,
                              color: Color(0xFF1D1D1F),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1D1D1F),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Prompt',
                            ),
                            items:
                                [
                                      "All Active",
                                      "Awaiting PO",
                                      "Need Deposit",
                                      "Waiting Credit Term",
                                    ]
                                    .map(
                                      (String value) =>
                                          DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          ),
                                    )
                                    .toList(),
                            onChanged: (newValue) => setState(
                              () => _selectedInsightFilter = newValue!,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (val) => setState(() => _searchText = val),
                        decoration: InputDecoration(
                          hintText: "ค้นหาโปรเจกต์...",
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
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final p = filteredProjects[index];
                      final isSelected = _selectedProjectId == p['id'];

                      Color statusCol = const Color(0xFF86868B);
                      if (p['insight_status'] == 'Need Deposit') {
                        statusCol = const Color(0xFFD97781);
                      }
                      if (p['insight_status'] == 'Waiting Credit Term') {
                        statusCol = const Color(0xFFF59E0B);
                      }

                      return InkWell(
                        onTap: () => setState(() {
                          _selectedProjectId = p['id'];
                          _selectedSupplierQuote =
                              null; // รีเซ็ตซัพเมื่อเปลี่ยนโปรเจกต์

                          // Auto route tab
                          if (!p['docs']['PI']) {
                            _activeDocTab = "QU";
                          } else if (!p['docs']['DP']) {
                            _activeDocTab = "PI";
                          } else if (!p['docs']['CI']) {
                            _activeDocTab = "DP";
                          } else {
                            _activeDocTab = "CI";
                          }
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
                                  Text(
                                    p['insight_status'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusCol,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p['customer'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF1D1D1F),
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
          // 2. MAIN WORKSPACE: พื้นที่ทำงานกว้างขวาง
          // ==========================================
          Expanded(
            child: Column(
              children: [
                // 🌟 HEADER & MACRO TOGGLE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${selectedProject['customer']}",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D1D1F),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Project ID: ${selectedProject['id']}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF86868B),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // 🌟 ปุ่มเรียกดูประวัติ Drawer
                          _buildButton(
                            _isInboundMode ? "Document Logs" : "Expense Logs",
                            Colors.white,
                            const Color(0xFF1D1D1F),
                            isOutlined: true,
                            icon: Icons.history,
                            onTap: () =>
                                _scaffoldKey.currentState?.openEndDrawer(),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F5F7),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMacroToggleTab(
                                  true,
                                  "Inbound",
                                  Icons.arrow_downward_rounded,
                                  const Color(0xFF4A9062),
                                ),
                                _buildMacroToggleTab(
                                  false,
                                  "Outbound",
                                  Icons.arrow_upward_rounded,
                                  const Color(0xFFD97781),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 🌟 CONTENT AREA
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48.0),
                    child: Center(
                      // จัดกึ่งกลางให้สวยงาม
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 1000,
                        ), // จำกัดความกว้างไม่ให้ยืดเกินไป
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isInboundMode
                              ? _buildInboundWorkspace(selectedProject)
                              : _buildOutboundWorkspace(selectedProject),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // VIEW: INBOUND WORKSPACE (ฝั่งลูกค้า)
  // =========================================================
  Widget _buildInboundWorkspace(Map<String, dynamic> project) {
    List supplierQuotes = project['supplier_quotes'] ?? [];

    return Column(
      key: const ValueKey("INBOUND_WORKSPACE"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Document Flow (ใช้ Step Indicator แทน Dropdown รกๆ) ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              _buildFlowTab("QU", "Quotation", project['docs']['QU']),
              _buildFlowDivider(),
              _buildFlowTab("PI", "Proforma Invoice", project['docs']['PI']),
              _buildFlowDivider(),
              _buildFlowTab("DP", "Record Deposit", project['docs']['DP']),
              _buildFlowDivider(),
              _buildFlowTab("CI", "Commercial Invoice", project['docs']['CI']),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // --- พื้นที่ฟอร์มทำงานหลัก ---
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _activeDocTab == "DP"
              ? _buildDepositForm(project)
              : _buildGenerateDocForm(project, supplierQuotes),
        ),

        const SizedBox(height: 64),

        // --- ส่วนเครื่องมือพิเศษ (อยู่ด้านล่าง) ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFileUploadCard(
                "Client PO / Approved Quote",
                "อัปโหลดใบสั่งซื้อหรือหลักฐานจากลูกค้า",
                Icons.document_scanner_outlined,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "สคบ. & Shipping Mark Generator",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "สร้างไฟล์ PDF พร้อมพิมพ์ โดยดึงข้อมูลจากโปรเจกต์นี้ให้อัตโนมัติ",
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Generating Shipping Mark PDF..."),
                            backgroundColor: Color(0xFF4A9062),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Generate PDF",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- ฟอร์มสร้าง Quotation / PI / CI ---
  Widget _buildGenerateDocForm(
    Map<String, dynamic> project,
    List supplierQuotes,
  ) {
    String docTitle = _activeDocTab == "QU"
        ? "Quotation"
        : (_activeDocTab == "PI" ? "Proforma Invoice" : "Commercial Invoice");

    double subtotal = 0;
    for (var prod in project['products']) {
      double p = double.tryParse(prod['price'].toString()) ?? 0.0;
      int q = int.tryParse(prod['qty'].toString()) ?? 0;
      subtotal += (p * q);
    }
    double vat = subtotal * 0.07;
    double grandTotal = subtotal + vat;
    double depositPaid = project['deposit_amount'] ?? 0.0;
    double balanceDue = grandTotal - depositPaid;

    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                docTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const Text(
                "Date: 26 May 2026",
                style: TextStyle(
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          // 🌟 Header ของตาราง และปุ่ม Auto-fill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text(
                    "Description",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    "Qty",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      const Text(
                        "Unit Price",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      if (_activeDocTab == "QU" && supplierQuotes.isNotEmpty)
                        // 🌟 ย้ายการเลือก Supplier มาซ่อนไว้ในปุ่มนี้ (ประหยัดพื้นที่ สวยงาม)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: InkWell(
                            onTap: () => _showAutoFillSupplierDialog(
                              context,
                              project,
                              supplierQuotes,
                            ),
                            child: const Tooltip(
                              message: "Auto-fill from Supplier Rate",
                              child: Icon(
                                Icons.auto_fix_high,
                                size: 16,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    "Amount",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // รายการสินค้า
          ...(project['products'] as List).asMap().entries.map((entry) {
            int index = entry.key;
            var prod = entry.value;
            double price = double.tryParse(prod['price'].toString()) ?? 0.0;
            int qty = int.tryParse(prod['qty'].toString()) ?? 0;
            double amount = price * qty;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildEditableField(
                      prod['name'].toString(),
                      (val) => setState(
                        () => project['products'][index]['name'] = val,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildEditableField(
                      qty.toString(),
                      (val) => setState(
                        () => project['products'][index]['qty'] = val,
                      ),
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildEditableField(
                      price.toString(),
                      (val) => setState(
                        () => project['products'][index]['price'] = val,
                      ),
                      isNumber: true,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "฿ ${amount.toStringAsFixed(2)}",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFD97781),
                      size: 22,
                    ),
                    onPressed: () =>
                        setState(() => project['products'].removeAt(index)),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(
              () =>
                  project['products'].add({"name": "", "qty": 1, "price": 0.0}),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, size: 16, color: Color(0xFF5B7BD5)),
                  SizedBox(width: 4),
                  Text(
                    "Add Item",
                    style: TextStyle(
                      color: Color(0xFF5B7BD5),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 64, color: Color(0xFFF4F5F7)),

          // ส่วนคำนวณยอด
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 350,
                child: Column(
                  children: [
                    _buildSummaryRow(
                      "Subtotal",
                      "฿ ${subtotal.toStringAsFixed(2)}",
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow("VAT (7%)", "฿ ${vat.toStringAsFixed(2)}"),

                    if (_activeDocTab == "CI") ...[
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        "Grand Total",
                        "฿ ${grandTotal.toStringAsFixed(2)}",
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Color(0xFFF4F5F7)),
                      ),
                      _buildSummaryRow(
                        "Less: Deposit Paid",
                        "- ฿ ${depositPaid.toStringAsFixed(2)}",
                        color: const Color(0xFFD97781),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Color(0xFFF4F5F7)),
                      ),
                      _buildSummaryRow(
                        "Balance Due",
                        "฿ ${balanceDue.toStringAsFixed(2)}",
                        isBold: true,
                        color: const Color(0xFF5B7BD5),
                        size: 20,
                      ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Color(0xFFF4F5F7)),
                      ),
                      _buildSummaryRow(
                        "Grand Total",
                        "฿ ${grandTotal.toStringAsFixed(2)}",
                        isBold: true,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 64),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildButton(
                "Preview A4 PDF",
                Colors.white,
                const Color(0xFF5B7BD5),
                isOutlined: true,
                icon: Icons.remove_red_eye_outlined,
                onTap: () {
                  _showA4PreviewDialog(
                    context,
                    project['customer'],
                    _activeDocTab,
                    project['products'],
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildButton(
                "Save & Issue Document",
                const Color(0xFF1D1D1F),
                Colors.white,
                icon: Icons.check_circle,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dialog สำหรับ Auto-fill ราคาจากซัพพลายเออร์
  void _showAutoFillSupplierDialog(
    BuildContext context,
    Map<String, dynamic> project,
    List supplierQuotes,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "🪄 Auto-fill from Supplier",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("เลือกดึงราคาต้นทุนตั้งต้นจากโรงงาน:"),
        actions:
            supplierQuotes
                .map(
                  (q) => TextButton(
                    onPressed: () {
                      setState(() {
                        for (var prod in project['products']) {
                          if (q['rates'].containsKey(prod['name'])) {
                            prod['price'] = q['rates'][prod['name']]; // ทับราคา
                          }
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      q['supplier_name'],
                      style: const TextStyle(color: Color(0xFF059669)),
                    ),
                  ),
                )
                .toList()
              ..add(
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Color(0xFF86868B)),
                  ),
                ),
              ),
      ),
    );
  }

  // --- ฟอร์มรับมัดจำ ---
  Widget _buildDepositForm(Map<String, dynamic> project) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Record Deposit Payment",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Deposit Amount",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildEditableField(
                      "${project['deposit_amount']}",
                      (val) {},
                      isNumber: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Date Received",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildEditableField("26 May 2026", (val) {}),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: _buildButton(
              "Confirm Payment",
              const Color(0xFF1D1D1F),
              Colors.white,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // VIEW: OUTBOUND WORKSPACE (ฝั่งซัพพลายเออร์)
  // =========================================================
  Widget _buildOutboundWorkspace(Map<String, dynamic> project) {
    List expenses = project['outbound_expenses'] ?? [];
    double totalCost = 0;
    double totalPaid = 0;
    for (var exp in expenses) {
      totalCost += exp['amount'];
      if (exp['status'] == 'Paid') totalPaid += exp['amount'];
    }
    double totalPending = totalCost - totalPaid;

    return Column(
      key: const ValueKey("OUTBOUND_WORKSPACE"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Outbound Expenses (บันทึกต้นทุนและรายจ่าย)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            _buildButton(
              "+ Record Expense",
              const Color(0xFF1D1D1F),
              Colors.white,
              icon: Icons.add,
              onTap: () => _showRecordExpenseDialog(context, project),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _buildExpenseStatCard(
                "Total Cost (รวม)",
                "฿${totalCost.toStringAsFixed(2)}",
                Icons.account_balance_wallet_outlined,
                const Color(0xFFF4F5F7),
                const Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildExpenseStatCard(
                "Paid (จ่ายแล้ว)",
                "฿${totalPaid.toStringAsFixed(2)}",
                Icons.check_circle_outline,
                const Color(0xFFB7E4C7).withOpacity(0.3),
                const Color(0xFF4A9062),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildExpenseStatCard(
                "Pending (รอจ่าย)",
                "฿${totalPending.toStringAsFixed(2)}",
                Icons.pending_actions,
                const Color(0xFFFDE2E4).withOpacity(0.5),
                const Color(0xFFD97781),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),

        const Text(
          "Expense History",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF4F5F7))),
                ),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 4,
                      child: Text(
                        "Description",
                        style: TextStyle(
                          color: Color(0xFF86868B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Category",
                        style: TextStyle(
                          color: Color(0xFF86868B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Amount",
                        style: TextStyle(
                          color: Color(0xFF86868B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Status",
                        style: TextStyle(
                          color: Color(0xFF86868B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Date",
                        style: TextStyle(
                          color: Color(0xFF86868B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(width: 32),
                  ],
                ),
              ),
              if (expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      "ยังไม่มีการบันทึกรายจ่าย",
                      style: TextStyle(
                        color: Color(0xFF86868B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ...expenses.asMap().entries.map((entry) {
                int index = entry.key;
                var exp = entry.value;
                bool isPaid = exp['status'] == 'Paid';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF4F5F7)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          exp['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          exp['category'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "฿${exp['amount'].toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? const Color(0xFFB7E4C7).withOpacity(0.3)
                                  : const Color(0xFFFDE2E4).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              exp['status'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPaid
                                    ? const Color(0xFF4A9062)
                                    : const Color(0xFFD97781),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          exp['date'],
                          style: const TextStyle(
                            color: Color(0xFF86868B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFD97781),
                          size: 18,
                        ),
                        onPressed: () => setState(
                          () => project['outbound_expenses'].removeAt(index),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // HELPER WIDGETS
  // =========================================================

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
    double size = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color ?? const Color(0xFF86868B),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? const Color(0xFF1D1D1F),
            fontSize: size,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: textColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileUploadCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF5B7BD5)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF86868B)),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: Color(0xFF64748B),
                  size: 24,
                ),
                SizedBox(height: 8),
                Text(
                  "Click to upload file",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String initialValue,
    Function(String) onChanged, {
    bool isNumber = false,
  }) {
    return SizedBox(
      height: 44,
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF4F5F7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFlowTab(String id, String title, bool isCompleted) {
    final isActive = _activeDocTab == id;
    Color bgColor = isActive
        ? const Color(0xFFAEC4FA).withOpacity(0.3)
        : Colors.transparent;
    Color textColor = isActive
        ? const Color(0xFF5B7BD5)
        : (isCompleted ? const Color(0xFF4A9062) : const Color(0xFF86868B));
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeDocTab = id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: const Color(0xFFAEC4FA))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCompleted && !isActive)
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Color(0xFF4A9062),
                ),
              if (isCompleted && !isActive) const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: isActive || isCompleted
                      ? FontWeight.bold
                      : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 10,
        color: Color(0xFFE2E2E2),
      ),
    );
  }

  Widget _buildMacroToggleTab(
    bool isInbound,
    String title,
    IconData icon,
    Color activeColor,
  ) {
    bool isSelected = _isInboundMode == isInbound;
    return GestureDetector(
      onTap: () => setState(() => _isInboundMode = isInbound),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : const Color(0xFF86868B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1D1D1F)
                    : const Color(0xFF86868B),
                fontSize: 14,
              ),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DRAWER: DOCUMENT HISTORY (แสดงประวัติจากขอบจอขวา)
  // =========================================================
  Widget _buildHistoryDrawer(Map<String, dynamic> project) {
    return Drawer(
      width: 400,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Activity & History",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    "Documents Log",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF86868B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if ((project['history'] as List).isEmpty)
                    const Text(
                      "No documents generated yet.",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFB4B4B8),
                      ),
                    )
                  else
                    ...(project['history'] as List).map(
                      (hist) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E2E2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  hist['doc_no'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFAEC4FA,
                                    ).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    hist['ver'],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5B7BD5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hist['type'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF86868B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hist['date'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFB4B4B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DIALOGS
  // =========================================================
  void _showRecordExpenseDialog(
    BuildContext context,
    Map<String, dynamic> project,
  ) {
    String title = "";
    String category = "Cost of Goods (COGS)";
    double amount = 0.0;
    String status = "Pending";
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "Record New Expense",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Expense Title",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: "เช่น ค่าขนส่งทางเรือ, มัดจำโรงงาน",
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => title = val,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Category",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items:
                        [
                              "Cost of Goods (COGS)",
                              "Shipping & Logistics",
                              "Tax & Customs",
                              "Sample & Prototype",
                              "Operation",
                              "Others",
                            ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (val) => setDialogState(() => category = val!),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Amount THB",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "0.00",
                      prefixIcon: const Icon(Icons.money),
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => amount = double.tryParse(val) ?? 0.0,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Payment Status",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => status = "Pending"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: status == "Pending"
                                  ? const Color(0xFFFDE2E4).withOpacity(0.5)
                                  : const Color(0xFFF4F5F7),
                              border: Border.all(
                                color: status == "Pending"
                                    ? const Color(0xFFD97781)
                                    : Colors.transparent,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                "Pending",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97781),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setDialogState(() => status = "Paid"),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: status == "Paid"
                                  ? const Color(0xFFB7E4C7).withOpacity(0.3)
                                  : const Color(0xFFF4F5F7),
                              border: Border.all(
                                color: status == "Paid"
                                    ? const Color(0xFF4A9062)
                                    : Colors.transparent,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                "Paid",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A9062),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                onPressed: () {
                  if (title.isNotEmpty && amount > 0) {
                    setState(() {
                      if (project['outbound_expenses'] == null) {
                        project['outbound_expenses'] = [];
                      }
                      project['outbound_expenses'].add({
                        "title": title,
                        "category": category,
                        "amount": amount,
                        "status": status,
                        "date": "Today",
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D1D1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Save Expense",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showA4PreviewDialog(
    BuildContext context,
    String clientName,
    String docType,
    List<dynamic> products, {
    String? docNo,
    String? date,
  }) {
    String mainTitle = docType == "QU" || docType == "Quotation"
        ? "QUOTATION"
        : (docType == "PI" || docType == "Proforma Invoice"
              ? "PROFORMA INVOICE"
              : "COMMERCIAL INVOICE");
    double subtotal = 0;
    for (var prod in products) {
      subtotal +=
          ((double.tryParse(prod['price'].toString()) ?? 0.0) *
          (int.tryParse(prod['qty'].toString()) ?? 0));
    }
    double vat = subtotal * 0.07;
    double grandTotal = subtotal + vat;

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
                          Text(
                            mainTitle,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.5,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Doc No: ${docNo ?? 'DRAFT-999'}\nDate: ${date ?? '26 May 2026'}",
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
                    "BILL TO / ลูกค้า:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF86868B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    clientName,
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
                            "DESCRIPTION",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "QTY",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "UNIT PRICE",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...products.map((prod) {
                    double price =
                        double.tryParse(prod['price'].toString()) ?? 0.0;
                    int qty = int.tryParse(prod['qty'].toString()) ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              prod['name'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "$qty pcs",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "฿ ${price.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              "฿ ${(qty * price).toStringAsFixed(2)}",
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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
                                  "Subtotal / ยอดรวม",
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
                                  "TOTAL / ยอดเงินสุทธิ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "฿ ${grandTotal.toStringAsFixed(2)}",
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
                            "Authorized Signature",
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
