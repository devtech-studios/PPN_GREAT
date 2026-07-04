import 'package:flutter/material.dart';

import 'modules/auth/login_screen.dart';

class PPNGreatApp extends StatelessWidget {
  const PPNGreatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PPN Great ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        primaryColor: const Color(0xFF5B7BD5),
        fontFamily: 'Prompt', // ใช้ฟอนต์ Prompt
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF5B7BD5),
          secondary: const Color(0xFF4A9062),
        ),
      ),
      home: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 850) {
            return const MobileOwnerScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

// ============================================================================
// MOBILE OWNER SCREEN
// ============================================================================
class MobileOwnerScreen extends StatefulWidget {
  const MobileOwnerScreen({super.key});

  @override
  State<MobileOwnerScreen> createState() => _MobileOwnerScreenState();
}

class _MobileOwnerScreenState extends State<MobileOwnerScreen> {
  String _activeTab = "Dashboard";

  // --- MOCK DATA ---
  final Map<String, dynamic> _companyStats = {
    "net_cash_balance": 2850000.0,
    "ar_pending": 1200000.0,
    "ap_pending": 450000.0,
    "total_active_orders": 12,
    "completed_deliveries": 34,
    "pending_deliveries": 8,
    "avg_lead_time": 45,
  };

  final List<Map<String, dynamic>> _projectData = [
    {
      "id": "PRJ-001",
      "customer": "Lion (Thailand)",
      "revenue": 1700000.0,
      "cogs": 850000.0,
      "ocean_freight": 45000.0,
      "inland_freight": 8000.0,
      "status": "Production",
      "lead_time": 42,
      "foc_qty": 200,
      "category": "Bags",
    },
    {
      "id": "PRJ-009",
      "customer": "Central Group",
      "revenue": 450000.0,
      "cogs": 210000.0,
      "ocean_freight": 15000.0,
      "inland_freight": 5000.0,
      "status": "Shipping",
      "lead_time": 38,
      "foc_qty": 50,
      "category": "Premium Gifts",
    },
    {
      "id": "PRJ-010",
      "customer": "AIS",
      "revenue": 1284000.0,
      "cogs": 650000.0,
      "ocean_freight": 35000.0,
      "inland_freight": 6000.0,
      "status": "Completed",
      "lead_time": 55,
      "foc_qty": 100,
      "category": "Electronics",
    },
  ];

  final List<Map<String, dynamic>> _taxData = [
    {
      "month": "May 2026",
      "container": "TLLU 1234567",
      "vat": 125000.0,
      "duty": 55000.0,
      "shipping_fee": 18500.0,
    },
    {
      "month": "Apr 2026",
      "container": "NYKU 9876543",
      "vat": 45000.0,
      "duty": 12000.0,
      "shipping_fee": 9000.0,
    },
  ];

  final List<Map<String, dynamic>> _inventoryAgingData = [
    {
      "sku": "BG-COT-01",
      "name": "กระเป๋าผ้าคอตตอน 12 ออนซ์",
      "qty": 2500,
      "value": 125000.0,
      "days": 15,
      "status": "Healthy (<30 Days)",
    },
    {
      "sku": "UM-GLF-30",
      "name": "ร่มกอล์ฟ 30 นิ้ว",
      "qty": 450,
      "value": 67500.0,
      "days": 45,
      "status": "Warning (30-60 Days)",
    },
    {
      "sku": "BT-STL-05",
      "name": "กระบอกน้ำสแตนเลส (เก่า)",
      "qty": 120,
      "value": 10200.0,
      "days": 95,
      "status": "Critical (>90 Days)",
    },
  ];

  final List<Map<String, dynamic>> _customerPortfolioData = [
    {
      "customer": "Lion (Thailand)",
      "revenue": 3400000.0,
      "share": 45.5,
      "active_projects": 3,
    },
    {
      "customer": "AIS",
      "revenue": 2100000.0,
      "share": 28.1,
      "active_projects": 2,
    },
    {
      "customer": "Central",
      "revenue": 1200000.0,
      "share": 16.0,
      "active_projects": 4,
    },
  ];

  final List<Map<String, dynamic>> _categoryData = [
    {
      "category": "Textile & Bags",
      "revenue": 4200000.0,
      "margin": 35.0,
      "trend": "+12.5%",
    },
    {
      "category": "Premium Gifts",
      "revenue": 2100000.0,
      "margin": 42.0,
      "trend": "+5.2%",
    },
  ];

  final List<Map<String, dynamic>> _logisticsData = [
    {
      "method": "Sea Freight (FCL)",
      "avg_cost": "฿25k / ตู้",
      "avg_days": 15,
      "on_time": "95%",
    },
    {
      "method": "Land Freight (Truck)",
      "avg_cost": "฿18k / คัน",
      "avg_days": 5,
      "on_time": "70%",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1D1D1F)),
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 24,
                left: 24,
                right: 24,
              ),
              color: const Color(0xFFF4F5F7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF1D1D1F),
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Owner Portal",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  Text(
                    "PPN GREAT CO., LTD.",
                    style: TextStyle(fontSize: 12, color: Color(0xFF86868B)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    "Dashboard",
                    "ภาพรวมบริษัท",
                    Icons.grid_view_rounded,
                  ),
                  const Divider(
                    indent: 24,
                    endIndent: 24,
                    color: Color(0xFFE2E2E2),
                  ),
                  _buildDrawerSectionTitle("Financials"),
                  _buildDrawerItem(
                    "Profitability",
                    "กำไรต่อโปรเจกต์",
                    Icons.pie_chart_outline,
                  ),
                  _buildDrawerItem(
                    "CashFlow",
                    "กระแสเงินสด & AR/AP",
                    Icons.account_balance_wallet_outlined,
                  ),
                  _buildDrawerItem(
                    "TaxAnalytics",
                    "ภาษีนำเข้า & ชิปปิ้ง",
                    Icons.fact_check_outlined,
                  ),
                  _buildDrawerSectionTitle("Operations"),
                  _buildDrawerItem(
                    "Delivery",
                    "สถานะการจัดส่ง",
                    Icons.local_shipping_outlined,
                  ),
                  _buildDrawerItem(
                    "LeadTime",
                    "วิเคราะห์ Lead Time",
                    Icons.timer_outlined,
                  ),
                  _buildDrawerItem(
                    "InventoryAging",
                    "สินค้าค้างสต็อก (Aging)",
                    Icons.inventory_2_outlined,
                  ),
                  _buildDrawerSectionTitle("Partners & Claims"),
                  _buildDrawerItem(
                    "SupplierRating",
                    "Ranking โรงงาน",
                    Icons.stars_outlined,
                  ),
                  _buildDrawerItem(
                    "FOCAnalytics",
                    "สถิติของเผื่อเคลม (FOC)",
                    Icons.assignment_return_outlined,
                  ),
                  _buildDrawerSectionTitle("Insights"),
                  _buildDrawerItem(
                    "CustomerPortfolio",
                    "สัดส่วนลูกค้า",
                    Icons.groups_3_outlined,
                  ),
                  _buildDrawerItem(
                    "CategoryDemand",
                    "กลุ่มสินค้าขายดี",
                    Icons.trending_up_rounded,
                  ),
                  _buildDrawerItem(
                    "LogisticsEfficiency",
                    "ประสิทธิภาพขนส่ง",
                    Icons.analytics_outlined,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E2E2)),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("ออกจากระบบ (Mock)"),
                    backgroundColor: Color(0xFFD97781),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Color(0xFFD97781), size: 20),
                    SizedBox(width: 16),
                    Text(
                      "ออกจากระบบ",
                      style: TextStyle(
                        color: Color(0xFFD97781),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildActiveContent(),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_activeTab) {
      case "Dashboard":
        return "ภาพรวมบริษัท";
      case "Profitability":
        return "กำไรสุทธิรายโปรเจกต์";
      case "CashFlow":
        return "กระแสเงินสด & AR/AP";
      case "TaxAnalytics":
        return "ภาษีนำเข้า & ชิปปิ้ง";
      case "Delivery":
        return "สถานะการจัดส่ง";
      case "LeadTime":
        return "วิเคราะห์ Lead Time";
      case "InventoryAging":
        return "สินค้าค้างสต็อก (Aging)";
      case "SupplierRating":
        return "Ranking ซัพพลายเออร์";
      case "FOCAnalytics":
        return "สถิติของเผื่อเคลม (FOC)";
      case "CustomerPortfolio":
        return "สัดส่วนลูกค้า";
      case "CategoryDemand":
        return "กลุ่มสินค้าขายดี";
      case "LogisticsEfficiency":
        return "ประสิทธิภาพขนส่ง";
      default:
        return "PPN GREAT";
    }
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB4B4B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String id, String title, IconData icon) {
    bool isActive = _activeTab == id;
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? const Color(0xFF1D1D1F) : const Color(0xFF86868B),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? const Color(0xFF1D1D1F) : const Color(0xFF86868B),
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selected: isActive,
      selectedTileColor: const Color(0xFFAEC4FA).withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: () {
        setState(() => _activeTab = id);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildActiveContent() {
    switch (_activeTab) {
      case "Dashboard":
        return _buildDashboardMobile();
      case "Profitability":
        return _buildProfitabilityMobile();
      case "CashFlow":
        return _buildCashFlowMobile();
      case "TaxAnalytics":
        return _buildTaxMobile();
      case "Delivery":
        return _buildDeliveryMobile();
      case "LeadTime":
        return _buildLeadTimeMobile();
      case "InventoryAging":
        return _buildInventoryAgingMobile();
      case "SupplierRating":
        return _buildSupplierMobile();
      case "FOCAnalytics":
        return _buildFocMobile();
      case "CustomerPortfolio":
        return _buildCustomerMobile();
      case "CategoryDemand":
        return _buildCategoryMobile();
      case "LogisticsEfficiency":
        return _buildLogisticsMobile();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // 1. DASHBOARD (อัปเกรดให้ดูพรีเมียมขึ้น)
  // ==========================================
  Widget _buildDashboardMobile() {
    return Column(
      key: const ValueKey("Dashboard"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "สวัสดีครับ คุณผู้บริหาร 👋",
          style: TextStyle(fontSize: 16, color: Color(0xFF86868B)),
        ),
        const SizedBox(height: 4),
        const Text(
          "ภาพรวมธุรกิจวันนี้",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 24),

        // กล่องเงินสด (เพิ่ม Gradient ให้ดูพรีเมียม)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D1D1F), Color(0xFF2C3E50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Net Cash Balance (เงินสดในมือ)",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                "฿${(_companyStats['net_cash_balance'] / 1000000).toStringAsFixed(2)}M",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AR (รอรับ)",
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        "฿${(_companyStats['ar_pending'] / 1000).toStringAsFixed(0)}k",
                        style: const TextStyle(
                          color: Color(0xFFB7E4C7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "AP (รอจ่าย)",
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        "฿${(_companyStats['ap_pending'] / 1000).toStringAsFixed(0)}k",
                        style: const TextStyle(
                          color: Color(0xFFFDE2E4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Quick Actions (แอปเมนูด่วนแบบวงกลม)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickAction(
              Icons.pie_chart_rounded,
              "กำไร",
              "Profitability",
              const Color(0xFF5B7BD5),
            ),
            _buildQuickAction(
              Icons.local_shipping_rounded,
              "จัดส่ง",
              "Delivery",
              const Color(0xFFD08A2A),
            ),
            _buildQuickAction(
              Icons.inventory_2_rounded,
              "สต็อก",
              "InventoryAging",
              const Color(0xFF4A9062),
            ),
            _buildQuickAction(
              Icons.groups_rounded,
              "ลูกค้า",
              "CustomerPortfolio",
              const Color(0xFFD97781),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Project Pipeline Tracker
        const Text(
          "สถานะโปรเจกต์ (Pipeline)",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPipelineStep("เสนอราคา", "4", isActive: true),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color(0xFFE2E2E2),
              ),
              _buildPipelineStep("มัดจำ", "2", isActive: true),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color(0xFFE2E2E2),
              ),
              _buildPipelineStep("ผลิต", "5", isActive: true),
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color(0xFFE2E2E2),
              ),
              _buildPipelineStep("จัดส่ง", "1", isActive: false),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // สถิติรอง
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                "Lead Time เฉลี่ย",
                "${_companyStats['avg_lead_time']} วัน",
                const Color(0xFF5B7BD5),
                const Color(0xFFAEC4FA).withOpacity(0.2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileStatCard(
                "รอเคลียร์ภาษี",
                "2 ตู้",
                const Color(0xFFD97781),
                const Color(0xFFFDE2E4).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Mobile Helper Widgets ---
  Widget _buildQuickAction(
    IconData icon,
    String label,
    String tabId,
    Color color,
  ) {
    return InkWell(
      onTap: () => setState(() => _activeTab = tabId),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep(
    String label,
    String count, {
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1D1D1F) : const Color(0xFFF4F5F7),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF86868B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF1D1D1F) : const Color(0xFF86868B),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Color(0xFF86868B)),
        ),
      ],
    );
  }

  Widget _buildMobileStatCard(
    String title,
    String value,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
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
    );
  }

  Widget _buildMobileCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Map<String, String> rows,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF86868B)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFF4F5F7)),
          ),
          ...rows.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF86868B),
                    ),
                  ),
                  Text(
                    e.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                      fontSize: 13,
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

  // --- REPORT VIEWS ---
  Widget _buildProfitabilityMobile() {
    return Column(
      key: const ValueKey("Profitability"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("กำไรสุทธิรายโปรเจกต์", "Net Profit Analytics"),
        const SizedBox(height: 16),
        ..._projectData.map((p) {
          double tax = p['cogs'] * 0.01;
          double profit =
              p['revenue'] -
              (p['cogs'] + p['ocean_freight'] + p['inland_freight'] + tax);
          double margin = (profit / p['revenue']) * 100;
          return _buildMobileCard(
            title: p['id'],
            subtitle: p['customer'],
            badgeText: "${margin.toStringAsFixed(1)}% Margin",
            badgeColor: const Color(0xFF4A9062),
            rows: {
              "Revenue": "฿${(p['revenue'] / 1000).toStringAsFixed(1)}k",
              "Net Profit": "฿${(profit / 1000).toStringAsFixed(1)}k",
            },
          );
        }),
      ],
    );
  }

  Widget _buildCashFlowMobile() {
    return Column(
      key: const ValueKey("CashFlow"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("กระแสเงินสด", "Cash Flow & AR/AP"),
        const SizedBox(height: 16),
        _buildMobileStatCard(
          "เงินสดพร้อมใช้",
          "฿2.85M",
          const Color(0xFF1D1D1F),
          const Color(0xFFF4F5F7),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                "AR (รับ)",
                "฿1.20M",
                const Color(0xFF4A9062),
                const Color(0xFFB7E4C7).withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileStatCard(
                "AP (จ่าย)",
                "฿450k",
                const Color(0xFFD97781),
                const Color(0xFFFDE2E4).withOpacity(0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaxMobile() {
    return Column(
      key: const ValueKey("TaxAnalytics"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("ภาษีนำเข้า & ชิปปิ้ง", "Import Tax & Clearance"),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                "VAT จ่ายสะสม",
                "฿255k",
                const Color(0xFF5B7BD5),
                const Color(0xFFAEC4FA).withOpacity(0.2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMobileStatCard(
                "อากรสะสม",
                "฿99k",
                const Color(0xFFD97781),
                const Color(0xFFFDE2E4).withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ..._taxData.map((t) {
          double total = t['vat'] + t['duty'] + t['shipping_fee'];
          return _buildMobileCard(
            title: t['container'],
            subtitle: "รอบเรือ: ${t['month']}",
            badgeText: "Total: ฿${(total / 1000).toStringAsFixed(1)}k",
            badgeColor: const Color(0xFF5B7BD5),
            rows: {
              "VAT (7%)": "฿${t['vat'].toStringAsFixed(0)}",
              "Import Duty": "฿${t['duty'].toStringAsFixed(0)}",
            },
          );
        }),
      ],
    );
  }

  Widget _buildDeliveryMobile() {
    return Column(
      key: const ValueKey("Delivery"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("การจัดส่ง", "Delivery Overview"),
        const SizedBox(height: 16),
        ..._projectData.map(
          (p) => _buildMobileCard(
            title: p['customer'],
            subtitle: p['id'],
            badgeText: p['status'],
            badgeColor: p['status'] == 'Completed'
                ? const Color(0xFF4A9062)
                : const Color(0xFFD08A2A),
            rows: {"Categories": p['category'], "Status": p['status']},
          ),
        ),
      ],
    );
  }

  Widget _buildLeadTimeMobile() {
    return Column(
      key: const ValueKey("LeadTime"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Lead Time เฉลี่ย: ${_companyStats['avg_lead_time']} วัน",
          "ระยะเวลาตั้งแต่เริ่มจนส่งของ",
        ),
        const SizedBox(height: 24),
        ..._projectData.map((p) {
          double widthFactor = p['lead_time'] / 60.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${p['id']} - ${p['customer']}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      "${p['lead_time']} วัน",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: p['lead_time'] > 50
                            ? const Color(0xFFD97781)
                            : const Color(0xFF5B7BD5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widthFactor.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: p['lead_time'] > 50
                            ? const Color(0xFFD97781)
                            : const Color(0xFF5B7BD5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInventoryAgingMobile() {
    return Column(
      key: const ValueKey("InventoryAging"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("สินค้าค้างสต็อก", "Inventory Aging"),
        const SizedBox(height: 16),
        ..._inventoryAgingData.map((inv) {
          Color statusCol = const Color(0xFF4A9062);
          if (inv['days'] > 30 && inv['days'] <= 60) {
            statusCol = const Color(0xFFD08A2A);
          }
          if (inv['days'] > 60) statusCol = const Color(0xFFD97781);
          return _buildMobileCard(
            title: inv['sku'],
            subtitle: inv['name'],
            badgeText: "${inv['days']} Days",
            badgeColor: statusCol,
            rows: {
              "Qty In Stock": "${inv['qty']} pcs",
              "Total Value": "฿${(inv['value'] / 1000).toStringAsFixed(1)}k",
            },
          );
        }),
      ],
    );
  }

  Widget _buildSupplierMobile() {
    return Column(
      key: const ValueKey("SupplierRating"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Ranking ซัพพลายเออร์", "Supplier Analytics"),
        const SizedBox(height: 16),
        _buildMobileCard(
          title: "Guangzhou Bags",
          subtitle: "Textile",
          badgeText: "★ 4.8",
          badgeColor: const Color(0xFFD08A2A),
          rows: {"Active Bills": "3", "Total AP": "฿325k"},
        ),
        _buildMobileCard(
          title: "Shenzhen Tech",
          subtitle: "Electronics",
          badgeText: "★ 4.5",
          badgeColor: const Color(0xFFD08A2A),
          rows: {"Active Bills": "1", "Total AP": "฿125k"},
        ),
      ],
    );
  }

  Widget _buildFocMobile() {
    return Column(
      key: const ValueKey("FOCAnalytics"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("สถิติของเคลม (FOC)", "FOC Analytics"),
        const SizedBox(height: 16),
        ..._projectData.map((p) {
          double percent = (p['foc_qty'] / 1000) * 100;
          return _buildMobileCard(
            title: p['id'],
            subtitle: p['category'],
            badgeText: "+${p['foc_qty']} pcs",
            badgeColor: const Color(0xFF5B7BD5),
            rows: {
              "Order Qty": "1,000 pcs",
              "FOC Percentage": "${percent.toStringAsFixed(1)}%",
            },
          );
        }),
      ],
    );
  }

  Widget _buildCustomerMobile() {
    return Column(
      key: const ValueKey("CustomerPortfolio"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("สัดส่วนรายได้ลูกค้า", "Revenue Share by Customer"),
        const SizedBox(height: 16),
        ..._customerPortfolioData.map(
          (c) => _buildMobileCard(
            title: c['customer'],
            subtitle: "${c['active_projects']} Active Projects",
            badgeText: "${c['share']}%",
            badgeColor: const Color(0xFF1D1D1F),
            rows: {
              "Total Revenue":
                  "฿${(c['revenue'] / 1000000).toStringAsFixed(2)}M",
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryMobile() {
    return Column(
      key: const ValueKey("CategoryDemand"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("กลุ่มสินค้าขายดี", "Category Demand"),
        const SizedBox(height: 16),
        ..._categoryData.map(
          (c) => _buildMobileCard(
            title: c['category'],
            subtitle: "Margin: ${c['margin']}%",
            badgeText: c['trend'],
            badgeColor: const Color(0xFF4A9062),
            rows: {
              "Revenue Generated":
                  "฿${(c['revenue'] / 1000000).toStringAsFixed(2)}M",
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogisticsMobile() {
    return Column(
      key: const ValueKey("LogisticsEfficiency"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("ประสิทธิภาพขนส่ง", "Logistics Efficiency"),
        const SizedBox(height: 16),
        ..._logisticsData.map(
          (l) => _buildMobileCard(
            title: l['method'],
            subtitle: "Avg Transit: ${l['avg_days']} Days",
            badgeText: "On-Time: ${l['on_time']}",
            badgeColor: const Color(0xFF5B7BD5),
            rows: {"Avg Cost": l['avg_cost']},
          ),
        ),
      ],
    );
  }
}
