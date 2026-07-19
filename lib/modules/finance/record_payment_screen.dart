import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({super.key});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = false;
  bool _isSubmitting = false;

  String _searchText = "";
  String _selectedProjectId = "";

  // ใช้ TextEditingController เพื่อไม่ให้ Cursor หลุดโฟกัสเวลาพิมพ์
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _paymentMethod = "Bank Transfer (โอนเงิน)";

  List<Map<String, dynamic>> _billingProjects = [];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toString().split(' ').first;
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final projRes = await _api.get(ProjectEndpoints.index);
      final List rawProj = projRes.data['data'] ?? [];

      final payRes = await _api.get(FinanceEndpoints.payments);
      final List rawPayments = payRes.data['data'] ?? [];

      final docRes = await _api.get(FinanceEndpoints.documents);
      final List rawDocs = docRes.data['data'] ?? [];

      List<Map<String, dynamic>> tempProjects = [];

      for (var p in rawProj) {
        final pId = p['id'];
        final pCode = p['project_code'] ?? '';
        final customerName = p['customer']?['name'] ?? 'General Customer';

        final projDocs = rawDocs
            .where((d) => d['project_id'] == pId && d['status'] != 'Cancelled')
            .toList();

        final ciDoc = projDocs.firstWhere(
          (d) => d['doc_type'] == 'CI',
          orElse: () => null,
        );
        final piDoc = projDocs.firstWhere(
          (d) => d['doc_type'] == 'PI',
          orElse: () => null,
        );
        final quDoc = projDocs.firstWhere(
          (d) => d['doc_type'] == 'QU',
          orElse: () => null,
        );

        double grandTotal = 0.0;
        String invoiceNo = 'N/A';
        List products = [];

        if (ciDoc != null) {
          grandTotal =
              double.tryParse(ciDoc['total_amount']?.toString() ?? '0.0') ??
              0.0;
          invoiceNo = ciDoc['doc_no'] ?? '';
          products = (ciDoc['items'] as List? ?? [])
              .map(
                (it) => {
                  'name': it['item_name'] ?? '',
                  'qty': it['qty'] ?? 1,
                  'price':
                      double.tryParse(it['unit_price']?.toString() ?? '0.0') ??
                      0.0,
                },
              )
              .toList();
        } else if (piDoc != null) {
          grandTotal =
              double.tryParse(piDoc['total_amount']?.toString() ?? '0.0') ??
              0.0;
          invoiceNo = piDoc['doc_no'] ?? '';
          products = (piDoc['items'] as List? ?? [])
              .map(
                (it) => {
                  'name': it['item_name'] ?? '',
                  'qty': it['qty'] ?? 1,
                  'price':
                      double.tryParse(it['unit_price']?.toString() ?? '0.0') ??
                      0.0,
                },
              )
              .toList();
        } else if (quDoc != null) {
          grandTotal =
              double.tryParse(quDoc['total_amount']?.toString() ?? '0.0') ??
              0.0;
          invoiceNo = quDoc['doc_no'] ?? '';
          products = (quDoc['items'] as List? ?? [])
              .map(
                (it) => {
                  'name': it['item_name'] ?? '',
                  'qty': it['qty'] ?? 1,
                  'price':
                      double.tryParse(it['unit_price']?.toString() ?? '0.0') ??
                      0.0,
                },
              )
              .toList();
        } else {
          grandTotal =
              double.tryParse(p['order_value']?.toString() ?? '0.0') ?? 0.0;
          final List itemsList = p['product_items'] ?? p['productItems'] ?? [];
          products = itemsList
              .map(
                (it) => {
                  'name': it['name'] ?? '',
                  'qty': it['qty'] ?? 1,
                  'price': 0.0,
                },
              )
              .toList();
        }

        final projPayments = rawPayments
            .where((pay) => pay['project_id'] == pId)
            .toList();

        double paidAmount = 0.0;
        for (var pay in projPayments) {
          if (pay['status'] == 'Confirmed') {
            paidAmount +=
                double.tryParse(pay['amount']?.toString() ?? '0.0') ?? 0.0;
          }
        }

        String status = 'Unpaid';
        if (paidAmount >= grandTotal && grandTotal > 0) {
          status = 'Paid';
        } else if (paidAmount > 0) {
          status = 'Partial';
        }

        List<Map<String, dynamic>> history = projPayments
            .map<Map<String, dynamic>>(
              (pay) => {
                'id': pay['id'],
                'round': pay['payment_type'] == 'Deposit'
                    ? 'มัดจำ (Deposit)'
                    : (pay['payment_type'] == 'Balance'
                          ? 'ส่วนที่เหลือ (Balance)'
                          : 'ชำระเต็มจำนวน (Full)'),
                'amount':
                    double.tryParse(pay['amount']?.toString() ?? '0.0') ?? 0.0,
                'date': pay['payment_date'] != null
                    ? pay['payment_date'].toString().split(' ').first
                    : '',
                'method': pay['method'] ?? '',
                'status': pay['status'] ?? 'Pending Verification',
                'slip_file_path': pay['slip_file_path'],
                'notes': pay['notes'],
              },
            )
            .toList();

        tempProjects.add({
          'id': pCode,
          'db_id': pId,
          'customer': customerName,
          'invoice_no': invoiceNo,
          'finance_document_id': ciDoc?['id'] ?? piDoc?['id'] ?? quDoc?['id'],
          'grand_total': grandTotal,
          'paid_amount': paidAmount,
          'status': status,
          'products': products,
          'history': history,
        });
      }

      if (!mounted) return;
      setState(() {
        _billingProjects = tempProjects;
        if (_billingProjects.isNotEmpty) {
          if (_selectedProjectId.isEmpty ||
              !_billingProjects.any((p) => p['id'] == _selectedProjectId)) {
            _selectedProjectId = _billingProjects[0]['id'];
          }
        } else {
          _selectedProjectId = "";
        }
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitPayment(Map<String, dynamic> project) async {
    if (_isSubmitting) return;
    double payAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (payAmount <= 0) {
      _showErrorSnackBar("กรุณาระบุยอดเงินที่ได้รับให้ถูกต้อง");
      return;
    }

    final int pId = project['db_id'];

    String paymentType = (project['history'] as List).isEmpty
        ? 'Deposit'
        : 'Balance';
    if (payAmount >= (project['grand_total'] - project['paid_amount'])) {
      paymentType = 'Full';
    }

    String method = 'Bank Transfer';
    if (_paymentMethod.contains('Cheque')) {
      method = 'Cheque';
    } else if (_paymentMethod.contains('Cash')) {
      method = 'Cash';
    } else if (_paymentMethod.contains('Other')) {
      method = 'Other';
    }

    final payload = {
      'project_id': pId,
      'finance_document_id': project['finance_document_id'],
      'payment_type': paymentType,
      'amount': payAmount,
      'method': method,
      'payment_date': _dateController.text,
      'notes': 'Recorded via Payments Portal',
    };

    setState(() => _isSubmitting = true);

    try {
      final response = await _api.post(
        FinanceEndpoints.payments,
        data: payload,
      );
      if (response.data['success'] == true) {
        _showSuccessSnackBar("บันทึกรับชำระเงินเรียบร้อยแล้ว (รอการยืนยัน)");
        _amountController.clear();
        await _fetchData();
      }
    } catch (e) {
      debugPrint("Error recording payment: $e");
      _showErrorSnackBar("เกิดข้อผิดพลาดในการบันทึกข้อมูลการรับเงิน");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _verifyPayment(int paymentId) async {
    try {
      final response = await _api.patch(
        FinanceEndpoints.verifyPayment(paymentId),
        data: {'status': 'Confirmed'},
      );
      if (response.data['success'] == true) {
        _showSuccessSnackBar("ยืนยันการรับชำระเงินของลูกค้าเรียบร้อยแล้ว");
        await _fetchData();
      }
    } catch (e) {
      debugPrint("Error verifying payment: $e");
      _showErrorSnackBar("เกิดข้อผิดพลาดในการยืนยันยอดเงิน");
    }
  }

  Future<void> _uploadSlip(int paymentId) async {
    try {
      // ใช้ FilePicker.pickFiles ตามโครงสร้างที่มีในโปรเจกต์นี้
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          _showErrorSnackBar("ไม่สามารถอ่านไฟล์ได้");
          return;
        }

        _showSuccessSnackBar("กำลังอัปโหลดไฟล์หลักฐาน...");

        final formData = dio.FormData.fromMap({
          'file': dio.MultipartFile.fromBytes(file.bytes!, filename: file.name),
        });

        // ใช้ _api.upload เพื่อส่ง Content-Type: multipart/form-data เสมอบนเว็บ
        final response = await _api.upload(
          FinanceEndpoints.uploadSlip(paymentId),
          formData: formData,
        );

        if (response.data['success'] == true) {
          _showSuccessSnackBar("อัปโหลดสลิปหลักฐานการชำระเงินเรียบร้อย");
          await _fetchData();
        }
      }
    } catch (e) {
      debugPrint("Error uploading slip: $e");
      _showErrorSnackBar("เกิดข้อผิดพลาดในการอัปโหลดหลักฐาน");
    }
  }

  Future<void> _viewSlip(String slipUrl) async {
    try {
      String fullUrl = slipUrl;
      // แทนที่พาธ /storage/slips/ ด้วยพาธสตรีมมิ่งผ่าน API เพื่อแก้ปัญหา 403 Forbidden บน Windows
      if (fullUrl.contains('/storage/slips/')) {
        fullUrl = fullUrl.replaceAll(
          '/storage/slips/',
          '/api/finance/payments/file/',
        );
      }

      if (!fullUrl.startsWith('http')) {
        final baseUri = Uri.parse(ApiConfig.baseUrl);
        final String baseStr =
            "${baseUri.scheme}://${baseUri.host}:${baseUri.port}";
        fullUrl = "$baseStr$fullUrl";
      }
      final uri = Uri.parse(fullUrl);
      // ละเว้น canLaunchUrl บนเว็บ เนื่องจากมักจะคืนค่า false ทั้งๆ ที่เปิดลิงก์ได้จริง
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Error launching slip url: $e");
      _showErrorSnackBar("ไม่สามารถเปิดลิงก์รูปสลิปหลักฐานได้");
    }
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

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredProjects() {
    if (_searchText.isEmpty) return _billingProjects;
    return _billingProjects
        .where(
          (p) =>
              p['customer'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ||
              p['id'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5B7BD5)),
        ),
      );
    }

    if (_billingProjects.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "ยังไม่มีข้อมูลโครงการสำหรับการรับเงิน",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D1D1F),
                ),
                child: const Text(
                  "โหลดข้อมูลใหม่",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredProjects = _getFilteredProjects();
    Map<String, dynamic> selectedProject = filteredProjects.firstWhere(
      (p) => p['id'] == _selectedProjectId,
      orElse: () => _billingProjects[0],
    );

    double balanceDue =
        selectedProject['grand_total'] - selectedProject['paid_amount'];

    double progress = 0.0;
    if (selectedProject['grand_total'] > 0) {
      progress =
          selectedProject['paid_amount'] / selectedProject['grand_total'];
    }
    if (progress.isNaN || progress.isInfinite || progress < 0) {
      progress = 0.0;
    }
    if (progress > 1.0) {
      progress = 1.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. LEFT PANEL: รายการรอรับชำระ
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
                    "Receive Payments",
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
                      final p = filteredProjects[index];
                      final isSelected = _selectedProjectId == p['id'];

                      Color statusColor = const Color(0xFFD97781);
                      Color statusBg = const Color(0xFFFDE2E4).withOpacity(0.5);
                      if (p['status'] == 'Partial') {
                        statusColor = const Color(0xFFD08A2A);
                        statusBg = const Color(0xFFFDF3E1);
                      } else if (p['status'] == 'Paid') {
                        statusColor = const Color(0xFF4A9062);
                        statusBg = const Color(0xFFB7E4C7).withOpacity(0.3);
                      }

                      return InkWell(
                        onTap: () => setState(() {
                          _selectedProjectId = p['id'];
                          _amountController
                              .clear(); // รีเซ็ตฟอร์มเวลาเปลี่ยนโปรเจกต์
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
                                    p['id'],
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
                                      p['status'],
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
                                p['customer'],
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
                                "INV: ${p['invoice_no']}",
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
          // 2. RIGHT PANEL: รายละเอียดและการรับเงิน
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Record Payment",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D1D1F),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "รับชำระเงิน: ${selectedProject['id']} - ${selectedProject['customer']}",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF5B7BD5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if ((selectedProject['history'] as List).isNotEmpty)
                        _buildButton(
                          "Preview Receipt (A4)",
                          Colors.white,
                          const Color(0xFF5B7BD5),
                          icon: Icons.receipt_long_outlined,
                          isOutlined: true,
                          onTap: () {
                            _showReceiptPreviewDialog(context, selectedProject);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- ส่วน Summary Cards ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryBox(
                          "ยอดเรียกเก็บรวม (Grand Total)",
                          "฿ ${selectedProject['grand_total'].toStringAsFixed(2)}",
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryBox(
                          "รับชำระแล้ว (Paid Amount)",
                          "฿ ${selectedProject['paid_amount'].toStringAsFixed(2)}",
                          color: const Color(0xFF4A9062),
                          bgColor: const Color(0xFFB7E4C7).withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // กล่อง Balance Due ทำ OnTap เพื่อดึงข้อมูลเข้าฟอร์ม
                      Builder(
                        builder: (context) {
                          final bool isOverpaid = balanceDue < 0;
                          final double displayBalance = isOverpaid
                              ? balanceDue.abs()
                              : balanceDue;

                          return Expanded(
                            child: _buildSummaryBox(
                              isOverpaid
                                  ? "ยอดชำระเกิน (Overpaid)"
                                  : "ยอดคงค้าง (คลิกเพื่อดึงยอด)",
                              "฿ ${displayBalance.toStringAsFixed(2)}",
                              color: isOverpaid
                                  ? const Color(0xFF4A9062)
                                  : const Color(0xFFD97781),
                              bgColor: isOverpaid
                                  ? const Color(0xFFB7E4C7).withOpacity(0.3)
                                  : const Color(0xFFFDE2E4).withOpacity(0.5),
                              onTap: () {
                                setState(() {
                                  _amountController.text = isOverpaid
                                      ? "0.00"
                                      : balanceDue.toStringAsFixed(2);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress Bar
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A9062),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "รับชำระแล้ว ${(progress * 100).toInt()}%",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF86868B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // --- ฟอร์มบันทึกรับเงิน (ซ่อนถ้าจ่ายครบแล้ว) ---
                  if (balanceDue > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                        ),
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
                          const Text(
                            "บันทึกรับชำระเงินงวดใหม่ (Record New Payment)",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Divider(height: 48, color: Color(0xFFF4F5F7)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // จำนวนเงิน (ใช้ Controller)
                              Expanded(
                                flex: 3,
                                child: _buildEditableField(
                                  "ยอดเงินที่ได้รับ (THB) *",
                                  "0.00",
                                  controller: _amountController,
                                  isNumber: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // ช่องทางการรับชำระ
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "ช่องทางการชำระเงิน *",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _paymentMethod,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFF4F5F7),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      items:
                                          [
                                                "Bank Transfer (โอนเงิน)",
                                                "Cheque (เช็ค)",
                                                "Cash (เงินสด)",
                                              ]
                                              .map(
                                                (m) => DropdownMenuItem<String>(
                                                  value: m,
                                                  child: Text(m),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (val) =>
                                          setState(() => _paymentMethod = val!),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // วันที่ (ใช้ Controller)
                              Expanded(
                                flex: 2,
                                child: _buildEditableField(
                                  "วันที่โอน/รับเช็ค *",
                                  "",
                                  controller: _dateController,
                                  icon: Icons.calendar_today,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Color(0xFF2563EB),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "หลังจากกดบันทึกแล้ว ท่านสามารถอัปโหลดรูปภาพสลิปหลักฐานการโอนเงินได้ที่แถวรายการนั้น ๆ ในตารางประวัติการรับชำระเงินด้านล่าง",
                                    style: TextStyle(
                                      color: Color(0xFF1E40AF),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF1D1D1F),
                                    ),
                                  )
                                : _buildButton(
                                    "Confirm & Record Payment",
                                    const Color(0xFF1D1D1F),
                                    Colors.white,
                                    onTap: () =>
                                        _submitPayment(selectedProject),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB7E4C7).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.verified,
                            color: Color(0xFF4A9062),
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "โปรเจกต์นี้รับชำระเงินครบถ้วนแล้ว (Fully Paid)",
                            style: TextStyle(
                              color: Color(0xFF4A9062),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // --- ตารางประวัติรับชำระเงิน ---
                  const Text(
                    "Payment History (ประวัติการรับชำระเงิน)",
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
                    child: (selectedProject['history'] as List).isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                "ยังไม่มีประวัติการโอนเงิน",
                                style: TextStyle(color: Color(0xFF86868B)),
                              ),
                            ),
                          )
                        : DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFF7F9FC),
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "รายการ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "วันที่ชำระ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "ช่องทาง",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "ยอดเงิน",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "สถานะ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "หลักฐาน (Slip)",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "การจัดการ",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: (selectedProject['history'] as List).map((
                              hist,
                            ) {
                              final int payId = hist['id'] ?? 0;
                              final bool isVerified =
                                  hist['status'] == 'Confirmed';
                              final String? slipPath = hist['slip_file_path'];

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      hist['round'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(hist['date'])),
                                  DataCell(Text(hist['method'])),
                                  DataCell(
                                    Text(
                                      "฿ ${hist['amount'].toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A9062),
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
                                        color: isVerified
                                            ? const Color(
                                                0xFFB7E4C7,
                                              ).withOpacity(0.3)
                                            : const Color(
                                                0xFFFDE2E4,
                                              ).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isVerified ? 'Confirmed' : 'Pending',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isVerified
                                              ? const Color(0xFF4A9062)
                                              : const Color(0xFFD97781),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    slipPath != null && slipPath.isNotEmpty
                                        ? TextButton.icon(
                                            onPressed: () =>
                                                _viewSlip(slipPath),
                                            icon: const Icon(
                                              Icons.receipt_long,
                                              size: 16,
                                            ),
                                            label: const Text("ดูสลิป"),
                                          )
                                        : ElevatedButton.icon(
                                            onPressed: () => _uploadSlip(payId),
                                            icon: const Icon(
                                              Icons.cloud_upload_outlined,
                                              size: 14,
                                            ),
                                            label: const Text("อัปโหลด"),
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                            ),
                                          ),
                                  ),
                                  DataCell(
                                    isVerified
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF4A9062),
                                                size: 16,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "Verified",
                                                style: TextStyle(
                                                  color: Color(0xFF4A9062),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          )
                                        : ElevatedButton.icon(
                                            onPressed: () =>
                                                _verifyPayment(payId),
                                            icon: const Icon(
                                              Icons.verified,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            label: const Text(
                                              "ยืนยันยอด",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF4A9062,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                            ),
                                          ),
                                  ),
                                ],
                              );
                            }).toList(),
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

  Widget _buildSummaryBox(
    String label,
    String value, {
    Color color = const Color(0xFF1D1D1F),
    Color bgColor = const Color(0xFFF4F5F7),
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          // ถ้ามี onTap ให้โชว์กรอบนิดนึงเวลากดจะได้ดูออกว่าเป็นปุ่ม
          border: onTap != null
              ? Border.all(color: color.withOpacity(0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // เปลี่ยนมารับ TextEditingController
  Widget _buildEditableField(
    String label,
    String hint, {
    TextEditingController? controller,
    bool isNumber = false,
    IconData? icon,
  }) {
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
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixIcon: icon != null
                ? Icon(icon, size: 18, color: const Color(0xFF86868B))
                : null,
            filled: true,
            fillColor: const Color(0xFFF4F5F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isOutlined
              ? Border.all(color: const Color(0xFFAEC4FA))
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
  // RECEIPT / TAX INVOICE PREVIEW (A4)
  // =========================================================

  void _showReceiptPreviewDialog(
    BuildContext context,
    Map<String, dynamic> project,
  ) {
    double subtotal = project['grand_total'] / 1.07;
    double vat = project['grand_total'] - subtotal;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black45,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Stack(
          children: [
            // Click outside container to close
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 794,
                  height: 1123,
                  padding: const EdgeInsets.all(72.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 30,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "PPN GREAT CO., LTD.",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "123/45 ซอยสุขุมวิท, แขวงคลองเตย, เขตคลองเตย\nกรุงเทพมหานคร 10110\nTax ID: 0105556000123",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF86868B),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "RECEIPT / TAX INVOICE",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                              const Text(
                                "ใบเสร็จรับเงิน / ใบกำกับภาษี",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF86868B),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Doc No: RE-2605-999\nDate: 26 May 2026\nRef INV: ${project['invoice_no']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1D1D1F),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      const Text(
                        "RECEIVED FROM / ได้รับเงินจาก:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF86868B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        project['customer'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const Text(
                        "Bangkok, Thailand",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF86868B),
                        ),
                      ),
                      const SizedBox(height: 48),

                      Container(
                        padding: const EdgeInsets.only(bottom: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF1D1D1F),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 5,
                              child: Text(
                                "DESCRIPTION / รายการชำระเงิน",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "AMOUNT (THB)",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                "ชำระค่าสินค้าตามเอกสารอ้างอิง ${project['invoice_no']}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "฿ ${project['paid_amount'].toStringAsFixed(2)}",
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 48, color: Color(0xFFE2E2E2)),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 320,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Subtotal / ยอดก่อนภาษี",
                                      style: TextStyle(
                                        color: Color(0xFF86868B),
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      "฿ ${subtotal.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "VAT (7%)",
                                      style: TextStyle(
                                        color: Color(0xFF86868B),
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      "฿ ${vat.toStringAsFixed(2)}",
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(color: Color(0xFFF4F5F7)),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "TOTAL RECEIVED",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1D1D1F),
                                      ),
                                    ),
                                    Text(
                                      "฿ ${project['paid_amount'].toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF5B7BD5),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F5F7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "Close Preview",
                                style: TextStyle(
                                  color: Color(0xFF86868B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 180,
                                height: 1,
                                color: const Color(0xFF86868B),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Authorized Signature / ผู้รับเงิน",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF86868B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Floating close button at the top-right
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  tooltip: "Close Preview (ปิด)",
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
