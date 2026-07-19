import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_error_handler.dart';
import 'create_project_screen.dart';

class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  // API client
  final ApiClient _api = ApiClient();
  bool _isLoadingList = false;
  bool _isLoadingDetail = false;
  List<dynamic> _projectsListDb = [];
  Map<String, dynamic>? _selectedProjectDetail;

  // UI state
  int _listViewState = 1;
  String _selectedStatusFilter = "All Status";
  String _searchText = "";
  String _selectedSort = "Target Date";
  bool _isTableView = false;
  String _selectedProjectId = "PPN-001";

  final ScrollController _tabsScrollController = ScrollController();
  final ScrollController _cardsScrollController = ScrollController();
  final bool _isCardsHovered = false;

  final List<String> _stages = [
    "All Active",
    "Inquiry",
    "Sample",
    "Production",
    "Shipping",
    "Distributing",
    "Delivered",
  ];

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  @override
  void dispose() {
    _tabsScrollController.dispose();
    _cardsScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjects() async {
    setState(() {
      _isLoadingList = true;
    });
    try {
      String? statusParam;
      if (_selectedStatusFilter != "All Status" && _selectedStatusFilter != "All Active") {
        statusParam = _selectedStatusFilter;
      }
      
      final response = await _api.get(ProjectEndpoints.index, queryParameters: {
        if (_searchText.isNotEmpty) 'search': _searchText,
        if (statusParam != null) 'status': statusParam,
        if (_selectedSort == "Target Date") ...{
          'sort': 'target_date',
          'order': 'asc',
        } else if (_selectedSort == "Order Value") ...{
          'sort': 'created_at',
          'order': 'desc',
        } else if (_selectedSort == "Date Created") ...{
          'sort': 'created_at',
          'order': 'asc',
        }
      });

      final body = response.data;
      if (body['success'] == true) {
        setState(() {
          _projectsListDb = body['data'];
          if (_projectsListDb.isNotEmpty) {
            final currentCode = _selectedProjectId;
            final exists = _projectsListDb.any((p) => p['project_code'] == currentCode);
            if (!exists) {
              _selectedProjectId = _projectsListDb[0]['project_code'] ?? "";
              final int dbId = _projectsListDb[0]['id'];
              _fetchProjectDetail(dbId);
            } else {
              final match = _projectsListDb.firstWhere((p) => p['project_code'] == currentCode);
              _fetchProjectDetail(match['id']);
            }
          } else {
            _selectedProjectId = "";
            _selectedProjectDetail = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching projects: $e");
      if (mounted) {
        final errorMessage = ApiErrorHandler.parseError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFD97781),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingList = false;
      });
    }
  }

  Future<void> _fetchProjectDetail(int id) async {
    setState(() {
      _isLoadingDetail = true;
    });
    try {
      final response = await _api.get(ProjectEndpoints.show(id));
      final body = response.data;
      if (body['success'] == true) {
        setState(() {
          _selectedProjectDetail = body['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching project detail: $e");
      if (mounted) {
        final errorMessage = ApiErrorHandler.parseError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFD97781),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingDetail = false;
      });
    }
  }

  int _safeInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) {
      return double.tryParse(val)?.toInt() ?? int.tryParse(val) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> _mapDbProjectToMock(Map<String, dynamic> dbProject) {
    final List<dynamic> dbProducts = dbProject['product_items'] ?? [];
    final List<Map<String, dynamic>> mappedProducts = dbProducts.map((p) {
      final List<dynamic> dbVariations = p['variations'] ?? [];
      final List<String> mappedVariations = dbVariations.map((v) {
        final optionName = v['option_name'] ?? "";
        final optionValue = v['option_value'] ?? "";
        return optionName.isNotEmpty ? "$optionName: $optionValue" : "";
      }).where((s) => s.isNotEmpty).toList();
      
      final List<dynamic> dbFiles = p['files'] ?? [];
      final List<Map<String, dynamic>> refFiles = [];
      final List<Map<String, dynamic>> artworkFiles = [];
      
      for (var f in dbFiles) {
        final String fileType = f['file_type'] ?? 'Reference';
        final String fileName = f['file_name'] ?? 'file';
        final String filePath = f['file_path'] ?? '';
        
        final mapFile = {
          "name": fileName,
          "path": filePath,
          "type": fileType,
          "icon": fileType == 'Artwork' ? Icons.brush_outlined : Icons.image_outlined,
          "color": fileType == 'Artwork' ? const Color(0xFFFDE2E4) : const Color(0xFFAEC4FA),
        };
        
        if (fileType == 'Artwork') {
          artworkFiles.add(mapFile);
        } else {
          refFiles.add(mapFile);
        }
      }

      return {
        "name": p['name'] ?? "สินค้าทั่วไป",
        "qty": "${p['qty'] ?? 0} ${p['unit'] ?? 'หน่วย'}",
        "target_date": p['target_date'] ?? "-",
        "specs": p['specs'] ?? "ไม่มีรายละเอียดข้อมูลจำเพาะ",
        "variations": mappedVariations,
        "ref_files": refFiles,
        "artwork_files": artworkFiles,
      };
    }).toList();

    final List<dynamic> dbAddRequests = dbProject['additional_requests'] ?? [];
    final List<Map<String, dynamic>> mappedAddRequests = dbAddRequests.map((r) {
      return {
        "desc": r['description'] ?? "",
        "cost": "+฿${(r['additional_cost'] ?? 0).toString()}",
      };
    }).toList();

    final List<dynamic> dbLogs = dbProject['activity_logs'] ?? [];
    final List<Map<String, dynamic>> mappedLogs = dbLogs.map((l) {
      return {
        "time": l['created_at'] != null ? l['created_at'].toString().split('T')[0] : "-",
        "user": l['user']?['full_name'] ?? "ระบบ",
        "text": l['description'] ?? "",
      };
    }).toList();

    int step = 0;
    final String status = dbProject['status'] ?? "Inquiry";
    if (status == "Inquiry") step = 0;
    else if (status == "Sample") step = 1;
    else if (status == "Production") step = 2;
    else if (status == "Shipping") step = 3;
    else if (status == "Distributing") step = 4;
    else if (status == "Delivered") step = 5;

    final String creditTerm = dbProject['credit_term'] ?? "Advance";
    final bool depositPaid = dbProject['deposit_paid'] ?? false;
    final bool balancePaid = dbProject['balance_paid'] ?? false;

    final bool ocpbOk = dbProject['ocpb_approved'] ?? false;
    final bool shippingMarkOk = dbProject['shipping_mark_approved'] ?? false;

    double totalVal = 0.0;
    for (var p in dbProducts) {
      final double qty = (p['qty'] ?? 0).toDouble();
      final double price = (p['unit_price'] ?? 0).toDouble();
      totalVal += qty * price;
    }
    String valStr = "฿${(totalVal / 1000000).toStringAsFixed(1)}M";
    if (totalVal < 1000000) {
      valStr = "฿${(totalVal / 1000).toStringAsFixed(0)}K";
    }

    return {
      "id": dbProject['project_code'] ?? "PPN-${dbProject['id']}",
      "db_id": dbProject['id'],
      "customer": dbProject['customer']?['name'] ?? "ลูกค้าทั่วไป",
      "status": status,
      "date": dbProject['created_at'] != null ? dbProject['created_at'].toString().split('T')[0] : "-",
      "due_date": dbProject['target_date'] ?? "-",
      "step": step,
      "is_active": status != "Cancelled",
      "is_paid": balancePaid,
      "days_left": _safeInt(dbProject['days_left']),
      "days_in_stage": _safeInt(dbProject['days_in_stage']),
      "order_value": valStr,
      "usage_location": dbProject['usage_location'] ?? "ไม่ระบุประเทศปลายทาง",
      "finance": {
        "deposit": depositPaid,
        "balance": balancePaid,
        "credit_term": creditTerm,
      },
      "compliance": {
        "ocpb": ocpbOk,
        "shipping_mark": shippingMarkOk,
      },
      "products": mappedProducts.isNotEmpty ? mappedProducts : [
        {
          "name": "ไม่มีรายการสินค้า",
          "qty": "0",
          "target_date": "-",
          "specs": "-",
          "variations": [],
          "ref_files": [],
          "artwork_files": [],
        }
      ],
      "additional_requests": mappedAddRequests,
      "logs": mappedLogs,
    };
  }

  Color _getUrgencyColor(int daysLeft, bool isActive) {
    if (!isActive) return const Color(0xFF86868B);
    if (daysLeft <= 0) return const Color(0xFF1D1D1F); // Delivered
    if (daysLeft <= 30) return const Color(0xFFEF4444); // Red
    if (daysLeft <= 45) return const Color(0xFFF59E0B); // Yellow
    return const Color(0xFF10B981); // Green
  }

  List<Map<String, dynamic>> _getFilteredProjects() {
    final List<Map<String, dynamic>> mapped = _projectsListDb.map((p) => _mapDbProjectToMock(p)).toList();
    return mapped;
  }



  void _scroll(ScrollController controller, double offset) {
    controller.animateTo(
      (controller.offset + offset).clamp(
        0.0,
        controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _getFilteredProjects();

    if (filteredProjects.isNotEmpty &&
        !filteredProjects.any((p) => p['id'] == _selectedProjectId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedProjectId = filteredProjects[0]['id']);
        }
      });
    }

    Map<String, dynamic>? selectedProject;
    if (_selectedProjectDetail != null) {
      selectedProject = _mapDbProjectToMock(_selectedProjectDetail!);
    } else if (filteredProjects.isNotEmpty) {
      selectedProject = filteredProjects.firstWhere(
        (p) => p['id'] == _selectedProjectId,
        orElse: () => filteredProjects[0],
      );
    }

    final bool isActive = selectedProject?['is_active'] ?? true;
    final int daysLeft = selectedProject?['days_left'] ?? 0;
    final String usageLocation =
        selectedProject?['usage_location'] ?? "Not Specified";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      // 🌟 ใช้ Stack เพื่อทำระบบ Drawer (Overlay)
      body: LayoutBuilder(
        builder: (context, constraints) {
          // คำนวณความกว้าง Drawer ตอนกาง (80% ของจอ สูงสุด 1200px)
          double drawerWidth = constraints.maxWidth * 0.8;
          if (drawerWidth > 1200) drawerWidth = 1200;

          return Stack(
            children: [
              // ==========================================
              // LAYER 1: โครงสร้างพื้นฐาน (ซ้าย List / ขวา Detail)
              // ==========================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ส่วนแสดง Project List ปกติ ---
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: _listViewState == 0
                        ? 0
                        : 380, // หดเหลือ 0 ถ้าพับเก็บ
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: _listViewState == 0
                        ? const SizedBox.shrink()
                        : _buildProjectListPanel(filteredProjects, 380),
                  ),

                  // --- ส่วนแสดง Project Detail ---
                  Expanded(
                    child: ClipRect(
                      child: selectedProject == null
                          ? const Center(
                              child: Text(
                                "กรุณาเลือกโปรเจกต์",
                                style: TextStyle(
                                  color: Color(0xFF86868B),
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : _buildProjectDetailPanel(
                              selectedProject,
                              isActive,
                              daysLeft,
                              usageLocation,
                            ),
                    ),
                  ),
                ],
              ),

              // ==========================================
              // LAYER 2: เงาดำ (Backdrop) ปรากฎเฉพาะตอนกาง Drawer
              // ==========================================
              if (_listViewState == 2)
                GestureDetector(
                  onTap: () => setState(
                    () => _listViewState = 1,
                  ), // กดที่เงาดำเพื่อหด Drawer กลับ
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),

              // ==========================================
              // LAYER 3: Drawer ลอยทับ (Project List แบบกางสุด)
              // ==========================================
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                top: 0,
                bottom: 0,
                left: _listViewState == 2
                    ? 0
                    : -drawerWidth, // ซ่อนไปทางซ้ายถ้าไม่ได้กาง
                child: Container(
                  width: drawerWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(5, 0),
                      ),
                    ],
                  ),
                  child: _buildProjectListPanel(filteredProjects, drawerWidth),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 🌟 แยก Widget: ส่วนแผงซ้าย (Project List) ---
  Widget _buildProjectListPanel(
    List<Map<String, dynamic>> filteredProjects,
    double currentWidth,
  ) {
    bool isCompact = currentWidth < 300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header & Collapse Buttons ---
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            top: 32,
            right: 16,
            bottom: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isCompact)
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Projects (${_projectsListDb.length})",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                  ],
                ),
              if (isCompact) const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_listViewState == 1)
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        color: Color(0xFF86868B),
                      ),
                      tooltip: "Collapse List",
                      onPressed: () => setState(() => _listViewState = 0),
                    ),
                  IconButton(
                    icon: Icon(
                      _listViewState == 2
                          ? Icons.close_fullscreen_rounded
                          : Icons.open_in_full_rounded,
                      color: const Color(0xFF86868B),
                    ),
                    tooltip: _listViewState == 2
                        ? "Default View"
                        : "Expand as Drawer",
                    onPressed: () => setState(
                      () => _listViewState = _listViewState == 2 ? 1 : 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- Search & Filters ---
        if (!isCompact)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: _listViewState == 2
                ? Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 16),
                      SizedBox(width: 140, child: _buildStatusDropdown()),
                      const SizedBox(width: 16),
                      SizedBox(width: 140, child: _buildSortDropdown()),
                    ],
                  )
                : Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildStatusDropdown()),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSortDropdown()),
                        ],
                      ),
                    ],
                  ),
          ),

        // --- Tabs & View Toggles ---
        if (_listViewState == 2 && !isCompact)
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              bottom: 16,
              right: 24,
              top: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ScrollConfiguration(
                    behavior: MouseDraggableScrollBehavior(),
                    child: SingleChildScrollView(
                      controller: _tabsScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _stages.map((stage) {
                          final isSelected =
                              _selectedStatusFilter == stage ||
                              (stage == "All Active" &&
                                  _selectedStatusFilter == "All Status");
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStatusFilter =
                                    stage == "All Active" ? "All Status" : stage;
                              });
                              _fetchProjects();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1D1D1F)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1D1D1F)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                stage,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF86868B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleBtn(Icons.grid_view_rounded, false),
                    _buildViewToggleBtn(Icons.table_rows_rounded, true),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.calendar_month_outlined,
                        size: 20,
                        color: Color(0xFF86868B),
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.timeline_rounded,
                        size: 20,
                        color: Color(0xFF86868B),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

        // --- Project List Items ---
        Expanded(
          child: filteredProjects.isEmpty
              ? const Center(
                  child: Text(
                    "No projects found",
                    style: TextStyle(
                      color: Color(0xFF86868B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : (_listViewState == 2 && !isCompact
                    ? (_isTableView
                          ? _buildTableViewExpanded(filteredProjects)
                          : _buildCardsAreaExpanded(filteredProjects))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final p = filteredProjects[index];
                          final isSelected =
                              _selectedProjectId == p['id'] &&
                              _listViewState != 2;
                          final isItemActive = p['is_active'] ?? true;

                          Color statusColor = const Color(0xFF5B7BD5);
                          Color statusBg = const Color(
                            0xFFAEC4FA,
                          ).withOpacity(0.3);
                          if (!isItemActive) {
                            statusColor = const Color(0xFF86868B);
                            statusBg = const Color(0xFFE2E2E2).withOpacity(0.5);
                          } else if (p['status'] == 'Ordered' ||
                              p['status'] == 'Production' ||
                              p['status'] == 'Shipping') {
                            statusColor = const Color(0xFF4A9062);
                            statusBg = const Color(0xFFB7E4C7).withOpacity(0.3);
                          } else if (p['status'] == 'Inquiry') {
                            statusColor = const Color(0xFFD97781);
                            statusBg = const Color(0xFFFDE2E4).withOpacity(0.5);
                          } else if (p['status'] == 'Delivered') {
                            statusColor = const Color(0xFF1D1D1F);
                            statusBg = const Color(0xFFE2E2E2).withOpacity(0.5);
                          }

                          final productCount = (p['products'] as List).length;
                          final firstProductName = p['products'][0]['name'];
                          final urgencyColor = _getUrgencyColor(
                            p['days_left'],
                            isItemActive,
                          );

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedProjectId = p['id'];
                                if (_listViewState == 2) _listViewState = 1;
                              });
                              _fetchProjectDetail(p['db_id']);
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: urgencyColor,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              p['id'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? const Color(0xFF5B7BD5)
                                                    : const Color(0xFF86868B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusBg,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isItemActive
                                                  ? p['status']
                                                  : "Cancelled",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isCompact) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          p['customer'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: isItemActive
                                                ? const Color(0xFF1D1D1F)
                                                : const Color(0xFF86868B),
                                            decoration: isItemActive
                                                ? null
                                                : TextDecoration.lineThrough,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          productCount > 1
                                              ? "$firstProductName (+${productCount - 1} รายการ)"
                                              : firstProductName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF86868B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .calendar_today_outlined,
                                                    size: 12,
                                                    color: urgencyColor,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      "Due: ${p['due_date']}",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: urgencyColor,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "${p['days_in_stage']}d in stage",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF86868B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )),
        ),
      ],
    );
  }

  // --- 🌟 2 ฟังก์ชันที่เคยหายไป ---
  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() => _searchText = value);
        _fetchProjects();
      },
      decoration: InputDecoration(
        hintText: "Search ID, Customer...",
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _buildViewToggleBtn(IconData icon, bool isTable) {
    bool isSelected = _isTableView == isTable;
    return InkWell(
      onTap: () => setState(() => _isTableView = isTable),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatusFilter,
          isExpanded: true,
          icon: const Icon(
            Icons.filter_list,
            size: 16,
            color: Color(0xFF64748B),
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w600,
            fontFamily: 'Prompt',
          ),
          items:
              [
                    "All Status",
                    "Inquiry",
                    "Sample",
                    "Production",
                    "Shipping",
                    "Delivered",
                  ]
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: (newValue) {
            setState(() => _selectedStatusFilter = newValue!);
            _fetchProjects();
          },
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          isExpanded: true,
          icon: const Icon(Icons.sort, size: 16, color: Color(0xFF64748B)),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w600,
            fontFamily: 'Prompt',
          ),
          items: ["Target Date", "Order Value", "Days in Stage", "Date Created"]
              .map(
                (String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (newValue) {
            setState(() => _selectedSort = newValue!);
            _fetchProjects();
          },
        ),
      ),
    );
  }

  // --- 🌟 แยก Widget: ส่วนแผงขวา (Project Detail) ---
  Widget _buildProjectDetailPanel(
    Map<String, dynamic> selectedProject,
    bool isActive,
    int daysLeft,
    String usageLocation,
  ) {
    // ดึงข้อมูล Finance & Compliance ออกมา
    final Map<String, dynamic> finance =
        selectedProject['finance'] ??
        {"deposit": false, "balance": false, "credit_term": "Cash"};
    final Map<String, dynamic> compliance =
        selectedProject['compliance'] ??
        {"ocpb": false, "shipping_mark": false};

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useVerticalHeader = screenWidth < 1200;

    final headerLeft = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_listViewState == 0)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: const Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    color: Color(0xFF1D1D1F),
                    size: 24,
                  ),
                  tooltip: "Show Projects List",
                  onPressed: () => setState(() => _listViewState = 1),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: !isActive
                    ? const Color(0xFFE2E2E2).withOpacity(0.5)
                    : const Color(0xFF1D1D1F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? selectedProject['status'] : "Cancelled",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: !isActive
                      ? const Color(0xFF1D1D1F)
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (isActive &&
                selectedProject['status'] != 'Delivered' &&
                daysLeft > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97781).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD97781)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Color(0xFFD97781),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Delivery in $daysLeft days",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97781),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "${selectedProject['id']} : ${selectedProject['customer']}",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: isActive
                ? const Color(0xFF1D1D1F)
                : const Color(0xFF86868B),
            letterSpacing: -0.5,
            decoration: isActive ? null : TextDecoration.lineThrough,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Color(0xFF86868B),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                "Usage Location: $usageLocation",
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );

    final headerRight = Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildButton(
          "Edit",
          Colors.white,
          const Color(0xFF1D1D1F),
          isOutlined: true,
          icon: Icons.edit_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateProjectScreen(projectId: selectedProject!['db_id']),
              ),
            ).then((_) {
              _fetchProjects();
            });
          },
        ),
        _buildButton(
          "Re-order",
          Colors.white,
          const Color(0xFF1D1D1F),
          isOutlined: true,
          onTap: () {},
        ),
        _buildButton(
          "Create New Project",
          const Color(0xFF1D1D1F),
          Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateProjectScreen(),
              ),
            );
          },
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header & Actions ---
          useVerticalHeader
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerLeft,
                    const SizedBox(height: 24),
                    headerRight,
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: headerLeft),
                    const SizedBox(width: 24),
                    headerRight,
                  ],
                ),
          const SizedBox(height: 48),

          // --- Section 1: Tracking Pipeline ---
          const Text(
            "Project Tracking",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          _buildTrackingPipeline(
            context,
            selectedProject,
            finance,
            compliance,
            isActive,
          ),
          const SizedBox(height: 48),

          // --- Section 2: Products List & Request Sample ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Products in this Project",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              _buildButton(
                "Request Sample",
                const Color(0xFFF4F5F7),
                const Color(0xFF1D1D1F),
                icon: Icons.science_outlined,
                onTap: () => _showRequestSampleDialog(context, selectedProject),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(selectedProject['products'].length, (index) {
            final product = selectedProject['products'][index];
            return _buildProductDetailCard(index, product);
          }),

          // --- Section 3: Additional Requests (Extra Costs) ---
          if ((selectedProject['additional_requests'] as List?)?.isNotEmpty ??
              false) ...[
            const SizedBox(height: 24),
            const Text(
              "Additional Requests & Extra Costs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF3E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD08A2A).withOpacity(0.5),
                ),
              ),
              child: Column(
                children: (selectedProject['additional_requests'] as List)
                    .map<Widget>((req) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "• ${req['desc']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1D1D1F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              req['cost'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFD08A2A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 48),

          // --- Section 4: Activity Log & Notes ---
          const Text(
            "Activity Log & Notes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E2E2)),
            ),
            child: Column(
              children: [
                ...((selectedProject['logs'] as List?)?.map((log) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFF4F5F7),
                          child: Icon(
                            log['user'] == 'System'
                                ? Icons.settings_system_daydream
                                : Icons.person,
                            size: 16,
                            color: const Color(0xFF86868B),
                          ),
                        ),
                        title: Text(
                          log['text'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        subtitle: Text(
                          "${log['user']} • ${log['time']}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                      );
                    }).toList() ??
                    []),
                const Divider(height: 1, color: Color(0xFFE2E2E2)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF5B7BD5),
                        child: Text("P", style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText:
                                "Add a manual work note (tagged to your name)...",
                            hintStyle: const TextStyle(
                              color: Color(0xFF86868B),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF4F5F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildButton(
                        "Add Note",
                        const Color(0xFF1D1D1F),
                        Colors.white,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          if (isActive)
            Center(
              child: TextButton.icon(
                onPressed: () =>
                    _confirmCancelProject(context, selectedProject),
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 16,
                  color: Color(0xFFD97781),
                ),
                label: const Text(
                  "Cancel this project",
                  style: TextStyle(
                    color: Color(0xFFD97781),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFD97781),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- Grid View (ตอนกางเต็มจอ) ---
  Widget _buildCardsAreaExpanded(List<Map<String, dynamic>> projects) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double spacing = 16.0;
        double cardWidth = (constraints.maxWidth - (spacing * 3)) / 4;

        List<Widget> allCards = projects
            .map((p) => _buildProjectCardFull(p, cardWidth))
            .toList();
        int columnCount = (allCards.length / 2).ceil();
        List<Widget> columns = [];
        for (int i = 0; i < columnCount; i++) {
          int firstIndex = i * 2;
          int secondIndex = firstIndex + 1;
          columns.add(
            Container(
              width: cardWidth,
              margin: EdgeInsets.only(
                right: i == columnCount - 1 ? 0 : spacing,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  allCards[firstIndex],
                  if (secondIndex < allCards.length) ...[
                    SizedBox(height: spacing),
                    allCards[secondIndex],
                  ],
                ],
              ),
            ),
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            ScrollConfiguration(
              behavior: MouseDraggableScrollBehavior(),
              child: SingleChildScrollView(
                controller: _cardsScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns,
                ),
              ),
            ),
            Positioned(
              left: 8,
              child: IgnorePointer(
                ignoring: !_isCardsHovered,
                child: AnimatedOpacity(
                  opacity: _isCardsHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: _buildArrowBtn(
                    Icons.chevron_left,
                    () =>
                        _scroll(_cardsScrollController, -(cardWidth + spacing)),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              child: IgnorePointer(
                ignoring: !_isCardsHovered,
                child: AnimatedOpacity(
                  opacity: _isCardsHovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: _buildArrowBtn(
                    Icons.chevron_right,
                    () => _scroll(_cardsScrollController, cardWidth + spacing),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Table View (ตอนกางเต็มจอ) ---
  Widget _buildTableViewExpanded(List<Map<String, dynamic>> projects) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Project No",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Customer",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Order Value",
                      style: TextStyle(
                        color: Color(0xFF64748B),
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
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Due Date",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...projects.map(
              (p) => InkWell(
                onTap: () {
                  setState(() {
                    _selectedProjectId = p['id'];
                    _listViewState = 1;
                  });
                  _fetchProjectDetail(p['db_id']);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF8FAFC)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          p['id'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p['customer'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p['order_value'] ?? "TBD",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
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
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p['status'],
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p['days_left'] <= 0
                              ? "Delivered"
                              : "Due in ${p['days_left']}d",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getUrgencyColor(
                              p['days_left'],
                              p['is_active'],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Pipeline สถานะโปรเจกต์ (ปรับเพิ่มส่วน Tracking ขวา)
  // ==========================================
  Widget _buildTrackingPipeline(
    BuildContext context,
    Map<String, dynamic> project,
    Map<String, dynamic> finance,
    Map<String, dynamic> compliance,
    bool isActive,
  ) {
    int currentStep = project['step'] ?? 0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useVerticalLayout = screenWidth < 1300;

    final opSteps = [
      "Inquiry",
      "Sample",
      "Production",
      "Shipping",
      "Distributing",
      "Delivered",
    ];

    Widget stepperWidget = Stack(
      children: [
        Positioned(
          top: 14,
          left: 40,
          right: 40,
          child: Row(
            children: List.generate(opSteps.length - 1, (index) {
              bool isCompleted = index < currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  color: !isActive
                      ? const Color(0xFFE2E2E2)
                      : (isCompleted
                            ? const Color(0xFF4A9062)
                            : const Color(0xFFF4F5F7)),
                ),
              );
            }),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(opSteps.length, (index) {
            bool isCompleted = index < currentStep;
            bool isCurrent = index == currentStep;
            Color nodeColor = !isActive
                ? const Color(0xFFE2E2E2)
                : (isCompleted
                      ? const Color(0xFF4A9062)
                      : (isCurrent
                            ? const Color(0xFF1D1D1F)
                            : const Color(0xFFF4F5F7)));

            return GestureDetector(
              onTap: () {
                if (!isActive) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Cannot update a cancelled project.",
                      ),
                    ),
                  );
                  return;
                }
                if (index != currentStep) {
                  _confirmStepChange(
                    context,
                    project,
                    index,
                    opSteps[index],
                  );
                }
              },
              child: SizedBox(
                width: 70,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: nodeColor,
                        shape: BoxShape.circle,
                        border: (isCurrent && isActive)
                            ? Border.all(
                                color: const Color(0xFFAEC4FA),
                                width: 4,
                              )
                            : Border.all(color: Colors.white, width: 2),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      opSteps[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: (isCurrent || isCompleted) && isActive
                            ? const Color(0xFF1D1D1F)
                            : const Color(0xFF86868B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );

    Widget detailsWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === ส่วนการเงินและเทอม ===
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Financial & Terms",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF86868B),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "💳 Credit: ${finance['credit_term'] ?? 'Cash'}",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5B7BD5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFinanceBadge(
                "Deposit",
                finance['deposit'] ?? false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFinanceBadge(
                "Balance",
                finance['balance'] ?? false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // === ส่วนการทำตามข้อกำหนดและโลจิสติกส์ ===
        const Text(
          "Compliance & Labels",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF86868B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildChecklistBadge(
                "OCPB (สคบ.)",
                compliance['ocpb'] ?? false,
                () => _confirmComplianceUpdate(
                  context,
                  project,
                  'ocpb',
                  "OCPB (สคบ.)",
                  !(compliance['ocpb'] ?? false),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChecklistBadge(
                "Shipping Mark",
                compliance['shipping_mark'] ?? false,
                () => _confirmComplianceUpdate(
                  context,
                  project,
                  'shipping_mark',
                  "Shipping Mark",
                  !(compliance['shipping_mark'] ?? false),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: useVerticalLayout
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                stepperWidget,
                const SizedBox(height: 32),
                const Divider(height: 1, color: Color(0xFFF4F5F7)),
                const SizedBox(height: 32),
                detailsWidget,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: stepperWidget,
                ),
                Container(
                  width: 1.5,
                  height: 140,
                  color: const Color(0xFFF4F5F7),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                ),
                Expanded(
                  flex: 4,
                  child: detailsWidget,
                ),
              ],
            ),
    );
  }

  // --- ป้ายกำกับการเงิน (อ่านอย่างเดียว) ---
  Widget _buildFinanceBadge(String label, bool isReceived) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isReceived
            ? const Color(0xFFB7E4C7).withOpacity(0.3)
            : const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReceived
              ? const Color(0xFF4A9062).withOpacity(0.5)
              : const Color(0xFFE2E2E2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isReceived ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isReceived
                ? const Color(0xFF4A9062)
                : const Color(0xFF86868B),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isReceived ? "Received" : "Pending",
                  style: TextStyle(
                    fontSize: 10,
                    color: isReceived
                        ? const Color(0xFF4A9062)
                        : const Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 🌟 ป้ายกำกับ Checklist (OCPB / Shipping Mark) ที่สามารถกดได้ ---
  Widget _buildChecklistBadge(
    String label,
    bool isChecked,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isChecked
                ? const Color(0xFF10B981).withOpacity(0.5)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isChecked
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 16,
              color: isChecked
                  ? const Color(0xFF059669)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isChecked
                          ? const Color(0xFF059669)
                          : const Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isChecked ? "Confirmed" : "Pending",
                    style: TextStyle(
                      fontSize: 10,
                      color: isChecked
                          ? const Color(0xFF059669)
                          : const Color(0xFF94A3B8),
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

  // --- Dialog ยืนยันการอัปเดต Checklist ---
  void _confirmComplianceUpdate(
    BuildContext context,
    Map<String, dynamic> project,
    String key,
    String label,
    bool targetValue,
  ) {
    String statusStr = targetValue ? "Confirmed / Approved" : "Pending";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Update $label",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "ต้องการอัปเดตสถานะ $label เป็น '$statusStr' ใช่หรือไม่?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF86868B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                project['compliance'] ??= {};
                project['compliance'][key] = targetValue;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D1F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Dialog ยืนยันการเปลี่ยนสถานะ Pipeline ---
  void _confirmStepChange(
    BuildContext context,
    Map<String, dynamic> project,
    int targetStep,
    String targetStepName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Update Tracking Status",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "คุณต้องการเปลี่ยนสถานะโปรเจกต์เป็น '$targetStepName' ใช่หรือไม่?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF86868B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close confirm dialog
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final response = await _api.patch(
                  ProjectEndpoints.status(project['db_id']),
                  data: {"status": targetStepName},
                );

                Navigator.pop(context); // Close loading spinner

                if (response.data['success'] == true) {
                  // Fetch updated project details and refresh projects list
                  await _fetchProjectDetail(project['db_id']);
                  _fetchProjects();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Status updated to $targetStepName"),
                      backgroundColor: const Color(0xFF4A9062),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("อัปเดตสถานะไม่สำเร็จ: ${response.data['error']?['message'] ?? 'ข้อผิดพลาดนิรนาม'}"),
                      backgroundColor: const Color(0xFFD97781),
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context); // Close loading spinner
                debugPrint("Error updating project status: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("เกิดข้อผิดพลาดในการเชื่อมต่อ: $e"),
                    backgroundColor: const Color(0xFFD97781),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B7BD5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailCard(int index, Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF4F5F7))),
            ),
            child: Row(
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
                const SizedBox(width: 16),
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildBoxedInfo("Quantity", product['qty']),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBoxedInfo(
                        "Target Date",
                        product['target_date'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildBoxedInfo("Specific Requirements", product['specs']),
                if ((product['variations'] as List?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 24),
                  const Text(
                    "Variations",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF86868B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (product['variations'] as List).map<Widget>((v) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          v,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1D1D1F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Reference Files",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF86868B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if ((product['ref_files'] as List?)?.isEmpty ?? true)
                            const Text(
                              "No reference files attached",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF86868B),
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            Column(
                              children: (product['ref_files'] as List)
                                  .map<Widget>((file) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: _buildFileCard(
                                        file['name'],
                                        file['type'],
                                        file['icon'],
                                        file['color'],
                                        isFullWidth: true,
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Artwork Files",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF86868B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if ((product['artwork_files'] as List?)?.isEmpty ??
                              true)
                            const Text(
                              "No artwork files attached",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF86868B),
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            Column(
                              children: (product['artwork_files'] as List)
                                  .map<Widget>((file) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: _buildFileCard(
                                        file['name'],
                                        file['type'],
                                        file['icon'],
                                        file['color'],
                                        isFullWidth: true,
                                      ),
                                    );
                                  })
                                  .toList(),
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

  Widget _buildBoxedInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF86868B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1D1D1F),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard(
    String fileName,
    String type,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1D1D1F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCardFull(Map<String, dynamic> p, double width) {
    final bool isItemActive = p['is_active'] ?? true;
    final int daysLeft = p['days_left'] ?? 0;
    Color urgencyColor = _getUrgencyColor(daysLeft, isItemActive);

    Color statusColor = const Color(0xFF5B7BD5);
    Color statusBg = const Color(0xFFAEC4FA).withOpacity(0.3);
    if (!isItemActive) {
      statusColor = const Color(0xFF86868B);
      statusBg = const Color(0xFFE2E2E2).withOpacity(0.5);
    } else if (p['status'] == 'Ordered' ||
        p['status'] == 'Production' ||
        p['status'] == 'Shipping') {
      statusColor = const Color(0xFF4A9062);
      statusBg = const Color(0xFFB7E4C7).withOpacity(0.3);
    } else if (p['status'] == 'Inquiry') {
      statusColor = const Color(0xFFD97781);
      statusBg = const Color(0xFFFDE2E4).withOpacity(0.5);
    } else if (p['status'] == 'Delivered') {
      statusColor = const Color(0xFF1D1D1F);
      statusBg = const Color(0xFFE2E2E2).withOpacity(0.5);
    }

    String orderValue = p['order_value'] ?? "TBD";
    String qty = (p['products'] != null && (p['products'] as List).isNotEmpty)
        ? p['products'][0]['qty'].toString()
        : "0";
    String dueDate = p['due_date'] ?? "TBD";
    int step = p['step'] ?? 0;
    double progress = (step + 1) / 6.0;

    return HoverCardWidget(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedProjectId = p['id'];
            _listViewState = 1;
          });
          _fetchProjectDetail(p['db_id']);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: urgencyColor, width: 4)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p['id'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p['status'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p['customer'],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isItemActive
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF86868B),
                      decoration: isItemActive
                          ? null
                          : TextDecoration.lineThrough,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Budget",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            orderValue,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Quantity",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            qty,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Progress",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: urgencyColor,
                        ),
                      ),
                      Text(
                        dueDate,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: urgencyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: urgencyColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Dialog ยืนยันยกเลิกโปรเจกต์ ---
  void _confirmCancelProject(
    BuildContext context,
    Map<String, dynamic> project,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Cancel Project",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFD97781),
          ),
        ),
        content: const Text(
          "Are you sure you want to cancel this project? This will mark it as inactive.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No", style: TextStyle(color: Color(0xFF86868B))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                project['is_active'] = false;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97781),
            ),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1E293B), size: 20),
      ),
    );
  }

  // --- Dialog ขอตัวอย่างสินค้า (Request Sample) ---
  void _showRequestSampleDialog(
    BuildContext context,
    Map<String, dynamic> project,
  ) {
    List<dynamic> products = project['products'] ?? [];
    List<bool> selectedProducts = List.generate(
      products.length,
      (index) => true,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool allSelected = selectedProducts.every((e) => e);
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "Request Sample",
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
                      "1. Select Products",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5B7BD5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: const Text(
                              "Select All",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            value: allSelected,
                            activeColor: const Color(0xFF1D1D1F),
                            onChanged: (val) {
                              setDialogState(() {
                                for (
                                  int i = 0;
                                  i < selectedProducts.length;
                                  i++
                                ) {
                                  selectedProducts[i] = val ?? false;
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          ...List.generate(products.length, (index) {
                            return CheckboxListTile(
                              title: Text(
                                products[index]['name'],
                                style: const TextStyle(fontSize: 14),
                              ),
                              value: selectedProducts[index],
                              activeColor: const Color(0xFF5B7BD5),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedProducts[index] = val ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "2. Select Artwork",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5B7BD5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "art1",
                          child: Text("Design A (Vector_V1.ai)"),
                        ),
                        DropdownMenuItem(
                          value: "art2",
                          child: Text("Design B (Vector_V2.ai)"),
                        ),
                      ],
                      onChanged: (val) {},
                      hint: const Text("Choose artwork for sample..."),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "3. Select Supplier(s)",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5B7BD5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: "E.g. Guangzhou Factory A...",
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "4. Amount",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5B7BD5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                decoration: InputDecoration(
                                  hintText: "E.g. 10 pcs",
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "5. Target Date (TH)",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5B7BD5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                decoration: InputDecoration(
                                  hintText: "DD/MM/YYYY",
                                  suffixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
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
                      ],
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Sample requested successfully!"),
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
                  "Submit Request",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButton(
    String title,
    Color bgColor,
    Color textColor, {
    IconData? icon,
    bool isOutlined = false,
    Color? borderColor,
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
              ? Border.all(
                  color: borderColor ?? const Color(0xFFE2E8F0),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
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

// Widget ช่วยทำ Hover Card
class HoverCardWidget extends StatefulWidget {
  final Widget child;
  const HoverCardWidget({super.key, required this.child});
  @override
  State<HoverCardWidget> createState() => _HoverCardWidgetState();
}

class _HoverCardWidgetState extends State<HoverCardWidget> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        child: widget.child,
      ),
    );
  }
}
