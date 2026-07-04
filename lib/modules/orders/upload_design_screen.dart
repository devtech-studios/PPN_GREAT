import 'dart:ui';

import 'package:flutter/material.dart';

class MouseDraggableScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class UploadDesignScreen extends StatefulWidget {
  const UploadDesignScreen({super.key});

  @override
  State<UploadDesignScreen> createState() => _UploadDesignScreenState();
}

class _UploadDesignScreenState extends State<UploadDesignScreen> {
  String _searchText = "";
  String _selectedProjectId = "PRJ-008";

  // ==========================================
  // Mock Data: ข้อมูลประวัติ Artwork 🌟 (เพิ่ม attempt)
  // ==========================================
  final List<Map<String, dynamic>> _artworkProjects = [
    {
      "id": "PRJ-008",
      "customer": "AIS",
      "status": "In Progress",
      "products": [
        {
          "name": "ร่มพับ 2 ตอน พรีเมียม",
          "qty": "3,000 คัน",
          "specs": "ร่มสีเขียว AIS สกรีนอุ่นใจ 2 จุด (กางออกขนาด 21 นิ้ว)",
          "artwork_logs": [
            {
              "id": "ART-001",
              "attempt": 1, // 🌟 ครั้งที่ 1
              "ver": "V1",
              "source": "In-house Designer",
              "status": "Need Revision",
              "date": "20 May 2026",
              "file_name": "Umbrella_AIS_V1.jpg",
              "feedback":
                  "ลูกค้าแจ้งว่า โลโก้น้องอุ่นใจเล็กเกินไป ขอขยายขึ้น 20%",
            },
            {
              "id": "ART-002",
              "attempt": 2, // 🌟 ครั้งที่ 2
              "ver": "V2",
              "source": "Freelance",
              "status": "Approved by Client",
              "date": "22 May 2026",
              "file_name": "Umbrella_AIS_V2_Final.png",
              "feedback":
                  "ลูกค้าคอนเฟิร์มแบบ V2 เรียบร้อย ส่งให้โรงงานผลิตได้เลย",
            },
            {
              "id": "ART-003",
              "attempt": 3, // 🌟 ครั้งที่ 3
              "ver": "V2.1 (Factory Proof)",
              "source": "Supplier",
              "status": "Awaiting Approval",
              "date": "25 May 2026",
              "file_name": "Factory_Template_AIS.pdf",
              "feedback":
                  "โรงงานตีเส้นลงบนแพทเทิร์นร่มจริง (Factory Proof) ให้เซลส์ตรวจสอบความถูกต้องก่อนสกรีนจริง",
            },
          ],
        },
      ],
    },
    {
      "id": "PRJ-015",
      "customer": "Cafe Amazon",
      "status": "Waiting Artwork",
      "products": [
        {
          "name": "แก้วน้ำพลาสติก 22oz (Reusable Cup)",
          "qty": "50,000 ใบ",
          "specs": "แก้วพลาสติก PP ฉีดสีเขียว Amazon สกรีนลายรอบใบ",
          "artwork_logs": [
            {
              "id": "ART-004",
              "attempt": 1, // 🌟 ครั้งที่ 1
              "ver": "V1",
              "source": "Customer Provided",
              "status": "Need Revision",
              "date": "01 Jun 2026",
              "file_name": "Amazon_Cup_Design.pdf",
              "feedback":
                  "ไฟล์ที่ลูกค้าส่งมาเป็น RGB กราฟิกแจ้งให้ลูกค้าแปลงเป็น CMYK/Pantone ก่อน",
            },
          ],
        },
      ],
    },
  ];

  final List<String> _artworkStages = [
    "Awaiting Approval",
    "Reviewing",
    "Approved by Client",
    "Approved by Supplier",
    "Need Revision",
    "Rejected",
  ];

  List<Map<String, dynamic>> _getFilteredProjects() {
    if (_searchText.isEmpty) return _artworkProjects;
    String searchLower = _searchText.toLowerCase();
    return _artworkProjects.where((p) {
      return p['customer'].toString().toLowerCase().contains(searchLower) ||
          p['id'].toString().toLowerCase().contains(searchLower);
    }).toList();
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
                    "Artwork Tracking",
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
                  child: filteredProjects.isEmpty
                      ? const Center(
                          child: Text(
                            "No pending projects",
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
                              onTap: () =>
                                  setState(() => _selectedProjectId = p['id']),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF8B5CF6).withOpacity(
                                          0.1,
                                        ) // สีม่วง
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(
                                            0xFF8B5CF6,
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
                                            ? const Color(0xFF7C3AED)
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
                                            Icons.brush_outlined,
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
          // 2. RIGHT PANEL: จัดการ Artwork (Detail)
          // ==========================================
          Expanded(
            child: selectedProject == null
                ? const Center(
                    child: Text(
                      "กรุณาเลือกโปรเจกต์",
                      style: TextStyle(color: Color(0xFF86868B)),
                    ),
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
                                  "Artwork & Design Tracking",
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
                                    color: Color(0xFF7C3AED),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            // 🌟 ปุ่ม Add Artwork Log
                            _buildButton(
                              "Add Artwork Log",
                              const Color(0xFF1D1D1F),
                              Colors.white,
                              icon: Icons.add,
                              onTap: () => _showAddArtworkLogDialog(
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
    List logs = product['artwork_logs'] as List;

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
                    color: const Color(0xFFEDE9FE), // สีม่วงอ่อน
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF7C3AED), // สีม่วง
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Requirement: ${product['specs']}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // รายการ Artwork Logs
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                if (logs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "ยังไม่มีประวัติการอัปโหลด Artwork ในสินค้านี้",
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ),
                  )
                else
                  ...logs.map((logData) => _buildArtworkLogItem(logData)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkLogItem(Map<String, dynamic> log) {
    bool isApproved = log['status'].toString().contains("Approved");
    bool isRejected =
        log['status'].toString().contains("Revision") ||
        log['status'].toString().contains("Rejected");

    // กำหนดสีของการ์ดตามสถานะ
    Color borderColor = const Color(0xFFE2E8F0);
    Color bgColor = const Color(0xFFF8FAFC);

    if (isApproved) {
      borderColor = const Color(0xFF10B981);
      bgColor = const Color(0xFFF0FDF4);
    } else if (isRejected) {
      borderColor = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFFFBEB);
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isApproved
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : (isRejected
                            ? const Color(0xFFF59E0B).withOpacity(0.3)
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
                      Icons.image_outlined,
                      size: 20,
                      color: isApproved
                          ? const Color(0xFF059669)
                          : (isRejected
                                ? const Color(0xFFD97706)
                                : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log['file_name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isApproved
                            ? const Color(0xFF064E3B)
                            : (isRejected
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 🌟 ป้าย Attempt (ครั้งที่)
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
                        "ครั้งที่ ${log['attempt'] ?? 1}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 🌟 ป้าย Version
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
                        log['ver'],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 🌟 ป้าย Source (จากใคร)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE), // ม่วงอ่อน
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Source: ${log['source']}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4CA4), // ม่วงเข้ม
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
                      value: log['status'],
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
                      items: _artworkStages
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() => log['status'] = val!);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details & Feedback
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ฝั่งซ้าย: ข้อมูลไฟล์
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // กล่องภาพจำลอง
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            color: Color(0xFFCBD5E1),
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow("Date:", log['date']),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // 🌟 ฝั่งขวา: Feedback & Notes
                Expanded(
                  flex: 7,
                  child: Container(
                    height: 154,
                    padding: const EdgeInsets.all(20),
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
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 16,
                                  color: isApproved
                                      ? const Color(0xFF059669)
                                      : (isRejected
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF1E293B)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Feedback / Notes",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isApproved
                                        ? const Color(0xFF064E3B)
                                        : (isRejected
                                              ? const Color(0xFF92400E)
                                              : const Color(0xFF1E293B)),
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () =>
                                  _showUpdateFeedbackDialog(context, log),
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
                                  "Edit Note",
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
                              log['feedback'].toString().isEmpty
                                  ? "ไม่มีหมายเหตุ"
                                  : log['feedback'],
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: log['feedback'].toString().isEmpty
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF334155),
                                fontStyle: log['feedback'].toString().isEmpty
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // --- Dialogs ---

  void _showAddArtworkLogDialog(
    BuildContext context,
    Map<String, dynamic> project,
  ) {
    String selectedProduct = project['products'][0]['name'];
    String source = "In-house Designer";
    String fileName = "";
    String note = "";
    String status = "Awaiting Approval";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Add Artwork Log"),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "บันทึกการส่งตรวจหรือรับไฟล์ Artwork เข้าสู่ระบบ",
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
                    DropdownButtonFormField<String>(
                      initialValue: selectedProduct,
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
                            (p) => DropdownMenuItem<String>(
                              value: p['name'],
                              child: Text(p['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedProduct = val!),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "2. Artwork Source (ที่มาของไฟล์)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: source,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF4F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items:
                          [
                                "In-house Designer",
                                "Freelance",
                                "Supplier",
                                "Customer Provided",
                              ]
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (val) => setDialogState(() => source = val!),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "3. Status & File Name",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF4F5F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _artworkStages
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => status = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              hintText: "E.g. Logo_V1.jpg",
                              filled: true,
                              fillColor: const Color(0xFFF4F5F7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => fileName = val,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "4. Initial Remarks / Feedback",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "e.g., รอให้ลูกค้าตรวจแบบที่ทำใหม่",
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
                onPressed: () {
                  setState(() {
                    var prod = (project['products'] as List).firstWhere(
                      (p) => p['name'] == selectedProduct,
                    );
                    if (prod['artwork_logs'] == null) prod['artwork_logs'] = [];

                    // 🌟 คำนวณครั้งที่ (Attempt)
                    int attemptNum = (prod['artwork_logs'] as List).length + 1;

                    prod['artwork_logs'].add({
                      "id": "ART-NEW-$attemptNum",
                      "attempt": attemptNum, // 🌟 เพิ่ม attempt ตอนกดเซฟ
                      "ver": "V$attemptNum",
                      "source": source,
                      "status": status,
                      "date": "Today",
                      "file_name": fileName.isEmpty
                          ? "Artwork_V$attemptNum.jpg"
                          : fileName,
                      "feedback": note,
                    });
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D1D1F),
                ),
                child: const Text(
                  "Save Log",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdateFeedbackDialog(
    BuildContext context,
    Map<String, dynamic> log,
  ) {
    String feedback = log['feedback'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Feedback / Notes"),
        content: SizedBox(
          width: 500,
          child: TextFormField(
            initialValue: feedback,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "บันทึกคอมเมนต์ เช่น ต้องปรับแก้สี โลโก้เล็กไป...",
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
            onPressed: () {
              setState(() => log['feedback'] = feedback);
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
