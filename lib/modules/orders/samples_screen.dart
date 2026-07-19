import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class SamplesScreen extends StatefulWidget {
  const SamplesScreen({super.key});

  @override
  State<SamplesScreen> createState() => _SamplesScreenState();
}

class _SamplesScreenState extends State<SamplesScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoadingProjects = false;
  bool _isLoadingSamples = false;
  List<dynamic> _projectsDb = [];
  List<dynamic> _dbSamples = [];

  String _searchText = "";
  String _selectedProjectId = "";

  final List<String> _sampleStages = [
    "Waiting from China",
    "Received from China",
    "Sent to Client",
    "Delivered to Client",
    "Approved by Client",
    "Rejected (Need Revision)",
  ];

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() {
      _isLoadingProjects = true;
    });
    try {
      final response = await _api.get(ProjectEndpoints.index, queryParameters: {
        if (_searchText.isNotEmpty) 'search': _searchText,
      });
      final body = response.data;
      if (body['success'] == true) {
        setState(() {
          _projectsDb = body['data'];
          if (_projectsDb.isNotEmpty) {
            final exists = _projectsDb.any((p) => p['project_code'] == _selectedProjectId);
            if (!exists) {
              _selectedProjectId = _projectsDb[0]['project_code'] ?? "";
              _fetchSamplesForProject(_projectsDb[0]['id']);
            } else {
              final match = _projectsDb.firstWhere((p) => p['project_code'] == _selectedProjectId);
              _fetchSamplesForProject(match['id']);
            }
          } else {
            _selectedProjectId = "";
            _dbSamples = [];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching projects for samples: $e");
    } finally {
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _fetchSamplesForProject(int pid) async {
    setState(() {
      _isLoadingSamples = true;
    });
    try {
      final response = await _api.get(SampleEndpoints.byProject(pid));
      final body = response.data;
      if (body['success'] == true) {
        setState(() {
          _dbSamples = body['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching samples: $e");
    } finally {
      setState(() {
        _isLoadingSamples = false;
      });
    }
  }

  Map<String, dynamic> _mapDbProjectToSampleMock(Map<String, dynamic> dbProject) {
    final List<dynamic> dbProducts = dbProject['product_items'] ?? [];
    final List<Map<String, dynamic>> mappedProducts = dbProducts.map((p) {
      final int pId = p['id'];
      final List<dynamic> productSamples = _dbSamples.where((s) => s['product_item_id'] == pId).toList();
      final List<Map<String, dynamic>> mappedSamples = productSamples.map((s) {
        String status = s['status'] ?? "Waiting from China";
        if (status == "Approved") status = "Approved by Client";
        if (status == "Rejected") status = "Rejected (Need Revision)";

        return {
          "id": s['sample_code'] ?? "CS-000",
          "db_id": s['id'],
          "attempt": s['attempt'] ?? 1,
          "type": s['sample_type'] ?? "Material Swatch",
          "origin": s['origin'] ?? "In-Stock",
          "supplier": s['supplier_name'] ?? "-",
          "status": status,
          "sent_date": s['sent_date'] ?? "-",
          "china_tracking": s['china_tracking'],
          "local_courier": s['local_courier'],
          "local_tracking": s['local_tracking'],
          "feedback": s['feedback'] ?? "ไม่มีข้อคิดเห็นเพิ่มเติม",
        };
      }).toList();

      return {
        "id": pId,
        "name": p['name'] ?? "สินค้าทั่วไป",
        "qty": "${p['qty'] ?? 0} ${p['unit'] ?? 'หน่วย'}",
        "specs": p['specs'] ?? "ไม่มีรายละเอียดข้อมูลจำเพาะ",
        "client_samples": mappedSamples,
      };
    }).toList();

    return {
      "id": dbProject['project_code'] ?? "PRJ-000",
      "db_id": dbProject['id'],
      "customer": dbProject['customer']?['name'] ?? "ลูกค้าทั่วไป",
      "status": dbProject['status'] ?? "Inquiry",
      "products": mappedProducts,
    };
  }

  List<Map<String, dynamic>> _getFilteredProjects() {
    return _projectsDb.map((p) => _mapDbProjectToSampleMock(p)).toList();
  }

  Future<void> _selectSentDate(
    BuildContext context,
    TextEditingController controller,
    Function(String) onDateSelected,
    StateSetter setDialogState,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1D1D1F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1D1D1F),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1D1D1F),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      controller.text = formatted;
      setDialogState(() {
        onDateSelected(formatted);
      });
    }
  }

  String _parseDateToDb(String dateStr) {
    if (dateStr.isEmpty || dateStr == "Today" || dateStr == "-") {
      final now = DateTime.now();
      return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    }
    final dbRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (dbRegExp.hasMatch(dateStr)) {
      return dateStr;
    }
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      return "${parts[2]}-${parts[1]}-${parts[0]}";
    }
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _getFilteredProjects();

    if (filteredProjects.isNotEmpty &&
        !filteredProjects.any((p) => p['id'] == _selectedProjectId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedProjectId = filteredProjects[0]['id']);
      });
    }

    Map<String, dynamic>? selectedProject;
    if (filteredProjects.isNotEmpty) {
      selectedProject = filteredProjects.firstWhere(
        (p) => p['id'] == _selectedProjectId,
        orElse: () => filteredProjects[0],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: Project List (Sidebar)
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    "Client Samples",
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
                    onChanged: (val) {
                      setState(() {
                        _searchText = val;
                      });
                      _fetchProjects();
                    },
                    decoration: InputDecoration(
                      hintText: "ค้นหารหัส, ชื่อลูกค้า...",
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: Color(0xFF86868B),
                      ),
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
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoadingProjects
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : filteredProjects.isEmpty
                          ? const Center(
                              child: Text(
                                "No projects found",
                                style: TextStyle(color: Color(0xFF86868B)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredProjects.length,
                              itemBuilder: (context, index) {
                                final p = filteredProjects[index];
                                final isSelected = _selectedProjectId == p['id'];

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedProjectId = p['id'];
                                    });
                                    _fetchSamplesForProject(p['db_id']);
                                  },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEC4899).withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(
                                            0xFFEC4899,
                                          ).withOpacity(0.5)
                                        : Colors.grey.withOpacity(0.15),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['id'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? const Color(0xFFD946EF)
                                            : const Color(0xFF86868B),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      p['customer'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Color(0xFF1D1D1F),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.science_outlined,
                                            size: 14,
                                            color: Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              p['status'],
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF334155),
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
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
          // 2. RIGHT PANEL: จัดการ Samples
          // ==========================================
          Expanded(
            child: selectedProject == null
                ? const Center(
                    child: Text(
                      "กรุณาเลือกโปรเจกต์",
                      style: TextStyle(color: Color(0xFF86868B)),
                    ),
                  )
                : _isLoadingSamples
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : SingleChildScrollView(
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
                                  "Client Sample Delivery Log",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D1D1F),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${selectedProject['id']} : ${selectedProject['customer']}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFD946EF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            // 🌟 ปุ่มบันทึกการส่งใหม่
                            _buildButton(
                              "Add Local Sample",
                              const Color(0xFF1D1D1F),
                              Colors.white,
                              icon: Icons.add,
                              onTap: () => _showAddLocalSampleDialog(
                                context,
                                selectedProject!,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // --- ลูปสินค้าหลัก ---
                        ...List.generate(selectedProject['products'].length, (
                          index,
                        ) {
                          final product = selectedProject!['products'][index];
                          return _buildProductBlock(product, index);
                        }),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- Widget Components ย่อย ---

  Widget _buildProductBlock(Map<String, dynamic> product, int index) {
    List samples = product['client_samples'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header สินค้า
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBCFE8).withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFFDB2777),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Specs: ${product['specs']}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // รายการ Samples ที่ส่งให้ลูกค้า
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                if (samples.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "ยังไม่มีประวัติการส่งตัวอย่างให้ลูกค้าในสินค้านี้",
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                  )
                else
                  ...samples.map((sData) => _buildSampleItem(sData)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleItem(Map<String, dynamic> sample) {
    bool isApproved = sample['status'] == "Approved by Client";
    bool isRejected = sample['status'].toString().contains("Rejected");
    bool isChina = sample['origin'] == "China";

    Color borderColor = const Color(0xFFE2E8F0);
    Color bgColor = const Color(0xFFF8FAFC);

    if (isApproved) {
      borderColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFF0FDF4);
    } else if (isRejected) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEF2F2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isApproved || isRejected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sample Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isApproved
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : (isRejected
                            ? const Color(0xFFEF4444).withOpacity(0.3)
                            : const Color(0xFFE2E8F0)),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: isApproved
                          ? const Color(0xFF059669)
                          : (isRejected
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      sample['type'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isApproved
                            ? const Color(0xFF064E3B)
                            : (isRejected
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 🌟 ป้ายแสดง "ครั้งที่ส่ง"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "ครั้งที่ ${sample['attempt'] ?? 1}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ป้าย Origin (China / Local)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isChina
                            ? const Color(0xFFFDE2E4)
                            : const Color(0xFFEAE4F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isChina ? "🇨🇳 From China" : "📦 In-Stock",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isChina
                              ? const Color(0xFF9D174D)
                              : const Color(0xFF6B4CA4),
                        ),
                      ),
                    ),
                  ],
                ),

                // 🌟 สถานะ Dropdown
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sample['status'],
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF475569),
                        size: 20,
                      ),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'Prompt',
                      ),
                      items: _sampleStages
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) async {
                        String dbStatus = val!;
                        if (dbStatus == "Approved by Client") dbStatus = "Approved";
                        if (dbStatus == "Rejected (Need Revision)") dbStatus = "Rejected";

                        try {
                          final response = await _api.patch(
                            SampleEndpoints.status(sample['db_id']),
                            data: {'status': dbStatus},
                          );
                          if (response.data['success'] == true) {
                            final match = _projectsDb.firstWhere((p) => p['project_code'] == _selectedProjectId);
                            _fetchSamplesForProject(match['id']);
                          }
                        } catch (e) {
                          debugPrint("Error updating sample status: $e");
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details & Tracking
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ฝั่งซ้าย: Tracking
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🌟 China Tracking (มีเฉพาะถ้ามาจากจีน)
                      if (isChina) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.flight_takeoff,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "From China to Office",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () => _showEditTrackingDialog(
                                      context,
                                      sample,
                                      isChinaTracking: true,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Supplier: ${sample['supplier']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sample['china_tracking'] ?? "-",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // 🌟 Local Tracking (ส่งให้ลูกค้า)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.local_shipping_outlined,
                                      size: 16,
                                      color: Color(0xFF64748B),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Delivery to Client",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () => _showEditTrackingDialog(
                                    context,
                                    sample,
                                    isChinaTracking: false,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Date Sent: ${sample['sent_date'] ?? '-'}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Courier: ${sample['local_courier'] ?? 'TBD'}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sample['local_tracking'] ?? "-",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // 🌟 ฝั่งขวา: Client Feedback & Notes
                Expanded(
                  flex: 6,
                  child: Container(
                    height: isChina ? 230 : 150, // ปรับความสูงให้พอดี
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? const Color(0xFFD1FAE5).withOpacity(0.5)
                          : (isRejected
                                ? const Color(0xFFFEE2E2).withOpacity(0.5)
                                : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isApproved
                            ? const Color(0xFF34D399)
                            : (isRejected
                                  ? const Color(0xFFF87171)
                                  : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isApproved
                                      ? Icons.thumb_up_alt_outlined
                                      : (isRejected
                                            ? Icons.warning_amber_rounded
                                            : Icons.comment_outlined),
                                  size: 16,
                                  color: isApproved
                                      ? const Color(0xFF059669)
                                      : (isRejected
                                            ? const Color(0xFFB91C1C)
                                            : const Color(0xFF1E293B)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Client Feedback / Notes",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isApproved
                                        ? const Color(0xFF064E3B)
                                        : (isRejected
                                              ? const Color(0xFF7F1D1D)
                                              : const Color(0xFF1E293B)),
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () =>
                                  _showUpdateFeedbackDialog(context, sample),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: const Text(
                                  "Update",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              sample['feedback'].toString().isEmpty
                                  ? "ยังไม่มีบันทึก feedback จากลูกค้า"
                                  : sample['feedback'],
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: sample['feedback'].toString().isEmpty
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF334155),
                                fontStyle: sample['feedback'].toString().isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
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
    );
  }

  // --- Dialogs ---

  void _showAddLocalSampleDialog(
    BuildContext context,
    Map<String, dynamic> project,
  ) {
    int selectedProduct = (project['products'] as List).isNotEmpty
        ? project['products'][0]['id']
        : 0;
    String selectedType = "Material Swatch";
    String courier = "";
    String trackNo = "";
    String note = "";
    // Default to today formatted as DD/MM/YYYY
    final now = DateTime.now();
    String sentDate = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

    final TextEditingController dateController = TextEditingController(text: sentDate);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Add Local Sample (In-Stock)"),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "บันทึกการส่งตัวอย่างที่มีในสต็อก (ไม่ต้องรอจากจีน) เพื่อให้ลูกค้าตรวจสอบ",
                      style: TextStyle(color: Color(0xFF86868B), fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      "1. Select Product",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedProduct,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: (project['products'] as List)
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p['id'] as int,
                              child: Text(p['name'] ?? 'สินค้า #${p['id']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedProduct = val!),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "1.5. Sample Type (ประเภทตัวอย่าง)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Pre-production Sample",
                          child: Text("Pre-production Sample (PPS)"),
                        ),
                        DropdownMenuItem(
                          value: "Material Swatch",
                          child: Text("Material Swatch (ชิ้นผ้า)"),
                        ),
                        DropdownMenuItem(
                          value: "3D Printed Mockup",
                          child: Text("3D Printed Mockup"),
                        ),
                        DropdownMenuItem(
                          value: "Other",
                          child: Text("Other (อื่นๆ)"),
                        ),
                      ],
                      onChanged: (val) =>
                          setDialogState(() => selectedType = val!),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "2. Delivery Information (To Client)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: dateController,
                            readOnly: true,
                            onTap: () => _selectSentDate(
                              context,
                              dateController,
                              (val) => sentDate = val,
                              setDialogState,
                            ),
                            decoration: InputDecoration(
                              hintText: "Date Sent",
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Color(0xFF86868B),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF4F5F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            decoration: InputDecoration(
                              hintText: "Courier (e.g. Grab)",
                              filled: true,
                              fillColor: const Color(0xFFF4F5F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => courier = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            decoration: InputDecoration(
                              hintText: "Tracking No.",
                              filled: true,
                              fillColor: const Color(0xFFF4F5F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => trackNo = val,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "3. Initial Remarks",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "e.g., ส่งเนื้อผ้า 3 สี ให้ลูกค้าเลือก",
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
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedProduct == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a product")),
                    );
                    return;
                  }

                  final int productItemId = selectedProduct;
                  final int projectDbId = project['db_id'];

                  try {
                    final String dbFormattedDate = _parseDateToDb(sentDate);
                    
                    final storeResponse = await _api.post(SampleEndpoints.store, data: {
                      'project_id': projectDbId,
                      'product_item_id': productItemId,
                      'sample_type': selectedType,
                      'origin': 'In-Stock',
                      'supplier_name': '-',
                      'status': 'Sent to Client',
                      'sent_date': dbFormattedDate,
                      'local_courier': courier.isEmpty ? 'TBD' : courier,
                      'local_tracking': trackNo.isEmpty ? '-' : trackNo,
                      'feedback': note.isEmpty ? 'ไม่มีคอมเมนต์เพิ่มเติม' : note,
                    });

                    if (storeResponse.data['success'] == true) {
                      _fetchSamplesForProject(projectDbId);
                    }
                  } catch (e) {
                    debugPrint("Error saving sample record: $e");
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D1D1F),
                ),
                child: const Text(
                  "Save Record",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTrackingDialog(
    BuildContext context,
    Map<String, dynamic> sample, {
    required bool isChinaTracking,
  }) {
    String courier = isChinaTracking
        ? (sample['supplier'] ?? "")
        : (sample['local_courier'] ?? "");
    String trackNo = isChinaTracking
        ? (sample['china_tracking'] ?? "")
        : (sample['local_tracking'] ?? "");

    trackNo = trackNo.contains("Wait") ? "" : trackNo;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isChinaTracking ? "Update China Tracking" : "Update Local Tracking",
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: courier,
                decoration: InputDecoration(
                  labelText: isChinaTracking
                      ? "Supplier / Courier"
                      : "Local Courier (ผู้จัดส่ง)",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => courier = val,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: trackNo,
                decoration: InputDecoration(
                  labelText: "Tracking Number",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => trackNo = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final Map<String, dynamic> updatePayload = {};
                if (isChinaTracking) {
                  updatePayload['supplier_name'] = courier;
                  updatePayload['china_tracking'] = trackNo;
                } else {
                  updatePayload['local_courier'] = courier;
                  updatePayload['local_tracking'] = trackNo;
                }

                final response = await _api.put(
                  SampleEndpoints.update(sample['db_id']),
                  data: updatePayload,
                );
                
                if (response.data['success'] == true) {
                  final match = _projectsDb.firstWhere((p) => p['project_code'] == _selectedProjectId);
                  _fetchSamplesForProject(match['id']);
                }
              } catch (e) {
                debugPrint("Error updating sample tracking: $e");
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D1F),
            ),
            child: const Text(
              "Save Updates",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateFeedbackDialog(
    BuildContext context,
    Map<String, dynamic> sample,
  ) {
    String feedback = sample['feedback'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Client Feedback"),
        content: SizedBox(
          width: 500,
          child: TextFormField(
            initialValue: feedback,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  "บันทึกคอมเมนต์จากลูกค้า เช่น ต้องปรับแก้สี หรือ อนุมัติแล้ว...",
              filled: true,
              fillColor: const Color(0xFFF4F5F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => feedback = val,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                String dbStatus = sample['status'] ?? "Waiting from China";
                if (dbStatus == "Approved by Client") dbStatus = "Approved";
                if (dbStatus == "Rejected (Need Revision)") dbStatus = "Rejected";

                final response = await _api.patch(
                  SampleEndpoints.status(sample['db_id']),
                  data: {
                    'status': dbStatus,
                    'feedback': feedback,
                  },
                );
                if (response.data['success'] == true) {
                  final match = _projectsDb.firstWhere((p) => p['project_code'] == _selectedProjectId);
                  _fetchSamplesForProject(match['id']);
                }
              } catch (e) {
                debugPrint("Error updating sample feedback: $e");
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D1F),
            ),
            child: const Text(
              "Save Feedback",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
              ? Border.all(color: const Color(0xFFE2E8F0))
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
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
