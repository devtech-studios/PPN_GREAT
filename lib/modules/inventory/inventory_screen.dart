import 'dart:ui';
import 'package:flutter/material.dart';

class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchText = "";
  String _selectedWarehouseId = "WH-001";

  // ==========================================
  // Mock Data: รายชื่อคลังสินค้า (เพิ่มสถานะ Temp Storage)
  // ==========================================
  final List<Map<String, dynamic>> _warehouses = [
    {
      "id": "WH-001",
      "name": "โกดังพระราม 2 (Zone A)",
      "province": "กรุงเทพมหานคร",
      "type": "PPN Own Warehouse (คลังหลัก)",
      "last_received": "26 May 2026",
      "current_stock": <Map<String, dynamic>>[
        {
          "item": "กระเป๋าผ้าคอตตอน 12 ออนซ์",
          "sku": "BG-COT-01",
          "ownership": "Client",
          "owner_ref": "Lion (Thailand)",
          "arrived": 25000,
          "sent": 5000,
          "available": 20000,
          "history": [
            {
              "date_in": "20 May 2026",
              "ref": "PRJ-001 (ล็อต 1)",
              "qty_in": 20000,
              "date_out": "25 May 2026 (5,000 pcs)",
              "recorded_by": "System (Container)",
            },
            {
              "date_in": "22 May 2026",
              "ref": "PRJ-015 (ล็อต 2)",
              "qty_in": 5000,
              "date_out": "-",
              "recorded_by": "System (Container)",
            },
          ],
        },
        // 🌟 เปลี่ยนเคสนี้เป็น "ฝากเก็บชั่วคราว"
        {
          "item": "ร่มพับ 2 ตอน พรีเมียม",
          "sku": "UM-FLD-02",
          "ownership": "Temp Storage", // สถานะฝากเก็บ
          "owner_ref": "PTG Energy", // อ้างอิงชื่อลูกค้า
          "arrived": 3000,
          "sent": 0,
          "available": 3000,
          "history": [
            {
              "date_in": "26 May 2026",
              "ref": "PRJ-035",
              "qty_in": 3000,
              "date_out": "-",
              "recorded_by":
                  "System (โกดังลูกค้าเต็ม ฝากไว้ก่อน)", // โน้ตบอกเหตุผล
            },
          ],
        },
      ],
    },
    {
      "id": "WH-002",
      "name": "โกดังบางนา (คลังรวมถาวร)",
      "province": "สมุทรปราการ",
      "type": "Shared Warehouse",
      "last_received": "10 May 2026",
      "current_stock": <Map<String, dynamic>>[
        {
          "item": "ร่มกอล์ฟ 30 นิ้ว Central",
          "sku": "UM-GLF-30",
          "ownership": "Client",
          "owner_ref": "Central Group",
          "arrived": 1500,
          "sent": 1500,
          "available": 0,
          "history": [
            {
              "date_in": "10 May 2026",
              "ref": "PRJ-004",
              "qty_in": 1500,
              "date_out": "15 May 2026 (Full)",
              "recorded_by": "Admin B",
            },
          ],
        },
        {
          "item": "กระบอกน้ำสแตนเลส (Stock กลาง)",
          "sku": "BT-STL-05",
          "ownership": "PPN Own Stock",
          "owner_ref": "PPN",
          "arrived": 2000,
          "sent": 200,
          "available": 1800,
          "history": [
            {
              "date_in": "01 Apr 2026",
              "ref": "PO-INT-001",
              "qty_in": 2000,
              "date_out": "15 Apr (200 pcs)",
              "recorded_by": "Manager C",
            },
          ],
        },
      ],
    },
  ];

  // รายการออเดอร์สำหรับทำ Manual Adjust
  final List<Map<String, dynamic>> _incomingOrders = [
    {
      "project_id": "PRJ-021",
      "customer": "Line Man",
      "product": "แจ็คเก็ตไรเดอร์ กันน้ำ",
      "qty": 10000,
    },
    {
      "project_id": "PRJ-035",
      "customer": "PTG Energy",
      "product": "กระบอกน้ำเก็บอุณหภูมิ",
      "qty": 5000,
    },
  ];

  List<Map<String, dynamic>> _getFilteredWarehouses() {
    if (_searchText.isEmpty) return _warehouses;
    return _warehouses
        .where(
          (w) =>
              w['name'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ||
              w['province'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredWarehouses = _getFilteredWarehouses();
    Map<String, dynamic> selectedWarehouse = filteredWarehouses.firstWhere(
      (w) => w['id'] == _selectedWarehouseId,
      orElse: () => _warehouses.isNotEmpty ? _warehouses[0] : {},
    );

    // คำนวณยอดรวมของคลังที่เลือก
    int totalSkus = 0;
    int totalAvailableItems = 0;
    if (selectedWarehouse.isNotEmpty) {
      final stockList = selectedWarehouse['current_stock'] as List;
      totalSkus = stockList.length;
      for (var item in stockList) {
        totalAvailableItems += (item['available'] as int);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: Sidebar - Warehouse List
          // ==========================================
          Container(
            width: 340,
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Warehouses",
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
                        tooltip: "เพิ่มคลังสินค้าใหม่",
                        onPressed: () => _showAddWarehouseDialog(context),
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
                      hintText: "ค้นหาคลังสินค้า...",
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
                    itemCount: filteredWarehouses.length,
                    itemBuilder: (context, index) {
                      final w = filteredWarehouses[index];
                      final isSelected = _selectedWarehouseId == w['id'];
                      final int skusCount = (w['current_stock'] as List).length;

                      return InkWell(
                        onTap: () =>
                            setState(() => _selectedWarehouseId = w['id']),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                    w['id'],
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
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "$skusCount SKUs",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                w['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Color(0xFF86868B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    w['province'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF86868B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Type: ${w['type']}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF86868B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Last received: ${w['last_received']}",
                                style: const TextStyle(
                                  fontSize: 11,
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
          // 2. RIGHT PANEL: หน้าต่างโชว์ Stock Inventory
          // ==========================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header & Action ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Inventory Overview",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D1D1F),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${selectedWarehouse['name']} (${selectedWarehouse['province']})",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF5B7BD5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // ซ่อนการ Manual Adjust ไว้ในปุ่ม
                      _buildButton(
                        "Manual Adjust",
                        Colors.white,
                        const Color(0xFF1D1D1F),
                        icon: Icons.edit_note,
                        isOutlined: true,
                        onTap: () =>
                            _showManualAdjustDialog(context, selectedWarehouse),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- Summary Cards ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          "Total SKUs",
                          "$totalSkus",
                          Icons.category_outlined,
                          const Color(0xFFEAE4F2),
                          const Color(0xFF6B4CA4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          "Available Items",
                          "$totalAvailableItems",
                          Icons.inventory_2_outlined,
                          const Color(0xFFB7E4C7).withOpacity(0.3),
                          const Color(0xFF4A9062),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          "Last Received",
                          selectedWarehouse['last_received'],
                          Icons.history_rounded,
                          const Color(0xFFF4F5F7),
                          const Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- ตารางรายการสินค้าปัจจุบัน ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Current Stock Inventory",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFF86868B),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Calculation: Available = Arrived - Sent",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF86868B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: (selectedWarehouse['current_stock'] as List).isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(64.0),
                            child: Center(
                              child: Text(
                                "คลังสินค้านี้ว่างเปล่า ไม่มีสินค้าใน Stock",
                                style: TextStyle(
                                  color: Color(0xFF86868B),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              // 🌟 Table Header (ใช้ Expanded)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: const [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "SKU",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        "Product Name",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "Ownership Tag",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        "Arrived",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        "Sent",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        "Available",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D1D1F),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          "History",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 🌟 Table Rows (ใช้ Expanded)
                              ...((selectedWarehouse['current_stock'] as List)
                                  .map((stock) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Color(0xFFF1F5F9),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              stock['sku'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              stock['item'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: _buildOwnershipBadge(
                                              stock['ownership'],
                                              stock['owner_ref'],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "${stock['arrived']}",
                                              style: const TextStyle(
                                                color: Color(0xFF4A9062),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "${stock['sent']}",
                                              style: const TextStyle(
                                                color: Color(0xFFD97781),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              "${stock['available']}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Color(0xFF1D1D1F),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: InkWell(
                                                onTap: () =>
                                                    _showMovementHistoryDialog(
                                                      context,
                                                      stock,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFAEC4FA,
                                                    ).withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.history_rounded,
                                                    color: Color(0xFF5B7BD5),
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList()),
                            ],
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

  Widget _buildSummaryCard(
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF86868B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 อัปเดตสี Ownership ให้มีกรณีของ Temp Storage
  Widget _buildOwnershipBadge(String ownership, String ref) {
    Color bg = const Color(0xFFDBEAFE);
    Color text = const Color(0xFF1E40AF);

    if (ownership == "PPN Own Stock") {
      bg = const Color(0xFFD1FAE5);
      text = const Color(0xFF065F46);
    } else if (ownership == "Temp Storage") {
      bg = const Color(0xFFFEF3C7); // สีเหลือง/ส้มอ่อน
      text = const Color(0xFFB45309); // สีส้มเข้ม
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            ownership,
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Ref: $ref",
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
  // DIALOGS
  // =========================================================

  void _showManualAdjustDialog(
    BuildContext context,
    Map<String, dynamic> warehouse,
  ) {
    String type = "Stock In (รับเข้า)";
    String? selectedProject;
    int receivedQty = 0;
    String note = "";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "Manual Stock Adjustment",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ใช้สำหรับปรับสต็อกฉุกเฉิน (ปกติสต็อกจะรับเข้า/หักออกอัตโนมัติจากหน้า Logistics และ Delivery)",
                      style: TextStyle(color: Color(0xFF86868B), fontSize: 12),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "1. ประเภทการปรับปรุง",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items:
                          [
                                "Stock In (รับเข้า)",
                                "Stock Out (เบิกออก)",
                                "Write-off (ตัดจำหน่าย/ของเสีย)",
                              ]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (val) => setDialogState(() => type = val!),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "2. อ้างอิงรายการโปรเจกต์",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedProject,
                      decoration: InputDecoration(
                        hintText: "เลือกรายการ",
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _incomingOrders
                          .map(
                            (o) => DropdownMenuItem<String>(
                              value: o['project_id'],
                              child: Text(
                                "${o['project_id']} - ${o['customer']} (${o['product']})",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedProject = val),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "3. จำนวนที่ปรับ (Pcs)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "0",
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => receivedQty = int.tryParse(val) ?? 0,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "4. หมายเหตุ (Reason)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "ระบุเหตุผลการปรับปรุง...",
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => note = val,
                    ),
                  ],
                ),
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
                  if (selectedProject == null || receivedQty == 0) return;
                  var order = _incomingOrders.firstWhere(
                    (o) => o['project_id'] == selectedProject,
                  );

                  setState(() {
                    if (type == "Stock In (รับเข้า)") {
                      (warehouse['current_stock'] as List).add({
                        "sku": "RCV-${order['project_id']}",
                        "item": order['product'],
                        "ownership": "Client",
                        "owner_ref": order['customer'],
                        "arrived": receivedQty,
                        "sent": 0,
                        "available": receivedQty,
                        "history": [
                          {
                            "date_in": "Today",
                            "ref": "Manual Adjust",
                            "qty_in": receivedQty,
                            "date_out": "-",
                            "recorded_by": "You",
                          },
                        ],
                      });
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("บันทึกการปรับปรุงสต็อกเรียบร้อยแล้ว"),
                      backgroundColor: Color(0xFF4A9062),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D1D1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Confirm Adjustment",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMovementHistoryDialog(
    BuildContext context,
    Map<String, dynamic> stockItem,
  ) {
    List history = stockItem['history'] ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Stock Movement: ${stockItem['item']}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: 800,
          child: history.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    "ไม่มีประวัติการเคลื่อนไหว",
                    style: TextStyle(color: Color(0xFF86868B)),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🌟 Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Date In",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              "Ref",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Qty In",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              "Date Out (Qty)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "By",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 🌟 Table Rows
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: history.map((h) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      h['date_in'].toString(),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      h['ref'].toString(),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      h['qty_in'].toString(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4A9062),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      h['date_out'].toString(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFD97781),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      h['recorded_by'].toString(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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
              "Close",
              style: TextStyle(
                color: Color(0xFF1D1D1F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWarehouseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "เพิ่มคลังสินค้าใหม่",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: "ชื่อคลังสินค้า / โกดัง *",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "ที่อยู่จริง (Physical Addr) *",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: "จังหวัด (Province) *",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "ประเภทคลัง (Warehouse Type)",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ["PPN Own", "Shared (รวมถาวร)", "Client's Site", "Other"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {},
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: "ชื่อผู้ติดต่อ",
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: "เบอร์โทรศัพท์",
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
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
              "ยกเลิก",
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
              "บันทึกคลังสินค้า",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
