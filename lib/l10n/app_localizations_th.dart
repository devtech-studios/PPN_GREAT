// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class STh extends S {
  STh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'PPN GREAT';

  @override
  String get appSubtitle => 'Import Operation Platform';

  @override
  String get importOperation => 'Import Operation';

  @override
  String dashboardGreeting(String name) {
    return 'สวัสดี คุณ $name 👋';
  }

  @override
  String activeProjectsToday(int count) {
    return 'คุณมี $count โปรเจกต์ที่กำลังดำเนินการ';
  }

  @override
  String get loadingActiveProjects => 'กำลังโหลดข้อมูลโปรเจกต์...';

  @override
  String get searchHint => 'ค้นหาโปรเจกต์, ลูกค้า...';

  @override
  String get overviewSection => 'ภาพรวม';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get operations => 'การดำเนินงาน';

  @override
  String get projects => 'โปรเจกต์';

  @override
  String get samples => 'ตัวอย่างสินค้า';

  @override
  String get artwork => 'อาร์ตเวิร์ก';

  @override
  String get containers => 'ตู้คอนเทนเนอร์';

  @override
  String get delivery => 'จัดส่ง';

  @override
  String get contacts => 'ผู้ติดต่อ';

  @override
  String get customers => 'ลูกค้า';

  @override
  String get suppliers => 'ซัพพลายเออร์';

  @override
  String get financeAndInventory => 'การเงินและคลังสินค้า';

  @override
  String get finance => 'การเงิน';

  @override
  String get inventory => 'คลังสินค้า';

  @override
  String get superAdmin => 'ผู้ดูแลระบบ';

  @override
  String get settings => 'ตั้งค่า';

  @override
  String get ownerOnly => 'เจ้าของเท่านั้น';

  @override
  String get reports => 'รายงาน';

  @override
  String get logOut => 'ออกจากระบบ';

  @override
  String get logOutConfirm => 'คุณต้องการออกจากระบบใช่หรือไม่?';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get save => 'บันทึก';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get delete => 'ลบ';

  @override
  String get edit => 'แก้ไข';

  @override
  String get add => 'เพิ่ม';

  @override
  String get close => 'ปิด';

  @override
  String get back => 'กลับ';

  @override
  String get next => 'ถัดไป';

  @override
  String get search => 'ค้นหา';

  @override
  String get loading => 'กำลังโหลด...';

  @override
  String get noData => 'ไม่มีข้อมูล';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get success => 'สำเร็จ';

  @override
  String get error => 'ผิดพลาด';

  @override
  String get signIn => 'เข้าสู่ระบบ';

  @override
  String get emailUsername => 'Email / Username';

  @override
  String get password => 'Password';

  @override
  String get loginValidation => 'กรุณากรอก Email และ Password';

  @override
  String get loginFailed => 'เข้าสู่ระบบไม่สำเร็จ';

  @override
  String loginFailedWithCode(int statusCode) {
    return 'เข้าสู่ระบบไม่สำเร็จ ($statusCode)';
  }

  @override
  String get connectionError =>
      'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่อ';

  @override
  String get splashTitle => 'PPN GREAT';

  @override
  String get splashSubtitle => 'Import Operation Platform';

  @override
  String get activeProjectsHeader => 'โปรเจกต์ที่กำลังดำเนินการ';

  @override
  String get activeProjectsSubtitle => 'ติดตามสถานะคำสั่งซื้อทั้งหมดในระบบ';

  @override
  String filterAllActive(int count) {
    return 'ทั้งหมดที่ดำเนินการ ($count)';
  }

  @override
  String filterInquiry(int count) {
    return 'สอบถามราคา ($count)';
  }

  @override
  String filterArtwork(int count) {
    return 'อาร์ตเวิร์ก ($count)';
  }

  @override
  String filterDeposit(int count) {
    return 'มัดจำ ($count)';
  }

  @override
  String filterSample(int count) {
    return 'ตัวอย่างสินค้า ($count)';
  }

  @override
  String filterProduction(int count) {
    return 'กำลังผลิต ($count)';
  }

  @override
  String filterShipping(int count) {
    return 'กำลังขนส่ง ($count)';
  }

  @override
  String get cardBudget => 'งบประมาณ';

  @override
  String get cardQuantity => 'จำนวน';

  @override
  String get cardProgress => 'ความคืบหน้า';

  @override
  String get cardDue => 'กำหนดส่ง:';

  @override
  String get quickActionsHeader => 'ทางลัดดำเนินการ';

  @override
  String get btnCreateNewProject => 'สร้างโปรเจกต์ใหม่';

  @override
  String get btnManageSamples => 'จัดการตัวอย่างสินค้า';

  @override
  String get btnUploadArtwork => 'อัปโหลดอาร์ตเวิร์ก';

  @override
  String get btnGeneratePI => 'สร้างใบแจ้งหนี้ PI';

  @override
  String get btnBookContainer => 'จองตู้คอนเทนเนอร์';

  @override
  String get btnRecordPayment => 'บันทึกการรับเงิน';

  @override
  String get activityLogHeader => 'ประวัติการดำเนินงาน';

  @override
  String get cashflowHeader => 'ภาพรวมกระแสเงินสด';

  @override
  String get filterThisMonth => 'เดือนนี้';

  @override
  String get labelIncoming => 'รายรับ';

  @override
  String get labelOutgoing => 'รายจ่าย';

  @override
  String get labelNetBalance => 'เงินสดสุทธิ';

  @override
  String get upcomingScheduleHeader => 'กำหนดการเร็วๆ นี้';

  @override
  String get viewFullCalendar => 'ดูปฏิทินทั้งหมด →';

  @override
  String containerArriving(String code) {
    return 'ตู้สินค้าถึงท่าเรือ ($code)';
  }

  @override
  String customerMeeting(String customer) {
    return 'นัดพบลูกค้า ($customer)';
  }

  @override
  String sampleDelivery(String customer) {
    return 'จัดส่งตัวอย่างให้ ($customer)';
  }

  @override
  String get mobileGreeting => 'สวัสดีครับ คุณผู้บริหาร 👋';

  @override
  String get businessOverviewToday => 'ภาพรวมธุรกิจวันนี้';

  @override
  String get netCashBalance => 'Net Cash Balance (เงินสดในมือ)';

  @override
  String get arPending => 'AR (รอรับ)';

  @override
  String get apPending => 'AP (รอจ่าย)';

  @override
  String get profit => 'กำไร';

  @override
  String get deliveryLabel => 'จัดส่ง';

  @override
  String get stock => 'สต็อก';

  @override
  String get customerLabel => 'ลูกค้า';

  @override
  String get projectPipeline => 'สถานะโปรเจกต์ (Pipeline)';

  @override
  String get quoteStep => 'เสนอราคา';

  @override
  String get depositStep => 'มัดจำ';

  @override
  String get productionStep => 'ผลิต';

  @override
  String get shippingStep => 'จัดส่ง';

  @override
  String get avgLeadTime => 'Lead Time เฉลี่ย';

  @override
  String daysUnit(int count) {
    return '$count วัน';
  }

  @override
  String get pendingTaxClearance => 'รอเคลียร์ภาษี';

  @override
  String containersUnit(int count) {
    return '$count ตู้';
  }

  @override
  String get ownerPortal => 'Owner Portal';

  @override
  String get companyName => 'PPN GREAT CO., LTD.';

  @override
  String get financials => 'Financials';

  @override
  String get profitability => 'กำไรต่อโปรเจกต์';

  @override
  String get cashFlow => 'กระแสเงินสด & AR/AP';

  @override
  String get taxAnalytics => 'ภาษีนำเข้า & ชิปปิ้ง';

  @override
  String get deliveryStatus => 'สถานะการจัดส่ง';

  @override
  String get leadTimeAnalysis => 'วิเคราะห์ Lead Time';

  @override
  String get inventoryAging => 'สินค้าค้างสต็อก (Aging)';

  @override
  String get supplierRating => 'Ranking โรงงาน';

  @override
  String get focAnalytics => 'สถิติของเผื่อเคลม (FOC)';

  @override
  String get customerPortfolio => 'สัดส่วนลูกค้า';

  @override
  String get categoryDemand => 'กลุ่มสินค้าขายดี';

  @override
  String get logisticsEfficiency => 'ประสิทธิภาพขนส่ง';

  @override
  String get companyOverview => 'ภาพรวมบริษัท';

  @override
  String get netProfitByProject => 'กำไรสุทธิรายโปรเจกต์';

  @override
  String get cashFlowTitle => 'กระแสเงินสด';

  @override
  String get cashAvailable => 'เงินสดพร้อมใช้';

  @override
  String get arReceivable => 'AR (รับ)';

  @override
  String get apPayable => 'AP (จ่าย)';

  @override
  String get importTaxTitle => 'ภาษีนำเข้า & ชิปปิ้ง';

  @override
  String get vatAccumulated => 'VAT จ่ายสะสม';

  @override
  String get dutyAccumulated => 'อากรสะสม';

  @override
  String shipRound(String month) {
    return 'รอบเรือ: $month';
  }

  @override
  String get deliveryOverview => 'การจัดส่ง';

  @override
  String leadTimeAvgDays(int days) {
    return 'Lead Time เฉลี่ย: $days วัน';
  }

  @override
  String get leadTimeSubtitle => 'ระยะเวลาตั้งแต่เริ่มจนส่งของ';

  @override
  String get inventoryAgingTitle => 'สินค้าค้างสต็อก';

  @override
  String get supplierRankingTitle => 'Ranking ซัพพลายเออร์';

  @override
  String get focClaimStats => 'สถิติของเคลม (FOC)';

  @override
  String get customerRevenueShare => 'สัดส่วนรายได้ลูกค้า';

  @override
  String get bestSellingCategories => 'กลุ่มสินค้าขายดี';

  @override
  String get logisticsEfficiencyTitle => 'ประสิทธิภาพขนส่ง';

  @override
  String get errorSaving => 'เกิดข้อผิดพลาดในการบันทึก';

  @override
  String get fieldCompanyName => 'ชื่อบริษัท/ลูกค้า';

  @override
  String get fieldTaxId => 'เลขประจำตัวผู้เสียภาษี (Tax ID)';

  @override
  String get fieldBillingAddress => 'ที่อยู่ออกบิล';

  @override
  String get fieldPhone => 'เบอร์โทรศัพท์';

  @override
  String get fieldEmail => 'อีเมล';

  @override
  String get fieldStatus => 'สถานะ';

  @override
  String get fieldType => 'ประเภทลูกค้า';

  @override
  String get fieldBranch => 'สาขา';

  @override
  String get fieldIndustry => 'ประเภทธุรกิจ';

  @override
  String get fieldLeadSource => 'ช่องทางลูกค้า';

  @override
  String get errorDuplicate => 'มีข้อมูลนี้อยู่ในระบบแล้ว (ซ้ำซ้อน)';

  @override
  String get errorRequired => 'จำเป็นต้องกรอกข้อมูลช่องนี้';

  @override
  String get errorInvalidFormat => 'รูปแบบข้อมูลไม่ถูกต้อง';

  @override
  String get errorConnectionTimeout =>
      'หมดเวลารอการเชื่อมต่อกับเซิร์ฟเวอร์ (Connection Timeout)';

  @override
  String get errorSendTimeout => 'หมดเวลาส่งข้อมูล (Send Timeout)';

  @override
  String get errorReceiveTimeout =>
      'หมดเวลารับข้อมูลจากเซิร์ฟเวอร์ (Receive Timeout)';

  @override
  String errorBadResponse(int statusCode) {
    return 'เซิร์ฟเวอร์ตอบกลับด้วยข้อผิดพลาด (รหัส $statusCode)';
  }

  @override
  String get errorCancelled => 'การเชื่อมต่อถูกยกเลิก';

  @override
  String get errorConnection =>
      'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ตหรือเซิร์ฟเวอร์ API';

  @override
  String get errorGenericConnection =>
      'เกิดข้อผิดพลาดในการเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get selectProject => 'เลือกโปรเจกต์';

  @override
  String get searchSupplier => 'ค้นหาชื่อโรงงาน...';

  @override
  String get savePaymentSuccess => 'บันทึกการโอนเงินออกให้ซัพพลายเออร์สำเร็จ';

  @override
  String get addBillSuccess => 'เพิ่มบิลค่าใช้จ่ายใหม่สำเร็จ';

  @override
  String get createBillForFactory => 'สร้างบิลค่าใช้จ่ายใหม่สำหรับโรงงานนี้';

  @override
  String get unnamedProduct => 'สินค้าไม่ระบุชื่อ';

  @override
  String uploadFileSuccess(String fileType) {
    return 'อัปโหลดไฟล์ $fileType สำเร็จ';
  }

  @override
  String get quotesTab => 'ขอราคา (Quotes)';

  @override
  String get samplesTab => 'ขอตัวอย่าง (Samples)';

  @override
  String get paymentsTab => 'รอบบิลจ่ายเงิน (AP)';

  @override
  String get quoteListDesc => 'รายการสินค้าที่ต้องการให้โรงงานนี้ประเมินราคา';

  @override
  String get noQuotes => 'ยังไม่มีรายการขอราคาจากโรงงานนี้';

  @override
  String get unitCost => 'Unit Cost (ทุน)';

  @override
  String get sampleListDesc => 'รายการตัวอย่างสินค้าที่ร้องขอไปทางโรงงาน';

  @override
  String get noSamples => 'ยังไม่มีรายการขอตัวอย่างจากโรงงานนี้';

  @override
  String get editSpecCost => 'แก้ไขสเปก/ค่าใช้จ่าย';

  @override
  String get monthlyAP => 'Monthly Accounts Payable (ตัดจ่ายซัพพลายเออร์)';

  @override
  String get monthlyAPDesc =>
      'รวบรวมบิล Deposit และ Balance เพื่อทำเรื่องจ่ายออกทีเดียวช่วงสิ้นเดือน';

  @override
  String get noPendingBills => 'ยอดเยี่ยม! ไม่มีรอบบิลค้างชำระสำหรับโรงงานนี้';

  @override
  String get postponeBills => 'เลื่อนบิลไปเดือนหน้า';

  @override
  String get postponeSuccess => 'เลื่อนรอบบิลที่เลือกสำเร็จ (Local Mock)';

  @override
  String get languageSwitch => 'เปลี่ยนภาษา';

  @override
  String get languageThai => 'ไทย';

  @override
  String get languageEnglish => 'English';

  @override
  String get activeProjects => 'Active Projects';

  @override
  String get cashflowOverview => 'Cashflow Overview';

  @override
  String get upcomingSchedule => 'Upcoming Schedule';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get createNewProject => 'สร้างโปรเจกต์ใหม่';

  @override
  String get recordPayment => 'บันทึกการรับเงิน';

  @override
  String get newCustomer => 'เพิ่มลูกค้าใหม่';

  @override
  String get viewAllProjects => 'ดูโปรเจกต์ทั้งหมด';
}
