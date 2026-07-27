import 'package:flutter/material.dart';

class BranchOption {
  final int id;
  final int shopId;
  final String code;
  final String name;

  const BranchOption({
    required this.id,
    required this.shopId,
    required this.code,
    required this.name,
  });
}

class BranchProvider extends ChangeNotifier {
  static final BranchProvider instance = BranchProvider._internal();
  BranchProvider._internal();

  int _selectedShopId = 1;
  int _selectedBranchId = 1;

  final List<BranchOption> _availableBranches = const [
    BranchOption(id: 1, shopId: 1, code: "HQ-BANGKOK", name: "สำนักงานใหญ่ (Bangkok HQ)"),
    BranchOption(id: 101, shopId: 1, code: "BANGSAEN", name: "สาขาบางแสน (Bangsaen Branch)"),
    BranchOption(id: 102, shopId: 1, code: "PATTAYA", name: "สาขาพัทยา (Pattaya Branch)"),
  ];

  int get selectedShopId => _selectedShopId;
  int get selectedBranchId => _selectedBranchId;
  List<BranchOption> get availableBranches => _availableBranches;

  BranchOption get activeBranch => _availableBranches.firstWhere(
        (b) => b.id == _selectedBranchId,
        orElse: () => _availableBranches.first,
      );

  void selectBranch(int branchId) {
    if (_selectedBranchId == branchId) return;
    _selectedBranchId = branchId;
    notifyListeners();
  }
}

final branchProvider = BranchProvider.instance;
