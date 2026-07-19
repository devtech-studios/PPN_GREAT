import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_error_handler.dart';

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
  // API client
  final ApiClient _api = ApiClient();
  bool _isLoading = false;
  List<dynamic> _warehouses = [];
  List<dynamic> _currentStock = [];
  List<dynamic> _activeProjects = [];

  String _searchText = "";
  dynamic _selectedWarehouseId;

  @override
  void initState() {
    super.initState();
    _fetchWarehouses();
    _fetchActiveProjects();
  }

  Future<void> _fetchWarehouses() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(InventoryEndpoints.warehouses);
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        setState(() {
          _warehouses = data;
          if (_warehouses.isNotEmpty) {
            final exists = _warehouses.any(
              (w) => w['id'] == _selectedWarehouseId,
            );
            if (!exists) {
              _selectedWarehouseId = _warehouses[0]['id'];
            }
            _fetchWarehouseStocks(_selectedWarehouseId);
          } else {
            _selectedWarehouseId = null;
            _currentStock = [];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching warehouses: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchWarehouseStocks(dynamic warehouseId) async {
    if (warehouseId == null) return;
    try {
      final int wId = warehouseId is int
          ? warehouseId
          : int.tryParse(warehouseId.toString()) ?? 0;
      if (wId == 0) return;
      final response = await _api.get(InventoryEndpoints.warehouseStocks(wId));
      if (response.data['success'] == true) {
        setState(() {
          _currentStock = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching warehouse stocks: $e");
    }
  }

  Future<void> _fetchActiveProjects() async {
    try {
      final response = await _api.get(ProjectEndpoints.index);
      if (response.data['success'] == true) {
        setState(() {
          _activeProjects = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching active projects: $e");
    }
  }

  Future<void> _addWarehouse({
    required String name,
    required String location,
  }) async {
    try {
      final response = await _api.post(
        InventoryEndpoints.warehouses,
        data: {'name': name, 'location': location},
      );

      if (response.data['success'] == true) {
        _fetchWarehouses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("เพิ่มคลังสินค้าใหม่เรียบร้อยแล้ว"),
              backgroundColor: Color(0xFF4A9062),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data['message'] ??
                    "เกิดข้อผิดพลาดในการสร้างคลังสินค้า",
              ),
              backgroundColor: const Color(0xFFD97781),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error adding warehouse: $e");
      if (mounted) {
        final errorMessage = ApiErrorHandler.parseError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFD97781),
          ),
        );
      }
    }
  }

  Future<void> _adjustStock({
    required int warehouseId,
    required int projectId,
    required int productItemId,
    required int qty,
    required String type, // IN, OUT, ADJUST
    required String notes,
    String? locationInWarehouse,
  }) async {
    try {
      final response = await _api.post(
        InventoryEndpoints.adjust,
        data: {
          'warehouse_id': warehouseId,
          'project_id': projectId,
          'product_item_id': productItemId,
          'qty': qty,
          'type': type,
          'notes': notes,
          if (locationInWarehouse != null && locationInWarehouse.isNotEmpty)
            'location_in_warehouse': locationInWarehouse,
        },
      );

      if (response.data['success'] == true) {
        _fetchWarehouseStocks(_selectedWarehouseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("บันทึกการปรับปรุงสต็อกเรียบร้อยแล้ว"),
              backgroundColor: Color(0xFF4A9062),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.data['message'] ?? "เกิดข้อผิดพลาดในการบันทึก",
              ),
              backgroundColor: const Color(0xFFD97781),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error adjusting stock: $e");
      if (mounted) {
        final errorMessage = ApiErrorHandler.parseError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFD97781),
          ),
        );
      }
    }
  }

  String _getLastReceivedDate(List stocks) {
    if (stocks.isEmpty) return 'ไม่มีข้อมูล';
    DateTime? latest;
    for (var s in stocks) {
      final dateStr = s['last_received_at'] ?? s['updated_at'];
      if (dateStr != null) {
        final dt = DateTime.tryParse(dateStr.toString());
        if (dt != null) {
          if (latest == null || dt.isAfter(latest)) {
            latest = dt;
          }
        }
      }
    }
    if (latest == null) return 'ไม่มีข้อมูล';
    return "${latest.day} ${_getMonthName(latest.month)} ${latest.year}";
  }

  String _getWarehouseType(Map<String, dynamic> w) {
    final String name = (w['name'] ?? '').toString().toLowerCase();
    if (name.contains('ราม 2') || name.contains('rama 2'))
      return 'PPN Own Warehouse (คลังหลัก)';
    if (name.contains('บางนา') || name.contains('bangna'))
      return 'Shared Warehouse';
    return 'PPN Own';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  List<dynamic> _getFilteredWarehouses() {
    if (_searchText.isEmpty) return _warehouses;
    return _warehouses
        .where(
          (w) =>
              (w['name'] ?? '').toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ||
              (w['location'] ?? '').toString().toLowerCase().contains(
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
      orElse: () => _warehouses.isNotEmpty
          ? Map<String, dynamic>.from(_warehouses[0])
          : <String, dynamic>{},
    );

    // คำนวณยอดรวมของคลังที่เลือก
    int totalSkus = _currentStock.length;
    int totalAvailableItems = 0;
    if (_currentStock.isNotEmpty) {
      for (var item in _currentStock) {
        final int inStock = item['qty_in_stock'] ?? 0;
        final int reserved = item['qty_reserved'] ?? 0;
        totalAvailableItems += (inStock - reserved);
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
                      final String province = (w['location'] ?? '')
                          .toString()
                          .split(' ')
                          .first;
                      final String typeStr = _getWarehouseType(w);
                      final String lastRec = isSelected
                          ? _getLastReceivedDate(_currentStock)
                          : 'เปิดเพื่อดู';

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedWarehouseId = w['id'];
                          });
                          _fetchWarehouseStocks(w['id']);
                        },
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
                                    "WH-${w['id']?.toString().padLeft(3, '0')}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFF5B7BD5)
                                          : const Color(0xFF86868B),
                                    ),
                                  ),
                                  Icon(
                                    Icons.warehouse_rounded,
                                    size: 16,
                                    color: isSelected
                                        ? const Color(0xFF5B7BD5)
                                        : const Color(0xFF86868B),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                w['name'] ?? '',
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
                                  Expanded(
                                    child: Text(
                                      province.isNotEmpty
                                          ? province
                                          : (w['location'] ?? ''),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF86868B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Type: $typeStr",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF86868B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Last received: $lastRec",
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
                            selectedWarehouse['name'] != null
                                ? "${selectedWarehouse['name']} (${selectedWarehouse['location']?.toString().split(' ').first ?? ''})"
                                : "กำลังโหลด...",
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
                          _getLastReceivedDate(_currentStock),
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
                    child: _currentStock.isEmpty
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
                              ...(_currentStock.map((stock) {
                                final skuStr =
                                    stock['product_item']?['sku'] ?? 'TBA';
                                final nameStr =
                                    stock['product_item']?['name'] ??
                                    'ไม่มีรายการสินค้า';
                                final arrivedQty = stock['qty_in_stock'] ?? 0;
                                final sentQty = stock['qty_reserved'] ?? 0;
                                final availableQty = arrivedQty - sentQty;

                                final String ownership =
                                    stock['project'] != null
                                    ? 'Client'
                                    : 'PPN Own Stock';
                                final String ref =
                                    stock['project']?['customer']?['name'] ??
                                    stock['project']?['project_code'] ??
                                    'PPN';

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
                                          skuStr,
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
                                          nameStr,
                                          style: const TextStyle(fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: _buildOwnershipBadge(
                                          ownership,
                                          ref,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          "$arrivedQty",
                                          style: const TextStyle(
                                            color: Color(0xFF4A9062),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          "$sentQty",
                                          style: const TextStyle(
                                            color: Color(0xFFD97781),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          "$availableQty",
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                                    BorderRadius.circular(8),
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
                              }).toList()),
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
    int? selectedProjectId;
    int? selectedProductItemId;
    int receivedQty = 0;
    String note = "";
    String locationInWarehouse = "";

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
                      value: type,
                      decoration: InputDecoration(
                        labelText: "Adjustment type | ประเภทการปรับปรุง",
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
                                "Write-off (ปรับยอดสต็อก)",
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
                    DropdownButtonFormField<int>(
                      value: selectedProjectId,
                      decoration: InputDecoration(
                        labelText: "Adjustment project | โครงการอ้างอิง",
                        hintText: "เลือกโปรเจกต์",
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _activeProjects
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p['id'] as int,
                              child: Text(
                                "${p['project_code'] ?? 'PRJ-${p['id']}'} - ${p['customer']?['name'] ?? 'ลูกค้าทั่วไป'}",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedProjectId = val;
                          selectedProductItemId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    if (selectedProjectId != null) ...[
                      const Text(
                        "เลือกรายการสินค้าในโปรเจกต์",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedProductItemId,
                        decoration: InputDecoration(
                          labelText: "Adjustment product | สินค้าที่ปรับ",
                          hintText: "เลือกสินค้า",
                          filled: true,
                          fillColor: const Color(0xFFF4F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: (() {
                          final proj = _activeProjects.firstWhere(
                            (p) => p['id'] == selectedProjectId,
                            orElse: () => null,
                          );
                          final List items = proj != null
                              ? (proj['product_items'] ?? [])
                              : [];
                          return items
                              .map(
                                (item) => DropdownMenuItem<int>(
                                  value: item['id'] as int,
                                  child: Text(
                                    "${item['sku'] ?? 'TBA'} - ${item['name'] ?? ''}",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList();
                        })(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedProductItemId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

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
                        labelText: "Adjustment quantity | จำนวนที่ปรับ",
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
                      "4. ที่ตั้งในคลังสินค้า (Location in Warehouse)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Warehouse location | ที่ตั้งในคลัง",
                        hintText: "เช่น Zone A-1",
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => locationInWarehouse = val,
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "5. หมายเหตุ (Reason)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Adjustment reason | เหตุผล",
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
                  if (selectedProjectId == null ||
                      selectedProductItemId == null ||
                      receivedQty == 0)
                    return;

                  String typeCode = 'IN';
                  if (type == "Stock Out (เบิกออก)") {
                    typeCode = 'OUT';
                  } else if (type == "Write-off (ปรับยอดสต็อก)") {
                    typeCode = 'ADJUST';
                  }

                  _adjustStock(
                    warehouseId: warehouse['id'] as int,
                    projectId: selectedProjectId!,
                    productItemId: selectedProductItemId!,
                    qty: receivedQty,
                    type: typeCode,
                    notes: note,
                    locationInWarehouse: locationInWarehouse,
                  );
                  Navigator.pop(context);
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
    List history = stockItem['movements'] ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Stock Movement: ${stockItem['product_item']?['name'] ?? ''}",
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
                            flex: 3,
                            child: Text(
                              "Date & Time",
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
                              "Type",
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
                              "Quantity",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              "Details / Reason",
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
                              "Recorded By",
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
                            final dateStr = h['created_at'] != null
                                ? DateTime.tryParse(h['created_at'].toString())
                                          ?.toLocal()
                                          .toString()
                                          .split('.')
                                          .first ??
                                      h['created_at'].toString()
                                : '-';
                            final typeStr = h['movement_type'] ?? 'IN';
                            final Color typeColor = typeStr == 'IN'
                                ? const Color(0xFF10B981)
                                : (typeStr == 'OUT'
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFF59E0B));
                            final notesStr =
                                h['notes'] ??
                                h['reference_type'] ??
                                'Manual Adjustment';
                            final byStr = h['creator']?['name'] ?? 'System';

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
                                    flex: 3,
                                    child: Text(
                                      dateStr,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: typeColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          typeStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: typeColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "${h['qty'] ?? 0}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: typeColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      notesStr,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      byStr,
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
    String name = "";
    String physicalAddr = "";
    String province = "";

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
                onChanged: (val) => name = val,
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
                onChanged: (val) => physicalAddr = val,
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
                onChanged: (val) => province = val,
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
            onPressed: () {
              if (name.isEmpty || physicalAddr.isEmpty || province.isEmpty)
                return;
              _addWarehouse(name: name, location: "$province $physicalAddr");
              Navigator.pop(context);
            },
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
