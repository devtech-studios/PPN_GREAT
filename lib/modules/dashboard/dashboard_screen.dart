import 'dart:ui';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_service.dart';
import '../../modules/auth/login_screen.dart';
import '../../modules/containers/containers_screen.dart';
import '../../modules/customers/create_customer_screen.dart';
import '../../modules/inventory/inventory_screen.dart';
import '../../modules/orders/project_list_screen.dart';
import '../../modules/suppliers/suppliers_screen.dart';
import '../../modules/finance/generate_pi_screen.dart';
import '../../modules/delivery/delivery_screen.dart';
import '../../modules/reports/reports_screen.dart';
import '../finance/record_payment_screen.dart';
import '../orders/create_project_screen.dart';
import '../orders/samples_screen.dart';
import '../orders/upload_design_screen.dart';

// ============================================================================
// MAIN LAYOUT (SIDEBAR & WRAPPER)
// ============================================================================
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // ==========================================
          // Left Sidebar (Organized by Clusters)
          // ==========================================
          Container(
            width: 260,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PPN GREAT",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Import Operation",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. OVERVIEW
                            _buildSidebarGroupTitle("OVERVIEW"),
                            _buildDominantMenuItem(
                              0,
                              "Dashboard",
                              Icons.grid_view_rounded,
                            ),

                            // 2. OPERATIONS
                            _buildSidebarGroupTitle("OPERATIONS"),
                            _buildMenuItem(
                              1,
                              "Projects",
                              Icons.folder_open_rounded,
                            ),
                            _buildMenuItem(
                              10,
                              "Samples",
                              Icons.science_outlined,
                            ), // Mock Route
                            _buildMenuItem(
                              4,
                              "Containers",
                              Icons.directions_boat_outlined,
                            ),
                            _buildMenuItem(
                              7,
                              "Delivery",
                              Icons.local_shipping_outlined,
                            ),

                            // 3. CONTACTS
                            _buildSidebarGroupTitle("CONTACTS"),
                            _buildMenuItem(
                              2,
                              "Customers",
                              Icons.people_outline,
                            ),
                            _buildMenuItem(
                              3,
                              "Suppliers",
                              Icons.business_outlined,
                            ),

                            // 4. FINANCE & INVENTORY
                            _buildSidebarGroupTitle("FINANCE & INVENTORY"),
                            _buildMenuItem(
                              5,
                              "Finance",
                              Icons.account_balance_wallet_outlined,
                            ),
                            _buildMenuItem(
                              6,
                              "Inventory",
                              Icons.inventory_2_outlined,
                            ),

                            const Spacer(),

                            // 5. SUPER ADMIN
                            _buildSidebarGroupTitle("SUPER ADMIN"),
                            _buildMenuItem(
                              9,
                              "Settings",
                              Icons.settings_outlined,
                            ),

                            // 6. OWNER ONLY
                            _buildSidebarGroupTitle("OWNER ONLY"),
                            _buildMenuItem(
                              8,
                              "Reports",
                              Icons.bar_chart_rounded,
                            ),

                            const SizedBox(height: 16),
                            _buildLogoutButton(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // Main Content Area (Dashboard)
          // ==========================================
          const Expanded(child: DashboardScreen()),
        ],
      ),
    );
  }

  Widget _buildSidebarGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // เมนู Dashboard ที่เด่นกว่าอันอื่น
  Widget _buildDominantMenuItem(int index, String title, IconData icon) {
    return InkWell(
      onTap: () {}, // อยู่หน้า Dashboard อยู่แล้ว
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: const Color(
            0xFF2563EB,
          ).withOpacity(0.1), // พื้นหลังสีน้ำเงินอ่อน
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon) {
    return InkWell(
      onTap: () {
        Widget destination;
        switch (index) {
          case 1:
            destination = const ProjectListScreen();
            break;
          case 2:
            destination = const CreateCustomerScreen();
            break;
          case 3:
            destination = const SuppliersScreen();
            break;
          case 4:
            destination = const ContainersScreen();
            break;
          case 5:
            destination = const GeneratePIScreen();
            break;
          case 6:
            destination = const InventoryScreen();
            break;
          case 7:
            destination = const DeliveryScreen();
            break;
          case 8:
            destination = const ReportsScreen();
            break;
          case 10:
            return; // Mock Sample
          default:
            destination = Scaffold(
              appBar: AppBar(title: Text(title)),
              body: Center(child: Text("$title Page")),
            );
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "Log Out",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text("คุณต้องการออกจากระบบใช่หรือไม่?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "ยกเลิก",
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await AuthService().logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "ออกจากระบบ",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 16),
            Text(
              "Log Out",
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD SCREEN
// ============================================================================
class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Global Search Dropdown State
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlay;
  final FocusNode _searchFocusNode = FocusNode();

  final ApiClient _api = ApiClient();
  
  bool _isLoadingSummary = false;
  bool _isLoadingActivities = false;
  bool _isLoadingRevenueChart = false;
  bool _isLoadingProjects = false;
  
  Map<String, dynamic>? _summaryData;
  List<dynamic> _activitiesData = [];
  List<dynamic> _revenueChartData = [];
  List<dynamic> _projectsData = [];

  Future<void> _fetchSummary() async {
    setState(() => _isLoadingSummary = true);
    try {
      final response = await _api.get('/dashboard/summary');
      if (response.data['success'] == true) {
        setState(() {
          _summaryData = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard summary: $e");
    } finally {
      setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoadingActivities = true);
    try {
      final response = await _api.get('/dashboard/activities');
      if (response.data['success'] == true) {
        setState(() {
          _activitiesData = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard activities: $e");
    } finally {
      setState(() => _isLoadingActivities = false);
    }
  }

  Future<void> _fetchRevenueChart() async {
    setState(() => _isLoadingRevenueChart = true);
    try {
      final response = await _api.get('/dashboard/revenue-chart');
      if (response.data['success'] == true) {
        setState(() {
          _revenueChartData = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard revenue chart: $e");
    } finally {
      setState(() => _isLoadingRevenueChart = false);
    }
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoadingProjects = true);
    try {
      final response = await _api.get(ProjectEndpoints.index);
      if (response.data['success'] == true) {
        setState(() {
          _projectsData = response.data['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard projects: $e");
    } finally {
      setState(() => _isLoadingProjects = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchSummary(),
      _fetchActivities(),
      _fetchRevenueChart(),
      _fetchProjects(),
    ]);
  }

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}K";
    }
    return value.toStringAsFixed(0);
  }

  String _formatTime(String? createdAtStr) {
    if (createdAtStr == null || createdAtStr.isEmpty) return "";
    try {
      final DateTime dt = DateTime.parse(createdAtStr).toLocal();
      final DateTime now = DateTime.now();
      final int diffDays = now.difference(dt).inDays;
      final String hourMinute = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      
      if (diffDays == 0 && dt.day == now.day) {
        return "Today, $hourMinute";
      } else if (diffDays <= 1) {
        return "Yesterday, $hourMinute";
      } else {
        return "${dt.day}/${dt.month}/${dt.year} $hourMinute";
      }
    } catch (e) {
      if (createdAtStr.length >= 16) {
        return createdAtStr.substring(0, 16).replaceAll('T', ' ');
      }
      return createdAtStr;
    }
  }

  IconData _getActivityIcon(String action) {
    final String act = action.toLowerCase();
    if (act.contains('approve') || act.contains('confirm') || act.contains('success')) {
      return Icons.check_circle;
    } else if (act.contains('create') || act.contains('add')) {
      return Icons.add_circle;
    } else if (act.contains('upload') || act.contains('file')) {
      return Icons.upload_file;
    } else if (act.contains('pay') || act.contains('finance') || act.contains('money')) {
      return Icons.attach_money;
    } else if (act.contains('ship') || act.contains('deliver') || act.contains('container')) {
      return Icons.local_shipping;
    } else if (act.contains('reject') || act.contains('cancel') || act.contains('fail')) {
      return Icons.cancel;
    }
    return Icons.info_outline;
  }

  Color _getActivityColor(String action) {
    final String act = action.toLowerCase();
    if (act.contains('approve') || act.contains('confirm') || act.contains('success')) {
      return const Color(0xFF10B981);
    } else if (act.contains('create') || act.contains('add')) {
      return const Color(0xFF2563EB);
    } else if (act.contains('upload') || act.contains('file')) {
      return const Color(0xFF8B5CF6);
    } else if (act.contains('pay') || act.contains('finance') || act.contains('money')) {
      return const Color(0xFFF59E0B);
    } else if (act.contains('ship') || act.contains('deliver') || act.contains('container')) {
      return const Color(0xFF06B6D4);
    } else if (act.contains('reject') || act.contains('cancel') || act.contains('fail')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF64748B);
  }

  @override
  void initState() {
    super.initState();
    _refreshAll();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _showSearchDropdown();
      } else {
        Future.delayed(
          const Duration(milliseconds: 150),
          () => _removeSearchDropdown(),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _removeSearchDropdown();
    super.dispose();
  }

  void _showSearchDropdown() {
    if (_searchOverlay != null) return;
    _searchOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: 350,
        child: CompositedTransformFollower(
          link: _searchLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchResultGroup("Projects", [
                    {
                      "icon": Icons.folder,
                      "title": "PPN-001 (Lion)",
                      "subtitle": "Waiting Sample V2",
                    },
                    {
                      "icon": Icons.folder,
                      "title": "PPN-009 (Central)",
                      "subtitle": "Artwork Approved",
                    },
                  ]),
                  const Divider(color: Color(0xFFF1F5F9)),
                  _buildSearchResultGroup("Customers", [
                    {
                      "icon": Icons.business,
                      "title": "Central Group",
                      "subtitle": "4 Active Projects",
                    },
                  ]),
                  const Divider(color: Color(0xFFF1F5F9)),
                  _buildSearchResultGroup("Suppliers", [
                    {
                      "icon": Icons.factory,
                      "title": "Guangzhou Bags",
                      "subtitle": "Textile",
                    },
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_searchOverlay!);
  }

  void _removeSearchDropdown() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  Widget _buildSearchResultGroup(
    String groupName,
    List<Map<String, dynamic>> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            groupName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        ...items.map(
          (item) => InkWell(
            onTap: () => _searchFocusNode.unfocus(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(item["icon"], size: 18, color: const Color(0xFF64748B)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        item["subtitle"],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // MAIN CONTENT (75%)
          // ==========================================
          Expanded(
            flex: 75,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION 1: Header & Global Search ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ใช้ Expanded หุ้มฝั่งซ้ายเพื่อป้องกันการล้นจอเมื่อจอแคบ
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.dashboardGreeting("Pun"),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _summaryData != null
                                  ? s.activeProjectsToday(
                                      _summaryData!['active_projects_count'] as int? ?? 0,
                                    )
                                  : s.loadingActiveProjects,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // GLOBAL SEARCH BAR
                      CompositedTransformTarget(
                        link: _searchLayerLink,
                        child: Container(
                          width: 320,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: s.searchHint,
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF64748B),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- SECTION 2: Active Projects ---
                  ActiveProjectsSection(
                    projects: _projectsData,
                    isLoading: _isLoadingProjects,
                  ),
                  const SizedBox(height: 48),

                  // --- SECTION 3: Cashflow & Upcoming Schedule ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _buildCashflowOverview()),
                      const SizedBox(width: 32),
                      Expanded(flex: 4, child: _buildUpcomingSchedule()),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ==========================================
          // RIGHT PANEL: Quick Actions & Activity (25%)
          // ==========================================
          Container(
            width: 360,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context)!.quickActionsHeader,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Primary Action (Filled)
                  _buildPrimaryActionButton(
                    S.of(context)!.btnCreateNewProject,
                    Icons.add_circle,
                    const Color(0xFF2563EB),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateProjectScreen(),
                        ),
                      );
                    },
                  ),

                  // 🌟 เพิ่มปุ่ม Manage Samples ตรงนี้ ก่อน Upload Artwork
                  _buildSecondaryActionButton(
                    S.of(context)!.btnManageSamples,
                    Icons.science_outlined,
                    const Color(0xFFEC4899), // สีชมพูให้เข้ากับแถบ Sample
                    () {
                      // ไปหน้า samples_screen (สมมติว่ามีหน้าจอสำหรับจัดการ samples)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SamplesScreen(),
                        ),
                      );
                    },
                  ),

                  // Secondary Actions (Outlined)
                  _buildSecondaryActionButton(
                    S.of(context)!.btnUploadArtwork,
                    Icons.brush_outlined,
                    const Color(0xFF8B5CF6),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadDesignScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSecondaryActionButton(
                    S.of(context)!.btnGeneratePI,
                    Icons.receipt_long_outlined,
                    const Color(0xFFF59E0B),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GeneratePIScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSecondaryActionButton(
                    S.of(context)!.btnBookContainer,
                    Icons.directions_boat_outlined,
                    const Color(0xFF64748B),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContainersScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSecondaryActionButton(
                    S.of(context)!.btnRecordPayment,
                    Icons.payments_outlined,
                    const Color(0xFF10B981),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecordPaymentScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 56),

                  Text(
                    S.of(context)!.activityLogHeader,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _activitiesData.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              S.of(context)!.noData,
                              style: const TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ),
                        )
                      : Column(
                          children: _activitiesData.map((activity) {
                            final String action = activity['action']?.toString() ?? "";
                            final String desc = activity['description']?.toString() ?? "";
                            final String timeStr = _formatTime(activity['created_at']?.toString());
                            
                            return _buildTimelineItem(
                              desc,
                              timeStr,
                              _getActivityColor(action),
                              _getActivityIcon(action),
                            );
                          }).toList(),
                        ),
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

  Widget _buildCashflowOverview() {
    final double revenueMtd = _summaryData != null
        ? double.tryParse(_summaryData!['revenue_mtd'].toString()) ?? 0.0
        : 3200000.0;
    final double pendingPayments = _summaryData != null
        ? double.tryParse(_summaryData!['pending_payments_amount'].toString()) ?? 0.0
        : 2800000.0;
    final double netBalance = revenueMtd - pendingPayments;

    final String incomingStr = "+ ฿${_formatAmount(revenueMtd)}";
    final String outgoingStr = "- ฿${_formatAmount(pendingPayments)}";
    final String netBalanceStr = "${netBalance >= 0 ? '+' : '-'} ฿${_formatAmount(netBalance.abs())}";

    double maxTotal = 1.0;
    for (var item in _revenueChartData) {
      double val = double.tryParse(item['total'].toString()) ?? 0.0;
      if (val > maxTotal) {
        maxTotal = val;
      }
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                S.of(context)!.cashflowHeader,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              // Period Selector
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      S.of(context)!.filterThisMonth,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFinanceSummary(
                S.of(context)!.labelIncoming,
                _summaryData != null ? incomingStr : "+ ฿3.2M",
                const Color(0xFF10B981),
                true,
                "22%",
              ),
              _buildFinanceSummary(
                S.of(context)!.labelOutgoing,
                _summaryData != null ? outgoingStr : "- ฿2.8M",
                const Color(0xFFEF4444),
                false,
                "8%",
              ),
              _buildFinanceSummary(
                S.of(context)!.labelNetBalance,
                _summaryData != null ? netBalanceStr : "+ ฿400K",
                const Color(0xFF2563EB),
                netBalance >= 0,
                "15%",
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2563EB).withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _revenueChartData.isEmpty
                ? const Center(
                    child: Text(
                      "Loading chart data...",
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _revenueChartData.map((item) {
                        final double val = double.tryParse(item['total'].toString()) ?? 0.0;
                        final double ratio = maxTotal > 0 ? (val / maxTotal) : 0.0;
                        final String monthStr = item['month'].toString();
                        final String displayMonth = monthStr.split('-').last;
                        
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (val > 0)
                                  Text(
                                    _formatAmount(val),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  )
                                else
                                  const Text(
                                    "",
                                    style: TextStyle(fontSize: 9),
                                  ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  height: (ratio * 80).clamp(4.0, 80.0),
                                  decoration: BoxDecoration(
                                    color: val > 0 
                                        ? const Color(0xFF2563EB) 
                                        : const Color(0xFF2563EB).withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  displayMonth,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {},
              child: const Text(
                "View full finance report →",
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceSummary(
    String label,
    String amount,
    Color amountColor,
    bool isTrendPositive,
    String trendValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isTrendPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: isTrendPositive
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              size: 18,
            ),
            Text(
              "$trendValue vs last month",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isTrendPositive
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingSchedule() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                S.of(context)!.upcomingScheduleHeader,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {}, // Link to Calendar
                child: Text(
                  S.of(context)!.viewFullCalendar,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildScheduleItem(
            S.of(context)!.containerArriving("NYK-892"),
            "Tomorrow, 08:00 AM",
            const Color(0xFF2563EB),
            Icons.directions_boat,
          ),
          _buildScheduleItem(
            S.of(context)!.customerMeeting("Tesla"),
            "Tomorrow, 02:00 PM",
            const Color(0xFF8B5CF6),
            Icons.groups,
          ),
          _buildScheduleItem(
            S.of(context)!.sampleDelivery("Lion"),
            "Wed, 10:00 AM",
            const Color(0xFFF59E0B),
            Icons.inventory_2,
          ),
          _buildScheduleItem(
            "Payment due (Supplier X)",
            "Fri, 12:00 PM",
            const Color(0xFFEF4444),
            Icons.payments,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    String title,
    String time,
    Color themeColor,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {}, // Clickable to project
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 14, color: themeColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 13,
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
    );
  }

  // Primary Action (Filled Button)
  Widget _buildPrimaryActionButton(
    String title,
    IconData icon,
    Color themeColor,
    VoidCallback onTap,
  ) {
    return HoverCardWidget(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Secondary Action (Outlined Button)
  Widget _buildSecondaryActionButton(
    String title,
    IconData icon,
    Color themeColor,
    VoidCallback onTap,
  ) {
    return HoverCardWidget(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: themeColor, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFCBD5E1),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String text,
    String time,
    Color iconBg,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: iconBg),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// CUSTOM HELPER WIDGETS
// =========================================================
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

// =========================================================
// ACTIVE PROJECTS SECTION (Handles Cards & Table View)
// =========================================================
class ActiveProjectsSection extends StatefulWidget {
  final List<dynamic> projects;
  final bool isLoading;

  const ActiveProjectsSection({
    super.key,
    required this.projects,
    required this.isLoading,
  });

  @override
  State<ActiveProjectsSection> createState() => _ActiveProjectsSectionState();
}

class _ActiveProjectsSectionState extends State<ActiveProjectsSection> {
  String _selectedTab = "All Active";
  bool _isTableView = false;

  final ScrollController _tabsScrollController = ScrollController();
  final ScrollController _cardsScrollController = ScrollController();
  bool _isTabsHovered = false;
  bool _isCardsHovered = false;

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}K";
    }
    return value.toStringAsFixed(0);
  }

  List<Map<String, dynamic>> get _tabsData {
    final s = S.of(context);
    int countByStatus(String status) {
      if (status == "All Active") {
        return widget.projects.where((p) => p['status'] != 'Delivered' && p['status'] != 'Cancelled').length;
      }
      return widget.projects.where((p) => p['status'] == status).length;
    }
    
    return [
      {"name": "All Active", "label": s != null ? s.filterAllActive(countByStatus("All Active")) : "All Active (${countByStatus("All Active")})", "count": countByStatus("All Active"), "color": const Color(0xFF0F172A)},
      {"name": "Inquiry", "label": s != null ? s.filterInquiry(countByStatus("Inquiry")) : "Inquiry (${countByStatus("Inquiry")})", "count": countByStatus("Inquiry"), "color": const Color(0xFFF59E0B)},
      {"name": "Artwork", "label": s != null ? s.filterArtwork(countByStatus("Artwork")) : "Artwork (${countByStatus("Artwork")})", "count": countByStatus("Artwork"), "color": const Color(0xFF8B5CF6)},
      {"name": "Deposit", "label": s != null ? s.filterDeposit(countByStatus("Deposit")) : "Deposit (${countByStatus("Deposit")})", "count": countByStatus("Deposit"), "color": const Color(0xFFEF4444)},
      {"name": "Sample", "label": s != null ? s.filterSample(countByStatus("Sample")) : "Sample (${countByStatus("Sample")})", "count": countByStatus("Sample"), "color": const Color(0xFFEC4899)},
      {"name": "Production", "label": s != null ? s.filterProduction(countByStatus("Production")) : "Production (${countByStatus("Production")})", "count": countByStatus("Production"), "color": const Color(0xFF2563EB)},
      {"name": "Shipping", "label": s != null ? s.filterShipping(countByStatus("Shipping")) : "Shipping (${countByStatus("Shipping")})", "count": countByStatus("Shipping"), "color": const Color(0xFF06B6D4)},
    ];
  }

  List<Map<String, dynamic>> get _processedProjects {
    return widget.projects.map((p) {
      final String code = p['project_code']?.toString() ?? 'PPN-XXX';
      final String customerName = p['customer']?['name']?.toString() ?? 'Unknown Customer';
      final String status = p['status']?.toString() ?? 'Inquiry';
      
      Color statusColor = const Color(0xFF64748B);
      switch (status) {
        case 'Inquiry': statusColor = const Color(0xFFF59E0B); break;
        case 'Artwork': statusColor = const Color(0xFF8B5CF6); break;
        case 'Deposit': statusColor = const Color(0xFFEF4444); break;
        case 'Sample': statusColor = const Color(0xFFEC4899); break;
        case 'Production': statusColor = const Color(0xFF2563EB); break;
        case 'Shipping': statusColor = const Color(0xFF06B6D4); break;
        case 'Delivered': statusColor = const Color(0xFF10B981); break;
      }
      
      final double budgetVal = double.tryParse(p['order_value']?.toString() ?? '0') ?? 0.0;
      final String budgetStr = budgetVal > 0 ? "฿${_formatAmount(budgetVal)}" : "฿0";
      
      int totalQty = 0;
      final List<dynamic>? productItems = p['product_items'] as List<dynamic>?;
      if (productItems != null) {
        for (var item in productItems) {
          totalQty += int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
        }
      }
      final String qtyStr = "$totalQty pcs";
      
      final String rawTargetDate = p['target_date']?.toString() ?? "";
      final String checkInStr = rawTargetDate.split(' ').first.split('T').first;
      final String duePrefix = S.of(context)?.cardDue ?? "Due:";
      final String dueStr = checkInStr.isNotEmpty ? "$duePrefix $checkInStr" : "";
      
      double progress = 0.05;
      Color urgencyColor = const Color(0xFF10B981);
      switch (status) {
        case 'Inquiry': progress = 0.1; urgencyColor = const Color(0xFFF59E0B); break;
        case 'Artwork': progress = 0.25; urgencyColor = const Color(0xFF8B5CF6); break;
        case 'Deposit': progress = 0.4; urgencyColor = const Color(0xFFEF4444); break;
        case 'Sample': progress = 0.55; urgencyColor = const Color(0xFFEC4899); break;
        case 'Production': progress = 0.75; urgencyColor = const Color(0xFF2563EB); break;
        case 'Shipping': progress = 0.9; urgencyColor = const Color(0xFF06B6D4); break;
        case 'Delivered': progress = 1.0; urgencyColor = const Color(0xFF10B981); break;
      }

      return {
        "db_id": p['id'],
        "id": code,
        "customer": customerName,
        "status": status,
        "statusColor": statusColor,
        "budget": budgetStr,
        "qty": qtyStr,
        "due": dueStr,
        "urgency": urgencyColor,
        "progress": progress,
      };
    }).toList();
  }

  @override
  void dispose() {
    _tabsScrollController.dispose();
    _cardsScrollController.dispose();
    super.dispose();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context)!.activeProjectsHeader,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.of(context)!.activeProjectsSubtitle,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // View Toggle (Cards vs Table)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildViewToggleBtn(Icons.grid_view_rounded, false),
                  _buildViewToggleBtn(Icons.table_rows_rounded, true),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- 1. Tabs Area ---
        MouseRegion(
          onEnter: (_) => setState(() => _isTabsHovered = true),
          onExit: (_) => setState(() => _isTabsHovered = false),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ScrollConfiguration(
                behavior: MouseDraggableScrollBehavior(),
                child: SingleChildScrollView(
                  controller: _tabsScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _tabsData.map((tab) => _buildTab(tab)).toList(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                child: IgnorePointer(
                  ignoring: !_isTabsHovered,
                  child: AnimatedOpacity(
                    opacity: _isTabsHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _buildArrowBtn(
                      Icons.chevron_left,
                      () => _scroll(_tabsScrollController, -300),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: IgnorePointer(
                  ignoring: !_isTabsHovered,
                  child: AnimatedOpacity(
                    opacity: _isTabsHovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _buildArrowBtn(
                      Icons.chevron_right,
                      () => _scroll(_tabsScrollController, 300),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // --- 2. Content Area ---
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isTableView ? _buildTableView() : _buildCardsArea(),
        ),
      ],
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

  Widget _buildTab(Map<String, dynamic> tabData) {
    String name = tabData['name'];
    int count = tabData['count'];
    Color themeColor = tabData['color'];
    final isSelected = _selectedTab == name;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = name);
        if (_cardsScrollController.hasClients) _cardsScrollController.jumpTo(0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          tabData['label'] ?? "$name ($count)",
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCardsArea() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isCardsHovered = true),
      onExit: (_) => setState(() => _isCardsHovered = false),
      child: LayoutBuilder(
        key: ValueKey("Cards_$_selectedTab"),
        builder: (context, constraints) {
          double spacing = 16.0;
          double cardWidth = (constraints.maxWidth - (spacing * 2)) / 3;

          List<Map<String, dynamic>> filtered = _selectedTab == "All Active"
              ? _processedProjects
              : _processedProjects
                    .where((p) => p['status'] == _selectedTab)
                    .toList();

          List<Widget> allCards = filtered
              .map((p) => _buildProjectCard(p, cardWidth))
              .toList();

          int columnCount = (allCards.length / 2).ceil();
          if (columnCount == 0) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text("No projects in this stage.")),
            );
          }

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
                      () => _scroll(
                        _cardsScrollController,
                        -(cardWidth + spacing),
                      ),
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
                      () =>
                          _scroll(_cardsScrollController, cardWidth + spacing),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableView() {
    List<Map<String, dynamic>> filtered = _selectedTab == "All Active"
        ? _processedProjects
        : _processedProjects.where((p) => p['status'] == _selectedTab).toList();

    return Container(
      key: ValueKey("Table_$_selectedTab"),
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
                    "Budget / Qty",
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
                    "Progress (Urgency)",
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
          ...filtered.map(
            (p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC))),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "${p['budget']} / ${p['qty']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                          color: p['statusColor'],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p['status'],
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: p['progress'],
                              child: Container(
                                decoration: BoxDecoration(
                                  color: p['urgency'],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          p['due'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p['urgency'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

  // --- วิธีแก้บั๊ก BorderRadius ใช้งานร่วมกับ non-uniform Border ด้วย ClipRRect ---
  Widget _buildProjectCard(Map<String, dynamic> project, double width) {
    return HoverCardWidget(
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // ใช้ ClipRRect ครอบเพื่อตัดขอบมน โดยไม่ต้องใส่ borderRadius ใน BoxDecoration ที่มีเส้นขอบไม่เท่ากัน
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(
                  color: project['urgency'],
                  width: 5,
                ), // เส้นขอบสีบอกความด่วน (หนา 5px)
                top: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                right: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                bottom: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      project['id'],
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
                        color: project['statusColor'],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        project['status'],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  project['customer'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
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
                        Text(
                          S.of(context)!.cardBudget,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          project['budget'],
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
                        Text(
                          S.of(context)!.cardQuantity,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          project['qty'],
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
                      S.of(context)!.cardProgress,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: project['urgency'],
                      ),
                    ),
                    Text(
                      project['due'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: project['urgency'],
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
                    widthFactor: project['progress'],
                    child: Container(
                      decoration: BoxDecoration(
                        color: project['urgency'],
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
    );
  }
}
