import 'dart:ui';
import 'package:flutter/material.dart';

class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  String _searchText = "";
  String _selectedOrderId = "DO-001";

  // ฟอร์มจัดส่งแบบหลายรายการ (Multi-product Dispatch)
  String _deliveryAddress = "";
  String _dispatchDate = "26 May 2026";
  List<Map<String, dynamic>> _dispatchItems = [];

  // ==========================================
  // Mock Data
  // ==========================================
  final List<Map<String, dynamic>> _deliveryOrders = [
    {
      "id": "DO-001",
      "project_id": "PRJ-009",
      "customer": "Central Group",
      "status": "Ready to Ship",
      "address": "คลังสินค้า Central บางนา 123 หมู่ 4 สมุทรปราการ",
      "products": <Map<String, dynamic>>[
        {
          "name": "ร่มกอล์ฟ 30 นิ้ว พิมพ์ลายรอบคัน",
          "total_qty": 1500,
          "delivered_qty": 500,
          "defect_qty": 0,
        },
        {
          "name": "กระบอกน้ำสแตนเลส เลเซอร์โลโก้",
          "total_qty": 2000,
          "delivered_qty": 2000,
          "defect_qty": 10,
        },
        {
          "name": "ถุงผ้าสปันบอนด์ 75 แกรม หูหิ้ว",
          "total_qty": 3000,
          "delivered_qty": 0,
          "defect_qty": 0,
        },
      ],
      "history": <Map<String, dynamic>>[
        {
          "batch": "Round 1",
          "date": "15 May 2026",
          "items": [
            {
              "product": "ร่มกอล์ฟ 30 นิ้ว พิมพ์ลายรอบคัน",
              "qty": 500,
              "defect": 0,
            },
            {
              "product": "กระบอกน้ำสแตนเลส เลเซอร์โลโก้",
              "qty": 2000,
              "defect": 10,
            },
          ],
        },
      ],
    },
    {
      "id": "DO-002",
      "project_id": "PRJ-001",
      "customer": "Lion (Thailand)",
      "status": "Customs clearing",
      "address": "666 ถ.พระราม 3 แขวงบางคอแหลม เขตยานนาวา กทม",
      "products": <Map<String, dynamic>>[
        {
          "name": "กระเป๋าผ้าคอตตอน 12 ออนซ์",
          "total_qty": 20000,
          "delivered_qty": 0,
          "defect_qty": 0,
        },
      ],
      "history": <Map<String, dynamic>>[],
    },
  ];

  List<Map<String, dynamic>> _getFilteredOrders() {
    if (_searchText.isEmpty) return _deliveryOrders;
    return _deliveryOrders
        .where(
          (o) =>
              o['customer'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ||
              o['project_id'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initDispatchForm();
  }

  void _initDispatchForm() {
    _dispatchItems = [
      {"product_name": null, "qty": 0, "defect": 0, "error": null},
    ];
  }

  void _loadOrderData(Map<String, dynamic> order) {
    _deliveryAddress = order['address'];
    _initDispatchForm();
  }

  // ฟังก์ชันดึงข้อมูลจาก PO อัตโนมัติ
  void _autoFillRemainingFromPO(List<Map<String, dynamic>> products) {
    List<Map<String, dynamic>> newItems = [];
    for (var p in products) {
      int rem = p['total_qty'] - p['delivered_qty'];
      if (rem > 0) {
        newItems.add({
          "product_name": p['name'],
          "qty": rem,
          "defect": 0,
          "error": null,
        });
      }
    }

    if (newItems.isNotEmpty) {
      setState(() {
        _dispatchItems = newItems;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✓ ดึงรายการสินค้าที่เหลือจาก PO ลงฟอร์มเรียบร้อย"),
          backgroundColor: Color(0xFF4A9062),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ออเดอร์นี้จัดส่งครบทุกรายการแล้ว"),
          backgroundColor: Color(0xFF86868B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();

    Map<String, dynamic> selectedOrder;
    if (filteredOrders.isEmpty) {
      selectedOrder = _deliveryOrders[0];
    } else {
      selectedOrder = filteredOrders.firstWhere(
        (o) => o['id'] == _selectedOrderId,
        orElse: () => filteredOrders[0],
      );
    }

    if (_deliveryAddress.isEmpty) {
      _deliveryAddress = selectedOrder['address'];
    }

    List<Map<String, dynamic>> products = List<Map<String, dynamic>>.from(
      selectedOrder['products'],
    );
    int nextRound = (selectedOrder['history'] as List).length + 1;

    // เลือกสีของสถานะออเดอร์
    Color orderStatusColor = const Color(0xFF86868B);
    Color orderStatusBg = const Color(0xFFF4F5F7);
    if (selectedOrder['status'] == 'Ready to Ship') {
      orderStatusColor = const Color(0xFFD08A2A);
      orderStatusBg = const Color(0xFFFDF3E1);
    } else if (selectedOrder['status'] == 'Delivered') {
      orderStatusColor = const Color(0xFF4A9062);
      orderStatusBg = const Color(0xFFB7E4C7).withOpacity(0.3);
    } else if (selectedOrder['status'] == 'Customs clearing') {
      orderStatusColor = const Color(0xFF5B7BD5);
      orderStatusBg = const Color(0xFFAEC4FA).withOpacity(0.3);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: Sidebar
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
                    "Delivery Management",
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
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final isSelected = _selectedOrderId == order['id'];

                      Color statusColor = const Color(0xFF86868B);
                      Color statusBg = const Color(0xFFF4F5F7);
                      if (order['status'] == 'Ready to Ship') {
                        statusColor = const Color(0xFFD08A2A);
                        statusBg = const Color(0xFFFDF3E1);
                      } else if (order['status'] == 'Delivered') {
                        statusColor = const Color(0xFF4A9062);
                        statusBg = const Color(0xFFB7E4C7).withOpacity(0.3);
                      } else if (order['status'] == 'Customs clearing') {
                        statusColor = const Color(0xFF5B7BD5);
                        statusBg = const Color(0xFFAEC4FA).withOpacity(0.3);
                      }

                      return InkWell(
                        onTap: () => setState(() {
                          _selectedOrderId = order['id'];
                          _loadOrderData(order);
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
                                    order['project_id'],
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
                                      order['status'],
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
                                order['customer'],
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
                                "Total Items: ${(order['products'] as List).length}",
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
          // 2. RIGHT PANEL: รายละเอียดและการจัดการจัดส่ง
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Dispatch & Delivery",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Project: ${selectedOrder['project_id']} - ${selectedOrder['customer']}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: orderStatusBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: orderStatusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedOrder['status'] == 'Ready to Ship'
                                  ? Icons.local_shipping
                                  : Icons.info_outline,
                              size: 16,
                              color: orderStatusColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Status: ${selectedOrder['status']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: orderStatusColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- 1. ข้อมูลสรุปยอดคงเหลือ (Overview Cards - 2 Columns) ---
                  const Text(
                    "Delivery Overview",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      double cardWidth = (constraints.maxWidth - 16) / 2;
                      if (cardWidth < 300) {
                        cardWidth = constraints.maxWidth;
                      }

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: products.map((p) {
                          int rem = p['total_qty'] - p['delivered_qty'];
                          bool isDone = rem <= 0;
                          int def = p['defect_qty'] ?? 0;
                          double prog = p['total_qty'] > 0
                              ? (p['delivered_qty'] / p['total_qty']).clamp(
                                  0.0,
                                  1.0,
                                )
                              : 0;

                          return Container(
                            width: cardWidth,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDone
                                    ? const Color(0xFF10B981).withOpacity(0.3)
                                    : const Color(0xFFE2E8F0),
                                width: isDone ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // แถว 1: ไอคอน + ชื่อ + ป้าย (Defect / Completed)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFEFF6FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isDone
                                            ? Icons.check_circle_rounded
                                            : Icons.inventory_2_rounded,
                                        color: isDone
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF3B82F6),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (def > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                "⚠️ มีของเสีย $def ชิ้น",
                                                style: const TextStyle(
                                                  color: Color(0xFFEF4444),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // ป้าย Remaining หรือ Completed เด่นๆ
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDone
                                            ? const Color(0xFFF0FDF4)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isDone ? "Completed" : "เหลือ $rem",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDone
                                              ? const Color(0xFF059669)
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // แถว 2: Progress Bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: prog,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDone
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF3B82F6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // แถว 3: ข้อความ "ส่งแล้ว... (เหลือ...)"
                                Row(
                                  children: [
                                    Text(
                                      isDone
                                          ? "ส่งครบแล้ว ${p['total_qty']} / ${p['total_qty']} pcs"
                                          : "ส่งแล้ว ${p['delivered_qty']} / ${p['total_qty']} pcs (เหลือ $rem)",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDone
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // --- 2. ฟอร์มยืนยันจัดส่ง (Dispatch Confirmation Form) ---
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_shipping_rounded,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Record New Delivery (บันทึกจัดส่งรอบที่ $nextRound)",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "กรอกข้อมูลเพื่อตัดยอดคงเหลือ และบันทึกประวัติการจัดส่ง",
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 48, color: Color(0xFFF4F5F7)),

                        // แถวตั้งค่า Shipment
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildFormField(
                                "Delivery Date",
                                TextFormField(
                                  initialValue: _dispatchDate,
                                  onChanged: (val) => _dispatchDate = val,
                                  decoration: _inputDeco(
                                    icon: Icons.calendar_today,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _buildFormField(
                                "Delivery Address",
                                TextFormField(
                                  initialValue: _deliveryAddress,
                                  maxLines: 2,
                                  onChanged: (val) => _deliveryAddress = val,
                                  decoration: _inputDeco(
                                    icon: Icons.location_on_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // --- รายการสินค้าที่จะจัดส่ง (Dynamic List) ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Items in this delivery round",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // ปุ่ม Auto-fill จาก PO ลูกค้า
                            TextButton.icon(
                              onPressed: () =>
                                  _autoFillRemainingFromPO(products),
                              icon: const Icon(
                                Icons.playlist_add_check_rounded,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                              label: const Text(
                                "Auto-fill remaining from PO",
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFEFF6FF),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ..._dispatchItems.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> item = entry.value;

                          int remainingQty = 0;
                          if (item['product_name'] != null) {
                            var pData = products.firstWhere(
                              (p) => p['name'] == item['product_name'],
                              orElse: () => {
                                'total_qty': 0,
                                'delivered_qty': 0,
                              },
                            );
                            remainingQty =
                                pData['total_qty'] - pData['delivered_qty'];
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item['error'] != null
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFE2E8F0),
                                width: item['error'] != null ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Dropdown เลือกสินค้า
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Select Product",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            initialValue:
                                                item['product_name'], // Binding data
                                            decoration: _inputDeco(),
                                            hint: const Text(
                                              "เลือกสินค้าที่จะส่ง",
                                            ),
                                            items: products
                                                .where(
                                                  (p) =>
                                                      (p['total_qty'] -
                                                          p['delivered_qty']) >
                                                      0,
                                                )
                                                .map(
                                                  (p) =>
                                                      DropdownMenuItem<String>(
                                                        value: p['name'],
                                                        child: Text(
                                                          p['name'],
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                )
                                                .toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                item['product_name'] = val;
                                                item['qty'] = 0;
                                                item['error'] = null;
                                              });
                                            },
                                          ),
                                          if (item['product_name'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Text(
                                                "Available to send: $remainingQty pcs",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF2563EB),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // 2. Qty Input + Quick Fill
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Delivery Qty",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            key: Key(
                                              "qty_${index}_${item['qty']}",
                                            ),
                                            initialValue: item['qty']
                                                .toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: _inputDeco(
                                              errorText: item['error'],
                                            ),
                                            onChanged: (val) => item['qty'] =
                                                int.tryParse(val) ?? 0,
                                          ),
                                          if (item['product_name'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Row(
                                                children: [
                                                  _buildQuickFillBtn(
                                                    "Half",
                                                    () => setState(() {
                                                      item['qty'] =
                                                          remainingQty ~/ 2;
                                                      item['error'] = null;
                                                    }),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  _buildQuickFillBtn(
                                                    "All Remaining",
                                                    () => setState(() {
                                                      item['qty'] =
                                                          remainingQty;
                                                      item['error'] = null;
                                                    }),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // 3. Defect Qty
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Defect Qty",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            initialValue: item['defect']
                                                .toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: _inputDeco(),
                                            onChanged: (val) => item['defect'] =
                                                int.tryParse(val) ?? 0,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // 4. Delete Row
                                    Padding(
                                      padding: const EdgeInsets.only(top: 24),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFEF4444),
                                        ),
                                        onPressed: () => setState(
                                          () => _dispatchItems.removeAt(index),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                        // ปุ่ม Add Product To Dispatch
                        OutlinedButton.icon(
                          onPressed: () => setState(
                            () => _dispatchItems.add({
                              "product_name": null,
                              "qty": 0,
                              "defect": 0,
                              "error": null,
                            }),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text("Add product to this delivery"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E293B),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                        Center(
                          child: InkWell(
                            onTap: () {
                              bool hasError = false;
                              setState(() {
                                // Validation
                                for (var item in _dispatchItems) {
                                  if (item['product_name'] == null) {
                                    item['error'] = "Please select product";
                                    hasError = true;
                                  } else {
                                    var pData = products.firstWhere(
                                      (p) => p['name'] == item['product_name'],
                                    );
                                    int rem =
                                        pData['total_qty'] -
                                        pData['delivered_qty'];
                                    if (item['qty'] <= 0) {
                                      item['error'] = "Must be > 0";
                                      hasError = true;
                                    } else if (item['qty'] > rem) {
                                      item['error'] =
                                          "Exceeds remaining ($rem)";
                                      hasError = true;
                                    } else {
                                      item['error'] = null;
                                    }
                                  }
                                }
                              });

                              if (hasError) return;

                              // บันทึกข้อมูล
                              setState(() {
                                List<Map<String, dynamic>> savedItems = [];
                                for (var item in _dispatchItems) {
                                  var prod = (selectedOrder['products'] as List)
                                      .firstWhere(
                                        (p) =>
                                            p['name'] == item['product_name'],
                                      );
                                  prod['delivered_qty'] += item['qty'];
                                  if (item['defect'] > 0) {
                                    prod['defect_qty'] =
                                        (prod['defect_qty'] ?? 0) +
                                        item['defect'];
                                  }

                                  savedItems.add({
                                    "product": item['product_name'],
                                    "qty": item['qty'],
                                    "defect": item['defect'],
                                  });
                                }

                                selectedOrder['address'] = _deliveryAddress;

                                (selectedOrder['history'] as List).add({
                                  "batch": "Round $nextRound",
                                  "date": _dispatchDate,
                                  "items": savedItems,
                                });

                                _initDispatchForm();
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "✓ Delivery recorded successfully!",
                                  ),
                                  backgroundColor: Color(0xFF4A9062),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "Confirm Delivery",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // --- 3. Delivery History Table ---
                  const Text(
                    "Delivery History",
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
                    child: (selectedOrder['history'] as List).isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                "ยังไม่มีประวัติการจัดส่งในระบบ",
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
                                  "Batch / Date",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Product Delivered",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Qty",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Defect",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: (selectedOrder['history'] as List).expand((
                              hist,
                            ) {
                              return (hist['items'] as List).map((item) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            hist['batch'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            hist['date'],
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF86868B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(item['product'])),
                                    DataCell(
                                      Text(
                                        "${item['qty']} pcs",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        "${item['defect']} pcs",
                                        style: TextStyle(
                                          color: item['defect'] > 0
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              });
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

  Widget _buildFormField(String label, Widget child) {
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
        child,
      ],
    );
  }

  InputDecoration _inputDeco({IconData? icon, String? errorText}) {
    return InputDecoration(
      errorText: errorText,
      errorStyle: const TextStyle(
        color: Color(0xFFEF4444),
        fontWeight: FontWeight.w600,
      ),
      suffixIcon: icon != null
          ? Icon(icon, size: 18, color: const Color(0xFF86868B))
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }

  Widget _buildQuickFillBtn(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
