import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/auth/auth_service.dart';
import '../../modules/auth/login_screen.dart';
import '../../modules/containers/containers_screen.dart';
import '../../modules/dashboard/dashboard_screen.dart';
import '../../modules/customers/create_customer_screen.dart';
import '../../modules/inventory/inventory_screen.dart';
import '../../modules/orders/project_list_screen.dart';
import '../../modules/orders/samples_screen.dart';
import '../../modules/suppliers/suppliers_screen.dart';
import '../../modules/finance/generate_pi_screen.dart';
import '../../modules/delivery/delivery_screen.dart';
import '../../modules/reports/reports_screen.dart';
import '../../modules/orders/upload_design_screen.dart';
import '../widgets/language_switch_button.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Scaffold(
      body: Row(
        children: [
          // ==========================================
          // Left Sidebar
          // ==========================================
          Container(
            width: 260,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.appTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.importOperation,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF86868B),
                        ),
                      ),
                    ],
                  ),
                ),

                // === ส่วนเมนูทั้งหมด (Scrollable แบบยืดหยุ่น) ===
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. OVERVIEW
                            _buildSidebarGroupTitle(s.overviewSection.toUpperCase()),
                            _buildMenuItem(
                              0,
                              s.dashboard,
                              Icons.grid_view_rounded,
                            ),

                            // 2. OPERATIONS
                            _buildSidebarGroupTitle(s.operations.toUpperCase()),
                            _buildMenuItem(
                              1,
                              "${s.projects} (12)",
                              Icons.folder_open_rounded,
                            ),
                            _buildMenuItem(
                              10, // Samples กดแล้วไปหน้า UploadDesignScreen
                              s.samples,
                              Icons.science_outlined,
                            ),
                            _buildMenuItem(
                              11, // 🌟ไปหน้า UploadDesignScreen (หน้า Artwork เดิม)
                              s.artwork,
                              Icons.brush_outlined,
                            ),
                            _buildMenuItem(
                              4,
                              s.containers,
                              Icons.directions_boat_outlined,
                            ),
                            _buildMenuItem(
                              7,
                              s.delivery,
                              Icons.local_shipping_outlined,
                            ),

                            // 3. CONTACTS
                            _buildSidebarGroupTitle(s.contacts.toUpperCase()),
                            _buildMenuItem(
                              2,
                              s.customers,
                              Icons.people_outline,
                            ),
                            _buildMenuItem(
                              3,
                              s.suppliers,
                              Icons.business_outlined,
                            ),

                            // 4. FINANCE & INVENTORY
                            _buildSidebarGroupTitle(s.financeAndInventory.toUpperCase()),
                            _buildMenuItem(
                              5,
                              s.finance,
                              Icons.account_balance_wallet_outlined,
                            ),
                            _buildMenuItem(
                              6,
                              s.inventory,
                              Icons.inventory_2_outlined,
                            ),

                            // Spacer จะทำหน้าที่ดันส่วนด้านล่างให้ไปติดขอบจอด้านล่างเสมอ
                            const Spacer(),

                            // 5. SUPER ADMIN (ตั้งค่าระบบ)
                            _buildSidebarGroupTitle(s.superAdmin.toUpperCase()),
                            _buildMenuItem(
                              9,
                              s.settings,
                              Icons.settings_outlined,
                            ),

                            // 6. OWNER (เจ้าของ)
                            _buildSidebarGroupTitle(s.ownerOnly.toUpperCase()),
                            _buildMenuItem(
                              8,
                              s.reports,
                              Icons.bar_chart_rounded,
                            ),

                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: LanguageSwitchButton(),
                            ),
                            const SizedBox(height: 8),
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
          // Main Content Area
          // ==========================================
          const Expanded(child: DashboardScreen()),
        ],
      ),
    );
  }

  // สร้าง Widget หัวข้อกลุ่มเมนู
  Widget _buildSidebarGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFFB4B4B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // สร้าง Widget ปุ่ม Logout
  Widget _buildLogoutButton(BuildContext context) {
    final s = S.of(context)!;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              s.logOut,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(s.logOutConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  s.cancel,
                  style: const TextStyle(color: Color(0xFF86868B)),
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
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97781),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  s.logOut,
                  style: const TextStyle(
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
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFD97781), size: 20),
            const SizedBox(width: 16),
            Text(
              s.logOut,
              style: const TextStyle(
                color: Color(0xFFD97781),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างเมนู
  Widget _buildMenuItem(int index, String title, IconData icon) {
    final isSelected = index == 0; // Index 0 คือ Dashboard

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
          // 👇 10: Samples ไปหน้า UploadDesignScreen
          case 10:
            destination = const SamplesScreen();
            break;
          case 11: // 🌟 Artwork
            destination = const UploadDesignScreen();
            break;
          case 0:
            return;
          default:
            destination = Scaffold(
              backgroundColor: const Color(0xFFF7F9FC),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$title Page",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Back to Dashboard"),
                    ),
                  ],
                ),
              ),
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
          color: isSelected
              ? const Color(0xFF2563EB).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: const Color(0xFF2563EB).withOpacity(0.2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF86868B),
              size: isSelected ? 22 : 20,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF86868B),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: isSelected ? 15 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
