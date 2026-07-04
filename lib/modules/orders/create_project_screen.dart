import 'dart:ui';
import 'package:flutter/material.dart';
import '../customers/create_customer_screen.dart';

class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  // Global Project State
  int _selectedPriority = 0;
  bool _isRepeatOrder = false;

  // 🌟 ค่าเริ่มต้นเป็น null (ไม่ Pre-select ลูกค้า)
  String? _selectedCustomerName;
  String? _selectedContactPerson;

  // Project Details
  String _projectTargetDate = "";

  // Items State
  final List<Map<String, dynamic>> _productItems = [
    {
      "id": 1,
      "type": "",
      "quantities": [""],
      "custom_target_date": "",
      "specs": "",
    },
  ];
  int _nextItemId = 2;

  // Mock Data: ลูกค้าและผู้ติดต่อ
  final List<Map<String, dynamic>> _customers = [
    {
      "name": "Lion (Thailand)",
      "type": "เจ้าใหญ่",
      "last_project": "กระเป๋าผ้าคอตตอน • 2 months ago",
      "contacts": ["K. Somchai (MKT)", "K. Ann (Purchasing)"],
    },
    {
      "name": "Tesla Thailand",
      "type": "เจ้าใหญ่",
      "last_project": "สายชาร์จ EV • 15 days ago",
      "contacts": ["K. Mike (Event)"],
    },
    {
      "name": "ร้านเจ๊จู นำเข้า",
      "type": "เจ้าเล็ก",
      "last_project": "เครื่องครัว • 1 year ago",
      "contacts": ["เจ๊จู"],
    },
    {
      "name": "Siam Paragon",
      "type": "เจ้าใหญ่",
      "last_project": "ถุงกระดาษ Premium • 5 months ago",
      "contacts": ["K.ploy (CRM)", "K. Nut (MKT)"],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: SELECT CUSTOMER (กลับมาใช้แบบเดิม)
          // ==========================================
          _buildCustomerSidebar(),

          // ==========================================
          // 2. RIGHT PANEL: PROJECT & ITEMS FORM
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
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Create New Project",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D1D1F),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 🌟 แสดงชื่อลูกค้าที่เลือกจากด้านซ้าย
                          Text(
                            _selectedCustomerName == null
                                ? "⚠️ Please select a customer from the left panel"
                                : "Client: $_selectedCustomerName",
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedCustomerName == null
                                  ? const Color(0xFFD97781)
                                  : const Color(0xFF5B7BD5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildButton(
                            "Cancel",
                            Colors.white,
                            const Color(0xFF1D1D1F),
                            isOutlined: true,
                            onTap: () => _confirmCancelDialog(context),
                          ),
                          const SizedBox(width: 16),
                          _buildButton(
                            "Create Project",
                            const Color(0xFF1D1D1F),
                            Colors.white,
                            onTap: () => _confirmCreateDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- Project Details ---
                  const Text(
                    "Project Details",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 🌟 ย้าย Contact Person มาไว้ตรงนี้
                            Expanded(
                              flex: 2,
                              child: _selectedCustomerName == null
                                  ? _buildDropdownField(
                                      "Contact Person in charge *",
                                      "โปรดเลือกลูกค้าด้านซ้ายก่อน",
                                      [],
                                      null,
                                      null,
                                    )
                                  : _buildDropdownField(
                                      "Contact Person in charge *",
                                      "เลือกผู้รับผิดชอบ...",
                                      (_customers.firstWhere(
                                                (c) =>
                                                    c['name'] ==
                                                    _selectedCustomerName,
                                              )['contacts']
                                              as List)
                                          .cast<String>(),
                                      _selectedContactPerson,
                                      (val) => setState(
                                        () => _selectedContactPerson = val,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: _buildInputField(
                                "Project Target Date *",
                                "DD/MM/YYYY",
                                icon: Icons.calendar_today,
                                onChanged: (val) => _projectTargetDate = val,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: _buildInputField(
                                "Overall Budget (THB)",
                                "งบประมาณรวม (ถ้ามี)",
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Order Status",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1D1D1F),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => setState(
                                      () => _isRepeatOrder = !_isRepeatOrder,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isRepeatOrder
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFF4F5F7),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _isRepeatOrder
                                              ? const Color(0xFF4A9062)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _isRepeatOrder
                                                ? "Repeat Order (มีโมลด์แล้ว)"
                                                : "New Project (โปรเจกต์ใหม่)",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: _isRepeatOrder
                                                  ? const Color(0xFF059669)
                                                  : const Color(0xFF86868B),
                                              fontSize: 13,
                                            ),
                                          ),
                                          Switch(
                                            value: _isRepeatOrder,
                                            activeThumbColor: const Color(
                                              0xFF4A9062,
                                            ),
                                            onChanged: (val) => setState(
                                              () => _isRepeatOrder = val,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Project Priority",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1D1D1F),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F5F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildPriorityOption(
                                          "Normal",
                                          0,
                                          const Color(0xFFAEC4FA),
                                        ),
                                        _buildPriorityOption(
                                          "Urgent",
                                          1,
                                          const Color(0xFFFFCAD4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: _buildInputField(
                                "Project Specs & Requirements",
                                "ระบุธีมงาน, แคมเปญ หรือความต้องการภาพรวมของโปรเจกต์...",
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // --- Product List ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Product List (Optional)",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      Text(
                        "สามารถสร้างโปรเจกต์โดยยังไม่ต้องระบุสินค้าได้",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD08A2A).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ..._productItems.asMap().entries.map(
                    (entry) => _buildProductItemBlock(entry.key, entry.value),
                  ),

                  _buildAddProductButton(),
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
  // WIDGET BUILDERS
  // =========================================================

  // 1. แถบลูกค้าด้านซ้าย (กลับมาทำหน้าที่เป็นตัวเลือกหลัก)
  Widget _buildCustomerSidebar() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
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
              "Select Customer",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "ค้นหาลูกค้า...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF4F5F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCustomerScreen(),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFAEC4FA).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFAEC4FA).withOpacity(0.5),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      size: 18,
                      color: Color(0xFF5B7BD5),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Create New Customer",
                      style: TextStyle(
                        color: Color(0xFF5B7BD5),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 32, color: Color(0xFFF4F5F7)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final c = _customers[index];
                final isSelected = _selectedCustomerName == c['name'];

                return InkWell(
                  onTap: () => setState(() {
                    _selectedCustomerName = c['name'];
                    _selectedContactPerson =
                        null; // รีเซ็ตผู้ติดต่อเมื่อเปลี่ยนบริษัท
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFAEC4FA).withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFAEC4FA)
                            : Colors.grey.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['name'],
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: const Color(0xFF1D1D1F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Last: ${c['last_project']}",
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
    );
  }

  // 3. Block สินค้าแต่ละชิ้น
  Widget _buildProductItemBlock(int index, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF4F5F7))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAEC4FA).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B7BD5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Product Item",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _confirmRemoveProduct(item['id']),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFD97781),
                    size: 18,
                  ),
                  label: const Text(
                    "Remove this product",
                    style: TextStyle(color: Color(0xFFD97781)),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // แถวที่ 1
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Product Type *",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              hintText: "Search or type custom product...",
                              suffixIcon: const Icon(
                                Icons.search,
                                size: 18,
                                color: Color(0xFF86868B),
                              ),
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
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Quantity (สามารถขอหลายสเตปได้) *",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...item['quantities'].asMap().entries.map((qEntry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: "e.g. 1000",
                                        filled: true,
                                        fillColor: const Color(0xFFF4F5F7),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (qEntry.key > 0)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Color(0xFFD97781),
                                        size: 18,
                                      ),
                                      onPressed: () => setState(
                                        () => item['quantities'].removeAt(
                                          qEntry.key,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          InkWell(
                            onTap: () =>
                                setState(() => item['quantities'].add("")),
                            child: const Text(
                              "+ Add another qty option",
                              style: TextStyle(
                                color: Color(0xFF5B7BD5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Target Date",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          item['custom_target_date'] == ""
                              ? InkWell(
                                  onTap: () => setState(
                                    () => item['custom_target_date'] =
                                        "DD/MM/YYYY",
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F5F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _projectTargetDate.isEmpty
                                            ? "Same as Project"
                                            : _projectTargetDate,
                                        style: const TextStyle(
                                          color: Color(0xFF86868B),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : TextFormField(
                                  decoration: InputDecoration(
                                    hintText: "DD/MM/YYYY",
                                    suffixIcon: InkWell(
                                      onTap: () => setState(
                                        () => item['custom_target_date'] = "",
                                      ),
                                      child: const Icon(Icons.close, size: 16),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF4F5F7),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // แถวที่ 2
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Specs & Requirements *",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  "ระบุวัสดุ สี ขนาด จุดสกรีน... (หากมีหลายลายใน 1 สินค้า โปรดระบุจำนวนของแต่ละลายที่นี่)",
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
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Reference Images & Logo",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 135,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F5F7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFAEC4FA).withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                // 🌟 เปลี่ยนไอคอนและข้อความ ให้รับเฉพาะรูปภาพ
                                Icon(
                                  Icons.image_outlined,
                                  size: 28,
                                  color: Color(0xFFAEC4FA),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Drop image files here",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "JPG, PNG, WEBP (Max 10MB)",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF86868B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductButton() {
    return InkWell(
      onTap: () => setState(() {
        _productItems.add({
          "id": _nextItemId,
          "type": "",
          "quantities": [""],
          "custom_target_date": "",
          "specs": "",
        });
        _nextItemId++;
      }),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFAEC4FA), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, color: Color(0xFF5B7BD5), size: 24),
            SizedBox(width: 12),
            Text(
              "Add Another Product",
              style: TextStyle(
                color: Color(0xFF5B7BD5),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  void _confirmRemoveProduct(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Product?"),
        content: const Text(
          "คุณแน่ใจหรือไม่ที่จะลบสินค้ารายการนี้ออกจากโปรเจกต์?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97781),
            ),
            onPressed: () {
              setState(() => _productItems.removeWhere((p) => p['id'] == id));
              Navigator.pop(ctx);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Project Creation?"),
        content: const Text(
          "ข้อมูลทั้งหมดที่กรอกมาจะไม่ถูกบันทึก คุณแน่ใจหรือไม่?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Editing"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D1F),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCreateDialog(BuildContext context) {
    if (_selectedCustomerName == null || _selectedContactPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาเลือกลูกค้าและผู้ติดต่อให้ครบถ้วน"),
          backgroundColor: Color(0xFFD97781),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Create Project"),
        content: const Text(
          "ตรวจสอบข้อมูลครบถ้วนและต้องการสร้างโปรเจกต์ใหม่ใช่หรือไม่?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Back"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D1F),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showSuccessPopup(context);
            },
            child: const Text(
              "Confirm & Create",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 64,
                color: Color(0xFF4A9062),
              ),
              const SizedBox(height: 16),
              const Text(
                "Project Created Successfully!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "รหัสโปรเจกต์ PRJ-055 ถูกสร้างเรียบร้อยแล้ว",
                style: TextStyle(color: Color(0xFF86868B)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D1D1F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "View / Edit Project",
                    style: TextStyle(
                      color: Colors.white,
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

  // --- Utility Widgets ---

  Widget _buildDropdownField(
    String label,
    String hint,
    List<String> items,
    String? value,
    Function(String?)? onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF4F5F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: items
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String hint, {
    int maxLines = 1,
    bool isNumber = false,
    IconData? icon,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB4B4B8), fontSize: 13),
            suffixIcon: icon != null
                ? Icon(icon, size: 18, color: const Color(0xFF86868B))
                : null,
            filled: true,
            fillColor: const Color(0xFFF4F5F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityOption(String title, int index, Color activeColor) {
    final isSelected = _selectedPriority == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
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
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF1D1D1F)
                  : const Color(0xFF86868B),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    String title,
    Color bgColor,
    Color textColor, {
    bool isOutlined = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isOutlined
              ? Border.all(color: const Color(0xFFE2E2E2))
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
