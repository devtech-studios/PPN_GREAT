import 'package:flutter/material.dart';
import 'package:ppn_great/core/api/api_client.dart';
import 'package:ppn_great/core/api/api_endpoints.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _activeTab = "RevenueForecast";

  // 🌟 Filter State สำหรับ Revenue Forecast
  String _filterPeriod = "Month"; // Day, Month, Quarter, Year
  String _filterValue = "Jun 2026";

  // =========================================================
  // API INTEGRATION & REAL DATA STATE
  // =========================================================
  final ApiClient _api = ApiClient();
  bool _isLoading = false;

  Map<String, dynamic> _financialSummary = {};
  Map<String, dynamic> _operationalSummary = {};
  List<dynamic> _revenueByMonth = [];
  List<dynamic> _profitByProject = [];
  List<dynamic> _realPayments = [];
  List<dynamic> _realContainers = [];
  List<dynamic> _realRounds = [];
  List<dynamic> _realProjects = [];

  int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return int.tryParse(val.toString()) ?? 0;
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final fRes = await _api.get(ReportEndpoints.financialSummary);
      final oRes = await _api.get(ReportEndpoints.operationalSummary);
      final mRes = await _api.get(ReportEndpoints.revenueByMonth);
      final pRes = await _api.get(ReportEndpoints.profitByProject);
      final payRes = await _api.get('/finance/payments');
      final cRes = await _api.get(ContainerEndpoints.index);
      final rRes = await _api.get(DeliveryEndpoints.index);
      final projRes = await _api.get(ProjectEndpoints.index);

      if (mounted) {
        setState(() {
          if (fRes.data['success'] == true) {
            _financialSummary = fRes.data['data'] ?? {};
          }
          if (oRes.data['success'] == true) {
            _operationalSummary = oRes.data['data'] ?? {};
          }
          if (mRes.data['success'] == true) {
            _revenueByMonth = mRes.data['data'] ?? [];
          }
          if (pRes.data['success'] == true) {
            _profitByProject = pRes.data['data'] ?? [];
          }
          if (payRes.data['success'] == true) {
            _realPayments = payRes.data['data'] ?? [];
          }
          if (cRes.data['success'] == true) {
            _realContainers = cRes.data['data'] ?? [];
          }
          if (rRes.data['success'] == true) {
            _realRounds = rRes.data['data'] ?? [];
          }
          if (projRes.data['success'] == true) {
            _realProjects = projRes.data['data'] ?? [];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching reports: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =========================================================
  // MOCK DATA สรุปภาพรวมและข้อมูลของทุก REPORT (พร้อม Getters เชื่อม API)
  // =========================================================

  // ข้อมูลคาดการณ์รายรับ (Revenue Forecast)
  final List<Map<String, dynamic>> _mockRevenueData = [
    {
      "date": "05 Jun 2026",
      "project": "PRJ-009",
      "customer": "Central Group",
      "amount": 150000.0,
      "status": "Paid",
      "invoice": "INV-260601",
    },
    {
      "date": "28 Jun 2026",
      "project": "PRJ-001",
      "customer": "Lion (Thailand)",
      "amount": 850000.0,
      "status": "Pending",
      "invoice": "INV-260602",
    },
    {
      "date": "10 Jul 2026",
      "project": "PRJ-010",
      "customer": "AIS",
      "amount": 642000.0,
      "status": "Pending",
      "invoice": "INV-260701",
    },
    {
      "date": "15 Jul 2026",
      "project": "PRJ-004",
      "customer": "Central Group",
      "amount": 250000.0,
      "status": "Pending",
      "invoice": "INV-260702",
    },
    {
      "date": "20 May 2026",
      "project": "PRJ-021",
      "customer": "Line Man",
      "amount": 120000.0,
      "status": "Overdue",
      "invoice": "INV-260505",
    },
  ];

  List<dynamic> get _revenueData {
    if (_realPayments.isNotEmpty) {
      return _realPayments.map((p) {
        final cust = p['customer']?['name'] ?? 'N/A';
        final proj = p['project']?['project_code'] ?? 'N/A';
        final doc = p['finance_document']?['doc_no'] ?? 'N/A';
        return {
          "date": p['payment_date'] ?? 'N/A',
          "project": proj,
          "customer": cust,
          "amount": _parseDouble(p['amount']),
          "status": p['status'] == 'Confirmed' ? 'Paid' : 'Pending',
          "invoice": doc,
        };
      }).toList();
    }
    return _mockRevenueData;
  }

  final Map<String, dynamic> _mockCompanyStats = {
    "net_cash_balance": 2850000.0,
    "ar_pending": 1200000.0,
    "ap_pending": 450000.0,
    "total_active_orders": 12,
    "completed_deliveries": 34,
    "pending_deliveries": 8,
    "avg_lead_time": 45,
  };

  Map<String, dynamic> get _companyStats {
    if (_financialSummary.isNotEmpty || _operationalSummary.isNotEmpty) {
      return {
        "net_cash_balance": _parseDouble(_financialSummary['total_revenue']),
        "ar_pending": _parseDouble(_financialSummary['total_revenue']) - _parseDouble(_financialSummary['total_cogs']),
        "ap_pending": _parseDouble(_financialSummary['total_cogs']),
        "total_active_orders": _parseInt(_operationalSummary['active_projects_count']),
        "completed_deliveries": _parseInt(_operationalSummary['completed_projects_count']),
        "pending_deliveries": _realRounds.where((r) => r['status'] == 'Scheduled').length,
        "avg_lead_time": _parseInt(_operationalSummary['avg_lead_time_days']),
      };
    }
    return _mockCompanyStats;
  }

  final List<Map<String, dynamic>> _mockProjectData = [
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

  List<dynamic> get _projectData {
    if (_profitByProject.isNotEmpty) {
      return _profitByProject.map((p) {
        return {
          "id": p['project_code'] ?? 'N/A',
          "customer": p['customer_name'] ?? 'N/A',
          "revenue": _parseDouble(p['revenue']),
          "cogs": _parseDouble(p['cogs']),
          "ocean_freight": 0.0,
          "inland_freight": 0.0,
          "status": "Active",
          "lead_time": 30,
          "foc_qty": 0,
          "category": "General",
        };
      }).toList();
    }
    return _mockProjectData;
  }

  final List<Map<String, dynamic>> _mockTaxData = [
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
    {
      "month": "Apr 2026",
      "container": "EVER 1122334",
      "vat": 85000.0,
      "duty": 32000.0,
      "shipping_fee": 12000.0,
    },
  ];

  List<dynamic> get _taxData {
    if (_realContainers.isNotEmpty) {
      return _realContainers.map((c) {
        final arrival = c['actual_arrival'] ?? c['eta'] ?? '';
        final month = arrival.isNotEmpty ? arrival.toString().split('-').sublist(0, 2).join('-') : 'N/A';
        return {
          "month": month,
          "container": c['container_no'] ?? 'N/A',
          "vat": _parseDouble(c['vat']),
          "duty": _parseDouble(c['duty']),
          "shipping_fee": _parseDouble(c['shipping_fee']),
        };
      }).toList();
    }
    return _mockTaxData;
  }

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
      "name": "กระบอกน้ำสแตนเลส (รุ่นเก่า)",
      "qty": 120,
      "value": 10200.0,
      "days": 95,
      "status": "Critical (>90 Days)",
    },
  ];

  final List<Map<String, dynamic>> _mockDeliveryData = [
    {
      "project": "PRJ-009",
      "customer": "Central Group",
      "batch": "รอบ 1",
      "date": "25 May 2026",
      "status": "Completed",
      "performance": "On-Time",
    },
    {
      "project": "PRJ-001",
      "customer": "Lion (Thailand)",
      "batch": "รอบ 1",
      "date": "28 May 2026",
      "status": "Pending",
      "performance": "On-Track",
    },
    {
      "project": "PRJ-021",
      "customer": "Line Man",
      "batch": "รอบ 2 (ปิดจ็อบ)",
      "date": "02 Jun 2026",
      "status": "Pending",
      "performance": "Delayed",
    },
  ];

  List<dynamic> get _deliveryData {
    if (_realRounds.isNotEmpty) {
      return _realRounds.map((r) {
        final String date = r['dispatch_date'] ?? 'N/A';
        final List items = r['items'] ?? [];
        final String proj = items.isNotEmpty ? (items[0]['project']?['project_code'] ?? 'N/A') : 'N/A';
        final String cust = items.isNotEmpty ? (items[0]['customer']?['name'] ?? 'N/A') : 'N/A';
        return {
          "project": proj,
          "customer": cust,
          "batch": "Round ${r['id']}",
          "date": date,
          "status": r['status'] ?? 'Pending',
          "performance": r['status'] == 'Delivered' ? 'On-Time' : 'On-Track',
        };
      }).toList();
    }
    return _mockDeliveryData;
  }

  final List<Map<String, dynamic>> _mockCustomerPortfolioData = [
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
      "customer": "Central Group",
      "revenue": 1200000.0,
      "share": 16.0,
      "active_projects": 4,
    },
    {
      "customer": "Others",
      "revenue": 780000.0,
      "share": 10.4,
      "active_projects": 3,
    },
  ];

  List<dynamic> get _customerPortfolioData {
    if (_realPayments.isNotEmpty) {
      final Map<String, double> revenueByCust = {};
      double totalRevenue = 0.0;
      final Map<String, Set<int>> activeProjectsByCust = {};

      for (var p in _realPayments) {
        final String custName = p['customer']?['name'] ?? 'N/A';
        final double amt = _parseDouble(p['amount']);
        if (p['status'] == 'Confirmed') {
          revenueByCust[custName] = (revenueByCust[custName] ?? 0.0) + amt;
          totalRevenue += amt;
        }
        final projId = p['project_id'];
        if (projId != null) {
          activeProjectsByCust.putIfAbsent(custName, () => {}).add(projId as int);
        }
      }

      if (totalRevenue > 0) {
        return revenueByCust.entries.map((e) {
          final share = (e.value / totalRevenue) * 100;
          return {
            "customer": e.key,
            "revenue": e.value,
            "share": double.parse(share.toStringAsFixed(1)),
            "active_projects": activeProjectsByCust[e.key]?.length ?? 0,
          };
        }).toList();
      }
    }
    return _mockCustomerPortfolioData;
  }

  final List<Map<String, dynamic>> _categoryData = [
    {
      "category": "Textile & Bags (งานผ้า)",
      "revenue": 4200000.0,
      "margin": 35.0,
      "trend": "+12.5%",
    },
    {
      "category": "Premium Gifts (ร่ม/แก้ว)",
      "revenue": 2100000.0,
      "margin": 42.0,
      "trend": "+5.2%",
    },
    {
      "category": "Electronics (Gadgets)",
      "revenue": 1180000.0,
      "margin": 28.0,
      "trend": "-2.1%",
    },
  ];

  final List<Map<String, dynamic>> _logisticsData = [
    {
      "method": "Sea Freight (FCL)",
      "avg_cost": "฿25,000 / ตู้",
      "avg_days": 15,
      "on_time": "95%",
    },
    {
      "method": "Sea Freight (LCL)",
      "avg_cost": "฿3,500 / CBM",
      "avg_days": 18,
      "on_time": "85%",
    },
    {
      "method": "Land Freight (Truck)",
      "avg_cost": "฿18,000 / คัน",
      "avg_days": 5,
      "on_time": "70%",
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
          // 1. LEFT PANEL: เมนูรายงานทั้งหมด
          // ==========================================
          Container(
            width: 300,
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
                _buildBackButton(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    "Executive Reports",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSectionTitle("Financials"),
                        _buildMenuTab(
                          "RevenueForecast",
                          "คาดการณ์รายรับ & วางบิล",
                          Icons.query_stats_rounded,
                        ),
                        _buildMenuTab(
                          "Profitability",
                          "กำไรสุทธิรายโปรเจกต์",
                          Icons.pie_chart_outline,
                        ),
                        _buildMenuTab(
                          "CashFlow",
                          "กระแสเงินสด & AR/AP",
                          Icons.account_balance_wallet_outlined,
                        ),
                        _buildMenuTab(
                          "TaxAnalytics",
                          "ภาษีนำเข้า & ค่าธรรมเนียม",
                          Icons.fact_check_outlined,
                        ),

                        _buildSectionTitle("Operations"),
                        _buildMenuTab(
                          "Delivery",
                          "สถานะการทยอยส่งของ",
                          Icons.local_shipping_outlined,
                        ),
                        _buildMenuTab(
                          "LeadTime",
                          "วิเคราะห์เวลาทำงาน (Lead Time)",
                          Icons.timer_outlined,
                        ),
                        _buildMenuTab(
                          "InventoryAging",
                          "สินค้าค้างสต็อก (Aging)",
                          Icons.inventory_2_outlined,
                        ),

                        _buildSectionTitle("Partners & Claims"),
                        _buildMenuTab(
                          "SupplierRating",
                          "Ranking ซัพพลายเออร์",
                          Icons.stars_outlined,
                        ),
                        _buildMenuTab(
                          "FOCAnalytics",
                          "สถิติของเคลม (FOC)",
                          Icons.assignment_return_outlined,
                        ),

                        _buildSectionTitle("Market Insights"),
                        _buildMenuTab(
                          "CustomerPortfolio",
                          "สัดส่วนรายได้ลูกค้า",
                          Icons.groups_3_outlined,
                        ),
                        _buildMenuTab(
                          "CategoryDemand",
                          "กลุ่มสินค้าขายดี",
                          Icons.trending_up_rounded,
                        ),
                        _buildMenuTab(
                          "LogisticsEfficiency",
                          "ประสิทธิภาพขนส่ง",
                          Icons.analytics_outlined,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 2. RIGHT PANEL: Content Area
          // ==========================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildActiveContent(),
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

  // --- เนื้อหาของแต่ละรายงาน ---
  Widget _buildActiveContent() {
    switch (_activeTab) {
      case "RevenueForecast":
        return _buildRevenueForecastReport();
      case "Profitability":
        return _buildProfitabilityReport();
      case "CashFlow":
        return _buildCashFlowReport();
      case "Delivery":
        return _buildDeliveryReport();
      case "LeadTime":
        return _buildLeadTimeReport();
      case "SupplierRating":
        return _buildSupplierReport();
      case "TaxAnalytics":
        return _buildTaxReport();
      case "InventoryAging":
        return _buildInventoryAgingReport();
      case "FOCAnalytics":
        return _buildFocReport();
      case "CustomerPortfolio":
        return _buildCustomerPortfolioReport();
      case "CategoryDemand":
        return _buildCategoryDemandReport();
      case "LogisticsEfficiency":
        return _buildLogisticsReport();
      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================
  // REPORT IMPLEMENTATIONS
  // =========================================================

  // 🌟 1. Revenue Forecast (คาดการณ์รายรับ) - แบบฟิลเตอร์ใหม่ & Inline Summary
  Widget _buildRevenueForecastReport() {
    // 1. จัดการตัวเลือก Dropdown ตามประเภท Period
    List<String> valueOptions = [];
    if (_filterPeriod == "Day") {
      valueOptions = [
        "05 Jun 2026",
        "28 Jun 2026",
        "10 Jul 2026",
        "15 Jul 2026",
      ];
    } else if (_filterPeriod == "Month") {
      valueOptions = ["May 2026", "Jun 2026", "Jul 2026"];
    } else if (_filterPeriod == "Quarter") {
      valueOptions = ["Q1 2026", "Q2 2026", "Q3 2026", "Q4 2026"];
    } else if (_filterPeriod == "Year") {
      valueOptions = ["2025", "2026"];
    }

    // ตรวจสอบค่าก่อนแสดงผลป้องกัน Error ถ้าเปลี่ยน Type
    if (!valueOptions.contains(_filterValue)) {
      _filterValue = valueOptions.isNotEmpty ? valueOptions.first : "";
    }

    // 2. ฟิลเตอร์ข้อมูลให้ตรงกับเงื่อนไข
    List<dynamic> filteredRevenue = _revenueData.where((e) {
      if (_filterPeriod == "Month" ||
          _filterPeriod == "Year" ||
          _filterPeriod == "Day") {
        return e['date'].toString().contains(_filterValue.split(" ")[0]);
      }
      return true; // ถ้าเป็น Quarter จะจำลองแสดงข้อมูลทั้งหมด
    }).toList();

    if (filteredRevenue.isEmpty) {
      filteredRevenue = _revenueData; // Fallback สำหรับ Mock
    }

    // 3. คำนวณสรุปยอด (Summary)
    double totalExpected = 0;
    double totalPaid = 0;
    double totalPending = 0;

    for (var r in filteredRevenue) {
      totalExpected += r['amount'];
      if (r['status'] == 'Paid') {
        totalPaid += r['amount'];
      } else {
        totalPending += r['amount'];
      }
    }

    return Column(
      key: const ValueKey("RevenueForecast"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- แถบเครื่องมือ Filter วันที่ ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(
              "การคาดการณ์รายรับและติดตามการชำระเงิน",
              "ยอดเรียกเก็บเงินจากลูกค้าแบ่งตามโปรเจกต์และกำหนดชำระ",
            ),
            Row(
              children: [
                // Dropdown เลือกรูปแบบเวลา
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterPeriod,
                      icon: const Icon(
                        Icons.filter_alt_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1D1D1F),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Prompt',
                      ),
                      items: ["Day", "Month", "Quarter", "Year"]
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(value),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _filterPeriod = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Dropdown เลือกค่าของวันที่
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterValue,
                      icon: const Icon(
                        Icons.calendar_month,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1D1D1F),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Prompt',
                      ),
                      items: valueOptions
                          .map(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(value),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _filterValue = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- ตารางแสดงบิลรายตัว ---
        _buildDataTable(
          [
            "Expected Date",
            "Project / Invoice",
            "Customer",
            "Amount",
            "Status",
          ],
          filteredRevenue.map((r) {
            Color statusColor;
            Color statusBg;
            String statusText = r['status'];

            if (statusText == "Paid") {
              statusColor = const Color(0xFF4A9062);
              statusBg = const Color(0xFFDCFCE7);
            } else if (statusText == "Overdue") {
              statusColor = const Color(0xFFEF4444);
              statusBg = const Color(0xFFFEE2E2);
            } else {
              // Pending
              statusColor = const Color(0xFFD97706);
              statusBg = const Color(0xFFFEF3C7);
            }

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    r['date'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusText == "Overdue"
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF1D1D1F),
                    ),
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['project'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B7BD5),
                        ),
                      ),
                      Text(
                        r['invoice'],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(r['customer'])),
                DataCell(
                  Text(
                    "฿${(r['amount']).toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // --- 🌟 สรุปยอดรวมแบบแนวนอน (Inline Summary) เรียบง่าย ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInlineSummaryItem(
                "Total Expected (เรียกเก็บรวม)",
                "฿${(totalExpected / 1000).toStringAsFixed(1)}k",
                const Color(0xFF1D1D1F),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              _buildInlineSummaryItem(
                "Received (รับชำระแล้ว)",
                "฿${(totalPaid / 1000).toStringAsFixed(1)}k",
                const Color(0xFF4A9062),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              _buildInlineSummaryItem(
                "Pending (รอเก็บ/เลยกำหนด)",
                "฿${(totalPending / 1000).toStringAsFixed(1)}k",
                const Color(0xFFD97706),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Profitability
  Widget _buildProfitabilityReport() {
    return Column(
      key: const ValueKey("Profitability"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "วิเคราะห์ต้นทุนและกำไรสุทธิ",
          "กำไรหลังหักต้นทุนสินค้า, ค่าขนส่ง และภาษี 1%",
        ),
        const SizedBox(height: 24),
        _buildDataTable(
          [
            "Project",
            "Revenue",
            "COGS",
            "Logistics",
            "Tax Buffer (1%)",
            "Net Profit",
          ],
          _projectData.map((p) {
            double tax = p['cogs'] * 0.01;
            double profit =
                p['revenue'] -
                (p['cogs'] + p['ocean_freight'] + p['inland_freight'] + tax);
            double margin = (profit / p['revenue']) * 100;
            return DataRow(
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['id'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B7BD5),
                        ),
                      ),
                      Text(
                        p['customer'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    "฿${(p['revenue'] / 1000).toStringAsFixed(1)}k",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    "฿${(p['cogs'] / 1000).toStringAsFixed(1)}k",
                    style: const TextStyle(color: Color(0xFFD97781)),
                  ),
                ),
                DataCell(
                  Text(
                    "฿${((p['ocean_freight'] + p['inland_freight']) / 1000).toStringAsFixed(1)}k",
                    style: const TextStyle(color: Color(0xFFD97781)),
                  ),
                ),
                DataCell(
                  Text(
                    "฿${(tax / 1000).toStringAsFixed(1)}k",
                    style: const TextStyle(color: Color(0xFFD08A2A)),
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "฿${(profit / 1000).toStringAsFixed(1)}k",
                        style: const TextStyle(
                          color: Color(0xFF4A9062),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "${margin.toStringAsFixed(1)}% Margin",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4A9062),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 3. Cash Flow
  Widget _buildCashFlowReport() {
    return Column(
      key: const ValueKey("CashFlow"),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Net Cash",
                "เงินสดพร้อมใช้",
                "฿2.85M",
                const Color(0xFF1D1D1F),
                const Color(0xFFF4F5F7),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Credit (AR)",
                "ลูกหนี้รอเรียกเก็บ",
                "฿1.20M",
                const Color(0xFF4A9062),
                const Color(0xFFB7E4C7).withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Debt (AP)",
                "เจ้าหนี้รอจ่าย",
                "฿450k",
                const Color(0xFFD97781),
                const Color(0xFFFDE2E4).withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ภาพรวมสถานะโปรเจกต์ (Project Pipeline)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFlowStep("Inquiry", "4"),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFFE2E2E2),
                  ),
                  _buildFlowStep("Artwork", "3"),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFFE2E2E2),
                  ),
                  _buildFlowStep("Deposit", "2"),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFFE2E2E2),
                  ),
                  _buildFlowStep("Production", "2"),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFFE2E2E2),
                  ),
                  _buildFlowStep("Shipping", "1"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Tax Analytics
  Widget _buildTaxReport() {
    return Column(
      key: const ValueKey("TaxAnalytics"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Total VAT Paid",
                "จ่าย VAT สะสม (ดึงคืนได้)",
                "฿255,000",
                const Color(0xFF5B7BD5),
                const Color(0xFFAEC4FA).withOpacity(0.2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Import Duty",
                "ภาษีนำเข้าสะสม (เป็นต้นทุน)",
                "฿99,000",
                const Color(0xFFD97781),
                const Color(0xFFFDE2E4).withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          "รายละเอียดภาษีและชิปปิ้งรายตู้",
          "ประวัติค่าใช้จ่ายเคลียร์ตู้สินค้าเมื่อเรือเข้าไทย",
        ),
        const SizedBox(height: 24),
        _buildDataTable(
          [
            "Month",
            "Container No.",
            "VAT (7%)",
            "Import Duty",
            "Shipping Fee",
            "Total Paid",
          ],
          _taxData.map((t) {
            double total = t['vat'] + t['duty'] + t['shipping_fee'];
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    t['month'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text(t['container'])),
                DataCell(
                  Text(
                    "฿${t['vat'].toStringAsFixed(0)}",
                    style: const TextStyle(color: Color(0xFF5B7BD5)),
                  ),
                ),
                DataCell(
                  Text(
                    "฿${t['duty'].toStringAsFixed(0)}",
                    style: const TextStyle(color: Color(0xFFD97781)),
                  ),
                ),
                DataCell(Text("฿${t['shipping_fee'].toStringAsFixed(0)}")),
                DataCell(
                  Text(
                    "฿${total.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 5. Delivery Tracking
  Widget _buildDeliveryReport() {
    return Column(
      key: const ValueKey("Delivery"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Active Orders",
                "ออเดอร์ที่กำลังรัน",
                "${_companyStats['total_active_orders']} Projects",
                const Color(0xFF1D1D1F),
                const Color(0xFFF4F5F7),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Completed",
                "จัดส่งเสร็จสิ้นแล้ว",
                "${_companyStats['completed_deliveries']} Rounds",
                const Color(0xFF4A9062),
                const Color(0xFFB7E4C7).withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Pending",
                "รอบที่รอทยอยส่ง",
                "${_companyStats['pending_deliveries']} Rounds",
                const Color(0xFFD08A2A),
                const Color(0xFFFDF3E1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          "Delivery Schedule",
          "ตารางการทยอยจัดส่งสินค้าให้ลูกค้า",
        ),
        const SizedBox(height: 24),
        _buildDataTable(
          ["Date", "Project", "Customer", "Batch", "Performance", "Status"],
          _deliveryData.map((d) {
            Color perfCol = d['performance'] == "Delayed"
                ? const Color(0xFFD97781)
                : const Color(0xFF4A9062);
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    d['date'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    d['project'],
                    style: const TextStyle(color: Color(0xFF5B7BD5)),
                  ),
                ),
                DataCell(Text(d['customer'])),
                DataCell(Text(d['batch'])),
                DataCell(
                  Text(
                    d['performance'],
                    style: TextStyle(
                      color: perfCol,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      d['status'],
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 6. Lead Time Report
  Widget _buildLeadTimeReport() {
    return Column(
      key: const ValueKey("LeadTime"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Lead Time เฉลี่ย: ${_companyStats['avg_lead_time']} วัน",
          "เวลาตั้งแต่วันเปิดโปรเจกต์ จนถึงส่งของถึงมือลูกค้า (เกณฑ์มาตรฐาน < 50 วัน)",
        ),
        const SizedBox(height: 32),
        ..._projectData.map(
          (p) => _buildLeadTimeBar(p['id'], p['customer'], p['lead_time']),
        ),
      ],
    );
  }

  // 7. Inventory Aging
  Widget _buildInventoryAgingReport() {
    return Column(
      key: const ValueKey("InventoryAging"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "สินค้าค้างสต็อก (Inventory Aging)",
          "ตรวจสอบสินค้าคงคลังเพื่อป้องกันเงินทุนจม",
        ),
        const SizedBox(height: 24),
        _buildDataTable(
          [
            "SKU",
            "Product Name",
            "Qty",
            "Stock Value",
            "Days in Stock",
            "Health Status",
          ],
          _inventoryAgingData.map((inv) {
            Color statusCol = const Color(0xFF4A9062);
            if (inv['days'] > 30 && inv['days'] <= 60) {
              statusCol = const Color(0xFFD08A2A);
            }
            if (inv['days'] > 60) statusCol = const Color(0xFFD97781);

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    inv['sku'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                DataCell(Text(inv['name'])),
                DataCell(Text("${inv['qty']} pcs")),
                DataCell(
                  Text(
                    "฿${inv['value'].toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    "${inv['days']} Days",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusCol,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusCol.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      inv['status'],
                      style: TextStyle(
                        fontSize: 11,
                        color: statusCol,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 8. Supplier Rating & AP
  Widget _buildSupplierReport() {
    return Column(
      key: const ValueKey("SupplierRating"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Ranking & Outstanding Debt",
          "วิเคราะห์ประสิทธิภาพซัพพลายเออร์และยอดค้างชำระ",
        ),
        const SizedBox(height: 24),
        _buildDataTable(
          ["Supplier", "Category", "Rating", "Active Bills", "Total AP"],
          [
            _buildSupplierRow(
              "Guangzhou Bags Factory",
              "Textile",
              4.8,
              3,
              "฿325,000",
            ),
            _buildSupplierRow(
              "Shenzhen Electronics Hub",
              "Electronics",
              4.5,
              1,
              "฿125,000",
            ),
            _buildSupplierRow("Yiwu Premium Gifts", "Premium", 4.9, 0, "฿0"),
          ],
        ),
      ],
    );
  }

  // 9. FOC Analytics
  Widget _buildFocReport() {
    return Column(
      key: const ValueKey("FOCAnalytics"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "สถิติการสั่งเผื่อเคลม (FOC)",
          "เทียบยอดสั่งจริงกับยอดที่ซัพพลายเออร์ส่งแถมมาให้เพื่อประเมินความคุ้มค่า",
        ),
        const SizedBox(height: 24),
        _buildDataTable(
          ["Project", "Product Category", "Order Qty", "FOC Received", "FOC %"],
          _projectData.map((p) {
            double percent =
                (p['foc_qty'] / 1000) *
                100; // Mock calculation based on 1000 base for demo
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    p['id'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text(p['category'])),
                DataCell(const Text("1,000 pcs")),
                DataCell(
                  Text(
                    "+${p['foc_qty']} pcs",
                    style: const TextStyle(
                      color: Color(0xFF4A9062),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(Text("${percent.toStringAsFixed(1)}%")),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 10. Customer Portfolio
  Widget _buildCustomerPortfolioReport() {
    return Column(
      key: const ValueKey("CustomerPortfolio"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Customer Portfolio",
          "สัดส่วนรายได้แยกตามบริษัทลูกค้า (Revenue Concentration)",
        ),
        const SizedBox(height: 24),
        _buildDataTable(
          ["Customer", "Total Revenue", "Share %", "Active Projects"],
          _customerPortfolioData.map((c) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    c['customer'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text("฿${(c['revenue'] / 1000000).toStringAsFixed(2)}M"),
                ),
                DataCell(
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          "${c['share']}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5B7BD5),
                          ),
                        ),
                      ),
                      Container(
                        height: 6,
                        width: c['share'] * 1.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B7BD5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text("${c['active_projects']} Projects")),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 11. Category Demand
  Widget _buildCategoryDemandReport() {
    return Column(
      key: const ValueKey("CategoryDemand"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Product Category Demand",
          "วิเคราะห์กลุ่มสินค้าพรีเมียมที่ทำกำไรและมียอดสั่งซื้อสูงสุด",
        ),
        const SizedBox(height: 24),
        _buildDataTable(
          ["Category", "Revenue Generated", "Avg Margin", "YoY Trend"],
          _categoryData.map((c) {
            bool isUp = c['trend'].toString().contains("+");
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    c['category'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text("฿${(c['revenue'] / 1000000).toStringAsFixed(2)}M"),
                ),
                DataCell(
                  Text(
                    "${c['margin']}%",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isUp
                          ? const Color(0xFFB7E4C7).withOpacity(0.3)
                          : const Color(0xFFFDE2E4).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c['trend'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUp
                            ? const Color(0xFF4A9062)
                            : const Color(0xFFD97781),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 12. Logistics Efficiency
  Widget _buildLogisticsReport() {
    return Column(
      key: const ValueKey("LogisticsEfficiency"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Logistics Efficiency",
          "เปรียบเทียบต้นทุนและระยะเวลาการขนส่งแต่ละประเภท",
        ),
        const SizedBox(height: 24),
        _buildDataTable(
          [
            "Freight Method",
            "Avg Cost",
            "Avg Transit Time",
            "On-Time Delivery %",
          ],
          _logisticsData.map((l) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    l['method'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text(l['avg_cost'])),
                DataCell(Text("${l['avg_days']} Days")),
                DataCell(
                  Text(
                    l['on_time'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A9062),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // =========================================================
  // UI COMPONENTS & HELPERS
  // =========================================================

  // 🌟 Helper สร้างกล่องข้อมูลสำหรับ Inline Summary แนวนอน
  Widget _buildInlineSummaryItem(String title, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTabTitle(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Executive Dashboard สำหรับผู้บริหาร",
          style: TextStyle(fontSize: 15, color: Color(0xFF86868B)),
        ),
      ],
    );
  }

  String _getTabTitle() {
    switch (_activeTab) {
      case "RevenueForecast":
        return "Revenue & Collection Forecast";
      case "Profitability":
        return "Project Profitability";
      case "CashFlow":
        return "Cash Flow & Balances";
      case "TaxAnalytics":
        return "Import Tax & Clearance";
      case "Delivery":
        return "Delivery & Schedules";
      case "LeadTime":
        return "Lead Time Performance";
      case "InventoryAging":
        return "Inventory Aging Health";
      case "SupplierRating":
        return "Supplier Analytics & AP";
      case "FOCAnalytics":
        return "Claims & FOC Strategy";
      case "CustomerPortfolio":
        return "Customer Portfolio";
      case "CategoryDemand":
        return "Category Performance";
      case "LogisticsEfficiency":
        return "Logistics Efficiency";
      default:
        return "Reports Analytics";
    }
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 32, right: 16, bottom: 16),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: const [
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF86868B),
              ),
              SizedBox(width: 8),
              Text(
                "Dashboard",
                style: TextStyle(
                  color: Color(0xFF86868B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 20, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB4B4B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuTab(String id, String title, IconData icon) {
    bool isActive = _activeTab == id;
    return InkWell(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFAEC4FA).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? const Color(0xFF5B7BD5)
                  : const Color(0xFF86868B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF5B7BD5)
                      : const Color(0xFF1D1D1F),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
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
          style: const TextStyle(fontSize: 14, color: Color(0xFF86868B)),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<String> columns, List<DataRow> rows) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9FC)),
        dataRowHeight: 65,
        columns: columns
            .map(
              (c) => DataColumn(
                label: Text(
                  c,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
        rows: rows,
      ),
    );
  }

  DataRow _buildSupplierRow(
    String name,
    String cat,
    double rate,
    int bills,
    String ap,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataCell(Text(cat)),
        DataCell(
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              Text(" $rate"),
            ],
          ),
        ),
        DataCell(Text("$bills")),
        DataCell(
          Text(
            ap,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97781),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadTimeBar(String id, String customer, int days) {
    double widthFactor = days / 60.0; // 60 Days max scale for visual reference
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$id - $customer",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "$days วัน",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: days > 50
                      ? const Color(0xFFD97781)
                      : const Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
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
                  color: days > 50
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
  }

  Widget _buildStatCard(
    String title,
    String subtitle,
    String value,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.7),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep(String label, String count) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Color(0xFF1D1D1F),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF86868B),
          ),
        ),
      ],
    );
  }
}
