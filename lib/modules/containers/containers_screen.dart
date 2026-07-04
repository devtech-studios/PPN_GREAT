import 'package:flutter/material.dart';

class ContainersScreen extends StatefulWidget {
  const ContainersScreen({super.key});

  @override
  State<ContainersScreen> createState() => _ContainersScreenState();
}

class _ContainersScreenState extends State<ContainersScreen> {
  String _searchText = "";
  String _selectedContainerId = "SHP-2605-01";
  String _activeTab = "Tracking";

  // ==========================================
  // Mock Data: ปรับปรุงวันที่ 3 สเตป (Doc Issue, Actual Departure, ETA)
  // ==========================================
  final List<Map<String, dynamic>> _shipments = [
    {
      "id": "SHP-2605-01",
      "container_no": "TLLU 1234567 (40HC)",
      "status": "In Transit",
      "tracking": {
        "doc_issue_date": "10 Jun 2026", // 1. วันที่ออกเอกสาร
        "actual_departure": "12 Jun 2026", // 2. วันที่เรือออกจริง
        "estimated_arrival":
            "25 Jun 2026", // 3. วันคาดการณ์ของจะมาถึง (อัปเดตได้เรื่อยๆ)
      },
      "plan_file": "TLLU1234567_Loading_Plan.pdf",
      "customs": {"vat": 125000.0, "tax": 55000.0, "shipping_fee": 18500.0},
      "steps": {"Tracking": true, "Plan": true, "Customs": false},
    },
    {
      "id": "SHP-2605-02",
      "container_no": "Pending Container No.",
      "status": "Waiting Document",
      "tracking": {
        "doc_issue_date": "",
        "actual_departure": "",
        "estimated_arrival": "05 Jul 2026",
      },
      "plan_file": "",
      "customs": {"vat": 0.0, "tax": 0.0, "shipping_fee": 0.0},
      "steps": {"Tracking": false, "Plan": false, "Customs": false},
    },
  ];

  List<Map<String, dynamic>> _getFilteredShipments() {
    if (_searchText.isEmpty) return _shipments;
    return _shipments
        .where(
          (s) =>
              s['id'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ) ||
              s['container_no'].toString().toLowerCase().contains(
                _searchText.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredShipments = _getFilteredShipments();

    // Fallback selection
    if (filteredShipments.isNotEmpty &&
        !filteredShipments.any((s) => s['id'] == _selectedContainerId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedContainerId = filteredShipments[0]['id']);
      });
    }

    final selectedShipment = filteredShipments.isNotEmpty
        ? filteredShipments.firstWhere(
            (s) => s['id'] == _selectedContainerId,
            orElse: () => filteredShipments[0],
          )
        : null;

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
                  child: filteredShipments.isEmpty
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
                            bool isCleared = s['status'] == 'Cleared Customs';
                            bool inTransit = s['status'] == 'In Transit';

                            Color statusColor = const Color(0xFF86868B);
                            Color statusBg = const Color(
                              0xFFE2E2E2,
                            ).withOpacity(0.5);
                            if (isCleared) {
                              statusColor = const Color(0xFF4A9062);
                              statusBg = const Color(
                                0xFFB7E4C7,
                              ).withOpacity(0.3);
                            } else if (inTransit) {
                              statusColor = const Color(0xFF5B7BD5);
                              statusBg = const Color(
                                0xFFAEC4FA,
                              ).withOpacity(0.3);
                            } else {
                              statusColor = const Color(0xFFD97781);
                              statusBg = const Color(
                                0xFFFDE2E4,
                              ).withOpacity(0.5);
                            }

                            return InkWell(
                              onTap: () => setState(() {
                                _selectedContainerId = s['id'];
                                if (!s['steps']['Tracking']) {
                                  _activeTab = "Tracking";
                                } else if (!s['steps']['Plan']) {
                                  _activeTab = "Plan";
                                } else {
                                  _activeTab = "Customs";
                                }
                              }),
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
                                          s['id'],
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
                                            s['status'],
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
                                      s['container_no'],
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
                                          "ETA: ${s['tracking']['estimated_arrival'].isEmpty ? 'TBA' : s['tracking']['estimated_arrival']}",
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
            child: selectedShipment == null
                ? const Center(
                    child: Text(
                      "กรุณาเลือกรายการ",
                      style: TextStyle(color: Color(0xFF86868B)),
                    ),
                  )
                : SingleChildScrollView(
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
                                  "Shipment: ${selectedShipment['id']} | ${selectedShipment['container_no']}",
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
                                selectedShipment['steps']['Tracking'],
                              ),
                              _buildFlowDivider(),
                              _buildFlowTab(
                                "Plan",
                                "แผนโหลดตู้ (Container Plan)",
                                selectedShipment['steps']['Plan'],
                              ),
                              _buildFlowDivider(),
                              _buildFlowTab(
                                "Customs",
                                "ขาเข้าศุลกากร (Customs)",
                                selectedShipment['steps']['Customs'],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildActiveForm(selectedShipment),
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
  // FORMS BUILDERS
  // =========================================================

  Widget _buildActiveForm(Map<String, dynamic> shipment) {
    if (_activeTab == "Tracking") return _buildTrackingForm(shipment);
    if (_activeTab == "Plan") return _buildContainerPlanForm(shipment);
    if (_activeTab == "Customs") return _buildCustomsForm(shipment);
    return const SizedBox.shrink();
  }

  // 🌟 แบบฟอร์มใหม่: ติดตามวันที่ 3 สเตป
  Widget _buildTrackingForm(Map<String, dynamic> shipment) {
    var data = shipment['tracking'];
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
                  Icons.share_location_rounded,
                  color: Color(0xFF5B7BD5),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Shipment Dates Tracking",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "ติดตามและอัปเดตวันคาดการณ์ของมาถึง (ETA / ATA)",
                    style: TextStyle(color: Color(0xFF86868B)),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 48, color: Color(0xFFF4F5F7)),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. วันที่ออกเอกสาร
              Expanded(
                child: _buildTrackingField(
                  "วันที่ออกเอกสาร (Doc Issue Date)",
                  "DD/MM/YYYY",
                  initialValue: data['doc_issue_date'],
                  icon: Icons.edit_document,
                  onChanged: (val) => data['doc_issue_date'] = val,
                ),
              ),
              const SizedBox(width: 24),
              // 2. วันที่เรือออกจริง
              Expanded(
                child: _buildTrackingField(
                  "วันที่เรือออกจริง (Actual Departure)",
                  "DD/MM/YYYY",
                  initialValue: data['actual_departure'],
                  icon: Icons.directions_boat_filled_outlined,
                  onChanged: (val) => data['actual_departure'] = val,
                ),
              ),
              const SizedBox(width: 24),
              // 3. วันคาดการณ์ของจะมาถึง (กะวันของถึง อัปเดตได้เรื่อยๆ)
              Expanded(
                child: _buildTrackingField(
                  "วันคาดการณ์ของจะมาถึง (ETA)",
                  "ปรับแก้วันที่ได้เรื่อยๆ",
                  initialValue: data['estimated_arrival'],
                  icon: Icons.update,
                  onChanged: (val) => data['estimated_arrival'] = val,
                  isHighlight:
                      true, // ทำให้สีต่างออกไปเพื่อให้รู้ว่าช่องนี้ใช้กะระยะเวลาและปรับบ่อย
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          Center(
            child: _buildButton(
              "Save Dates & Update Tracking",
              const Color(0xFF1D1D1F),
              Colors.white,
              icon: Icons.save,
              onTap: () {
                setState(() {
                  shipment['steps']['Tracking'] = true;
                  if (data['actual_departure'].toString().isNotEmpty) {
                    shipment['status'] =
                        "In Transit"; // ถ้าเรือออกจริงแล้วเปลี่ยนสถานะ
                  } else if (data['doc_issue_date'].toString().isNotEmpty) {
                    shipment['status'] = "Document Issued"; // ถ้าเพิ่งออกเอกสาร
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✓ อัปเดตข้อมูล Tracking วันที่เรียบร้อย"),
                    backgroundColor: Color(0xFF4A9062),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 แบบฟอร์มใหม่: อัปโหลด PDF แผนการตู้จากจีน
  Widget _buildContainerPlanForm(Map<String, dynamic> shipment) {
    String currentFile = shipment['plan_file'] ?? "";
    bool hasFile = currentFile.isNotEmpty;

    return Container(
      key: const ValueKey("Plan"),
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
                  color: const Color(0xFFEAE4F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF6B4CA4),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Container Loading Plan (จากฝั่งจีน)",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "อัปโหลดไฟล์ PDF/Excel สรุปตำแหน่งของในตู้ที่โรงงานส่งมาให้",
                    style: TextStyle(color: Color(0xFF86868B)),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 48, color: Color(0xFFF4F5F7)),

          if (hasFile) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFEF4444),
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentFile,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Uploaded on: 12 Jun 2026",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildButton(
                    "View File",
                    Colors.white,
                    const Color(0xFF1D1D1F),
                    isOutlined: true,
                    icon: Icons.remove_red_eye_outlined,
                    onTap: () {
                      // Action to view PDF
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        shipment['plan_file'] = "";
                        shipment['steps']['Plan'] = false;
                      });
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                    ),
                    tooltip: "ลบไฟล์",
                  ),
                ],
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () {
                // Mock อัปโหลดไฟล์
                setState(() {
                  shipment['plan_file'] = "Supplier_Loading_Plan_Final.pdf";
                  shipment['steps']['Plan'] = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("อัปโหลดไฟล์เรียบร้อย"),
                    backgroundColor: Color(0xFF4A9062),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Click to upload Container Plan (PDF / Excel)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "รองรับไฟล์จาก Supplier/Forwarder จีน",
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomsForm(Map<String, dynamic> shipment) {
    var data = shipment['customs'];
    var trackingData = shipment['tracking'];
    double totalCustoms =
        (data['vat'] ?? 0.0) +
        (data['tax'] ?? 0.0) +
        (data['shipping_fee'] ?? 0.0);

    String etaStr = trackingData['estimated_arrival'];
    String paymentDueDate = etaStr.isNotEmpty
        ? "ภายใน 7 วันหลังเรือเข้าคาดการณ์ ($etaStr)"
        : "TBA";

    return Container(
      key: const ValueKey("Customs"),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Customs & Clearance",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "ประสานชิปปิ้ง เคลียร์ภาษีและอากรขาเข้า",
                        style: TextStyle(color: Color(0xFF86868B)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Total Clearance Cost",
                      style: TextStyle(fontSize: 12, color: Color(0xFF86868B)),
                    ),
                    Text(
                      "฿ ${totalCustoms.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 48, color: Color(0xFFF4F5F7)),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF3E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD08A2A).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD08A2A),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "กำหนดชำระเงินภาษี (Payment Due Date)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD08A2A),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      paymentDueDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1D1F),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildCustomsField(
                  "VAT (ภาษีมูลค่าเพิ่ม 7%)",
                  "0.00",
                  initialValue: data['vat'].toString(),
                  prefix: "฿ ",
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCustomsField(
                  "ภาษีนำเข้า (Import Tax)",
                  "0.00",
                  initialValue: data['tax'].toString(),
                  prefix: "฿ ",
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCustomsField(
                  "Shipping Fee (ค่าบริการชิปปิ้ง)",
                  "0.00",
                  initialValue: data['shipping_fee'].toString(),
                  prefix: "฿ ",
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: _buildButton(
              "✓ Confirm & Pay to Shipping",
              const Color(0xFF1D1D1F),
              Colors.white,
              onTap: () {
                setState(() {
                  shipment['steps']['Customs'] = true;
                  shipment['status'] = "Cleared Customs";
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✓ ตู้ผ่านพิธีการศุลกากรเรียบร้อยแล้ว!"),
                    backgroundColor: Color(0xFF4A9062),
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
  // HELPER WIDGETS & DIALOGS
  // =========================================================

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

  Widget _buildCustomsField(
    String label,
    String hint, {
    String? initialValue,
    String? prefix,
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
          initialValue: initialValue,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            filled: true,
            fillColor: const Color(0xFFF4F5F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
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
    String estimatedDate = "";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "สร้างรายการ Tracking ใหม่",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "เลขตู้ / Booking No.",
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => containerNo = val,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "ETA (วันคาดว่าจะถึง)",
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      filled: true,
                      fillColor: const Color(0xFFF4F5F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => estimatedDate = val,
                  ),
                ],
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
                onPressed: () {
                  if (containerNo.isEmpty) return;

                  String newId = "SHP-2605-0${_shipments.length + 1}";

                  setState(() {
                    _shipments.insert(0, {
                      "id": newId,
                      "container_no": containerNo,
                      "status": "Waiting Document",
                      "tracking": {
                        "doc_issue_date": "",
                        "actual_departure": "",
                        "estimated_arrival": estimatedDate,
                      },
                      "plan_file": "",
                      "customs": {"vat": 0.0, "tax": 0.0, "shipping_fee": 0.0},
                      "steps": {
                        "Tracking": false,
                        "Plan": false,
                        "Customs": false,
                      },
                    });
                    _selectedContainerId = newId;
                    _activeTab = "Tracking";
                  });
                  Navigator.pop(context);
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
