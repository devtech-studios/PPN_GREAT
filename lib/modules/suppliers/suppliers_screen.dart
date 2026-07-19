import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final ApiClient _api = ApiClient();

  bool _isLoadingSuppliers = false;
  bool _isLoadingProjects = false;
  bool _isLoadingQuotes = false;
  bool _isLoadingSamples = false;
  bool _isLoadingBills = false;

  List<dynamic> _suppliersDb = [];
  List<dynamic> _dbQuotes = [];
  List<dynamic> _dbSamples = [];
  List<dynamic> _dbBills = [];
  List<dynamic> _projectsDb = [];

  int? _selectedSupplierDbId;
  String _activeTab = "Quotes"; // Tab เริ่มต้น: Quotes / Samples / Payments
  String _searchText = "";

  // Set สำหรับเก็บบิลที่ถูกติ๊กเลือกเพื่อจ่ายหรือเลื่อน
  final Set<int> _selectedBillIds = {};

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
    _fetchProjects();
  }

  Future<void> _fetchSuppliers() async {
    setState(() {
      _isLoadingSuppliers = true;
    });
    try {
      final response = await _api.get(SupplierEndpoints.index);
      final body = response.data;
      if (body['success'] == true) {
        setState(() {
          _suppliersDb = body['data'];
          if (_suppliersDb.isNotEmpty) {
            if (_selectedSupplierDbId == null ||
                !_suppliersDb.any((s) => s['id'] == _selectedSupplierDbId)) {
              _selectedSupplierDbId = _suppliersDb.first['id'];
            }
            _fetchSupplierDetails(_selectedSupplierDbId!);
          } else {
            _selectedSupplierDbId = null;
            _dbQuotes = [];
            _dbSamples = [];
            _dbBills = [];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching suppliers: $e");
    } finally {
      setState(() {
        _isLoadingSuppliers = false;
      });
    }
  }

  Future<void> _fetchProjects() async {
    setState(() {
      _isLoadingProjects = true;
    });
    try {
      final response = await _api.get(ProjectEndpoints.index);
      final body = response.data;
      if (body['success'] == true) {
        setState(() {
          _projectsDb = body['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching projects: $e");
    } finally {
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _fetchSupplierDetails(int supplierId) async {
    _fetchQuotes(supplierId);
    _fetchSamples(supplierId);
    _fetchBills(supplierId);
  }

  Future<void> _fetchQuotes(int supplierId) async {
    setState(() {
      _isLoadingQuotes = true;
    });
    try {
      final response = await _api.get(SupplierEndpoints.quotes(supplierId));
      final body = response.data;
      if (body['success'] == true) {
        setState(() {
          _dbQuotes = body['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching quotes: $e");
    } finally {
      setState(() {
        _isLoadingQuotes = false;
      });
    }
  }

  Future<void> _fetchSamples(int supplierId) async {
    setState(() {
      _isLoadingSamples = true;
    });
    try {
      final response = await _api.get(SupplierEndpoints.samples(supplierId));
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

  Future<void> _fetchBills(int supplierId) async {
    setState(() {
      _isLoadingBills = true;
    });
    try {
      final response = await _api.get(SupplierEndpoints.bills(supplierId));
      final body = response.data;
      if (body['success'] == true) {
        setState(() {
          _dbBills = body['data'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching bills: $e");
    } finally {
      setState(() {
        _isLoadingBills = false;
      });
    }
  }

  Future<void> _paySelectedBills(int supplierId) async {
    if (_selectedBillIds.isEmpty) return;
    setState(() {
      _isLoadingBills = true;
    });
    try {
      for (int bid in _selectedBillIds) {
        await _api.patch(SupplierEndpoints.payBill(supplierId, bid));
      }
      _showSuccessBanner("บันทึกการโอนเงินออกให้ซัพพลายเออร์สำเร็จ");
      setState(() {
        _selectedBillIds.clear();
      });
      _fetchBills(supplierId);
    } catch (e) {
      debugPrint("Error paying bills: $e");
    } finally {
      setState(() {
        _isLoadingBills = false;
      });
    }
  }

  Future<void> _createBill({
    required int supplierId,
    required String projectId,
    required String productName,
    required String billType,
    required double amount,
    required String currency,
    required String dueMonth,
  }) async {
    try {
      final response = await _api.post(
        SupplierEndpoints.bills(supplierId),
        data: {
          'project_id': int.parse(projectId),
          'product_name': productName,
          'bill_type': billType,
          'amount': amount,
          'currency': currency,
          'due_month': dueMonth,
        },
      );
      if (response.data['success'] == true) {
        _showSuccessBanner("เพิ่มบิลค่าใช้จ่ายใหม่สำเร็จ");
        _fetchBills(supplierId);
      }
    } catch (e) {
      debugPrint("Error creating bill: $e");
    }
  }

  void _showAddBillDialog(BuildContext context, Map<String, dynamic> supplier) {
    String? selectedProjId;
    String prodName = "";
    String billType = "Deposit";
    String amount = "";
    String currency = "THB";
    String dueMonth =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create Supplier Bill",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "สร้างบิลค่าใช้จ่ายใหม่สำหรับโรงงานนี้",
                    style: TextStyle(color: Color(0xFF86868B)),
                  ),
                  const Divider(height: 48),

                  // Project Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Project",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedProjId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Project",
                          hintText: "เลือกโปรเจกต์",
                          filled: true,
                          fillColor: const Color(0xFFF4F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _projectsDb
                            .map(
                              (p) => DropdownMenuItem(
                                value: p['id']?.toString(),
                                child: Text(
                                  "${p['project_code']} - ${p['customer']?['name'] ?? ''}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedProjId = val;
                            var prj = _projectsDb.firstWhere(
                              (p) => p['id']?.toString() == val,
                            );
                            var prodItems = prj['product_items'] as List? ?? [];
                            if (prodItems.isNotEmpty) {
                              prodName =
                                  prodItems.first['name']?.toString() ?? '';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Product Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Product Name",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: TextEditingController(text: prodName)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: prodName.length),
                          ),
                        onChanged: (val) => prodName = val,
                        decoration: InputDecoration(
                          labelText: "Product Name",
                          filled: true,
                          fillColor: const Color(0xFFF4F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bill Type & Currency
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Bill Type",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: billType,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: ["Deposit", "Balance", "Full Payment"]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setDialogState(() => billType = val!),
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
                              "Currency",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: currency,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: ["THB", "USD"]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setDialogState(() => currency = val!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount & Due Month
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Amount",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              onChanged: (val) => amount = val,
                              decoration: InputDecoration(
                                hintText: "0.00",
                                errorText: errorText,
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                              "Due Month (YYYY-MM)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: TextEditingController(text: dueMonth),
                              onChanged: (val) => dueMonth = val,
                              decoration: InputDecoration(
                                labelText: "Due Month (YYYY-MM)",
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (selectedProjId == null) {
                            setDialogState(
                              () => errorText = "Project is required",
                            );
                            return;
                          }
                          if (amount.isEmpty ||
                              double.tryParse(amount) == null) {
                            setDialogState(
                              () => errorText = "Valid amount is required",
                            );
                            return;
                          }
                          _createBill(
                            supplierId: supplier['id'] ?? 0,
                            projectId: selectedProjId!,
                            productName: prodName.isNotEmpty
                                ? prodName
                                : "สินค้าไม่ระบุชื่อ",
                            billType: billType,
                            amount: double.parse(amount),
                            currency: currency,
                            dueMonth: dueMonth,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D1D1F),
                        ),
                        child: const Text(
                          "Create Bill",
                          style: TextStyle(color: Colors.white),
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
    );
  }

  Future<void> _uploadBillFile(
    int supplierId,
    int billId,
    String fileType,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null &&
          (result.files.single.bytes != null ||
              result.files.single.path != null)) {
        setState(() {
          _isLoadingBills = true;
        });

        final bytes = result.files.single.bytes;
        final path = result.files.single.path;
        final fileName = result.files.single.name;

        dio.MultipartFile multipartFile;
        if (bytes != null) {
          multipartFile = dio.MultipartFile.fromBytes(
            bytes,
            filename: fileName,
          );
        } else {
          multipartFile = await dio.MultipartFile.fromFile(
            path!,
            filename: fileName,
          );
        }

        final formData = dio.FormData.fromMap({
          'file_type': fileType,
          'file': multipartFile,
        });

        final response = await _api.post(
          SupplierEndpoints.uploadBill(supplierId, billId),
          data: formData,
        );

        if (response.data['success'] == true) {
          _showSuccessBanner("อัปโหลดไฟล์ $fileType สำเร็จ");
          _fetchBills(supplierId);
        }
      }
    } catch (e) {
      debugPrint("Error uploading file: $e");
    } finally {
      setState(() {
        _isLoadingBills = false;
      });
    }
  }

  List<dynamic> _getFilteredSuppliers() {
    if (_searchText.isEmpty) return _suppliersDb;
    return _suppliersDb
        .where(
          (s) => s['name'].toString().toLowerCase().contains(
            _searchText.toLowerCase(),
          ),
        )
        .toList();
  }

  void _showSuccessBanner(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4A9062), // Green Banner
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSuppliers = _getFilteredSuppliers();
    Map<String, dynamic> selectedSupplier = {};

    if (filteredSuppliers.isNotEmpty) {
      final found = filteredSuppliers.firstWhere(
        (s) => s['id'] == _selectedSupplierDbId,
        orElse: () => filteredSuppliers.first,
      );
      selectedSupplier = Map<String, dynamic>.from(found);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: รายชื่อ Suppliers
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Suppliers",
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
                        tooltip: "Add New Supplier",
                        onPressed: () => _showAddSupplierDialog(context),
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
                      hintText: "ค้นหาชื่อโรงงาน...",
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
                    itemCount: filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      final sup = filteredSuppliers[index];
                      final isSelected = _selectedSupplierDbId == sup['id'];

                      // 🌟 Show counts for selected supplier, default to 0 for others
                      int pendingQuotesCount = 0;
                      int pendingSamplesCount = 0;
                      if (isSelected) {
                        pendingQuotesCount = _dbQuotes
                            .where((q) => q['status'] != 'Approved')
                            .length;
                        pendingSamplesCount = _dbSamples
                            .where((s) => s['status'] != 'Approved')
                            .length;
                      }

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSupplierDbId = sup['id'];
                            _selectedBillIds.clear();
                          });
                          _fetchSupplierDetails(sup['id']);
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sup['category']?.toString() ?? 'General',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFF5B7BD5)
                                          : const Color(0xFF86868B),
                                    ),
                                  ),
                                  if (pendingQuotesCount > 0 ||
                                      pendingSamplesCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDE2E4),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "$pendingQuotesCount Quotes, $pendingSamplesCount Samples",
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFFD97781),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                sup['name']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF1D1D1F),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Color(0xFFF2C94C),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${sup['rating'] ?? '0.0'} Rating",
                                    style: const TextStyle(
                                      fontSize: 11,
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
          // 2. RIGHT PANEL: รายละเอียด / Quotes / Samples / Payments
          // ==========================================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48.0),
              child: Column(
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
                            Row(
                              children: [
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
                                    selectedSupplier['category']?.toString() ??
                                        'General',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF86868B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Tooltip(
                                  message:
                                      "Rating based on delivery time, product quality, and communication.",
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 18,
                                        color: Color(0xFFF2C94C),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${selectedSupplier['rating'] ?? '0.0'}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D1D1F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedSupplier['name']?.toString() ??
                                  'No Supplier Selected',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D1D1F),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 18,
                                  color: Color(0xFF86868B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedSupplier['contact_person']
                                          ?.toString() ??
                                      'N/A',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 18,
                                  color: Color(0xFF86868B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedSupplier['phone']?.toString() ??
                                      'N/A',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildButton(
                        "Edit Supplier",
                        Colors.white,
                        const Color(0xFF1D1D1F),
                        isOutlined: true,
                        onTap: () {
                          if (selectedSupplier.isNotEmpty) {
                            _showEditSupplierDialog(context, selectedSupplier);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // --- 🌟 ระบบ Tabs สลับ 3 เมนู (Quotes / Samples / Payments) ---
                  Container(
                    width: 550,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTab(
                          "Quotes",
                          "ขอราคา (Quotes)",
                          Icons.request_quote_outlined,
                        ),
                        _buildTab(
                          "Samples",
                          "ขอตัวอย่าง (Samples)",
                          Icons.science_outlined,
                        ),
                        _buildTab(
                          "Payments",
                          "รอบบิลจ่ายเงิน (AP)",
                          Icons.payments_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // แสดงเนื้อหาตาม Tab ที่เลือก
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _activeTab == "Quotes"
                        ? _buildQuotesSection(selectedSupplier)
                        : _activeTab == "Samples"
                        ? _buildSamplesSection(selectedSupplier)
                        : _buildPaymentsSection(selectedSupplier),
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
  // TAB 1: QUOTES SECTION (ขอราคา)
  // =========================================================
  Widget _buildQuotesSection(Map<String, dynamic> selectedSupplier) {
    return Column(
      key: const ValueKey("Quotes"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Price Quote Requests",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "รายการสินค้าที่ต้องการให้โรงงานนี้ประเมินราคา",
                  style: TextStyle(fontSize: 14, color: Color(0xFF86868B)),
                ),
              ],
            ),
            _buildButton(
              "+ Request Quote",
              const Color(0xFF1D1D1F),
              Colors.white,
              onTap: () =>
                  _showRequestDialog(context, selectedSupplier, "Quote"),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_isLoadingQuotes)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_dbQuotes.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: Text(
                "ยังไม่มีรายการขอราคาจากโรงงานนี้",
                style: TextStyle(color: Color(0xFF86868B)),
              ),
            ),
          )
        else
          ..._dbQuotes.map((req) {
            bool isFilled = req['status'] == "Price Filled";
            bool isApproved = req['status'] == "Approved";
            bool isSent = req['status'] == "Link Sent";
            final double priceVal =
                double.tryParse(req['quoted_price']?.toString() ?? '0') ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              req['project']?['project_code']?.toString() ??
                                  'PPN-XXX',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B7BD5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "• ${req['customer_name']?.toString() ?? ''}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF86868B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req['product_name']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Quantity: ${req['qty'] ?? 0} pcs (At least 2 steps required)",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF86868B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🌟 Standard Requirement Info Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E2E2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Standard Requirements:",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Specs: ${req['specs'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                "Variations: ${req['variations'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                "Target Date: ${req['target_date']?.toString().split(' ').first ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                "Packing: ${req['packing'] ?? 'Standard Packing'}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "* FOC is not included in the quotation",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFD97781),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Status",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? const Color(0xFFB7E4C7).withOpacity(0.3)
                                : (isFilled
                                      ? const Color(0xFFFDE2E4).withOpacity(0.5)
                                      : (isSent
                                            ? const Color(0xFFEAE4F2)
                                            : const Color(0xFFF4F5F7))),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req['status']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isApproved
                                  ? const Color(0xFF4A9062)
                                  : (isFilled
                                        ? const Color(0xFFD97781)
                                        : const Color(0xFF86868B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Unit Cost (ทุน)",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (isFilled || isApproved)
                              ? "${req['currency'] ?? 'USD'} ${priceVal.toStringAsFixed(2)}"
                              : "-",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (isFilled || isApproved)
                                ? const Color(0xFF1D1D1F)
                                : const Color(0xFFB4B4B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isApproved)
                            _buildButton(
                              "✓ Approved (Ready for PI)",
                              const Color(0xFFF4F5F7),
                              const Color(0xFF4A9062),
                              onTap: () {},
                            )
                          else if (isFilled)
                            _buildButton(
                              "Review & Resubmit",
                              const Color(0xFF1D1D1F),
                              Colors.white,
                              icon: Icons.edit_document,
                              onTap: () => _showReviewQuoteDialog(
                                context,
                                Map<String, dynamic>.from(req),
                              ),
                            )
                          else ...[
                            _buildButton(
                              "Supplier Session Link",
                              isSent ? Colors.white : const Color(0xFFAEC4FA),
                              isSent
                                  ? const Color(0xFF1D1D1F)
                                  : const Color(0xFF1D1D1F),
                              isOutlined: isSent,
                              icon: Icons.link_rounded,
                              onTap: () => _showGenerateLinkDialog(
                                context,
                                selectedSupplier,
                                Map<String, dynamic>.from(req),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildButton(
                              "Manual Input",
                              Colors.white,
                              const Color(0xFF86868B),
                              isOutlined: true,
                              icon: Icons.keyboard_alt_outlined,
                              onTap: () => _showManualInputDialog(
                                context,
                                Map<String, dynamic>.from(req),
                              ),
                            ),
                          ],
                        ],
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

  // =========================================================
  // TAB 2: SAMPLES SECTION (ขอตัวอย่าง)
  // =========================================================
  Widget _buildSamplesSection(Map<String, dynamic> selectedSupplier) {
    return Column(
      key: const ValueKey("Samples"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Sample Requests",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "รายการตัวอย่างสินค้าที่ร้องขอไปทางโรงงาน",
                  style: TextStyle(fontSize: 14, color: Color(0xFF86868B)),
                ),
              ],
            ),
            _buildButton(
              "+ Request Sample",
              const Color(0xFF1D1D1F),
              Colors.white,
              onTap: () =>
                  _showRequestDialog(context, selectedSupplier, "Sample"),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_isLoadingSamples)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_dbSamples.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: Text(
                "ยังไม่มีรายการขอตัวอย่างจากโรงงานนี้",
                style: TextStyle(color: Color(0xFF86868B)),
              ),
            ),
          )
        else
          ..._dbSamples.map((req) {
            bool isSent = req['status'] == "Sample Sent";

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              req['project']?['project_code']?.toString() ??
                                  'PPN-XXX',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(
                                  0xFFEC4899,
                                ), // ใช้สีชมพูแยกจาก Quote
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "• ${req['customer_name']?.toString() ?? ''}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF86868B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req['product_name']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF2F8), // Pink background
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFBCFE8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Sample Details:",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF831843),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Specs: ${req['specs'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9D174D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Sample Cost: ${req['cost'] ?? 'TBD'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9D174D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Status",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSent
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF4F5F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req['status']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSent
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF86868B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tracking Info",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "No: ${req['tracking_no'] ?? '-'}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSent
                                ? const Color(0xFF1D1D1F)
                                : const Color(0xFFB4B4B8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "ETA: ${req['expected_date']?.toString().split(' ').first ?? '-'}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF86868B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isSent)
                            _buildButton(
                              "✓ Sample Received",
                              const Color(0xFFF4F5F7),
                              const Color(0xFF4A9062),
                              onTap: () => _receiveSample(
                                selectedSupplier['id'],
                                req['id'],
                              ),
                            )
                          else if (req['status'] != 'Approved')
                            _buildButton(
                              "Update Tracking",
                              Colors.white,
                              const Color(0xFF1D1D1F),
                              isOutlined: true,
                              icon: Icons.local_shipping_outlined,
                              onTap: () => _showUpdateTrackingDialog(
                                context,
                                selectedSupplier['id'],
                                Map<String, dynamic>.from(req),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (req['status'] != 'Approved')
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF86868B),
                              ),
                              tooltip: "แก้ไขสเปก/ค่าใช้จ่าย",
                              onPressed: () => _showEditSampleDetailsDialog(
                                context,
                                selectedSupplier['id'],
                                Map<String, dynamic>.from(req),
                              ),
                            ),
                        ],
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

  // =========================================================
  // TAB 3: PAYMENTS SECTION (บัญชีเจ้าหนี้ สิ้นเดือน)
  // =========================================================
  Widget _buildPaymentsSection(Map<String, dynamic> selectedSupplier) {
    if (_isLoadingBills) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final supplierId = selectedSupplier['id'] ?? 0;
    List pendingBills = _dbBills
        .where((b) => b['status'] == 'Pending')
        .toList();
    List paidBills = _dbBills.where((b) => b['status'] == 'Paid').toList();

    double totalSelectedAmount = 0;
    for (var bill in pendingBills) {
      if (_selectedBillIds.contains(bill['id'])) {
        final double amt =
            double.tryParse(
              bill['amount_thb']?.toString() ??
                  bill['amount']?.toString() ??
                  '0',
            ) ??
            0.0;
        totalSelectedAmount += amt;
      }
    }

    return Column(
      key: const ValueKey("Payments"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Monthly Accounts Payable (ตัดจ่ายซัพพลายเออร์)",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "รวบรวมบิล Deposit และ Balance เพื่อทำเรื่องจ่ายออกทีเดียวช่วงสิ้นเดือน",
                    style: TextStyle(fontSize: 14, color: Color(0xFF86868B)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildButton(
              "+ Add Bill",
              const Color(0xFF1D1D1F),
              Colors.white,
              onTap: () => _showAddBillDialog(context, selectedSupplier),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (pendingBills.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Column(
              children: const [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Color(0xFF4A9062),
                ),
                SizedBox(height: 16),
                Text(
                  "ยอดเยี่ยม! ไม่มีรอบบิลค้างชำระสำหรับโรงงานนี้",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A9062),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ...pendingBills.map((bill) {
            bool isSelected = _selectedBillIds.contains(bill['id']);
            bool isDeposit =
                bill['bill_type']?.toString().contains("Deposit") ??
                bill['type']?.toString().contains("Deposit") ??
                true;
            bool piUploaded =
                bill['pi_uploaded'] == true ||
                bill['pi_uploaded'] == 1 ||
                bill['pi_file_path'] != null;
            bool invUploaded =
                bill['invoice_uploaded'] == true ||
                bill['invoice_uploaded'] == 1 ||
                bill['invoice_file_path'] != null;
            final double amt =
                double.tryParse(
                  bill['amount_thb']?.toString() ??
                      bill['amount']?.toString() ??
                      '0',
                ) ??
                0.0;

            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedBillIds.remove(bill['id']);
                  } else {
                    _selectedBillIds.add(bill['id']);
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFAEC4FA).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFAEC4FA)
                        : Colors.grey.withOpacity(0.15),
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    // Checkbox
                    Checkbox(
                      value: isSelected,
                      semanticLabel: 'Select supplier bill ${bill['id']}',
                      activeColor: const Color(0xFF5B7BD5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedBillIds.add(bill['id']);
                          } else {
                            _selectedBillIds.remove(bill['id']);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 20),

                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                bill['project']?['project_code']?.toString() ??
                                    bill['project_id']?.toString() ??
                                    'PPN-XXX',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF86868B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDeposit
                                      ? const Color(0xFFFDE2E4)
                                      : const Color(0xFFEAE4F2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  bill['bill_type']?.toString() ??
                                      bill['type']?.toString() ??
                                      'Deposit',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDeposit
                                        ? const Color(0xFFD97781)
                                        : const Color(0xFF6B4CA4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bill['product_name']?.toString() ??
                                bill['product']?.toString() ??
                                '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🌟 Documents Warning (Click to Upload)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Documents (Click to upload)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF86868B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _uploadBillFile(
                                  supplierId,
                                  bill['id'],
                                  'pi',
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      piUploaded
                                          ? Icons.check_circle
                                          : Icons.warning_amber_rounded,
                                      size: 14,
                                      color: piUploaded
                                          ? const Color(0xFF4A9062)
                                          : const Color(0xFFD97781),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "PI",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        color: piUploaded
                                            ? const Color(0xFF4A9062)
                                            : const Color(0xFFD97781),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              InkWell(
                                onTap: () => _uploadBillFile(
                                  supplierId,
                                  bill['id'],
                                  'invoice',
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      invUploaded
                                          ? Icons.check_circle
                                          : Icons.warning_amber_rounded,
                                      size: 14,
                                      color: invUploaded
                                          ? const Color(0xFF4A9062)
                                          : const Color(0xFFD97781),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Invoice",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        color: invUploaded
                                            ? const Color(0xFF4A9062)
                                            : const Color(0xFFD97781),
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

                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Due Month",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF86868B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bill['due_month']?.toString() ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Amount (THB)",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF86868B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "฿ ${amt.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: _selectedBillIds.isEmpty
                  ? const Color(0xFFF4F5F7)
                  : const Color(0xFF1D1D1F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selected Bills: ${_selectedBillIds.length}",
                      style: TextStyle(
                        color: _selectedBillIds.isEmpty
                            ? const Color(0xFF86868B)
                            : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "฿ ${totalSelectedAmount.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: _selectedBillIds.isEmpty
                            ? const Color(0xFFB4B4B8)
                            : Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildButton(
                      "เลื่อนบิลไปเดือนหน้า",
                      _selectedBillIds.isEmpty
                          ? Colors.white
                          : const Color(0xFF333333),
                      _selectedBillIds.isEmpty
                          ? const Color(0xFFB4B4B8)
                          : Colors.white,
                      isOutlined: _selectedBillIds.isEmpty,
                      onTap: () {
                        if (_selectedBillIds.isEmpty) return;
                        _showSuccessBanner(
                          "เลื่อนรอบบิลที่เลือกสำเร็จ (Local Mock)",
                        );
                        setState(() {
                          _selectedBillIds.clear();
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildButton(
                      "Pay Selected Bills",
                      _selectedBillIds.isEmpty
                          ? const Color(0xFFE2E2E2)
                          : const Color(0xFFAEC4FA),
                      _selectedBillIds.isEmpty
                          ? const Color(0xFF86868B)
                          : const Color(0xFF1D1D1F),
                      onTap: () {
                        if (_selectedBillIds.isEmpty) return;
                        _paySelectedBills(supplierId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (paidBills.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Divider(height: 32),
          const Text(
            "Payment History (ประวัติการชำระเงินแล้ว)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          ...paidBills.map((bill) {
            bool isDeposit =
                bill['bill_type']?.toString().contains("Deposit") ??
                bill['type']?.toString().contains("Deposit") ??
                true;
            final double amt =
                double.tryParse(
                  bill['amount_thb']?.toString() ??
                      bill['amount']?.toString() ??
                      '0',
                ) ??
                0.0;
            final String paidDate = bill['paid_at'] != null
                ? bill['paid_at'].toString().split('T').first
                : '-';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF4CBB17),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              bill['project']?['project_code']?.toString() ??
                                  bill['project_id']?.toString() ??
                                  'PPN-XXX',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF86868B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDeposit
                                    ? const Color(0xFFFDE2E4)
                                    : const Color(0xFFEAE4F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                bill['bill_type']?.toString() ??
                                    bill['type']?.toString() ??
                                    'Deposit',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDeposit
                                      ? const Color(0xFFD97781)
                                      : const Color(0xFF8635B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bill['product_name']?.toString() ??
                              'สินค้าไม่ระบุชื่อ',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Paid Date: $paidDate",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF86868B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${bill['currency'] ?? 'THB'} ${amt.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF86868B),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // =========================================================
  // HELPER WIDGETS & DIALOGS
  // =========================================================

  Widget _buildTab(String id, String title, IconData icon) {
    bool isActive = _activeTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive
                    ? (id == "Samples"
                          ? const Color(0xFFEC4899)
                          : const Color(0xFF5B7BD5))
                    : const Color(0xFF86868B),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF1D1D1F)
                      : const Color(0xFF86868B),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  Future<void> _storeSupplier(
    String name,
    String contact,
    String phone,
    String category,
  ) async {
    try {
      final response = await _api.post(
        SupplierEndpoints.store,
        data: {
          'name': name,
          'contact_person': contact,
          'phone': phone,
          'category': category,
          'rating': 4.5,
          'is_active': true,
        },
      );
      if (response.data['success'] == true) {
        _showSuccessBanner("Supplier added successfully");
        _fetchSuppliers();
      }
    } catch (e) {
      debugPrint("Error storing supplier: $e");
    }
  }

  Future<void> _updateSupplier(
    int id,
    String name,
    String contact,
    String phone,
    String category,
  ) async {
    try {
      final response = await _api.put(
        SupplierEndpoints.update(id),
        data: {
          'name': name,
          'contact_person': contact,
          'phone': phone,
          'category': category,
        },
      );
      if (response.data['success'] == true) {
        _showSuccessBanner("Supplier updated successfully");
        _fetchSuppliers();
      }
    } catch (e) {
      debugPrint("Error updating supplier: $e");
    }
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: "Textile & Bags");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Add New Supplier",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Company / Factory Name",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: contactCtrl,
                decoration: InputDecoration(
                  labelText: "Contact Person",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: "Phone / WeChat ID",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: categoryCtrl,
                decoration: InputDecoration(
                  labelText: "Category",
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
              if (nameCtrl.text.isNotEmpty) {
                _storeSupplier(
                  nameCtrl.text,
                  contactCtrl.text,
                  phoneCtrl.text,
                  categoryCtrl.text,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D1F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Save Supplier",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSupplierDialog(
    BuildContext context,
    Map<String, dynamic> supplier,
  ) {
    final nameCtrl = TextEditingController(
      text: supplier['name']?.toString() ?? '',
    );
    final contactCtrl = TextEditingController(
      text: supplier['contact_person']?.toString() ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: supplier['phone']?.toString() ?? '',
    );
    final categoryCtrl = TextEditingController(
      text: supplier['category']?.toString() ?? '',
    );
    final int supplierId = supplier['id'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Edit Supplier",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: "Company / Factory Name",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: contactCtrl,
                decoration: InputDecoration(
                  labelText: "Contact Person",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: "Phone / WeChat ID",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: categoryCtrl,
                decoration: InputDecoration(
                  labelText: "Category",
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
              if (nameCtrl.text.isNotEmpty) {
                _updateSupplier(
                  supplierId,
                  nameCtrl.text,
                  contactCtrl.text,
                  phoneCtrl.text,
                  categoryCtrl.text,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D1D1F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Save Changes",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _receiveSample(int supplierId, int sampleId) async {
    try {
      final response = await _api.patch(
        SupplierEndpoints.sampleStatus(supplierId, sampleId),
        data: {'status': 'Approved'},
      );
      if (response.data['success'] == true) {
        _showSuccessBanner("Sample marked as received successfully.");
        _fetchSamples(supplierId);
      }
    } catch (e) {
      debugPrint("Error marking sample received: $e");
    }
  }

  Future<void> _updateSampleTracking(
    int supplierId,
    int sampleId,
    String trackingNo,
    String expectedDate,
  ) async {
    try {
      final response = await _api.put(
        SupplierEndpoints.updateSample(supplierId, sampleId),
        data: {
          'tracking_no': trackingNo,
          'expected_date': expectedDate.isNotEmpty ? expectedDate : null,
          'status': 'Sample Sent',
        },
      );
      if (response.data['success'] == true) {
        _showSuccessBanner("Sample tracking updated successfully.");
        _fetchSamples(supplierId);
      }
    } catch (e) {
      debugPrint("Error updating sample tracking: $e");
    }
  }

  Future<void> _updateSampleDetails({
    required int supplierId,
    required int sampleId,
    required String productName,
    required String specs,
    required String cost,
    required String trackingNo,
    required String expectedDate,
    required String status,
  }) async {
    try {
      final response = await _api.put(
        SupplierEndpoints.updateSample(supplierId, sampleId),
        data: {
          'product_name': productName,
          'specs': specs,
          'cost': cost,
          'tracking_no': trackingNo.isNotEmpty ? trackingNo : null,
          'expected_date': expectedDate.isNotEmpty ? expectedDate : null,
          'status': status,
        },
      );
      if (response.data['success'] == true) {
        _showSuccessBanner("แก้ไขข้อมูลความคืบหน้าของตัวอย่างสำเร็จ");
        _fetchSamples(supplierId);
      }
    } catch (e) {
      debugPrint("Error updating sample details: $e");
    }
  }

  void _showEditSampleDetailsDialog(
    BuildContext context,
    int supplierId,
    Map<String, dynamic> sample,
  ) {
    final prodNameCtrl = TextEditingController(
      text: sample['product_name']?.toString() ?? '',
    );
    final specsCtrl = TextEditingController(
      text: sample['specs']?.toString() ?? '',
    );
    final costCtrl = TextEditingController(
      text: sample['cost']?.toString() ?? '',
    );
    final trackingCtrl = TextEditingController(
      text: sample['tracking_no']?.toString() ?? '',
    );
    final dateCtrl = TextEditingController(
      text: sample['expected_date'] != null
          ? sample['expected_date'].toString().split(' ').first
          : '',
    );
    String status = sample['status']?.toString() ?? 'Waiting Supplier';
    final int sampleId = sample['id'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Edit Sample Details",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "แก้ไขรายละเอียดและความคืบหน้าของใบขอตัวอย่างนี้",
                    style: TextStyle(color: Color(0xFF86868B)),
                  ),
                  const Divider(height: 32),

                  TextFormField(
                    controller: prodNameCtrl,
                    decoration: InputDecoration(
                      labelText: "Product Name",
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: specsCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Sample Specs",
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: costCtrl,
                          decoration: InputDecoration(
                            labelText: "Sample Cost",
                            filled: true,
                            fillColor: const Color(0xFFF4F5F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          decoration: InputDecoration(
                            labelText: "Status",
                            filled: true,
                            fillColor: const Color(0xFFF4F5F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: ["Waiting Supplier", "Sample Sent", "Approved"]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setDialogState(() => status = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: trackingCtrl,
                          decoration: InputDecoration(
                            labelText: "Tracking Number",
                            filled: true,
                            fillColor: const Color(0xFFF4F5F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: dateCtrl,
                          decoration: InputDecoration(
                            labelText: "Expected Arrival (YYYY-MM-DD)",
                            filled: true,
                            fillColor: const Color(0xFFF4F5F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          _updateSampleDetails(
                            supplierId: supplierId,
                            sampleId: sampleId,
                            productName: prodNameCtrl.text,
                            specs: specsCtrl.text,
                            cost: costCtrl.text,
                            trackingNo: trackingCtrl.text,
                            expectedDate: dateCtrl.text,
                            status: status,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D1D1F),
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(color: Colors.white),
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
    );
  }

  void _showUpdateTrackingDialog(
    BuildContext context,
    int supplierId,
    Map<String, dynamic> sample,
  ) {
    final trackingCtrl = TextEditingController(
      text: sample['tracking_no']?.toString() ?? '',
    );
    final dateCtrl = TextEditingController(
      text: sample['expected_date'] != null
          ? sample['expected_date'].toString().split(' ').first
          : '',
    );
    final int sampleId = sample['id'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Update Sample Tracking",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: trackingCtrl,
                decoration: InputDecoration(
                  labelText: "Tracking Number",
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateCtrl,
                decoration: InputDecoration(
                  labelText: "Expected Arrival Date (YYYY-MM-DD)",
                  hintText: "e.g., 2026-08-15",
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
              _updateSampleTracking(
                supplierId,
                sampleId,
                trackingCtrl.text,
                dateCtrl.text,
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
              "Update Tracking",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRequest({
    required int supplierId,
    required String type,
    required String projectId,
    required String productName,
    required int qty,
    required String specs,
    String? cost,
    int? productItemId,
  }) async {
    try {
      final int pId = int.parse(projectId);
      if (type == "Quote") {
        final response = await _api.post(
          SupplierEndpoints.quotes(supplierId),
          data: {
            'project_id': pId,
            'product_item_id': productItemId,
            'product_name': productName,
            'qty': qty,
            'specs': specs,
            'variations': 'Standard',
            'packing': 'Standard Packing',
          },
        );
        if (response.data['success'] == true) {
          _showSuccessBanner("Quote request submitted successfully");
          _fetchQuotes(supplierId);
        }
      } else {
        // Sample
        final response = await _api.post(
          SupplierEndpoints.samples(supplierId),
          data: {
            'project_id': pId,
            'product_item_id': productItemId,
            'product_name': productName,
            'specs': specs,
            'cost': cost ?? 'TBD',
          },
        );
        if (response.data['success'] == true) {
          _showSuccessBanner("Sample request submitted successfully");
          _fetchSamples(supplierId);
        }
      }
    } catch (e) {
      debugPrint("Error submitting request: $e");
    }
  }

  void _showRequestDialog(
    BuildContext context,
    Map<String, dynamic> supplier,
    String type, // "Quote" หรือ "Sample"
  ) {
    String? selectedProjectId;
    List<Map<String, dynamic>> productsInProject = [];
    List<bool> selectedProducts = [];
    // 🌟 สร้าง List ของ TextEditingController เพื่อให้ปรับแก้ Qty ได้
    List<TextEditingController> qtyControllers = [];
    String customSpecs = "ขอตัวอย่างตามสเปก";
    String customCost = "TBD";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              type == "Quote" ? "Request Price Quote" : "Request Sample",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "1. เลือกโปรเจกต์ของลูกค้า",
                    style: TextStyle(
                      color: type == "Quote"
                          ? const Color(0xFF86868B)
                          : const Color(0xFFEC4899),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    hint: const Text("Select Project"),
                    value: selectedProjectId,
                    items: _projectsDb
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p['id']?.toString(),
                            child: Text(
                              "${p['project_code'] ?? p['id']} - ${p['customer']?['name'] ?? ''}",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedProjectId = val;
                        var prj = _projectsDb.firstWhere(
                          (p) => p['id']?.toString() == val,
                        );

                        var prodItems = prj['product_items'] as List? ?? [];
                        productsInProject = List<Map<String, dynamic>>.from(
                          prodItems.map(
                            (pi) => {
                              'id': pi['id'],
                              'name':
                                  pi['name']?.toString() ??
                                  pi['product_name']?.toString() ??
                                  '',
                              'qty':
                                  int.tryParse(pi['qty']?.toString() ?? '0') ??
                                  0,
                            },
                          ),
                        );
                        selectedProducts = List<bool>.filled(
                          productsInProject.length,
                          false,
                        );
                        qtyControllers = productsInProject
                            .map(
                              (p) => TextEditingController(
                                text: p['qty'].toString(),
                              ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (selectedProjectId != null) ...[
                    Text(
                      type == "Quote"
                          ? "2. ติ๊กเลือกสินค้าและระบุจำนวนที่ต้องการให้ซัพประเมินราคา:"
                          : "2. ติ๊กเลือกเฉพาะสินค้าที่ต้องการให้โรงงานนี้ทำ:",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF86868B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E2E2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: List.generate(productsInProject.length, (
                          index,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: CheckboxListTile(
                              title: Text(
                                productsInProject[index]['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              // 🌟 ถ้าเป็น Quote โชว์ช่องให้ปรับแก้ Qty ได้ ถ้าเป็น Sample โชว์ Text ธรรมดา
                              subtitle: type == "Quote"
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          const Text(
                                            "Req. Qty: ",
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          SizedBox(
                                            width: 100,
                                            height: 32,
                                            child: TextFormField(
                                              controller: qtyControllers[index],
                                              keyboardType:
                                                  TextInputType.number,
                                              enabled:
                                                  selectedProducts[index], // กรอกได้ต่อเมื่อติ๊กเลือก
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                filled: true,
                                                fillColor:
                                                    selectedProducts[index]
                                                    ? Colors.white
                                                    : const Color(0xFFF4F5F7),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  borderSide: BorderSide(
                                                    color: Colors.grey
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      "Qty: ${productsInProject[index]['qty']}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                              value: selectedProducts[index],
                              activeColor: type == "Quote"
                                  ? const Color(0xFF5B7BD5)
                                  : const Color(0xFFEC4899),
                              onChanged: (bool? val) {
                                setDialogState(
                                  () => selectedProducts[index] = val ?? false,
                                );
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    if (type == "Sample") ...[
                      const SizedBox(height: 16),
                      const Text(
                        "3. รายละเอียดสเปกและค่าใช้จ่ายของตัวอย่าง",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEC4899),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: "เช่น ขอตัวอย่างแคนวาสสีดำ หนาพิเศษ",
                          filled: true,
                          fillColor: const Color(0xFFF4F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) => customSpecs = val,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText:
                              "ค่าใช้จ่ายตัวอย่าง (เช่น Free, TBD, หรือ 500 บาท)",
                          filled: true,
                          fillColor: const Color(0xFFF4F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) => customCost = val,
                      ),
                    ],
                  ],
                ],
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
                onPressed:
                    (selectedProjectId == null ||
                        !selectedProducts.contains(true))
                    ? null
                    : () {
                        final int supplierId = supplier['id'] ?? 0;
                        for (int i = 0; i < productsInProject.length; i++) {
                          if (selectedProducts[i]) {
                            int finalQty =
                                int.tryParse(qtyControllers[i].text) ??
                                productsInProject[i]['qty'];
                            _submitRequest(
                              supplierId: supplierId,
                              type: type,
                              projectId: selectedProjectId!,
                              productName: productsInProject[i]['name'],
                              qty: finalQty,
                              specs: type == "Quote"
                                  ? "Standard specifications"
                                  : customSpecs,
                              cost: type == "Quote" ? null : customCost,
                              productItemId: productsInProject[i]['id'] != null
                                  ? int.tryParse(
                                      productsInProject[i]['id'].toString(),
                                    )
                                  : null,
                            );
                          }
                        }
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D1D1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Add Request",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🌟 Single Session Link
  Future<void> _generateAndShowLink(
    BuildContext context,
    Map<String, dynamic> supplier,
    Map<String, dynamic> req,
  ) async {
    try {
      final response = await _api.post(
        SupplierEndpoints.generateQuoteLink(supplier['id'], req['id']),
      );
      if (response.data['success'] == true) {
        final String sessionToken =
            response.data['data']['session_token'] ?? '';
        _fetchQuotes(supplier['id']); // reload quotes list
        if (context.mounted) {
          _showLinkDialog(context, supplier, sessionToken);
        }
      }
    } catch (e) {
      debugPrint("Error generating quote link: $e");
    }
  }

  void _showLinkDialog(
    BuildContext context,
    Map<String, dynamic> supplier,
    String token,
  ) {
    final String wechat =
        supplier['wechat']?.toString() ??
        supplier['email']?.toString() ??
        'N/A';
    final String portalUrl =
        "http://supplier.ppn-great.com"; // หรือ http://localhost:3000

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAEC4FA).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      color: Color(0xFF5B7BD5),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Supplier Portal Access",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "คัดลอกข้อมูลและลิงก์ด้านล่างเพื่อส่งให้โรงงานใน WeChat เพื่อเข้าสู่ระบบเสนอราคา (Supplier Portal):",
                style: TextStyle(color: Color(0xFF86868B), fontSize: 13),
              ),
              const SizedBox(height: 24),

              // 1. Portal Website Link
              _buildCredentialRow("Portal Link", portalUrl),
              const SizedBox(height: 16),

              // 2. Email / WeChat ID
              _buildCredentialRow("Email / WeChat ID", wechat),
              const SizedBox(height: 16),

              // 3. Access Token
              _buildCredentialRow("Access Token (Password)", token),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final String clipText =
                            "*ช่องทางเสนอราคา (PPN Supplier Portal)*\n"
                            "🌐 ลิงก์ระบบ: $portalUrl\n"
                            "👤 WeChat / Email: $wechat\n"
                            "🔑 Access Token: $token";
                        Clipboard.setData(ClipboardData(text: clipText));
                        Navigator.pop(context);
                        _showSuccessBanner(
                          "คัดลอกข้อมูลบัญชีเสนอราคาทั้งหมดเรียบร้อยแล้ว",
                        );
                      },
                      icon: const Icon(
                        Icons.copy_all,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        "Copy All Info",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7BD5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4F5F7),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          color: Color(0xFF1D1D1F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E2E2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1D1D1F),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  _showSuccessBanner("คัดลอก $label เรียบร้อย");
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1D1F),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Copy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showGenerateLinkDialog(
    BuildContext context,
    Map<String, dynamic> supplier,
    Map<String, dynamic> req,
  ) {
    _generateAndShowLink(context, supplier, req);
  }

  Future<void> _submitManualQuote({
    required int supplierId,
    required int quoteId,
    required String currency,
    required double price,
    required String leadTime,
    required int moq,
    required String remark,
    double? samplePrice,
    String? sampleLeadTime,
    String? sampleCondition,
  }) async {
    try {
      final response = await _api.put(
        SupplierEndpoints.updateQuote(supplierId, quoteId),
        data: {
          'quoted_price': price,
          'currency': currency,
          'lead_time': leadTime,
          'moq': moq,
          'remark': remark,
          'status': 'Price Filled',
          'sample_price': samplePrice,
          'sample_lead_time': sampleLeadTime,
          'sample_condition': sampleCondition,
        },
      );
      if (response.data['success'] == true) {
        _showSuccessBanner("Manual quote submitted successfully.");
        _fetchQuotes(supplierId);
      }
    } catch (e) {
      debugPrint("Error submitting manual quote: $e");
    }
  }

  Future<void> _updateQuoteStatus({
    required int supplierId,
    required int quoteId,
    required String status,
    String? buyerNote,
  }) async {
    try {
      final response = await _api.patch(
        SupplierEndpoints.quoteStatus(supplierId, quoteId),
        data: {
          'status': status,
          if (buyerNote != null) 'buyer_note': buyerNote,
        },
      );
      if (response.data['success'] == true) {
        _showSuccessBanner(
          status == 'Approved'
              ? "Quote Approved!"
              : "Requested revision. Supplier can now update the quote.",
        );
        _fetchQuotes(supplierId);
      }
    } catch (e) {
      debugPrint("Error updating quote status: $e");
    }
  }

  // 🌟 Manual Input Quote Dialog
  void _showManualInputDialog(BuildContext context, Map<String, dynamic> req) {
    String currency = "USD";
    String price = "";
    String leadTime = "";
    String moq = "";
    String remark = "";
    String samplePrice = "";
    String sampleLeadTime = "";
    String sampleCondition = "Free";
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Manual Quote Input",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "กรอกใบเสนอราคาด้วยตนเอง (กรณีโรงงานไม่สะดวกใช้ลิงก์)",
                    style: TextStyle(color: Color(0xFF86868B)),
                  ),
                  const Divider(height: 48),

                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Currency",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: currency,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: ["USD", "THB", "CNY"]
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setDialogState(() => currency = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Unit Price",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              onChanged: (val) => price = val,
                              decoration: InputDecoration(
                                hintText: "0.00",
                                errorText: errorText, // Inline validation error
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Lead Time",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              onChanged: (val) => leadTime = val,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                              "MOQ",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              onChanged: (val) => moq = val,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sample Price (ราคาตัวอย่าง)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              onChanged: (val) => samplePrice = val,
                              decoration: InputDecoration(
                                hintText: "0.00",
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                              "Sample Lead Time",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              onChanged: (val) => sampleLeadTime = val,
                              decoration: InputDecoration(
                                hintText: "เช่น 5-7 วัน",
                                filled: true,
                                fillColor: const Color(0xFFF4F5F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Sample Condition",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: sampleCondition,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF4F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ["Free", "Refundable", "Non-Refundable"]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => sampleCondition = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Remarks",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        onChanged: (val) => remark = val,
                        maxLines: 2,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF4F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (price.isEmpty) {
                            setDialogState(
                              () => errorText = "Price is required",
                            );
                            return;
                          }
                          // ยืนยันก่อนเซฟ
                          showDialog(
                            context: context,
                            builder: (confirmCtx) => AlertDialog(
                              title: const Text("Confirm Submission?"),
                              content: const Text(
                                "Once confirmed, the adjustment can't be made. You can only request a re-quote.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(confirmCtx),
                                  child: const Text("Back"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1D1D1F),
                                  ),
                                  onPressed: () {
                                    _submitManualQuote(
                                      supplierId: req['supplier_id'] ?? 0,
                                      quoteId: req['id'] ?? 0,
                                      currency: currency,
                                      price: double.tryParse(price) ?? 0.0,
                                      leadTime: leadTime,
                                      moq: int.tryParse(moq) ?? 0,
                                      remark: remark,
                                      samplePrice: double.tryParse(samplePrice),
                                      sampleLeadTime: sampleLeadTime.isNotEmpty
                                          ? sampleLeadTime
                                          : null,
                                      sampleCondition: sampleCondition,
                                    );
                                    Navigator.pop(confirmCtx); // Close confirm
                                    Navigator.pop(
                                      context,
                                    ); // Close manual input
                                  },
                                  child: const Text(
                                    "Confirm & Submit",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D1D1F),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          "Save Quote",
                          style: TextStyle(color: Colors.white),
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
    );
  }

  void _showReviewQuoteDialog(BuildContext context, Map<String, dynamic> req) {
    final double quotedPrice =
        double.tryParse(req['quoted_price']?.toString() ?? '0') ?? 0.0;
    final TextEditingController buyerNoteController = TextEditingController(
      text: req['buyer_note'] ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Review Supplier Quote",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "ตรวจสอบราคาและเงื่อนไขที่โรงงานเสนอมา",
                style: TextStyle(color: Color(0xFF86868B), fontSize: 14),
              ),
              const Divider(height: 48, color: Color(0xFFF4F5F7)),
              Row(
                children: [
                  const Text(
                    "Product: ",
                    style: TextStyle(color: Color(0xFF86868B), fontSize: 13),
                  ),
                  Text(
                    req['product_name']?.toString() ??
                        req['product']?.toString() ??
                        '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    "Quantity: ",
                    style: TextStyle(color: Color(0xFF86868B), fontSize: 13),
                  ),
                  Text(
                    "${req['qty'] ?? 0} pcs",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E2E2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Unit Cost (ราคาต้นทุน)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "${req['currency'] ?? 'USD'} ${quotedPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFE2E2E2)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Lead Time (ระยะเวลาผลิต)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text("${req['lead_time'] ?? '-'}"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "MOQ (ขั้นต่ำการผลิต)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text("${req['moq'] ?? 0} pcs"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Sample Price (ราคาตัวอย่าง)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          req['sample_price'] != null &&
                                  double.tryParse(
                                        req['sample_price'].toString(),
                                      ) !=
                                      null &&
                                  double.parse(req['sample_price'].toString()) >
                                      0
                              ? "${req['currency'] ?? 'THB'} ${double.parse(req['sample_price'].toString()).toStringAsFixed(2)}"
                              : "Free (ฟรี)",
                        ),
                      ],
                    ),
                    if (req['sample_lead_time'] != null &&
                        req['sample_lead_time'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Sample Lead Time",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text("${req['sample_lead_time']}"),
                        ],
                      ),
                    ],
                    if (req['sample_condition'] != null &&
                        req['sample_condition'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Sample Condition (เงื่อนไขตัวอย่าง)",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text("${req['sample_condition']}"),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Remarks (หมายเหตุจากโรงงาน):",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${req['remark'] ?? '-'}",
                          style: const TextStyle(
                            color: Color(0xFFD97781),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (req['revisions'] != null &&
                  (req['revisions'] as List).isNotEmpty) ...[
                const Text(
                  "Negotiation History (ประวัติการต่อรองราคา)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E2E2)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: (req['revisions'] as List).length,
                    itemBuilder: (ctx, index) {
                      final rev = (req['revisions'] as List)[index];
                      final bool isBuyer = rev['actor'] == 'buyer';
                      final String dateStr = rev['created_at'] != null
                          ? rev['created_at']
                                .toString()
                                .split('.')
                                .first
                                .replaceAll('T', ' ')
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isBuyer
                              ? const Color(0xFFFFFBEB)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isBuyer
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isBuyer
                                      ? "ฝ่ายจัดซื้อ (PPN)"
                                      : "โรงงาน (Supplier)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: isBuyer
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF047857),
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF86868B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (isBuyer)
                              Text(
                                rev['buyer_note']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF78350F),
                                ),
                              )
                            else ...[
                              Text(
                                "Price: ${rev['currency'] ?? 'USD'} ${rev['quoted_price']} • Lead Time: ${rev['lead_time']} • MOQ: ${rev['moq']}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF065F46),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (rev['remark'] != null &&
                                  rev['remark'].toString().isNotEmpty)
                                Text(
                                  "Note: ${rev['remark']}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF047857),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              TextFormField(
                controller: buyerNoteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "คำแนะนำ/เหตุผลในการแก้ไขราคา (Buyer's Note)",
                  hintText:
                      "ระบุเงื่อนไขที่อยากให้โรงงานแก้ไขราคาเสนอมา เช่น ขอราคา \$11.00...",
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: const Color(0xFFF4F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _updateQuoteStatus(
                          supplierId: req['supplier_id'] ?? 0,
                          quoteId: req['id'] ?? 0,
                          status: 'Needs Revision',
                          buyerNote: buyerNoteController.text,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFD97781)),
                        ),
                      ),
                      child: const Text(
                        "Need Revision",
                        style: TextStyle(
                          color: Color(0xFFD97781),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _updateQuoteStatus(
                          supplierId: req['supplier_id'] ?? 0,
                          quoteId: req['id'] ?? 0,
                          status: 'Approved',
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D1D1F),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Approve & Accept",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
