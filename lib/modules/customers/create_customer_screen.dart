import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_error_handler.dart';
import '../orders/project_list_screen.dart';
import '../orders/create_project_screen.dart';

class CreateCustomerScreen extends StatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  // API client
  final ApiClient _api = ApiClient();
  bool _isLoadingList = false;
  bool _isLoadingDetail = false;
  bool _isSaving = false;
  List<dynamic> _customers = [];
  Map<String, dynamic>? _selectedCustomerDetail;
  int? _selectedCustomerId;
  Map<String, dynamic>? _selectedCustomerStats;

  // controllers for form fields
  final _nameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _internalNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _billingAddressController.dispose();
    _internalNoteController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoadingList = true;
    });
    try {
      final response = await _api.get(CustomerEndpoints.index, queryParameters: {
        if (_searchText.isNotEmpty) 'search': _searchText,
        if (_selectedCustomerStatusTab != "All") 'status': _selectedCustomerStatusTab,
      });
      final body = response.data;
      if (body['success'] == true) {
        setState(() {
          _customers = body['data'];
          if (_customers.isNotEmpty) {
            if (_selectedCustomerId == null) {
              _selectedCustomerId = _customers[0]['id'];
              _selectedCustomerName = _customers[0]['name'];
              _fetchCustomerDetail(_selectedCustomerId!);
            } else {
              final exists = _customers.any((c) => c['id'] == _selectedCustomerId);
              if (!exists) {
                _selectedCustomerId = _customers[0]['id'];
                _selectedCustomerName = _customers[0]['name'];
                _fetchCustomerDetail(_selectedCustomerId!);
              }
            }
          } else {
            _selectedCustomerId = null;
            _selectedCustomerName = "";
            _selectedCustomerDetail = null;
            _selectedCustomerStats = null;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching customers: $e");
    } finally {
      setState(() {
        _isLoadingList = false;
      });
    }
  }

  Future<void> _fetchCustomerDetail(int id) async {
    setState(() {
      _isLoadingDetail = true;
    });
    try {
      final detailResponse = await _api.get(CustomerEndpoints.show(id));
      final statsResponse = await _api.get(CustomerEndpoints.stats(id));

      if (detailResponse.data['success'] == true) {
        setState(() {
          _selectedCustomerDetail = detailResponse.data['data'];
          if (statsResponse.data['success'] == true) {
            _selectedCustomerStats = statsResponse.data['data'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching customer detail: $e");
    } finally {
      setState(() {
        _isLoadingDetail = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _taxIdController.clear();
    _billingAddressController.clear();
    _internalNoteController.clear();
    setState(() {
      _selectedCustomerTier = 0; // SME
      _selectedLeadSource = null;
      _otherLeadSourceText = "";
      _selectedBranch = null;
      _selectedIndustry = null;
      _isShippingSameAsBilling = false;
      _formContacts.clear();
      _formContacts.add({
        "name": "",
        "role": null,
        "phone": "",
        "email": "",
        "line": "",
        "other_chat": "",
      });
      _formShippingAddresses.clear();
    });
  }

  Future<void> _saveCustomer() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final String companyName = _nameController.text.trim();
      final String taxId = _taxIdController.text.trim();
      final String billingAddress = _billingAddressController.text.trim();
      final String internalNote = _internalNoteController.text.trim();

      if (companyName.isEmpty) {
        throw Exception("กรุณากรอกชื่อบริษัท");
      }

      String typeStr = "SME";
      if (_selectedCustomerTier == 1) typeStr = "Mid-Market";
      if (_selectedCustomerTier == 2) typeStr = "Enterprise";

      String? leadSourceValue = _selectedLeadSource;
      if (leadSourceValue == "Referral (บอกต่อ)") leadSourceValue = "Referral";
      if (leadSourceValue == "Exhibition / Event") leadSourceValue = "Exhibition";
      if (leadSourceValue == "Others") leadSourceValue = "Other";

      final response = await _api.post(CustomerEndpoints.store, data: {
        'name': companyName,
        'type': typeStr,
        'status': 'Active',
        'tax_id': taxId.isNotEmpty ? taxId : null,
        'branch': _selectedBranch,
        'industry': _selectedIndustry,
        'lead_source': leadSourceValue,
        'internal_note': internalNote.isNotEmpty ? internalNote : null,
        'billing_address': billingAddress.isNotEmpty ? billingAddress : null,
      });

      final body = response.data;
      if (body['success'] == true) {
        final newCustomer = body['data'];
        final int customerId = newCustomer['id'];

        for (var contact in _formContacts) {
          final String name = contact['name'] ?? "";
          if (name.isNotEmpty) {
            await _api.post(CustomerEndpoints.contacts(customerId), data: {
              'name': name,
              'role': contact['role'],
              'phone': contact['phone'],
              'email': contact['email'],
              'line_id': contact['line'],
              'other_chat': contact['other_chat'],
              'is_primary': _formContacts.indexOf(contact) == 0,
            });
          }
        }

        if (!_isShippingSameAsBilling) {
          for (var addr in _formShippingAddresses) {
            final String label = addr['label'] ?? "";
            final String address = addr['address'] ?? "";
            if (label.isNotEmpty && address.isNotEmpty) {
              await _api.post(CustomerEndpoints.addresses(customerId), data: {
                'label': label,
                'address': address,
                'is_default': _formShippingAddresses.indexOf(addr) == 0,
              });
            }
          }
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("สร้างข้อมูลลูกค้า '${newCustomer['name']}' เรียบร้อยแล้ว!"),
            backgroundColor: const Color(0xFF4A9062),
          ),
        );

        _searchText = "";
        _selectedCustomerId = customerId;
        _selectedCustomerName = newCustomer['name'];
        _isCreatingMode = false;
        await _fetchCustomers();
      } else {
        throw Exception(body['error']?['message'] ?? 'บันทึกข้อมูลไม่สำเร็จ');
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("เกิดข้อผิดพลาด"),
          content: Text(ApiErrorHandler.parseError(e)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ตกลง"),
            )
          ],
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // สถานะการควบคุมหน้าจอ
  bool _isCreatingMode = false;
  bool _isEditingMode = false;
  final List<int> _deletedContactIds = [];
  final List<int> _deletedAddressIds = [];
  String _searchText = "";
  String _selectedCustomerName = "บริษัท สยามพารากอน จำกัด";

  // สถานะการพับแถบซ้าย (Drawer)
  bool _isListCollapsed = false;
  final String _selectedCustomerStatusTab = "All";

  // สถานะฟอร์ม (ตอน Create)
  int _selectedCustomerTier = 0;
  String? _selectedLeadSource;
  String _otherLeadSourceText = "";
  bool _isShippingSameAsBilling = false;
  String? _selectedBranch;
  String? _selectedIndustry;

  final List<Map<String, dynamic>> _formContacts = [
    {
      "name": "",
      "role": null,
      "phone": "",
      "email": "",
      "line": "",
      "other_chat": "",
    },
  ];
  final List<Map<String, dynamic>> _formShippingAddresses = [];

  // 🌟 Mock ข้อมูลลูกค้า (อัปเดตโครงสร้าง Contacts และ Addresses เป็นแบบ Array)
  final List<Map<String, dynamic>> _oldCustomers = [
    {
      "name": "บริษัท สยามพารากอน จำกัด",
      "type": "Enterprise",
      "customer_status": "Active",
      "active_projects_count": 2,
      "last_order_time": "1 mo ago",
      "lead_source": "Direct Contact",
      "tax_id": "0105555555555",
      "branch": "สำนักงานใหญ่ (HQ)",
      "industry": "Retail / ค้าปลีก",
      "internal_note": "ลูกค้าระดับ VIP เน้นงานด่วนและคุณภาพสูง",
      "contacts": [
        {
          "name": "คุณสมชาย",
          "role": "Procurement Manager",
          "phone": "02-123-4567",
          "email": "somchai@siamparagon.co.th",
          "line": "@siamparagon",
          "other_chat": "-",
        },
        {
          "name": "คุณวิภาดา",
          "role": "Marketing Director",
          "phone": "089-999-8888",
          "email": "wipada.mkt@siamparagon.co.th",
          "line": "wipada_sp",
          "other_chat": "-",
        },
      ],
      "billing_address":
          "991 ถนนพระรามที่ 1 แขวงปทุมวัน เขตปทุมวัน กรุงเทพมหานคร 10330",
      "shipping_addresses": [
        {
          "label": "โกดังรับสินค้า (บางพลี)",
          "address":
              "123 หมู่ 4 ถนนเทพารักษ์ ตำบลบางพลีใหญ่ อำเภอบางพลี สมุทรปราการ 10540",
        },
      ],
      "stats": {
        "revenue_lifetime": "฿ 12.5M",
        "revenue_this_year": "฿ 2.1M",
        "revenue_last_year": "฿ 4.3M",
        "projects_completed": 40,
        "projects_active": 5,
        "payment_on_time": 38,
        "payment_total": 40,
        "has_outstanding": false,
        "last_paid": "15 Apr 2026",
        "customer_since": "May 2020",
        "avg_projects_year": 7,
      },
      "projects": [
        {
          "id": "PRJ-003",
          "name": "ถุงกระดาษ Premium 50,000 ใบ",
          "status": "Ordered",
          "date_created": "10 May 2026",
          "target_date": "01 Jul 2026",
        },
        {
          "id": "PRJ-015",
          "name": "กล่องของขวัญปีใหม่ 10,000 กล่อง",
          "status": "Delivered",
          "date_created": "05 Nov 2025",
          "target_date": "20 Dec 2025",
        },
      ],
    },
    {
      "name": "Wongnai Media (LINE MAN Wongnai)",
      "type": "Mid-Market",
      "customer_status": "Active",
      "active_projects_count": 4,
      "last_order_time": "2 weeks ago",
      "lead_source": "Google Search",
      "tax_id": "0105556666666",
      "branch": "สำนักงานใหญ่ (HQ)",
      "industry": "Technology / ไอที",
      "internal_note": "ต้องการใบเสนอราคาไวภายใน 24 ชม.",
      "contacts": [
        {
          "name": "คุณนฤมล",
          "role": "Marketing Campaign Manager",
          "phone": "02-555-8888",
          "email": "narumon@wongnai.com",
          "line": "narumon.wn",
          "other_chat": "-",
        },
      ],
      "billing_address":
          "T-One Building ชั้น 26 ซอยสุขุมวิท 40 แขวงพระโขนง เขตคลองเตย กรุงเทพมหานคร 10110",
      "shipping_addresses": [],
      "stats": {
        "revenue_lifetime": "฿ 3.8M",
        "revenue_this_year": "฿ 850K",
        "revenue_last_year": "฿ 1.2M",
        "projects_completed": 15,
        "projects_active": 4,
        "payment_on_time": 14,
        "payment_total": 15,
        "has_outstanding": false,
        "last_paid": "28 May 2026",
        "customer_since": "Aug 2023",
        "avg_projects_year": 6,
      },
      "projects": [
        {
          "id": "PRJ-022",
          "name": "เสื้อแจ็คเก็ตไรเดอร์ 5,000 ตัว",
          "status": "Production",
          "date_created": "15 May 2026",
          "target_date": "30 Jun 2026",
        },
      ],
    },
    {
      "name": "ร้านเจ๊จู นำเข้าส่งออก",
      "type": "SME",
      "customer_status": "Inactive",
      "active_projects_count": 0,
      "last_order_time": "1 yr ago",
      "lead_source": "Facebook Ads",
      "tax_id": "3100000000000",
      "branch": "สาขาย่อย (Branch)",
      "industry": "Retail / ค้าปลีก",
      "internal_note": "ลูกค้ามักจะจ่ายเงินช้าประมาณ 1-2 สัปดาห์",
      "contacts": [
        {
          "name": "เจ๊จู",
          "role": "Owner / CEO",
          "phone": "081-234-5678",
          "email": "jeju_import@gmail.com",
          "line": "jeju_999",
          "other_chat": "WeChat: jeju_china",
        },
      ],
      "billing_address":
          "ตลาดสำเพ็ง ถนนราชวงศ์ แขวงจักรวรรดิ เขตสัมพันธวงศ์ กรุงเทพมหานคร 10100",
      "shipping_addresses": [
        {
          "label": "บ้านเจ๊จู (พระราม 2)",
          "address":
              "45/6 หมู่บ้าน X ถนนพระราม 2 แขวงแสมดำ เขตบางขุนเทียน กรุงเทพ 10150",
        },
      ],
      "stats": {
        "revenue_lifetime": "฿ 450K",
        "revenue_this_year": "฿ 0",
        "revenue_last_year": "฿ 100K",
        "projects_completed": 7,
        "projects_active": 0,
        "payment_on_time": 3,
        "payment_total": 7,
        "has_outstanding": true,
        "last_paid": "20 Feb 2025",
        "customer_since": "Mar 2024",
        "avg_projects_year": 3,
      },
      "projects": [],
    },
  ];

  final List<String> _leadSources = [
    "Facebook Ads",
    "Google Search",
    "Referral (บอกต่อ)",
    "Exhibition / Event",
    "Direct Contact",
    "Others",
  ];
  final List<String> _roleOptions = [
    "Owner / CEO",
    "Marketing Director",
    "Procurement Manager",
    "Marketing Officer",
    "Warehouse Manager",
    "Admin / Coordinator",
    "Other",
  ];

  List<dynamic> _getFilteredCustomers() {
    return _customers;
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _getFilteredCustomers();

    Map<String, dynamic>? selectedCustomer;
    if (!_isCreatingMode && _selectedCustomerDetail != null) {
      final stats = {
        "revenue_lifetime": "฿${((_selectedCustomerStats?['revenue_lifetime'] ?? 0) / 1000000).toStringAsFixed(1)}M",
        "revenue_this_year": "฿${((_selectedCustomerStats?['revenue_lifetime'] ?? 0) * 0.4 / 1000).toStringAsFixed(0)}K",
        "revenue_last_year": "฿${((_selectedCustomerStats?['revenue_lifetime'] ?? 0) * 0.6 / 1000).toStringAsFixed(0)}K",
        "projects_completed": _selectedCustomerStats?['projects_completed'] ?? 0,
        "projects_active": _selectedCustomerStats?['projects_active'] ?? 0,
        "payment_on_time": _selectedCustomerStats?['payment_on_time'] ?? 100,
        "payment_total": 100,
        "has_outstanding": _selectedCustomerStats?['has_outstanding'] ?? false,
        "last_paid": "N/A",
        "customer_since": _selectedCustomerStats?['customer_since'] ?? "N/A",
        "avg_projects_year": 0,
      };

      final List<dynamic> dbProjects = _selectedCustomerDetail!['projects'] ?? [];
      final List<Map<String, dynamic>> mappedProjects = dbProjects.map((p) {
        return {
          "id": p['project_code'] ?? "PRJ-${p['id']}",
          "name": (p['product_items'] != null && (p['product_items'] as List).isNotEmpty)
              ? p['product_items'][0]['name']
              : "โปรเจกต์ #${p['id']}",
          "status": p['status'] ?? "Pending",
          "date_created": p['created_at'] != null ? p['created_at'].toString().split('T')[0] : "-",
          "target_date": p['target_date'] ?? "-",
        };
      }).toList();

      final List<dynamic> dbContacts = _selectedCustomerDetail!['contacts'] ?? [];
      final List<Map<String, dynamic>> mappedContacts = dbContacts.map((c) {
        return {
          "name": c['name'] ?? "",
          "role": c['role'] ?? "-",
          "phone": c['phone'] ?? "-",
          "email": c['email'] ?? "-",
          "line": c['line_id'] ?? "-",
          "other_chat": c['other_chat'] ?? "-",
        };
      }).toList();

      final List<dynamic> dbAddresses = _selectedCustomerDetail!['shipping_addresses'] ?? [];
      final List<Map<String, dynamic>> mappedAddresses = dbAddresses.map((a) {
        return {
          "label": a['label'] ?? "",
          "address": a['address'] ?? "",
        };
      }).toList();

      selectedCustomer = {
        ..._selectedCustomerDetail!,
        "stats": stats,
        "projects": mappedProjects,
        "contacts": mappedContacts,
        "shipping_addresses": mappedAddresses,
      };
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: Customer List (Collapsible)
          // ==========================================
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isListCollapsed ? 80 : 340,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
            ),
            child: _isListCollapsed
                ? Column(
                    children: [
                      const SizedBox(height: 32),
                      IconButton(
                        icon: const Icon(Icons.menu, color: Color(0xFF1D1D1F)),
                        tooltip: "Expand List",
                        onPressed: () =>
                            setState(() => _isListCollapsed = false),
                      ),
                      const SizedBox(height: 24),
                      IconButton(
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: Color(0xFF2563EB),
                        ),
                        tooltip: "Create New Customer",
                        onPressed: () {
                          _clearForm();
                          setState(() {
                            _isCreatingMode = true;
                            _isListCollapsed = false;
                          });
                        },
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            InkWell(
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
                            IconButton(
                              icon: const Icon(
                                Icons.menu_open_rounded,
                                color: Color(0xFF86868B),
                              ),
                              tooltip: "Collapse List",
                              onPressed: () =>
                                  setState(() => _isListCollapsed = true),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: const Text(
                          "Customers",
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
                        child: InkWell(
                          onTap: () {
                            _clearForm();
                            setState(() => _isCreatingMode = true);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2563EB).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.person_add_alt_1,
                                  color: Color(0xFF2563EB),
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Create Customer",
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold,
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
                        child: TextField(
                          onChanged: (val) {
                            setState(() => _searchText = val);
                            _fetchCustomers();
                          },
                          decoration: InputDecoration(
                            hintText: "ค้นหาชื่อบริษัท...",
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
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredCustomers.isEmpty
                            ? const Center(
                                child: Text(
                                  "ไม่พบข้อมูล",
                                  style: TextStyle(color: Color(0xFF86868B)),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final c = filteredCustomers[index];
                                  final isSelected =
                                      !_isCreatingMode &&
                                      _selectedCustomerId == c['id'];
                                  final bool isActiveCustomer =
                                      (c['status'] ?? 'Active') == 'Active';

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isCreatingMode = false;
                                        _isEditingMode = false;
                                        _selectedCustomerId = c['id'];
                                        _selectedCustomerName = c['name'];
                                      });
                                      _fetchCustomerDetail(c['id']);
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  c['name'] ?? "",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF5B7BD5,
                                                          )
                                                        : const Color(
                                                            0xFF1D1D1F,
                                                          ),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isActiveCustomer)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color(
                                                          0xFF10B981,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "${c['active_projects_count']} active · last order ${c['last_order_time']}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF86868B),
                                              fontWeight: FontWeight.w500,
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
          // 2. RIGHT PANEL: สลับระหว่าง Profile กับ Form
          // ==========================================
          Expanded(
            child: _isCreatingMode
                ? _buildCreateCustomerForm()
                : (_isLoadingDetail
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                        ),
                      )
                    : (selectedCustomer == null
                        ? const Center(
                            child: Text(
                              "กรุณาเลือกลูกค้า",
                              style: TextStyle(color: Color(0xFF86868B)),
                            ),
                          )
                        : _buildCustomerProfile(selectedCustomer))),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // WIDGET 1: CUSTOMER PROFILE (80/20 Layout + Dynamic Display)
  // =========================================================
  Widget _buildCustomerProfile(Map<String, dynamic> customer) {
    Map<String, dynamic> stats = customer['stats'];
    int percentOnTime = (stats['payment_total'] > 0)
        ? ((stats['payment_on_time'] / stats['payment_total']) * 100).round()
        : 0;

    // จัดการข้อมูลที่อาจจะเป็นแบบใหม่หรือเก่า (รองรับ Mock Data)
    List<dynamic> contacts = customer['contacts'] ?? [];
    String billingAddress =
        customer['billing_address'] ?? customer['address'] ?? "-";
    List<dynamic> shippingAddresses = customer['shipping_addresses'] ?? [];
    String taxId = customer['tax_id'] ?? "-";
    String branch = customer['branch'] ?? "-";
    String industry = customer['industry'] ?? "-";
    String note = customer['internal_note'] ?? "ไม่มีหมายเหตุ";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: customer['type'] == 'Enterprise'
                                ? const Color(0xFFAEC4FA).withOpacity(0.2)
                                : const Color(0xFFB7E4C7).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            customer['type'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: customer['type'] == 'Enterprise'
                                  ? const Color(0xFF5B7BD5)
                                  : const Color(0xFF4A9062),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAE4F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Lead: ${customer['lead_source']}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF86868B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      customer['name'],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildButton(
                    "Edit Customer Detail",
                    Colors.white,
                    const Color(0xFF1D1D1F),
                    isOutlined: true,
                    onTap: () {
                      if (_selectedCustomerDetail == null) return;
                      if (_selectedCustomerId != _selectedCustomerDetail!['id']) return;

                      // 1. Populate controller values
                      _nameController.text = _selectedCustomerDetail!['name'] ?? "";
                      _taxIdController.text = _selectedCustomerDetail!['tax_id'] ?? "";
                      _billingAddressController.text = _selectedCustomerDetail!['billing_address'] ?? _selectedCustomerDetail!['address'] ?? "";
                      _internalNoteController.text = _selectedCustomerDetail!['internal_note'] ?? "";

                      // 2. Set dropdown and select values
                      _selectedBranch = _selectedCustomerDetail!['branch'];
                      _selectedIndustry = _selectedCustomerDetail!['industry'];

                      String? source = _selectedCustomerDetail!['lead_source'];
                      if (source == "Referral") source = "Referral (บอกต่อ)";
                      if (source == "Exhibition") source = "Exhibition / Event";
                      if (source == "Other") source = "Others";
                      _selectedLeadSource = source;

                      String type = _selectedCustomerDetail!['type'] ?? "SME";
                      if (type == "Mid-Market") {
                        _selectedCustomerTier = 1;
                      } else if (type == "Enterprise") {
                        _selectedCustomerTier = 2;
                      } else {
                        _selectedCustomerTier = 0;
                      }

                      // 3. Clear/set contacts and addresses
                      _formContacts.clear();
                      final dbContacts = _selectedCustomerDetail!['contacts'] ?? [];
                      if (dbContacts.isNotEmpty) {
                        for (var c in dbContacts) {
                          _formContacts.add({
                            'id': c['id'],
                            'name': c['name'] ?? "",
                            'role': c['role'],
                            'phone': c['phone'] ?? "",
                            'email': c['email'] ?? "",
                            'line': c['line_id'] ?? "",
                            'other_chat': c['other_chat'] ?? "",
                          });
                        }
                      } else {
                        _formContacts.add({
                          'name': "",
                          'role': null,
                          'phone': "",
                          'email': "",
                          'line': "",
                          'other_chat': "",
                        });
                      }

                      _formShippingAddresses.clear();
                      final dbAddresses = _selectedCustomerDetail!['shipping_addresses'] ?? [];
                      if (dbAddresses.isNotEmpty) {
                        _isShippingSameAsBilling = false;
                        for (var a in dbAddresses) {
                          _formShippingAddresses.add({
                            'id': a['id'],
                            'label': a['label'] ?? "",
                            'address': a['address'] ?? "",
                          });
                        }
                      } else {
                        _isShippingSameAsBilling = true;
                      }

                      // 4. Initialize deleted lists
                      _deletedContactIds.clear();
                      _deletedAddressIds.clear();

                      setState(() {
                        _isEditingMode = true;
                        _isCreatingMode = true;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildButton(
                    "+ Create New Project",
                    const Color(0xFF2563EB),
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
              ),
            ],
          ),
          const SizedBox(height: 48),

          // --- Body Layout (80% Detail & History, 20% Stats) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 80% AREA: Contact Detail & Project History
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌟 1. Company Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.domain,
                                size: 20,
                                color: Color(0xFF86868B),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Company Information",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildReadOnlyField("Tax ID", taxId),
                              ),
                              Expanded(
                                child: _buildReadOnlyField("Branch", branch),
                              ),
                              Expanded(
                                child: _buildReadOnlyField(
                                  "Industry",
                                  industry,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🌟 2. Contacts Card (วนลูปสร้างรายคน)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.people_alt_outlined,
                                size: 20,
                                color: Color(0xFF86868B),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Contact Persons",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // ลูปโชว์ Contacts
                          ...contacts.asMap().entries.map((entry) {
                            int index = entry.key;
                            var contact = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F9FC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: index == 0
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF86868B),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          index == 0 ? "Primary" : "Secondary",
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        contact['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D1D1F),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        contact['role'] ?? "-",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF86868B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildContactRow(
                                          Icons.phone_outlined,
                                          contact['phone'],
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildContactRow(
                                          Icons.email_outlined,
                                          contact['email'],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildContactRow(
                                          Icons.chat_bubble_outline,
                                          "Line: ${contact['line']}",
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildContactRow(
                                          Icons.forum_outlined,
                                          "Other: ${contact['other_chat'] ?? "-"}",
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🌟 3. Locations Card (Billing + Shipping)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                      color: Color(0xFF86868B),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Locations & Addresses",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D1D1F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  "Billing Address",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF86868B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  billingAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1D1D1F),
                                    height: 1.5,
                                  ),
                                ),

                                if (shippingAddresses.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  const Divider(color: Color(0xFFF4F5F7)),
                                  const SizedBox(height: 24),
                                  const Text(
                                    "Shipping Addresses",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF86868B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...shippingAddresses.map((addr) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F9FC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            addr['label'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF5B7BD5),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            addr['address'],
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF1D1D1F),
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ] else ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    "Shipping address is the same as billing address.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF86868B),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Internal Note
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.note_alt_outlined,
                                      size: 20,
                                      color: Color(0xFFD97706),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Internal Notes",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  note,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF92400E),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Project History Table
                    const Text(
                      "Project History",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFF4F5F7)),
                              ),
                            ),
                            child: Row(
                              children: const [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "ID",
                                    style: TextStyle(
                                      color: Color(0xFF86868B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    "Product Name",
                                    style: TextStyle(
                                      color: Color(0xFF86868B),
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
                                      color: Color(0xFF86868B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Date Created",
                                    style: TextStyle(
                                      color: Color(0xFF86868B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Target Date",
                                    style: TextStyle(
                                      color: Color(0xFF86868B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                              ],
                            ),
                          ),
                          if ((customer['projects'] as List).isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  "No project history",
                                  style: TextStyle(color: Color(0xFF86868B)),
                                ),
                              ),
                            ),
                          ...(customer['projects'] as List).map((project) {
                            bool isCompleted = project['status'] == 'Delivered';
                            bool isOrdered = project['status'] == 'Ordered';
                            Color statusColor = isCompleted
                                ? const Color(0xFF4A9062)
                                : (isOrdered
                                      ? const Color(0xFF5B7BD5)
                                      : const Color(0xFFD97781));
                            Color statusBgColor = isCompleted
                                ? const Color(0xFFB7E4C7).withOpacity(0.3)
                                : (isOrdered
                                      ? const Color(0xFFAEC4FA).withOpacity(0.2)
                                      : const Color(
                                          0xFFFDE2E4,
                                        ).withOpacity(0.5));

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProjectListScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFF4F5F7),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        project['id'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1D1D1F),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        project['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusBgColor,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            project['status'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        project['date_created'],
                                        style: const TextStyle(
                                          color: Color(0xFF86868B),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        project['target_date'],
                                        style: const TextStyle(
                                          color: Color(0xFF1D1D1F),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: Color(0xFF86868B),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),

              // 20% AREA: Statistics
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick Stats",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRichStatCard(
                      "Total Revenue (Life Time)",
                      stats['revenue_lifetime'],
                      [
                        "฿${stats['revenue_this_year']} this year",
                        "฿${stats['revenue_last_year']} last year",
                      ],
                      Icons.monetization_on_outlined,
                      const Color(0xFFB7E4C7),
                    ),
                    const SizedBox(height: 12),
                    _buildRichStatCard(
                      "Projects",
                      "${stats['projects_completed']} completed",
                      ["${stats['projects_active']} active projects"],
                      Icons.inventory_2_outlined,
                      const Color(0xFFE2E2E2),
                    ),
                    const SizedBox(height: 12),
                    _buildRichStatCard(
                      "Payment Status",
                      "${stats['payment_on_time']}/${stats['payment_total']} paid on time ($percentOnTime%)",
                      [
                        stats['has_outstanding']
                            ? "⚠️ Has outstanding balance"
                            : "No outstanding balance",
                        "Last paid: ${stats['last_paid']}",
                      ],
                      Icons.verified_user_outlined,
                      stats['has_outstanding']
                          ? const Color(0xFFFDE2E4)
                          : const Color(0xFFAEC4FA),
                    ),
                    const SizedBox(height: 12),
                    _buildRichStatCard(
                      "Customer Since",
                      stats['customer_since'],
                      ["Avg ${stats['avg_projects_year']} projects/year"],
                      Icons.history_rounded,
                      const Color(0xFFEAE4F2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // WIDGET 2: CREATE CUSTOMER FORM
  // =========================================================
  Widget _buildCreateCustomerForm() {
    return SingleChildScrollView(
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
                  Text(
                    _isEditingMode ? "Edit Customer Details" : "Create New Customer",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D1D1F),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditingMode
                        ? "แก้ไขรายละเอียดข้อมูลของบริษัทและผู้ติดต่อ"
                        : "เพิ่มข้อมูลบริษัทและช่องทางการติดต่อสำหรับ CRM",
                    style: const TextStyle(fontSize: 16, color: Color(0xFF86868B)),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildButton(
                    "Cancel",
                    Colors.white,
                    const Color(0xFF1D1D1F),
                    isOutlined: true,
                    onTap: () => _confirmCancelCreation(context),
                  ),
                  const SizedBox(width: 16),
                  _buildButton(
                    _isEditingMode ? "Update Customer" : "Save Customer",
                    const Color(0xFF2563EB),
                    Colors.white,
                    onTap: () => _isEditingMode
                        ? _confirmSaveEdit(context)
                        : _confirmSaveCreation(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // --- Section 1: Company Profile ---
          _buildSectionCard(
            title: "Company Profile",
            icon: Icons.domain,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInputField(
                        "Company Name / ชื่อบริษัท *",
                        "เช่น บริษัท พีพีเอ็น จำกัด",
                        controller: _nameController,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildDropdownField(
                        "Branch / สาขา",
                        "เลือกสาขา",
                        ["สำนักงานใหญ่ (HQ)", "สาขาย่อย (Branch)"],
                        _selectedBranch,
                        (val) => setState(() => _selectedBranch = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        "Tax ID / เลขประจำตัวผู้เสียภาษี *",
                        "X-XXXX-XXXXX-XX-X",
                        isNumber: true,
                        controller: _taxIdController,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildDropdownField(
                        "Industry / ประเภทธุรกิจ",
                        "เลือกอุตสาหกรรม",
                        [
                          "Retail / ค้าปลีก",
                          "Manufacturing / โรงงาน",
                          "Healthcare / สุขภาพ",
                          "Technology / ไอที",
                          "Food & Beverage / อาหาร",
                          "Other / อื่นๆ",
                        ],
                        _selectedIndustry,
                        (val) => setState(() => _selectedIndustry = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Section 2: CRM & Lead Tracking ---
          _buildSectionCard(
            title: "CRM & Lead Tracking",
            icon: Icons.radar,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Customer Tier (ขนาดธุรกิจ)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message:
                                "SME: <200 staff\nMid-Market: 200-2000 staff\nEnterprise: >2000 staff",
                            child: const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Color(0xFF86868B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTierSelector(),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Lead Source (รู้จักเราจากช่องทางไหน?)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _leadSources
                            .map((source) => _buildLeadSourceChip(source))
                            .toList(),
                      ),
                      // กล่องข้อความแสดงเมื่อเลือก Others
                      if (_selectedLeadSource == "Others") ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: "โปรดระบุเพิ่มเติม...",
                            filled: true,
                            fillColor: const Color(0xFFF4F5F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) => _otherLeadSourceText = val,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- 🌟 Section 3: Contact Persons (Multi-Contacts) ---
          _buildSectionCard(
            title: "Contact Persons",
            icon: Icons.people_alt_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._formContacts.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> contact = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              index == 0
                                  ? "Primary Contact (ผู้ติดต่อหลัก)"
                                  : "Secondary Contact $index",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B7BD5),
                              ),
                            ),
                            if (index > 0)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (contact['id'] != null) {
                                    _deletedContactIds.add(contact['id'] as int);
                                  }
                                  setState(() => _formContacts.removeAt(index));
                                },
                                tooltip: "Remove Contact",
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                "Full Name / ชื่อ-นามสกุล *",
                                "ชื่อผู้ติดต่อ",
                                initialValue: contact['name'],
                                onChanged: (val) => contact['name'] = val,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildDropdownField(
                                "Role & Position / บทบาทและตำแหน่ง",
                                "เลือกบทบาทหรือตำแหน่ง",
                                _roleOptions,
                                contact['role'],
                                (val) => setState(() => contact['role'] = val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                "Phone Number *",
                                "08X-XXX-XXXX",
                                isNumber: true,
                                icon: Icons.phone,
                                initialValue: contact['phone'],
                                onChanged: (val) => contact['phone'] = val,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildInputField(
                                "Email Address *",
                                "email@company.com",
                                icon: Icons.email_outlined,
                                initialValue: contact['email'],
                                onChanged: (val) => contact['email'] = val,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                "Line ID",
                                "ไอดีไลน์",
                                icon: Icons.chat,
                                initialValue: contact['line'],
                                onChanged: (val) => contact['line'] = val,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildInputField(
                                "Other Chat",
                                "WeChat, Telegram...",
                                icon: Icons.forum_outlined,
                                initialValue: contact['other_chat'],
                                onChanged: (val) => contact['other_chat'] = val,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _formContacts.add({
                        "name": "",
                        "role": null,
                        "phone": "",
                        "email": "",
                        "line": "",
                        "other_chat": "",
                      });
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Another Contact"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D1D1F),
                    side: const BorderSide(color: Color(0xFFE2E2E2)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- 🌟 Section 4: Locations (Multi-Addresses) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _buildSectionCard(
                  title: "Locations & Addresses",
                  icon: Icons.location_on_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        "Billing Address (ที่อยู่ออกบิล) *",
                        "กรอกที่อยู่สำหรับออกใบกำกับภาษี (บังคับ)",
                        maxLines: 3,
                        controller: _billingAddressController,
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFF4F5F7), height: 1),
                      const SizedBox(height: 24),

                      const Text(
                        "Shipping Addresses (ที่อยู่จัดส่ง)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Switch(
                            value: _isShippingSameAsBilling,
                            activeThumbColor: const Color(0xFF4A9062),
                            activeTrackColor: const Color(0xFFB7E4C7),
                            onChanged: (val) =>
                                setState(() => _isShippingSameAsBilling = val),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "ใช้ที่อยู่จัดส่งเดียวกับที่อยู่ออกบิล",
                            style: TextStyle(color: Color(0xFF1D1D1F)),
                          ),
                        ],
                      ),
                      if (!_isShippingSameAsBilling) ...[
                        if (_formShippingAddresses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              "ยังไม่มีข้อมูลที่อยู่จัดส่ง กรุณากดปุ่มเพิ่มด้านล่าง",
                              style: TextStyle(
                                color: Color(0xFF86868B),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ..._formShippingAddresses.asMap().entries.map((entry) {
                          int index = entry.key;
                          final addr = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                        "Address Label (ป้ายกำกับ)",
                                        "เช่น สาขาเชียงใหม่, โกดังรังสิต",
                                        initialValue: addr['label'],
                                        onChanged: (val) => addr['label'] = val,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFEF4444),
                                      ),
                                      onPressed: () {
                                        if (addr['id'] != null) {
                                          _deletedAddressIds.add(addr['id'] as int);
                                        }
                                        setState(() => _formShippingAddresses.removeAt(index));
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  "Full Address",
                                  "กรอกที่อยู่จัดส่งแบบเต็ม...",
                                  maxLines: 2,
                                  initialValue: addr['address'],
                                  onChanged: (val) => addr['address'] = val,
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _formShippingAddresses.add({
                                "label": "",
                                "address": "",
                              });
                            });
                          },
                          icon: const Icon(
                            Icons.add_location_alt_outlined,
                            color: Color(0xFF5B7BD5),
                          ),
                          label: const Text(
                            "Add Shipping Address",
                            style: TextStyle(
                              color: Color(0xFF5B7BD5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: "Internal Notes",
                      icon: Icons.note_alt_outlined,
                      child: _buildInputField(
                        "Remarks",
                        "พิมพ์หมายเหตุเพิ่มเติมสำหรับเซลส์หรือแอดมิน...",
                        maxLines: 5,
                        controller: _internalNoteController,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "💡 Note: Only administrators have permission to delete customer profiles.",
                      style: TextStyle(
                        color: Color(0xFF86868B),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildDropdownField(
    String label,
    String hint,
    List<String> items,
    String? currentValue,
    Function(String?) onChanged,
  ) {
    // ป้องกันการแครชของ DropdownButtonFormField ในกรณีที่ค่าจากฐานข้อมูลไม่มีอยู่ในรายการตัวเลือก
    final dropdownItems = List<String>.from(items);
    if (currentValue != null && !dropdownItems.contains(currentValue)) {
      dropdownItems.add(currentValue);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFFB4B4B8), fontSize: 13),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF4F5F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: dropdownItems
              .map(
                (String value) =>
                    DropdownMenuItem<String>(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF86868B)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1D1D1F)),
          ),
        ),
      ],
    );
  }

  Widget _buildRichStatCard(
    String title,
    String mainValue,
    List<String> subTexts,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1D1D1F), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF86868B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mainValue,
                  style: const TextStyle(
                    color: Color(0xFF1D1D1F),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                ...subTexts.map((text) {
                  bool isAlert = text.contains("⚠️");
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAlert ? "" : "• ",
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: isAlert
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: isAlert
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF1D1D1F)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint, {
    int maxLines = 1,
    bool isNumber = false,
    IconData? icon,
    TextEditingController? controller,
    String? initialValue,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB4B4B8), fontSize: 13),
            suffixIcon: icon != null
                ? Icon(icon, size: 18, color: const Color(0xFF86868B))
                : null,
            filled: true,
            fillColor: const Color(0xFFF4F5F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTierSelector() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTierOption("SME", 0)),
          Expanded(child: _buildTierOption("Mid-Market", 1)),
          Expanded(child: _buildTierOption("Enterprise", 2)),
        ],
      ),
    );
  }

  Widget _buildTierOption(String title, int index) {
    final isSelected = _selectedCustomerTier == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCustomerTier = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF1D1D1F)
                : const Color(0xFF86868B),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLeadSourceChip(String source) {
    final isSelected = _selectedLeadSource == source;
    return InkWell(
      onTap: () =>
          setState(() => _selectedLeadSource = isSelected ? null : source),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B7BD5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5B7BD5)
                : const Color(0xFFE2E2E2),
          ),
        ),
        child: Text(
          source,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF86868B),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    String title,
    Color bgColor,
    Color textColor, {
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
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Dialog ยืนยันการยกเลิกสร้าง/แก้ไขลูกค้า
  void _confirmCancelCreation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _isEditingMode ? "Cancel Editing?" : "Cancel Creation?",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFD97781),
          ),
        ),
        content: Text(
          _isEditingMode
              ? "Are you sure you want to discard your edits? Unsaved changes will be lost."
              : "Are you sure you want to discard this form? All entered data will be lost.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No", style: TextStyle(color: Color(0xFF86868B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isCreatingMode = false;
                _isEditingMode = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97781),
            ),
            child: const Text(
              "Yes, Discard",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog ยืนยันการบันทึกลูกค้า
  void _confirmSaveCreation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Save New Customer",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        content: const Text(
          "Are you sure you want to create this customer profile?",
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
              Navigator.pop(ctx);
              _saveCustomer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text(
              "Confirm & Save",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog ยืนยันการแก้ไขข้อมูลลูกค้า
  void _confirmSaveEdit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Update Customer Profile",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        content: const Text(
          "Are you sure you want to save changes to this customer profile?",
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
              Navigator.pop(ctx);
              _updateCustomer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text(
              "Confirm & Save",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันอัปเดตข้อมูลลูกค้า
  Future<void> _updateCustomer() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final String companyName = _nameController.text.trim();
      final String taxId = _taxIdController.text.trim();
      final String billingAddress = _billingAddressController.text.trim();
      final String internalNote = _internalNoteController.text.trim();

      if (companyName.isEmpty) {
        throw Exception("กรุณากรอกชื่อบริษัท");
      }

      String typeStr = "SME";
      if (_selectedCustomerTier == 1) typeStr = "Mid-Market";
      if (_selectedCustomerTier == 2) typeStr = "Enterprise";

      String? leadSourceValue = _selectedLeadSource;
      if (leadSourceValue == "Referral (บอกต่อ)") leadSourceValue = "Referral";
      if (leadSourceValue == "Exhibition / Event") leadSourceValue = "Exhibition";
      if (leadSourceValue == "Others") leadSourceValue = "Other";

      final int customerId = _selectedCustomerId!;

      // 1. อัปเดตข้อมูลลูกค้าพื้นฐาน
      final response = await _api.put(CustomerEndpoints.update(customerId), data: {
        'name': companyName,
        'type': typeStr,
        'tax_id': taxId.isNotEmpty ? taxId : null,
        'branch': _selectedBranch,
        'industry': _selectedIndustry,
        'lead_source': leadSourceValue,
        'internal_note': internalNote.isNotEmpty ? internalNote : null,
        'billing_address': billingAddress.isNotEmpty ? billingAddress : null,
      });

      final body = response.data;
      if (body['success'] == true) {
        // 2. ลบผู้ติดต่อที่กดลบ
        for (var cid in _deletedContactIds) {
          try {
            await _api.delete(CustomerEndpoints.deleteContact(customerId, cid));
          } catch (e) {
            debugPrint("Error deleting contact $cid: $e");
          }
        }

        // 3. ลบที่อยู่ที่กดลบ
        for (var aid in _deletedAddressIds) {
          try {
            await _api.delete(CustomerEndpoints.deleteAddress(customerId, aid));
          } catch (e) {
            debugPrint("Error deleting address $aid: $e");
          }
        }

        // 4. สร้างหรืออัปเดตผู้ติดต่อ
        for (var contact in _formContacts) {
          final String name = contact['name'] ?? "";
          if (name.isNotEmpty) {
            final contactPayload = {
              'name': name,
              'role': contact['role'],
              'phone': contact['phone'],
              'email': contact['email'],
              'line_id': contact['line'],
              'other_chat': contact['other_chat'],
              'is_primary': _formContacts.indexOf(contact) == 0,
            };

            if (contact['id'] != null) {
              // อัปเดตอันเดิม
              await _api.put(
                CustomerEndpoints.updateContact(customerId, contact['id']),
                data: contactPayload,
              );
            } else {
              // สร้างอันใหม่
              await _api.post(
                CustomerEndpoints.contacts(customerId),
                data: contactPayload,
              );
            }
          }
        }

        // 5. สร้างหรืออัปเดตที่อยู่จัดส่ง (หากไม่เหมือนกับที่อยู่ออกบิล)
        if (!_isShippingSameAsBilling) {
          for (var addr in _formShippingAddresses) {
            final String label = addr['label'] ?? "";
            final String address = addr['address'] ?? "";
            if (label.isNotEmpty && address.isNotEmpty) {
              final addressPayload = {
                'label': label,
                'address': address,
                'is_default': _formShippingAddresses.indexOf(addr) == 0,
              };

              if (addr['id'] != null) {
                // อัปเดตอันเดิม
                await _api.put(
                  CustomerEndpoints.updateAddress(customerId, addr['id']),
                  data: addressPayload,
                );
              } else {
                // สร้างอันใหม่
                await _api.post(
                  CustomerEndpoints.addresses(customerId),
                  data: addressPayload,
                );
              }
            }
          }
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("อัปเดตข้อมูลลูกค้า '$companyName' เรียบร้อยแล้ว!"),
            backgroundColor: const Color(0xFF4A9062),
          ),
        );

        _isCreatingMode = false;
        _isEditingMode = false;
        await _fetchCustomers();
        await _fetchCustomerDetail(customerId);
      } else {
        throw Exception(body['error']?['message'] ?? 'อัปเดตข้อมูลไม่สำเร็จ');
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("เกิดข้อผิดพลาด"),
          content: Text(ApiErrorHandler.parseError(e)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ตกลง"),
            )
          ],
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
