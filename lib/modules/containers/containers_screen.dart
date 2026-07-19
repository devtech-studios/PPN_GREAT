import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class ContainersScreen extends StatefulWidget {
  const ContainersScreen({super.key});

  @override
  State<ContainersScreen> createState() => _ContainersScreenState();
}

class _ContainersScreenState extends State<ContainersScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = false;
  bool _isSaving = false;

  String _searchText = "";
  int? _selectedContainerId;
  String _activeTab = "Tracking";

  List<Map<String, dynamic>> _containers = [];
  Map<String, dynamic>? _selectedContainerDetail;
  Map<String, dynamic> _editingContainer = {};
  List<Map<String, dynamic>> _activeProjects = [];
  List<Map<String, dynamic>> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _fetchContainers();
    _fetchActiveProjects();
    _fetchWarehouses();
  }

  Future<void> _fetchContainers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(ContainerEndpoints.index);
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        setState(() {
          _containers = List<Map<String, dynamic>>.from(data);
          if (_containers.isNotEmpty) {
            if (_selectedContainerId == null ||
                !_containers.any((c) => c['id'] == _selectedContainerId)) {
              _selectedContainerId = _containers[0]['id'];
            }
          } else {
            _selectedContainerId = null;
            _selectedContainerDetail = null;
            _editingContainer = {};
          }
        });

        if (_selectedContainerId != null) {
          await _fetchContainerDetail(_selectedContainerId!);
        }
      }
    } catch (e) {
      debugPrint("Error fetching containers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchContainerDetail(int id) async {
    try {
      final response = await _api.get(ContainerEndpoints.show(id));
      if (response.data['success'] == true) {
        setState(() {
          _selectedContainerDetail = Map<String, dynamic>.from(
            response.data['data'],
          );
          _editingContainer = Map<String, dynamic>.from(response.data['data']);
        });
      }
    } catch (e) {
      debugPrint("Error fetching container detail: $e");
    }
  }

  Future<void> _fetchActiveProjects() async {
    try {
      final response = await _api.get(ProjectEndpoints.index);
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        setState(() {
          _activeProjects = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error fetching active projects: $e");
    }
  }

  Future<void> _fetchWarehouses() async {
    try {
      final response = await _api.get(InventoryEndpoints.warehouses);
      if (response.data['success'] == true) {
        final List data = response.data['data'] ?? [];
        setState(() {
          _warehouses = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error fetching warehouses for container receipt: $e");
    }
  }

  Future<void> _routeGoodsToWarehouse({
    required int containerId,
    required int projectId,
    required int productItemId,
    required int warehouseId,
    required int qty,
  }) async {
    final response = await _api.post(
      ContainerEndpoints.routeGoods(containerId),
      data: {
        'project_id': projectId,
        'product_item_id': productItemId,
        'qty_total_received': qty,
        'routing': [
          {'type': 'inventory', 'qty': qty, 'warehouse_id': warehouseId},
        ],
      },
    );

    if (response.data['success'] == true) {
      _showSuccessSnackBar(
        "✓ รับสินค้าจากตู้เข้าโกดังและบันทึก Stock IN เรียบร้อย",
      );
      await _fetchContainerDetail(containerId);
    }
  }

  void _showReceiveGoodsDialog(
    BuildContext context,
    Map<String, dynamic> container,
  ) {
    final projects = List<Map<String, dynamic>>.from(
      container['projects'] ?? [],
    );
    int? selectedProjectId = projects.length == 1
        ? projects.first['id'] as int?
        : null;
    int? selectedProductId;
    int? selectedWarehouseId = _warehouses.length == 1
        ? _warehouses.first['id'] as int?
        : null;
    String qtyText = '';
    String? errorText;
    bool isSubmitting = false;

    List<Map<String, dynamic>> productsForProject() {
      if (selectedProjectId == null) return [];
      final project = projects.firstWhere(
        (row) => row['id'] == selectedProjectId,
        orElse: () => <String, dynamic>{},
      );
      return List<Map<String, dynamic>>.from(project['product_items'] ?? []);
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final products = productsForProject();
          if (selectedProductId != null &&
              !products.any((row) => row['id'] == selectedProductId)) {
            selectedProductId = null;
          }

          return AlertDialog(
            title: const Text(
              'Receive Container Goods into Warehouse | รับสินค้าจากตู้เข้าโกดัง',
            ),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedProjectId,
                    decoration: const InputDecoration(
                      labelText: 'Project in this container | โครงการในตู้นี้',
                    ),
                    items: projects
                        .map(
                          (project) => DropdownMenuItem<int>(
                            value: project['id'] as int,
                            child: Text(
                              '${project['project_code'] ?? project['id']} - ${project['customer']?['name'] ?? ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setDialogState(() {
                      selectedProjectId = value;
                      selectedProductId = null;
                      errorText = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedProductId,
                    decoration: const InputDecoration(
                      labelText: 'Product received | สินค้าที่รับเข้า',
                    ),
                    items: products
                        .map(
                          (product) => DropdownMenuItem<int>(
                            value: product['id'] as int,
                            child: Text(
                              product['name']?.toString() ??
                                  'Product ${product['id']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setDialogState(() {
                      selectedProductId = value;
                      errorText = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedWarehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Destination warehouse | โกดังปลายทาง',
                    ),
                    items: _warehouses
                        .map(
                          (warehouse) => DropdownMenuItem<int>(
                            value: warehouse['id'] as int,
                            child: Text(
                              warehouse['name']?.toString() ??
                                  'Warehouse ${warehouse['id']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setDialogState(() {
                      selectedWarehouseId = value;
                      errorText = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity received | จำนวนที่รับจริง',
                      errorText: errorText,
                    ),
                    onChanged: (value) => qtyText = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancel | ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final qty = int.tryParse(qtyText);
                        if (selectedProjectId == null ||
                            selectedProductId == null ||
                            selectedWarehouseId == null ||
                            qty == null ||
                            qty < 1) {
                          setDialogState(() {
                            errorText =
                                'Select project, product, warehouse and quantity > 0.';
                          });
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        try {
                          await _routeGoodsToWarehouse(
                            containerId: container['id'] as int,
                            projectId: selectedProjectId!,
                            productItemId: selectedProductId!,
                            warehouseId: selectedWarehouseId!,
                            qty: qty,
                          );
                          if (dialogContext.mounted)
                            Navigator.pop(dialogContext);
                        } catch (e) {
                          debugPrint('Error routing container goods: $e');
                          setDialogState(() {
                            isSubmitting = false;
                            errorText =
                                'Unable to receive goods. Check whether this item was already routed.';
                          });
                        }
                      },
                child: Text(
                  isSubmitting
                      ? 'Receiving... | กำลังรับเข้า...'
                      : 'Confirm Stock IN | ยืนยันรับเข้า',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveContainerChanges() async {
    if (_selectedContainerId == null) return;
    setState(() => _isSaving = true);
    try {
      final response = await _api.put(
        ContainerEndpoints.update(_selectedContainerId!),
        data: _editingContainer,
      );
      if (response.data['success'] == true) {
        _showSuccessSnackBar("✓ บันทึกข้อมูลเรียบร้อยแล้ว");
        await _fetchContainers();
      }
    } catch (e) {
      debugPrint("Error updating container: $e");
      _showErrorSnackBar("เกิดข้อผิดพลาดในการบันทึกข้อมูล");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _advanceContainerStep(String nextStatus) async {
    if (_selectedContainerId == null) return;
    setState(() => _isSaving = true);
    try {
      // 1. บันทึกฟิลด์วันที่ปัจจุบันก่อนเปลี่ยนขั้นตอน
      await _api.put(
        ContainerEndpoints.update(_selectedContainerId!),
        data: _editingContainer,
      );

      // 2. เลื่อนสถานะตู้สินค้า
      final response = await _api.patch(
        ContainerEndpoints.step(_selectedContainerId!),
        data: {
          'status': nextStatus,
          if (nextStatus == 'Delivered')
            'warehouse_arrival':
                _editingContainer['warehouse_arrival'] ??
                DateTime.now().toString().split(' ').first,
        },
      );
      if (response.data['success'] == true) {
        _showSuccessSnackBar(
          "✓ เลื่อนขั้นตอนการขนส่งเรียบร้อยแล้ว -> $nextStatus",
        );
        await _fetchContainers();
      }
    } catch (e) {
      debugPrint("Error advancing container step: $e");
      _showErrorSnackBar("เกิดข้อผิดพลาดในการเลื่อนขั้นตอน");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredShipments() {
    if (_searchText.isEmpty) return _containers;
    return _containers
        .where(
          (c) =>
              c['container_code'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ||
              (c['container_no'] ?? '').toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ||
              (c['vessel_name'] ?? '').toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ),
        )
        .toList();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4A9062),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD97781),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredShipments = _getFilteredShipments();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: รายการตู้คอนเทนเนอร์
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
                              fontWeight: FontWeight.w600,
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
                        "Logistics Tracking",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Create Container | สร้างตู้สินค้า',
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF5B7BD5),
                        ),
                        onPressed: () => _showCreateShipmentDialog(context),
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
                      hintText: "ค้นหา Shipment, เลขตู้...",
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
                  child: _isLoading && _containers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : filteredShipments.isEmpty
                      ? const Center(
                          child: Text(
                            "ไม่พบรายการ",
                            style: TextStyle(color: Color(0xFF86868B)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredShipments.length,
                          itemBuilder: (context, index) {
                            final s = filteredShipments[index];
                            final isSelected = _selectedContainerId == s['id'];

                            String status = s['status'] ?? 'Factory to Port';

                            Color statusColor = const Color(0xFF86868B);
                            Color statusBg = const Color(
                              0xFFE2E2E2,
                            ).withOpacity(0.5);

                            if (status == 'Delivered') {
                              statusColor = const Color(0xFF4A9062);
                              statusBg = const Color(
                                0xFFB7E4C7,
                              ).withOpacity(0.3);
                            } else if (status == 'Sailing') {
                              statusColor = const Color(0xFF2563EB);
                              statusBg = const Color(0xFFDBEAFE);
                            } else if (status == 'Port to Warehouse') {
                              statusColor = const Color(0xFF7C3AED);
                              statusBg = const Color(0xFFF3E8FF);
                            } else if (status == 'Factory to Port') {
                              statusColor = const Color(0xFFD97706);
                              statusBg = const Color(0xFFFEF3C7);
                            }

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedContainerId = s['id'];
                                });
                                _fetchContainerDetail(s['id']);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFFAEC4FA,
                                        ).withOpacity(0.15)
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
                                          s['container_code'] ?? 'CNT-???',
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
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusBg,
                                            borderRadius: BorderRadius.circular(
                                              6,
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
                                    const SizedBox(height: 8),
                                    Text(
                                      s['container_no'] ??
                                          "Pending Container No.",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF1D1D1F),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month_outlined,
                                          size: 14,
                                          color: Color(0xFF86868B),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "ETA: ${s['eta'] == null ? 'TBA' : _formatDateString(s['eta'])}",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
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
          // 2. RIGHT PANEL: Logistics Flow & Forms
          // ==========================================
          Expanded(
            child: Builder(
              builder: (context) {
                final detail = _selectedContainerDetail;
                if (_isLoading && detail == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (detail == null) {
                  return const Center(
                    child: Text(
                      "กรุณาเลือกรายการตู้สินค้า",
                      style: TextStyle(color: Color(0xFF86868B)),
                    ),
                  );
                }

                String currentStatus = detail['status'] ?? 'Factory to Port';
                bool trackingDone = currentStatus != 'Factory to Port';
                bool planDone =
                    currentStatus == 'Port to Warehouse' ||
                    currentStatus == 'Delivered';
                bool customsDone =
                    currentStatus == 'Delivered' ||
                    (detail['customs_cleared'] == true ||
                        detail['customs_cleared'] == 1);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Shipment & Tracking",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D1D1F),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Shipment Code: ${detail['container_code'] ?? ''} | เลขตู้: ${detail['container_no'] ?? 'Pending Container No.'}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5B7BD5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildFlowTab(
                              "Tracking",
                              "ติดตามสถานะ (Tracking)",
                              trackingDone,
                            ),
                            _buildFlowDivider(),
                            _buildFlowTab(
                              "Plan",
                              "แผนโหลดตู้ (Container Plan)",
                              planDone,
                            ),
                            _buildFlowDivider(),
                            _buildFlowTab(
                              "Customs",
                              "ขาเข้าศุลกากร (Customs)",
                              customsDone,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildActiveForm(detail),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FORMS BUILDERS
  // =========================================================

  Widget _buildActiveForm(Map<String, dynamic> detail) {
    if (_activeTab == "Tracking") return _buildTrackingForm(detail);
    if (_activeTab == "Plan") return _buildContainerPlanForm(detail);
    if (_activeTab == "Customs") return _buildCustomsForm(detail);
    return const SizedBox.shrink();
  }

  // 🌟 แบบฟอร์มแบบสเตปเชื่อม API
  Widget _buildTrackingForm(Map<String, dynamic> detail) {
    final String currentStatus = detail['status'] ?? 'Factory to Port';

    return Container(
      key: const ValueKey("Tracking"),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFAEC4FA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Color(0xFF5B7BD5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "สถานะปัจจุบัน: $currentStatus",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      "อัปเดตและติดตามข้อมูลการขนส่งตู้สินค้าในแต่ละขั้นตอน",
                      style: TextStyle(color: Color(0xFF86868B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 48, color: Color(0xFFF4F5F7)),

          // ==========================================
          // ขั้นตอนที่ 1: โรงงานส่งสินค้าไปท่าเรือจีน (Factory to Port)
          // ==========================================
          _buildStepSection(
            stepNumber: "1",
            title: "โรงงานส่งสินค้าไปท่าเรือจีน (Factory to Port)",
            isActive: currentStatus == 'Factory to Port',
            isPassed: currentStatus != 'Factory to Port',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerField(
                        "วันที่เริ่มออกจากโรงงาน (Factory Departure)",
                        _editingContainer['factory_departure'],
                        Icons.calendar_today,
                        currentStatus == 'Factory to Port',
                        (val) => setState(
                          () => _editingContainer['factory_departure'] = val,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildTrackingField(
                        "เลขอ้างอิงขนส่งจีน (China Domestic Tracking No.)",
                        "เช่น SF123456789",
                        initialValue: _editingContainer['domestic_tracking'],
                        icon: Icons.edit_road_outlined,
                        isHighlight: currentStatus == 'Factory to Port',
                        onChanged: (val) =>
                            _editingContainer['domestic_tracking'] = val,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildDatePickerField(
                        "วันที่ตู้ถึงท่าเรือจีน (Port Arrival China)",
                        _editingContainer['port_arrival_china'],
                        Icons.calendar_today,
                        false,
                        (val) => setState(
                          () => _editingContainer['port_arrival_china'] = val,
                        ),
                      ),
                    ),
                  ],
                ),
                if (currentStatus == 'Factory to Port') ...[
                  const SizedBox(height: 24),
                  Center(
                    child: _buildButton(
                      "✓ บันทึกและออกเรือสินค้า (Set Sailing)",
                      const Color(0xFF2563EB),
                      Colors.white,
                      icon: Icons.directions_boat,
                      onTap: () {
                        if (_editingContainer['factory_departure'] == null ||
                            _editingContainer['factory_departure']
                                .toString()
                                .isEmpty) {
                          _showErrorSnackBar(
                            "กรุณากรอกวันที่ออกจากโรงงานก่อนเปลี่ยนขั้นตอน",
                          );
                          return;
                        }
                        _advanceContainerStep('Sailing');
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ==========================================
          // ขั้นตอนที่ 2: ระหว่างการเดินเรือทางทะเล (Sailing)
          // ==========================================
          _buildStepSection(
            stepNumber: "2",
            title: "ระหว่างการเดินเรือทางทะเล (Sailing)",
            isActive: currentStatus == 'Sailing',
            isPassed:
                currentStatus == 'Port to Warehouse' ||
                currentStatus == 'Delivered',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTrackingField(
                        "ชื่อเรือบรรทุกสินค้า (Vessel Name)",
                        "เช่น COSCO SHIPPING",
                        initialValue: _editingContainer['vessel_name'],
                        icon: Icons.directions_boat_outlined,
                        isHighlight: currentStatus == 'Sailing',
                        onChanged: (val) =>
                            _editingContainer['vessel_name'] = val,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildTrackingField(
                        "ท่าเรือต้นทาง (Port of Origin)",
                        "เช่น Port of Shenzhen",
                        initialValue: _editingContainer['port_origin'],
                        icon: Icons.anchor,
                        onChanged: (val) =>
                            _editingContainer['port_origin'] = val,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildTrackingField(
                        "ท่าเรือปลายทาง (Port of Destination)",
                        "เช่น Bangkok Port",
                        initialValue: _editingContainer['port_destination'],
                        icon: Icons.location_on_outlined,
                        onChanged: (val) =>
                            _editingContainer['port_destination'] = val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerField(
                        "วันเรือออกเดินทางจริง (ETD)",
                        _editingContainer['etd'],
                        Icons.calendar_month,
                        false,
                        (val) => setState(() => _editingContainer['etd'] = val),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildDatePickerField(
                        "วันเรือคาดว่าจะถึงท่าไทย (ETA) *",
                        _editingContainer['eta'],
                        Icons.calendar_month,
                        currentStatus == 'Sailing',
                        (val) => setState(() => _editingContainer['eta'] = val),
                      ),
                    ),
                  ],
                ),
                if (currentStatus == 'Sailing') ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(
                        "บันทึกข้อมูลทั่วไป",
                        Colors.white,
                        const Color(0xFF1D1D1F),
                        icon: Icons.save,
                        isOutlined: true,
                        onTap: _saveContainerChanges,
                      ),
                      const SizedBox(width: 16),
                      _buildButton(
                        "✓ เรือถึงท่าเรือไทย (Set Port Arrival)",
                        const Color(0xFF7C3AED),
                        Colors.white,
                        icon: Icons.warehouse_outlined,
                        onTap: () {
                          if (_editingContainer['eta'] == null ||
                              _editingContainer['eta'].toString().isEmpty) {
                            _showErrorSnackBar(
                              "กรุณากรอกวันที่ ETA ก่อนแจ้งเรือถึงท่า",
                            );
                            return;
                          }
                          _advanceContainerStep('Port to Warehouse');
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ==========================================
          // ขั้นตอนที่ 3: ด่านท่าเรือไทย & พิธีการศุลกากร (Port to Warehouse)
          // ==========================================
          _buildStepSection(
            stepNumber: "3",
            title: "ด่านท่าเรือไทย & พิธีการศุลกากร (Port to Warehouse)",
            isActive: currentStatus == 'Port to Warehouse',
            isPassed: currentStatus == 'Delivered',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerField(
                        "วันที่เรือถึงไทยจริง (Actual Arrival) *",
                        _editingContainer['actual_arrival'],
                        Icons.calendar_today,
                        false,
                        (val) => setState(
                          () => _editingContainer['actual_arrival'] = val,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildDatePickerField(
                        "วันที่ผ่านพิธีการศุลกากร (Customs Cleared Date)",
                        _editingContainer['customs_date'],
                        Icons.assignment_turned_in_outlined,
                        false,
                        (val) => setState(() {
                          _editingContainer['customs_date'] = val;
                          _editingContainer['customs_cleared'] = true;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerField(
                        "วันสินค้าเข้าคลังจริง (Warehouse Arrival)",
                        _editingContainer['warehouse_arrival'],
                        Icons.local_shipping,
                        currentStatus == 'Port to Warehouse',
                        (val) => setState(
                          () => _editingContainer['warehouse_arrival'] = val,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "สถานะศุลกากร (Customs Cleared)",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Switch(
                              value:
                                  _editingContainer['customs_cleared'] ==
                                      true ||
                                  _editingContainer['customs_cleared'] == 1,
                              onChanged: (val) {
                                setState(() {
                                  _editingContainer['customs_cleared'] = val;
                                  if (val &&
                                      (_editingContainer['customs_date'] ==
                                              null ||
                                          _editingContainer['customs_date']
                                              .toString()
                                              .isEmpty)) {
                                    _editingContainer['customs_date'] =
                                        DateTime.now()
                                            .toString()
                                            .split(' ')
                                            .first;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (currentStatus == 'Port to Warehouse') ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(
                        "บันทึกข้อมูลทั่วไป",
                        Colors.white,
                        const Color(0xFF1D1D1F),
                        icon: Icons.save,
                        isOutlined: true,
                        onTap: _saveContainerChanges,
                      ),
                      const SizedBox(width: 16),
                      _buildButton(
                        "✓ ส่งมอบสินค้าเข้าคลังไทย (Set Delivered)",
                        const Color(0xFF10B981),
                        Colors.white,
                        icon: Icons.done_all,
                        onTap: () {
                          if (_editingContainer['actual_arrival'] == null ||
                              _editingContainer['actual_arrival']
                                  .toString()
                                  .isEmpty) {
                            _showErrorSnackBar(
                              "กรุณากรอกวันที่เรือถึงไทยจริงก่อนเสร็จสิ้นขั้นตอน",
                            );
                            return;
                          }
                          _advanceContainerStep('Delivered');
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ==========================================
          // ขั้นตอนที่ 4: ตู้สินค้าถึงคลังปลายทางสำเร็จ (Delivered)
          // ==========================================
          _buildStepSection(
            stepNumber: "4",
            title: "ตู้สินค้าถึงคลังไทยเรียบร้อยแล้ว (Delivered)",
            isActive: currentStatus == 'Delivered',
            isPassed: false,
            child: Column(
              children: [
                if (currentStatus == 'Delivered') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 64,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "ตู้สินค้าส่งถึงคลังไทยเรียบร้อยแล้ว (Delivered)",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "วันที่ถึงคลังสินค้าปลายทาง: ${_formatDateString(_editingContainer['warehouse_arrival'] ?? _editingContainer['updated_at'])}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  initialValue: _editingContainer['notes'],
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText:
                        "บันทึกข้อมูลเพิ่มเติมการจัดเก็บและคลังสินค้า (Notes)",
                    filled: true,
                    fillColor: const Color(0xFFF4F5F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => _editingContainer['notes'] = val,
                ),
                const SizedBox(height: 24),
                Center(
                  child: _buildButton(
                    "บันทึกข้อมูลทั่วไป / หมายเหตุ",
                    const Color(0xFF1D1D1F),
                    Colors.white,
                    icon: Icons.save,
                    onTap: _saveContainerChanges,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepSection({
    required String stepNumber,
    required String title,
    required bool isActive,
    required bool isPassed,
    required Widget child,
  }) {
    Color headerBg = const Color(0xFFF8FAFC);
    Color borderColor = const Color(0xFFE2E8F0);
    double borderWidth = 1.0;

    if (isActive) {
      headerBg = const Color(0xFFAEC4FA).withOpacity(0.08);
      borderColor = const Color(0xFF5B7BD5);
      borderWidth = 1.5;
    } else if (isPassed) {
      headerBg = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isPassed
                        ? const Color(0xFF10B981)
                        : (isActive
                              ? const Color(0xFF5B7BD5)
                              : const Color(0xFF86868B)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isPassed
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            stepNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? const Color(0xFF5B7BD5)
                          : (isPassed
                                ? const Color(0xFF047857)
                                : const Color(0xFF1D1D1F)),
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B7BD5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "กำลังดำเนินการ (Active)",
                      style: TextStyle(
                        color: Color(0xFF5B7BD5),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(24.0), child: child),
        ],
      ),
    );
  }

  // 🌟 แผนการโหลดตู้ดึงจาก DB
  Widget _buildContainerPlanForm(Map<String, dynamic> detail) {
    final List projects = detail['projects'] ?? [];

    return Container(
      key: const ValueKey("Plan"),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE4F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment, color: Color(0xFF6B4CA4)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Container Loading Plan (แผนบรรทุกตู้สินค้า)",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "รวมข้อมูลโครงการและใบสั่งซื้อสินค้าที่รวมส่งมาในตู้ใบนี้ (จำนวนโครงการที่ผูกไว้: ${projects.length} รายการ)",
                      style: const TextStyle(color: Color(0xFF86868B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 48, color: Color(0xFFF4F5F7)),

          if (projects.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  "ยังไม่มีการผูกโครงการใดๆ เข้ากับตู้สินค้าใบนี้",
                  style: TextStyle(color: Color(0xFF86868B), fontSize: 14),
                ),
              ),
            )
          else ...[
            const Text(
              "รายการโครงการที่บรรจุในตู้นี้ (Loaded Projects)",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        "รหัสโครงการ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "ชื่อลูกค้า",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "ชื่อโครงการ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "มูลค่าโครงการ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "สถานะโครงการ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: projects.map((p) {
                    final cust = p['customer'] != null
                        ? p['customer']['name']
                        : 'TBA';
                    double total = 0.0;
                    final rawTotal = p['order_value'] ?? p['grand_total'];
                    if (rawTotal != null) {
                      total = double.tryParse(rawTotal.toString()) ?? 0.0;
                    }

                    final List productItems = p['product_items'] ?? [];
                    final String productNames = productItems.isNotEmpty
                        ? productItems
                              .map((item) => item['name'] ?? '')
                              .join(', ')
                        : 'ไม่มีรายการสินค้า';

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            p['project_code']?.toString() ??
                                p['id']?.toString() ??
                                'PPN-???',
                          ),
                        ),
                        DataCell(Text(cust ?? '')),
                        DataCell(Text(productNames)),
                        DataCell(Text("฿ ${total.toStringAsFixed(2)}")),
                        DataCell(Text(p['status'] ?? '')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🌟 พิธีการศุลกากรเชื่อม API
  Widget _buildCustomsForm(Map<String, dynamic> detail) {
    bool isCleared =
        _editingContainer['customs_cleared'] == true ||
        _editingContainer['customs_cleared'] == 1;

    return Container(
      key: const ValueKey("Customs"),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFB7E4C7).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security, color: Color(0xFF4A9062)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Customs Clearance & Duties",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "รายละเอียดการเคลียร์ภาษีอากรขาเข้าที่ด่านศุลกากรไทย",
                      style: TextStyle(color: Color(0xFF86868B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 48, color: Color(0xFFF4F5F7)),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isCleared
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCleared
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCleared ? Icons.verified_user : Icons.warning_amber_rounded,
                  color: isCleared
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD97706),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCleared
                            ? "ผ่านพิธีการศุลกากรแล้ว (Customs Cleared)"
                            : "อยู่ระหว่างรอเคลียร์สินค้าที่ด่านศุลกากร",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCleared
                              ? const Color(0xFF047857)
                              : const Color(0xFFB45309),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCleared
                            ? "วันที่ดำเนินเรื่องผ่านสำเร็จ: ${_formatDateString(_editingContainer['customs_date'])}"
                            : "กำหนดส่งสินค้าคาดเดาจาก ETA: ${_formatDateString(_editingContainer['eta'])}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "สถานะการผ่านศุลกากร (Customs Cleared)",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Switch(
                        value: isCleared,
                        onChanged: (val) {
                          setState(() {
                            _editingContainer['customs_cleared'] = val;
                            if (val &&
                                (_editingContainer['customs_date'] == null ||
                                    _editingContainer['customs_date']
                                        .toString()
                                        .isEmpty)) {
                              _editingContainer['customs_date'] = DateTime.now()
                                  .toString()
                                  .split(' ')
                                  .first;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildDatePickerField(
                  "วันที่ผ่านพิธีการศุลกากร (Customs Cleared Date)",
                  _editingContainer['customs_date'],
                  Icons.calendar_month,
                  false,
                  (val) => setState(() {
                    _editingContainer['customs_date'] = val;
                    _editingContainer['customs_cleared'] = true;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: _editingContainer['notes'],
            maxLines: 3,
            decoration: InputDecoration(
              labelText:
                  "หมายเหตุ / ข้อมูลใบขนส่งสินค้าและรหัสเสียภาษี (Customs Info Notes)",
              filled: true,
              fillColor: const Color(0xFFF4F5F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => _editingContainer['notes'] = val,
          ),
          const SizedBox(height: 32),
          Center(
            child: _buildButton(
              "✓ บันทึกข้อมูลศุลกากร",
              const Color(0xFF1D1D1F),
              Colors.white,
              icon: Icons.save,
              onTap: _saveContainerChanges,
            ),
          ),
          if (detail['status'] == 'Delivered') ...[
            const SizedBox(height: 16),
            Center(
              child: _buildButton(
                'Receive Goods into Warehouse | รับสินค้าเข้าโกดัง',
                const Color(0xFF2563EB),
                Colors.white,
                icon: Icons.inventory_2_outlined,
                onTap: () => _showReceiveGoodsDialog(context, detail),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // HELPER WIDGETS & DIALOGS
  // =========================================================

  Widget _buildDatePickerField(
    String label,
    String? dateValue,
    IconData icon,
    bool isHighlight,
    Function(String) onDatePicked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isHighlight
                ? const Color(0xFF5B7BD5)
                : const Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: 'Select date: $label',
          child: InkWell(
            onTap: () async {
              DateTime initialDate = DateTime.now();
              if (dateValue != null && dateValue.toString().isNotEmpty) {
                try {
                  initialDate = DateTime.parse(dateValue);
                } catch (_) {}
              }
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                final formatted = picked.toString().split(' ').first;
                onDatePicked(formatted);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isHighlight
                    ? const Color(0xFFAEC4FA).withOpacity(0.15)
                    : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(12),
                border: isHighlight
                    ? Border.all(color: const Color(0xFF5B7BD5))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateValue == null || dateValue.toString().isEmpty
                        ? "เลือกวันที่"
                        : _formatDateString(dateValue),
                    style: TextStyle(
                      fontSize: 14,
                      color: dateValue == null || dateValue.toString().isEmpty
                          ? const Color(0xFF86868B)
                          : const Color(0xFF1D1D1F),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 18,
                    color: isHighlight
                        ? const Color(0xFF5B7BD5)
                        : const Color(0xFF86868B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingField(
    String label,
    String hint, {
    String? initialValue,
    IconData? icon,
    bool isHighlight = false,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isHighlight
                ? const Color(0xFF5B7BD5)
                : const Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: icon != null
                ? Icon(
                    icon,
                    size: 18,
                    color: isHighlight
                        ? const Color(0xFF5B7BD5)
                        : const Color(0xFF86868B),
                  )
                : null,
            filled: true,
            fillColor: isHighlight
                ? const Color(0xFFAEC4FA).withOpacity(0.15)
                : const Color(0xFFF4F5F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isHighlight
                  ? const BorderSide(color: Color(0xFF5B7BD5))
                  : BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowTab(String id, String title, bool isCompleted) {
    final isActive = _activeTab == id;
    Color bgColor = isActive
        ? const Color(0xFFAEC4FA).withOpacity(0.3)
        : Colors.transparent;
    Color textColor = isActive
        ? const Color(0xFF5B7BD5)
        : (isCompleted ? const Color(0xFF4A9062) : const Color(0xFF86868B));

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = id),
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

  // --- DIALOG: สร้าง Shipment ใหม่ ---
  void _showCreateShipmentDialog(BuildContext context) {
    String containerNo = "";
    String vesselName = "";
    String portOrigin = "Guangzhou Port";
    String portDestination = "Bangkok Port";
    String etdDate = "";
    String etaDate = "";
    List<int> selectedProjectIds = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "สร้างตู้สินค้า & การขนส่งใหม่ (Create Container)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "เลขตู้สินค้า / Container No. *",
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => containerNo = val,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "ชื่อเรือบรรทุกสินค้า / Vessel Name",
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) => vesselName = val,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: portOrigin,
                            decoration: InputDecoration(
                              labelText: "ท่าเรือต้นทาง (Origin)",
                              filled: true,
                              fillColor: const Color(0xFFF4F5F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => portOrigin = val,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: portDestination,
                            decoration: InputDecoration(
                              labelText: "ท่าเรือปลายทาง (Destination)",
                              filled: true,
                              fillColor: const Color(0xFFF4F5F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => portDestination = val,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "วันที่เดินทางคาดการณ์ (ETD/ETA)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  etdDate = picked.toString().split(' ').first;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F5F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    etdDate.isEmpty
                                        ? "ETD (วันเรือออก)"
                                        : _formatDateString(etdDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: etdDate.isEmpty
                                          ? const Color(0xFF86868B)
                                          : const Color(0xFF1D1D1F),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Color(0xFF86868B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(
                                  const Duration(days: 14),
                                ),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  etaDate = picked.toString().split(' ').first;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F5F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    etaDate.isEmpty
                                        ? "ETA (วันของถึงไทย)"
                                        : _formatDateString(etaDate),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: etaDate.isEmpty
                                          ? const Color(0xFF86868B)
                                          : const Color(0xFF1D1D1F),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Color(0xFF86868B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "เลือกโครงการที่บรรจุร่วมในตู้นี้ (Select Projects) *",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: _activeProjects.isEmpty
                          ? const Center(
                              child: Text(
                                "ไม่มีโครงการพร้อมส่งออก",
                                style: TextStyle(color: Color(0xFF86868B)),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _activeProjects.length,
                              itemBuilder: (ctx2, idx) {
                                final p = _activeProjects[idx];
                                final int pId = p['db_id'] ?? p['id'];
                                final bool isSelected = selectedProjectIds
                                    .contains(pId);

                                return CheckboxListTile(
                                  title: Text(
                                    "${p['project_code'] ?? 'PPN-???'} - ${p['customer'] is Map ? (p['customer']['name'] ?? 'No Customer') : (p['customer'] ?? 'No Customer')}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    p['name'] ?? '',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  value: isSelected,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selectedProjectIds.add(pId);
                                      } else {
                                        selectedProjectIds.remove(pId);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
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
                onPressed: () async {
                  if (containerNo.isEmpty) {
                    _showErrorSnackBar("กรุณากรอกเลขตู้สินค้า");
                    return;
                  }
                  if (selectedProjectIds.isEmpty) {
                    _showErrorSnackBar("กรุณาเลือกโครงการอย่างน้อย 1 โครงการ");
                    return;
                  }

                  final payload = {
                    "container_no": containerNo,
                    "vessel_name": vesselName,
                    "port_origin": portOrigin,
                    "port_destination": portDestination,
                    "etd": etdDate.isNotEmpty ? etdDate : null,
                    "eta": etaDate.isNotEmpty ? etaDate : null,
                    "project_ids": selectedProjectIds,
                  };

                  try {
                    final response = await _api.post(
                      ContainerEndpoints.store,
                      data: payload,
                    );
                    if (response.data['success'] == true) {
                      _showSuccessSnackBar(
                        "✓ บันทึกและสร้างตู้สินค้าเรียบร้อย",
                      );
                      Navigator.pop(context);
                      await _fetchContainers();
                    }
                  } catch (e) {
                    debugPrint("Error creating container: $e");
                    _showErrorSnackBar("เกิดข้อผิดพลาดในการสร้างตู้สินค้า");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D1D1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "บันทึก",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
