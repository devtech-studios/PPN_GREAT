import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ppn_great/core/api/api_client.dart';
import 'package:ppn_great/core/api/api_endpoints.dart';

class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) return int.tryParse(val) ?? 0;
  return int.tryParse(val.toString()) ?? 0;
}

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final ApiClient _api = ApiClient();
  String _searchText = "";
  int? _selectedProjectId;
  List<dynamic> _projects = [];
  List<dynamic> _rounds = [];
  List<dynamic> _warehouses = [];
  List<dynamic> _allStocks = [];
  bool _isLoading = true;

  // ฟอร์มจัดส่งแบบหลายรายการ (Multi-product Dispatch)
  String _deliveryAddress = "";
  String _dispatchDate = "";
  String _driverName = "";
  String _vehiclePlate = "";
  String _notes = "";
  List<Map<String, dynamic>> _dispatchItems = [];

  List<dynamic> _getFilteredProjects() {
    if (_searchText.isEmpty) return _projects;
    return _projects.where((p) {
      final code = (p['project_code'] ?? '').toString().toLowerCase();
      final customer = (p['customer']?['name'] ?? '').toString().toLowerCase();
      return code.contains(_searchText.toLowerCase()) ||
          customer.contains(_searchText.toLowerCase());
    }).toList();
  }

  int _getWarehouseStock(int? productItemId, int? warehouseId) {
    if (productItemId == null || warehouseId == null) return 0;
    for (var s in _allStocks) {
      if (s['product_item_id'] == productItemId &&
          s['warehouse_id'] == warehouseId) {
        return s['qty_in_stock'] ?? 0;
      }
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _dispatchDate = DateTime.now().toLocal().toString().split(' ').first;
    _initDispatchForm();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final pResponse = await _api.get(ProjectEndpoints.index);
      final rResponse = await _api.get(DeliveryEndpoints.index);
      final wResponse = await _api.get(InventoryEndpoints.warehouses);

      List<dynamic> allStocks = [];
      final warehousesList = wResponse.data['data'] ?? [];
      for (var w in warehousesList) {
        try {
          final stocksRes = await _api.get(
            InventoryEndpoints.warehouseStocks(_parseInt(w['id'])),
          );
          if (stocksRes.statusCode == 200) {
            final List data = stocksRes.data['data'] ?? [];
            allStocks.addAll(data);
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _projects = pResponse.data['data'] ?? [];
          _rounds = rResponse.data['data'] ?? [];
          _warehouses = warehousesList;
          _allStocks = allStocks;

          // Auto-select first project if none selected
          if (_selectedProjectId == null && _projects.isNotEmpty) {
            _selectedProjectId = _parseInt(_projects[0]['id']);
            final cust = _projects[0]['customer'];
            _deliveryAddress =
                cust?['billing_address'] ?? cust?['billing_address'] ?? '';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching data: $e"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _initDispatchForm() {
    _dispatchItems = [
      {"product_item_id": null, "qty": 0, "warehouse_id": null, "error": null},
    ];
    _driverName = "";
    _vehiclePlate = "";
    _notes = "";
  }

  void _loadProjectData(Map<String, dynamic> proj) {
    final cust = proj['customer'];
    _deliveryAddress =
        cust?['billing_address'] ?? cust?['billing_address'] ?? '';
    _initDispatchForm();
  }

  // ฟังก์ชันดึงข้อมูลจาก PO อัตโนมัติ
  void _autoFillRemainingFromPO(List<Map<String, dynamic>> products) {
    List<Map<String, dynamic>> newItems = [];
    for (var p in products) {
      int rem = p['total_qty'] - p['delivered_qty'];
      if (rem > 0) {
        newItems.add({
          "product_item_id": p['id'],
          "qty": rem,
          "warehouse_id": _warehouses.isNotEmpty ? _warehouses[0]['id'] : null,
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

  Future<void> _confirmRound(int roundId) async {
    try {
      final response = await _api.patch(DeliveryEndpoints.confirm(roundId));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ ยืนยันปล่อยรถ (In Transit) และหักสต็อกสำเร็จ!"),
            backgroundColor: Color(0xFF4A9062),
          ),
        );
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? "เกิดข้อผิดพลาด"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _completeRound(int roundId) async {
    try {
      final response = await _api.patch(DeliveryEndpoints.complete(roundId));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ ยืนยันส่งมอบสินค้าเสร็จสมบูรณ์เรียบร้อย!"),
            backgroundColor: Color(0xFF4A9062),
          ),
        );
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? "เกิดข้อผิดพลาด"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _saveRound() async {
    // Collect and format request payload
    final List<Map<String, dynamic>> itemsPayload = [];
    for (var item in _dispatchItems) {
      itemsPayload.add({
        "project_id": _selectedProjectId,
        "product_item_id": item['product_item_id'],
        "qty_to_deliver": item['qty'],
        "delivery_address": _deliveryAddress,
        "warehouse_id": item['warehouse_id'],
        "notes": _notes.isNotEmpty ? _notes : null,
      });
    }

    final payload = {
      "dispatch_date": _dispatchDate,
      "driver_name": _driverName.isNotEmpty ? _driverName : null,
      "vehicle_plate": _vehiclePlate.isNotEmpty ? _vehiclePlate : null,
      "notes": _notes.isNotEmpty ? _notes : null,
      "items": itemsPayload,
    };

    try {
      final response = await _api.post(DeliveryEndpoints.store, data: payload);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ บันทึกรอบจัดส่งใหม่เรียบร้อยแล้ว"),
            backgroundColor: Color(0xFF4A9062),
          ),
        );
        _initDispatchForm();
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? "เกิดข้อผิดพลาด"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredProjects = _getFilteredProjects();

    Map<String, dynamic> selectedProject;
    if (filteredProjects.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("ไม่มีข้อมูลโปรเจกต์ในการจัดส่ง")),
      );
    } else {
      selectedProject = filteredProjects.firstWhere(
        (p) => p['id'] == _selectedProjectId,
        orElse: () => filteredProjects[0],
      );
    }

    if (_deliveryAddress.isEmpty) {
      final cust = selectedProject['customer'];
      _deliveryAddress =
          cust?['billing_address'] ?? cust?['billing_address'] ?? '';
    }

    // Compute products list for Delivery Overview
    final List<Map<String, dynamic>> products = [];
    final List rawItems = selectedProject['product_items'] ?? [];
    for (var item in rawItems) {
      final int itemId = _parseInt(item['id']);
      final String itemName = item['name'] ?? 'ไม่มีชื่อสินค้า';
      final int totalQty = item['qty'] ?? 0;

      // Calculate delivered qty from _rounds
      int deliveredQty = 0;
      for (var r in _rounds) {
        final List rItems = r['items'] ?? [];
        for (var ri in rItems) {
          if (ri['product_item_id'] == itemId &&
              (r['status'] == 'Delivered' || r['status'] == 'In Transit')) {
            deliveredQty += _parseInt(ri['qty_to_deliver']);
          }
        }
      }

      products.add({
        "id": itemId,
        "name": itemName,
        "total_qty": totalQty,
        "delivered_qty": deliveredQty,
        "defect_qty": 0,
      });
    }

    int projectRoundsCount = 0;
    for (var r in _rounds) {
      final List rItems = r['items'] ?? [];
      final bool hasProjectItem = rItems.any(
        (ri) => ri['project_id'] == selectedProject['id'],
      );
      if (hasProjectItem) {
        projectRoundsCount++;
      }
    }
    int nextRound = projectRoundsCount + 1;

    Color orderStatusColor = const Color(0xFF86868B);
    Color orderStatusBg = const Color(0xFFF4F5F7);
    final String projStatus = selectedProject['status'] ?? 'Inquiry';
    if (projStatus == 'Production') {
      orderStatusColor = const Color(0xFFD08A2A);
      orderStatusBg = const Color(0xFFFDF3E1);
    } else if (projStatus == 'Delivered') {
      orderStatusColor = const Color(0xFF4A9062);
      orderStatusBg = const Color(0xFFB7E4C7).withOpacity(0.3);
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
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
                      final isSelected = _selectedProjectId == project['id'];

                      Color statusColor = const Color(0xFF86868B);
                      Color statusBg = const Color(0xFFF4F5F7);
                      final String status = project['status'] ?? 'Inquiry';
                      if (status == 'Production') {
                        statusColor = const Color(0xFFD08A2A);
                        statusBg = const Color(0xFFFDF3E1);
                      } else if (status == 'Delivered') {
                        statusColor = const Color(0xFF4A9062);
                        statusBg = const Color(0xFFB7E4C7).withOpacity(0.3);
                      }

                      return InkWell(
                        onTap: () => setState(() {
                          _selectedProjectId = project['id'];
                          _loadProjectData(project);
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
                                    project['project_code'] ??
                                        'PRJ-${project['id']}',
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
                                      status,
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
                                project['customer']?['name'] ?? 'ลูกค้าทั่วไป',
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
                                "Total Items: ${(project['product_items'] as List?)?.length ?? 0}",
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
                            "Project: ${selectedProject['project_code'] ?? 'PRJ-${selectedProject['id']}'} - ${selectedProject['customer']?['name'] ?? ''}",
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
                              projStatus == 'Production'
                                  ? Icons.local_shipping
                                  : Icons.info_outline,
                              size: 16,
                              color: orderStatusColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Status: $projStatus",
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
                              flex: 2,
                              child: _buildFormField(
                                "Driver Name",
                                TextFormField(
                                  initialValue: _driverName,
                                  onChanged: (val) => _driverName = val,
                                  decoration: _inputDeco(
                                    icon: Icons.person_outline,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _buildFormField(
                                "Vehicle Plate",
                                TextFormField(
                                  initialValue: _vehiclePlate,
                                  onChanged: (val) => _vehiclePlate = val,
                                  decoration: _inputDeco(
                                    icon: Icons.badge_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildFormField(
                                "Delivery Address",
                                TextFormField(
                                  key: Key("addr_$_selectedProjectId"),
                                  initialValue: _deliveryAddress,
                                  maxLines: 2,
                                  onChanged: (val) => _deliveryAddress = val,
                                  decoration: _inputDeco(
                                    icon: Icons.location_on_outlined,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildFormField(
                                "Notes (หมายเหตุเพิ่มเติม)",
                                TextFormField(
                                  initialValue: _notes,
                                  maxLines: 2,
                                  onChanged: (val) => _notes = val,
                                  decoration: _inputDeco(icon: Icons.notes),
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
                          if (item['product_item_id'] != null) {
                            var pData = products.firstWhere(
                              (p) => p['id'] == item['product_item_id'],
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
                                      flex: 3,
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
                                          DropdownButtonFormField<int>(
                                            isExpanded: true,
                                            value: item['product_item_id'],
                                            decoration: _inputDeco().copyWith(
                                              labelText:
                                                  'Delivery product ${index + 1}',
                                            ),
                                            hint: const Text(
                                              "เลือกสินค้าที่จะส่ง",
                                            ),
                                            items: products
                                                .map(
                                                  (p) => DropdownMenuItem<int>(
                                                    value: _parseInt(p['id']),
                                                    child: Text(
                                                      p['name'],
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                item['product_item_id'] = val;
                                                item['qty'] = 0;
                                                item['error'] = null;
                                              });
                                            },
                                          ),
                                          if (item['product_item_id'] != null)
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
                                    // 2. Dropdown เลือกคลังสินค้า
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Select Warehouse",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<int?>(
                                            isExpanded: true,
                                            value: item['warehouse_id'],
                                            decoration: _inputDeco().copyWith(
                                              labelText:
                                                  'Delivery warehouse ${index + 1}',
                                            ),
                                            hint: const Text(
                                              "เลือกคลังเพื่อตัดสต็อก",
                                            ),
                                            items: [
                                              const DropdownMenuItem<int?>(
                                                value: null,
                                                child: Text(
                                                  "ไม่ตัดสต็อก (Direct)",
                                                  style: TextStyle(
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                              ..._warehouses.map(
                                                (w) => DropdownMenuItem<int?>(
                                                  value: _parseInt(w['id']),
                                                  child: Text(
                                                    "${w['name']} (${w['location']?.toString().split(' ').first ?? ''})",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (val) {
                                              setState(() {
                                                item['warehouse_id'] = val;
                                              });
                                            },
                                          ),
                                          if (item['warehouse_id'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Text(
                                                "Stock in warehouse: ${_getWarehouseStock(item['product_item_id'], item['warehouse_id'])} pcs",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      _getWarehouseStock(
                                                            item['product_item_id'],
                                                            item['warehouse_id'],
                                                          ) >
                                                          0
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFFEF4444),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // 3. Qty Input + Quick Fill
                                    Expanded(
                                      flex: 2,
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
                                            decoration:
                                                _inputDeco(
                                                  errorText: item['error'],
                                                ).copyWith(
                                                  labelText:
                                                      'Delivery quantity ${index + 1}',
                                                ),
                                            onChanged: (val) => item['qty'] =
                                                int.tryParse(val) ?? 0,
                                          ),
                                          if (item['product_item_id'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Row(
                                                children: [
                                                  _buildQuickFillBtn(
                                                    "Half",
                                                    () => setState(() {
                                                      int maxDeliverable =
                                                          remainingQty;
                                                      if (item['warehouse_id'] !=
                                                          null) {
                                                        int
                                                        stock = _getWarehouseStock(
                                                          item['product_item_id'],
                                                          item['warehouse_id'],
                                                        );
                                                        maxDeliverable =
                                                            stock < remainingQty
                                                            ? stock
                                                            : remainingQty;
                                                      }
                                                      item['qty'] =
                                                          maxDeliverable ~/ 2;
                                                      item['error'] = null;
                                                    }),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  _buildQuickFillBtn(
                                                    "All",
                                                    () => setState(() {
                                                      int maxDeliverable =
                                                          remainingQty;
                                                      if (item['warehouse_id'] !=
                                                          null) {
                                                        int
                                                        stock = _getWarehouseStock(
                                                          item['product_item_id'],
                                                          item['warehouse_id'],
                                                        );
                                                        maxDeliverable =
                                                            stock < remainingQty
                                                            ? stock
                                                            : remainingQty;
                                                      }
                                                      item['qty'] =
                                                          maxDeliverable;
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
                              "product_item_id": null,
                              "qty": 0,
                              "warehouse_id": _warehouses.isNotEmpty
                                  ? _warehouses[0]['id']
                                  : null,
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
                                  if (item['product_item_id'] == null) {
                                    item['error'] = "Please select product";
                                    hasError = true;
                                  } else {
                                    var pData = products.firstWhere(
                                      (p) => p['id'] == item['product_item_id'],
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

                              // บันทึกข้อมูลไปยัง API
                              _saveRound();
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
                    child: () {
                      final projectRounds = _rounds.where((r) {
                        final List items = r['items'] ?? [];
                        return items.any(
                          (item) => item['project_id'] == selectedProject['id'],
                        );
                      }).toList();

                      if (projectRounds.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              "ยังไม่มีประวัติการจัดส่งในระบบ",
                              style: TextStyle(color: Color(0xFF86868B)),
                            ),
                          ),
                        );
                      }

                      return DataTable(
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 180,
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF7F9FC),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              "Round Info / Date",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Driver / Vehicle",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Product / Warehouse",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Qty / Status",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Actions",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: projectRounds.map((r) {
                          final List rItems = r['items'] ?? [];
                          final projItems = rItems
                              .where(
                                (ri) =>
                                    ri['project_id'] == selectedProject['id'],
                              )
                              .toList();

                          final String roundCode =
                              r['dispatch_code'] ?? 'DR-${r['id']}';
                          final String dispatchDateStr =
                              r['dispatch_date']?.toString().split('T').first ??
                              '';
                          final String driver = r['driver_name'] ?? 'ไม่ระบุ';
                          final String plate = r['vehicle_plate'] ?? '-';
                          final String status = r['status'] ?? 'Scheduled';

                          Color statusColor = const Color(0xFF86868B);
                          Color statusBg = const Color(0xFFF4F5F7);
                          if (status == 'In Transit') {
                            statusColor = const Color(0xFF2563EB);
                            statusBg = const Color(0xFFEFF6FF);
                          } else if (status == 'Delivered') {
                            statusColor = const Color(0xFF059669);
                            statusBg = const Color(0xFFF0FDF4);
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      roundCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      dispatchDateStr,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF86868B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      driver,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "ทะเบียน: $plate",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: projItems.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['product_item']?['name'] ??
                                                  'สินค้าทั่วไป',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              "คลัง: ${item['warehouse']?['name'] ?? 'Direct Shipped'}",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              DataCell(
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ...projItems.map((item) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Text(
                                            "${item['qty_to_deliver']} pcs",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                status == 'Scheduled'
                                    ? ElevatedButton.icon(
                                        onPressed: () =>
                                            _confirmRound(_parseInt(r['id'])),
                                        icon: const Icon(
                                          Icons.local_shipping,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          "Depart (ปล่อยรถ)",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF2563EB,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      )
                                    : status == 'In Transit'
                                    ? ElevatedButton.icon(
                                        onPressed: () =>
                                            _completeRound(_parseInt(r['id'])),
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          "Complete (ส่งสำเร็จ)",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF10B981,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Row(
                                        children: const [
                                          Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF10B981),
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "Done",
                                            style: TextStyle(
                                              color: Color(0xFF10B981),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    }(),
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
        Semantics(label: label, container: true, child: child),
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
