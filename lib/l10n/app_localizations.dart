import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In th, this message translates to:
  /// **'PPN GREAT'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In th, this message translates to:
  /// **'Import Operation Platform'**
  String get appSubtitle;

  /// No description provided for @importOperation.
  ///
  /// In th, this message translates to:
  /// **'Import Operation'**
  String get importOperation;

  /// No description provided for @dashboardGreeting.
  ///
  /// In th, this message translates to:
  /// **'สวัสดี คุณ {name} 👋'**
  String dashboardGreeting(String name);

  /// No description provided for @activeProjectsToday.
  ///
  /// In th, this message translates to:
  /// **'คุณมี {count} โปรเจกต์ที่กำลังดำเนินการ'**
  String activeProjectsToday(int count);

  /// No description provided for @loadingActiveProjects.
  ///
  /// In th, this message translates to:
  /// **'กำลังโหลดข้อมูลโปรเจกต์...'**
  String get loadingActiveProjects;

  /// No description provided for @searchHint.
  ///
  /// In th, this message translates to:
  /// **'ค้นหาโปรเจกต์, ลูกค้า...'**
  String get searchHint;

  /// No description provided for @overviewSection.
  ///
  /// In th, this message translates to:
  /// **'ภาพรวม'**
  String get overviewSection;

  /// No description provided for @dashboard.
  ///
  /// In th, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @operations.
  ///
  /// In th, this message translates to:
  /// **'การดำเนินงาน'**
  String get operations;

  /// No description provided for @projects.
  ///
  /// In th, this message translates to:
  /// **'โปรเจกต์'**
  String get projects;

  /// No description provided for @samples.
  ///
  /// In th, this message translates to:
  /// **'ตัวอย่างสินค้า'**
  String get samples;

  /// No description provided for @artwork.
  ///
  /// In th, this message translates to:
  /// **'อาร์ตเวิร์ก'**
  String get artwork;

  /// No description provided for @containers.
  ///
  /// In th, this message translates to:
  /// **'ตู้คอนเทนเนอร์'**
  String get containers;

  /// No description provided for @delivery.
  ///
  /// In th, this message translates to:
  /// **'จัดส่ง'**
  String get delivery;

  /// No description provided for @contacts.
  ///
  /// In th, this message translates to:
  /// **'ผู้ติดต่อ'**
  String get contacts;

  /// No description provided for @customers.
  ///
  /// In th, this message translates to:
  /// **'ลูกค้า'**
  String get customers;

  /// No description provided for @suppliers.
  ///
  /// In th, this message translates to:
  /// **'ซัพพลายเออร์'**
  String get suppliers;

  /// No description provided for @financeAndInventory.
  ///
  /// In th, this message translates to:
  /// **'การเงินและคลังสินค้า'**
  String get financeAndInventory;

  /// No description provided for @finance.
  ///
  /// In th, this message translates to:
  /// **'การเงิน'**
  String get finance;

  /// No description provided for @inventory.
  ///
  /// In th, this message translates to:
  /// **'คลังสินค้า'**
  String get inventory;

  /// No description provided for @superAdmin.
  ///
  /// In th, this message translates to:
  /// **'ผู้ดูแลระบบ'**
  String get superAdmin;

  /// No description provided for @settings.
  ///
  /// In th, this message translates to:
  /// **'ตั้งค่า'**
  String get settings;

  /// No description provided for @ownerOnly.
  ///
  /// In th, this message translates to:
  /// **'เจ้าของเท่านั้น'**
  String get ownerOnly;

  /// No description provided for @reports.
  ///
  /// In th, this message translates to:
  /// **'รายงาน'**
  String get reports;

  /// No description provided for @logOut.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบ'**
  String get logOut;

  /// No description provided for @logOutConfirm.
  ///
  /// In th, this message translates to:
  /// **'คุณต้องการออกจากระบบใช่หรือไม่?'**
  String get logOutConfirm;

  /// No description provided for @cancel.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิก'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In th, this message translates to:
  /// **'บันทึก'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In th, this message translates to:
  /// **'ยืนยัน'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In th, this message translates to:
  /// **'ลบ'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In th, this message translates to:
  /// **'แก้ไข'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In th, this message translates to:
  /// **'เพิ่ม'**
  String get add;

  /// No description provided for @close.
  ///
  /// In th, this message translates to:
  /// **'ปิด'**
  String get close;

  /// No description provided for @back.
  ///
  /// In th, this message translates to:
  /// **'กลับ'**
  String get back;

  /// No description provided for @next.
  ///
  /// In th, this message translates to:
  /// **'ถัดไป'**
  String get next;

  /// No description provided for @search.
  ///
  /// In th, this message translates to:
  /// **'ค้นหา'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In th, this message translates to:
  /// **'กำลังโหลด...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีข้อมูล'**
  String get noData;

  /// No description provided for @retry.
  ///
  /// In th, this message translates to:
  /// **'ลองใหม่'**
  String get retry;

  /// No description provided for @success.
  ///
  /// In th, this message translates to:
  /// **'สำเร็จ'**
  String get success;

  /// No description provided for @error.
  ///
  /// In th, this message translates to:
  /// **'ผิดพลาด'**
  String get error;

  /// No description provided for @signIn.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบ'**
  String get signIn;

  /// No description provided for @emailUsername.
  ///
  /// In th, this message translates to:
  /// **'Email / Username'**
  String get emailUsername;

  /// No description provided for @password.
  ///
  /// In th, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginValidation.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอก Email และ Password'**
  String get loginValidation;

  /// No description provided for @loginFailed.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบไม่สำเร็จ'**
  String get loginFailed;

  /// No description provided for @loginFailedWithCode.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบไม่สำเร็จ ({statusCode})'**
  String loginFailedWithCode(int statusCode);

  /// No description provided for @connectionError.
  ///
  /// In th, this message translates to:
  /// **'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่อ'**
  String get connectionError;

  /// No description provided for @splashTitle.
  ///
  /// In th, this message translates to:
  /// **'PPN GREAT'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In th, this message translates to:
  /// **'Import Operation Platform'**
  String get splashSubtitle;

  /// No description provided for @activeProjectsHeader.
  ///
  /// In th, this message translates to:
  /// **'โปรเจกต์ที่กำลังดำเนินการ'**
  String get activeProjectsHeader;

  /// No description provided for @activeProjectsSubtitle.
  ///
  /// In th, this message translates to:
  /// **'ติดตามสถานะคำสั่งซื้อทั้งหมดในระบบ'**
  String get activeProjectsSubtitle;

  /// No description provided for @filterAllActive.
  ///
  /// In th, this message translates to:
  /// **'ทั้งหมดที่ดำเนินการ ({count})'**
  String filterAllActive(int count);

  /// No description provided for @filterInquiry.
  ///
  /// In th, this message translates to:
  /// **'สอบถามราคา ({count})'**
  String filterInquiry(int count);

  /// No description provided for @filterArtwork.
  ///
  /// In th, this message translates to:
  /// **'อาร์ตเวิร์ก ({count})'**
  String filterArtwork(int count);

  /// No description provided for @filterDeposit.
  ///
  /// In th, this message translates to:
  /// **'มัดจำ ({count})'**
  String filterDeposit(int count);

  /// No description provided for @filterSample.
  ///
  /// In th, this message translates to:
  /// **'ตัวอย่างสินค้า ({count})'**
  String filterSample(int count);

  /// No description provided for @filterProduction.
  ///
  /// In th, this message translates to:
  /// **'กำลังผลิต ({count})'**
  String filterProduction(int count);

  /// No description provided for @filterShipping.
  ///
  /// In th, this message translates to:
  /// **'กำลังขนส่ง ({count})'**
  String filterShipping(int count);

  /// No description provided for @cardBudget.
  ///
  /// In th, this message translates to:
  /// **'งบประมาณ'**
  String get cardBudget;

  /// No description provided for @cardQuantity.
  ///
  /// In th, this message translates to:
  /// **'จำนวน'**
  String get cardQuantity;

  /// No description provided for @cardProgress.
  ///
  /// In th, this message translates to:
  /// **'ความคืบหน้า'**
  String get cardProgress;

  /// No description provided for @cardDue.
  ///
  /// In th, this message translates to:
  /// **'กำหนดส่ง:'**
  String get cardDue;

  /// No description provided for @quickActionsHeader.
  ///
  /// In th, this message translates to:
  /// **'ทางลัดดำเนินการ'**
  String get quickActionsHeader;

  /// No description provided for @btnCreateNewProject.
  ///
  /// In th, this message translates to:
  /// **'สร้างโปรเจกต์ใหม่'**
  String get btnCreateNewProject;

  /// No description provided for @btnManageSamples.
  ///
  /// In th, this message translates to:
  /// **'จัดการตัวอย่างสินค้า'**
  String get btnManageSamples;

  /// No description provided for @btnUploadArtwork.
  ///
  /// In th, this message translates to:
  /// **'อัปโหลดอาร์ตเวิร์ก'**
  String get btnUploadArtwork;

  /// No description provided for @btnGeneratePI.
  ///
  /// In th, this message translates to:
  /// **'สร้างใบแจ้งหนี้ PI'**
  String get btnGeneratePI;

  /// No description provided for @btnBookContainer.
  ///
  /// In th, this message translates to:
  /// **'จองตู้คอนเทนเนอร์'**
  String get btnBookContainer;

  /// No description provided for @btnRecordPayment.
  ///
  /// In th, this message translates to:
  /// **'บันทึกการรับเงิน'**
  String get btnRecordPayment;

  /// No description provided for @activityLogHeader.
  ///
  /// In th, this message translates to:
  /// **'ประวัติการดำเนินงาน'**
  String get activityLogHeader;

  /// No description provided for @cashflowHeader.
  ///
  /// In th, this message translates to:
  /// **'ภาพรวมกระแสเงินสด'**
  String get cashflowHeader;

  /// No description provided for @filterThisMonth.
  ///
  /// In th, this message translates to:
  /// **'เดือนนี้'**
  String get filterThisMonth;

  /// No description provided for @labelIncoming.
  ///
  /// In th, this message translates to:
  /// **'รายรับ'**
  String get labelIncoming;

  /// No description provided for @labelOutgoing.
  ///
  /// In th, this message translates to:
  /// **'รายจ่าย'**
  String get labelOutgoing;

  /// No description provided for @labelNetBalance.
  ///
  /// In th, this message translates to:
  /// **'เงินสดสุทธิ'**
  String get labelNetBalance;

  /// No description provided for @upcomingScheduleHeader.
  ///
  /// In th, this message translates to:
  /// **'กำหนดการเร็วๆ นี้'**
  String get upcomingScheduleHeader;

  /// No description provided for @viewFullCalendar.
  ///
  /// In th, this message translates to:
  /// **'ดูปฏิทินทั้งหมด →'**
  String get viewFullCalendar;

  /// No description provided for @containerArriving.
  ///
  /// In th, this message translates to:
  /// **'ตู้สินค้าถึงท่าเรือ ({code})'**
  String containerArriving(String code);

  /// No description provided for @customerMeeting.
  ///
  /// In th, this message translates to:
  /// **'นัดพบลูกค้า ({customer})'**
  String customerMeeting(String customer);

  /// No description provided for @sampleDelivery.
  ///
  /// In th, this message translates to:
  /// **'จัดส่งตัวอย่างให้ ({customer})'**
  String sampleDelivery(String customer);

  /// No description provided for @mobileGreeting.
  ///
  /// In th, this message translates to:
  /// **'สวัสดีครับ คุณผู้บริหาร 👋'**
  String get mobileGreeting;

  /// No description provided for @businessOverviewToday.
  ///
  /// In th, this message translates to:
  /// **'ภาพรวมธุรกิจวันนี้'**
  String get businessOverviewToday;

  /// No description provided for @netCashBalance.
  ///
  /// In th, this message translates to:
  /// **'Net Cash Balance (เงินสดในมือ)'**
  String get netCashBalance;

  /// No description provided for @arPending.
  ///
  /// In th, this message translates to:
  /// **'AR (รอรับ)'**
  String get arPending;

  /// No description provided for @apPending.
  ///
  /// In th, this message translates to:
  /// **'AP (รอจ่าย)'**
  String get apPending;

  /// No description provided for @profit.
  ///
  /// In th, this message translates to:
  /// **'กำไร'**
  String get profit;

  /// No description provided for @deliveryLabel.
  ///
  /// In th, this message translates to:
  /// **'จัดส่ง'**
  String get deliveryLabel;

  /// No description provided for @stock.
  ///
  /// In th, this message translates to:
  /// **'สต็อก'**
  String get stock;

  /// No description provided for @customerLabel.
  ///
  /// In th, this message translates to:
  /// **'ลูกค้า'**
  String get customerLabel;

  /// No description provided for @projectPipeline.
  ///
  /// In th, this message translates to:
  /// **'สถานะโปรเจกต์ (Pipeline)'**
  String get projectPipeline;

  /// No description provided for @quoteStep.
  ///
  /// In th, this message translates to:
  /// **'เสนอราคา'**
  String get quoteStep;

  /// No description provided for @depositStep.
  ///
  /// In th, this message translates to:
  /// **'มัดจำ'**
  String get depositStep;

  /// No description provided for @productionStep.
  ///
  /// In th, this message translates to:
  /// **'ผลิต'**
  String get productionStep;

  /// No description provided for @shippingStep.
  ///
  /// In th, this message translates to:
  /// **'จัดส่ง'**
  String get shippingStep;

  /// No description provided for @avgLeadTime.
  ///
  /// In th, this message translates to:
  /// **'Lead Time เฉลี่ย'**
  String get avgLeadTime;

  /// No description provided for @daysUnit.
  ///
  /// In th, this message translates to:
  /// **'{count} วัน'**
  String daysUnit(int count);

  /// No description provided for @pendingTaxClearance.
  ///
  /// In th, this message translates to:
  /// **'รอเคลียร์ภาษี'**
  String get pendingTaxClearance;

  /// No description provided for @containersUnit.
  ///
  /// In th, this message translates to:
  /// **'{count} ตู้'**
  String containersUnit(int count);

  /// No description provided for @ownerPortal.
  ///
  /// In th, this message translates to:
  /// **'Owner Portal'**
  String get ownerPortal;

  /// No description provided for @companyName.
  ///
  /// In th, this message translates to:
  /// **'PPN GREAT CO., LTD.'**
  String get companyName;

  /// No description provided for @financials.
  ///
  /// In th, this message translates to:
  /// **'Financials'**
  String get financials;

  /// No description provided for @profitability.
  ///
  /// In th, this message translates to:
  /// **'กำไรต่อโปรเจกต์'**
  String get profitability;

  /// No description provided for @cashFlow.
  ///
  /// In th, this message translates to:
  /// **'กระแสเงินสด & AR/AP'**
  String get cashFlow;

  /// No description provided for @taxAnalytics.
  ///
  /// In th, this message translates to:
  /// **'ภาษีนำเข้า & ชิปปิ้ง'**
  String get taxAnalytics;

  /// No description provided for @deliveryStatus.
  ///
  /// In th, this message translates to:
  /// **'สถานะการจัดส่ง'**
  String get deliveryStatus;

  /// No description provided for @leadTimeAnalysis.
  ///
  /// In th, this message translates to:
  /// **'วิเคราะห์ Lead Time'**
  String get leadTimeAnalysis;

  /// No description provided for @inventoryAging.
  ///
  /// In th, this message translates to:
  /// **'สินค้าค้างสต็อก (Aging)'**
  String get inventoryAging;

  /// No description provided for @supplierRating.
  ///
  /// In th, this message translates to:
  /// **'Ranking โรงงาน'**
  String get supplierRating;

  /// No description provided for @focAnalytics.
  ///
  /// In th, this message translates to:
  /// **'สถิติของเผื่อเคลม (FOC)'**
  String get focAnalytics;

  /// No description provided for @customerPortfolio.
  ///
  /// In th, this message translates to:
  /// **'สัดส่วนลูกค้า'**
  String get customerPortfolio;

  /// No description provided for @categoryDemand.
  ///
  /// In th, this message translates to:
  /// **'กลุ่มสินค้าขายดี'**
  String get categoryDemand;

  /// No description provided for @logisticsEfficiency.
  ///
  /// In th, this message translates to:
  /// **'ประสิทธิภาพขนส่ง'**
  String get logisticsEfficiency;

  /// No description provided for @companyOverview.
  ///
  /// In th, this message translates to:
  /// **'ภาพรวมบริษัท'**
  String get companyOverview;

  /// No description provided for @netProfitByProject.
  ///
  /// In th, this message translates to:
  /// **'กำไรสุทธิรายโปรเจกต์'**
  String get netProfitByProject;

  /// No description provided for @cashFlowTitle.
  ///
  /// In th, this message translates to:
  /// **'กระแสเงินสด'**
  String get cashFlowTitle;

  /// No description provided for @cashAvailable.
  ///
  /// In th, this message translates to:
  /// **'เงินสดพร้อมใช้'**
  String get cashAvailable;

  /// No description provided for @arReceivable.
  ///
  /// In th, this message translates to:
  /// **'AR (รับ)'**
  String get arReceivable;

  /// No description provided for @apPayable.
  ///
  /// In th, this message translates to:
  /// **'AP (จ่าย)'**
  String get apPayable;

  /// No description provided for @importTaxTitle.
  ///
  /// In th, this message translates to:
  /// **'ภาษีนำเข้า & ชิปปิ้ง'**
  String get importTaxTitle;

  /// No description provided for @vatAccumulated.
  ///
  /// In th, this message translates to:
  /// **'VAT จ่ายสะสม'**
  String get vatAccumulated;

  /// No description provided for @dutyAccumulated.
  ///
  /// In th, this message translates to:
  /// **'อากรสะสม'**
  String get dutyAccumulated;

  /// No description provided for @shipRound.
  ///
  /// In th, this message translates to:
  /// **'รอบเรือ: {month}'**
  String shipRound(String month);

  /// No description provided for @deliveryOverview.
  ///
  /// In th, this message translates to:
  /// **'การจัดส่ง'**
  String get deliveryOverview;

  /// No description provided for @leadTimeAvgDays.
  ///
  /// In th, this message translates to:
  /// **'Lead Time เฉลี่ย: {days} วัน'**
  String leadTimeAvgDays(int days);

  /// No description provided for @leadTimeSubtitle.
  ///
  /// In th, this message translates to:
  /// **'ระยะเวลาตั้งแต่เริ่มจนส่งของ'**
  String get leadTimeSubtitle;

  /// No description provided for @inventoryAgingTitle.
  ///
  /// In th, this message translates to:
  /// **'สินค้าค้างสต็อก'**
  String get inventoryAgingTitle;

  /// No description provided for @supplierRankingTitle.
  ///
  /// In th, this message translates to:
  /// **'Ranking ซัพพลายเออร์'**
  String get supplierRankingTitle;

  /// No description provided for @focClaimStats.
  ///
  /// In th, this message translates to:
  /// **'สถิติของเคลม (FOC)'**
  String get focClaimStats;

  /// No description provided for @customerRevenueShare.
  ///
  /// In th, this message translates to:
  /// **'สัดส่วนรายได้ลูกค้า'**
  String get customerRevenueShare;

  /// No description provided for @bestSellingCategories.
  ///
  /// In th, this message translates to:
  /// **'กลุ่มสินค้าขายดี'**
  String get bestSellingCategories;

  /// No description provided for @logisticsEfficiencyTitle.
  ///
  /// In th, this message translates to:
  /// **'ประสิทธิภาพขนส่ง'**
  String get logisticsEfficiencyTitle;

  /// No description provided for @errorSaving.
  ///
  /// In th, this message translates to:
  /// **'เกิดข้อผิดพลาดในการบันทึก'**
  String get errorSaving;

  /// No description provided for @fieldCompanyName.
  ///
  /// In th, this message translates to:
  /// **'ชื่อบริษัท/ลูกค้า'**
  String get fieldCompanyName;

  /// No description provided for @fieldTaxId.
  ///
  /// In th, this message translates to:
  /// **'เลขประจำตัวผู้เสียภาษี (Tax ID)'**
  String get fieldTaxId;

  /// No description provided for @fieldBillingAddress.
  ///
  /// In th, this message translates to:
  /// **'ที่อยู่ออกบิล'**
  String get fieldBillingAddress;

  /// No description provided for @fieldPhone.
  ///
  /// In th, this message translates to:
  /// **'เบอร์โทรศัพท์'**
  String get fieldPhone;

  /// No description provided for @fieldEmail.
  ///
  /// In th, this message translates to:
  /// **'อีเมล'**
  String get fieldEmail;

  /// No description provided for @fieldStatus.
  ///
  /// In th, this message translates to:
  /// **'สถานะ'**
  String get fieldStatus;

  /// No description provided for @fieldType.
  ///
  /// In th, this message translates to:
  /// **'ประเภทลูกค้า'**
  String get fieldType;

  /// No description provided for @fieldBranch.
  ///
  /// In th, this message translates to:
  /// **'สาขา'**
  String get fieldBranch;

  /// No description provided for @fieldIndustry.
  ///
  /// In th, this message translates to:
  /// **'ประเภทธุรกิจ'**
  String get fieldIndustry;

  /// No description provided for @fieldLeadSource.
  ///
  /// In th, this message translates to:
  /// **'ช่องทางลูกค้า'**
  String get fieldLeadSource;

  /// No description provided for @errorDuplicate.
  ///
  /// In th, this message translates to:
  /// **'มีข้อมูลนี้อยู่ในระบบแล้ว (ซ้ำซ้อน)'**
  String get errorDuplicate;

  /// No description provided for @errorRequired.
  ///
  /// In th, this message translates to:
  /// **'จำเป็นต้องกรอกข้อมูลช่องนี้'**
  String get errorRequired;

  /// No description provided for @errorInvalidFormat.
  ///
  /// In th, this message translates to:
  /// **'รูปแบบข้อมูลไม่ถูกต้อง'**
  String get errorInvalidFormat;

  /// No description provided for @errorConnectionTimeout.
  ///
  /// In th, this message translates to:
  /// **'หมดเวลารอการเชื่อมต่อกับเซิร์ฟเวอร์ (Connection Timeout)'**
  String get errorConnectionTimeout;

  /// No description provided for @errorSendTimeout.
  ///
  /// In th, this message translates to:
  /// **'หมดเวลาส่งข้อมูล (Send Timeout)'**
  String get errorSendTimeout;

  /// No description provided for @errorReceiveTimeout.
  ///
  /// In th, this message translates to:
  /// **'หมดเวลารับข้อมูลจากเซิร์ฟเวอร์ (Receive Timeout)'**
  String get errorReceiveTimeout;

  /// No description provided for @errorBadResponse.
  ///
  /// In th, this message translates to:
  /// **'เซิร์ฟเวอร์ตอบกลับด้วยข้อผิดพลาด (รหัส {statusCode})'**
  String errorBadResponse(int statusCode);

  /// No description provided for @errorCancelled.
  ///
  /// In th, this message translates to:
  /// **'การเชื่อมต่อถูกยกเลิก'**
  String get errorCancelled;

  /// No description provided for @errorConnection.
  ///
  /// In th, this message translates to:
  /// **'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ตหรือเซิร์ฟเวอร์ API'**
  String get errorConnection;

  /// No description provided for @errorGenericConnection.
  ///
  /// In th, this message translates to:
  /// **'เกิดข้อผิดพลาดในการเชื่อมต่ออินเทอร์เน็ต'**
  String get errorGenericConnection;

  /// No description provided for @selectProject.
  ///
  /// In th, this message translates to:
  /// **'เลือกโปรเจกต์'**
  String get selectProject;

  /// No description provided for @searchSupplier.
  ///
  /// In th, this message translates to:
  /// **'ค้นหาชื่อโรงงาน...'**
  String get searchSupplier;

  /// No description provided for @savePaymentSuccess.
  ///
  /// In th, this message translates to:
  /// **'บันทึกการโอนเงินออกให้ซัพพลายเออร์สำเร็จ'**
  String get savePaymentSuccess;

  /// No description provided for @addBillSuccess.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มบิลค่าใช้จ่ายใหม่สำเร็จ'**
  String get addBillSuccess;

  /// No description provided for @createBillForFactory.
  ///
  /// In th, this message translates to:
  /// **'สร้างบิลค่าใช้จ่ายใหม่สำหรับโรงงานนี้'**
  String get createBillForFactory;

  /// No description provided for @unnamedProduct.
  ///
  /// In th, this message translates to:
  /// **'สินค้าไม่ระบุชื่อ'**
  String get unnamedProduct;

  /// No description provided for @uploadFileSuccess.
  ///
  /// In th, this message translates to:
  /// **'อัปโหลดไฟล์ {fileType} สำเร็จ'**
  String uploadFileSuccess(String fileType);

  /// No description provided for @quotesTab.
  ///
  /// In th, this message translates to:
  /// **'ขอราคา (Quotes)'**
  String get quotesTab;

  /// No description provided for @samplesTab.
  ///
  /// In th, this message translates to:
  /// **'ขอตัวอย่าง (Samples)'**
  String get samplesTab;

  /// No description provided for @paymentsTab.
  ///
  /// In th, this message translates to:
  /// **'รอบบิลจ่ายเงิน (AP)'**
  String get paymentsTab;

  /// No description provided for @quoteListDesc.
  ///
  /// In th, this message translates to:
  /// **'รายการสินค้าที่ต้องการให้โรงงานนี้ประเมินราคา'**
  String get quoteListDesc;

  /// No description provided for @noQuotes.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรายการขอราคาจากโรงงานนี้'**
  String get noQuotes;

  /// No description provided for @unitCost.
  ///
  /// In th, this message translates to:
  /// **'Unit Cost (ทุน)'**
  String get unitCost;

  /// No description provided for @sampleListDesc.
  ///
  /// In th, this message translates to:
  /// **'รายการตัวอย่างสินค้าที่ร้องขอไปทางโรงงาน'**
  String get sampleListDesc;

  /// No description provided for @noSamples.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีรายการขอตัวอย่างจากโรงงานนี้'**
  String get noSamples;

  /// No description provided for @editSpecCost.
  ///
  /// In th, this message translates to:
  /// **'แก้ไขสเปก/ค่าใช้จ่าย'**
  String get editSpecCost;

  /// No description provided for @monthlyAP.
  ///
  /// In th, this message translates to:
  /// **'Monthly Accounts Payable (ตัดจ่ายซัพพลายเออร์)'**
  String get monthlyAP;

  /// No description provided for @monthlyAPDesc.
  ///
  /// In th, this message translates to:
  /// **'รวบรวมบิล Deposit และ Balance เพื่อทำเรื่องจ่ายออกทีเดียวช่วงสิ้นเดือน'**
  String get monthlyAPDesc;

  /// No description provided for @noPendingBills.
  ///
  /// In th, this message translates to:
  /// **'ยอดเยี่ยม! ไม่มีรอบบิลค้างชำระสำหรับโรงงานนี้'**
  String get noPendingBills;

  /// No description provided for @postponeBills.
  ///
  /// In th, this message translates to:
  /// **'เลื่อนบิลไปเดือนหน้า'**
  String get postponeBills;

  /// No description provided for @postponeSuccess.
  ///
  /// In th, this message translates to:
  /// **'เลื่อนรอบบิลที่เลือกสำเร็จ (Local Mock)'**
  String get postponeSuccess;

  /// No description provided for @languageSwitch.
  ///
  /// In th, this message translates to:
  /// **'เปลี่ยนภาษา'**
  String get languageSwitch;

  /// No description provided for @languageThai.
  ///
  /// In th, this message translates to:
  /// **'ไทย'**
  String get languageThai;

  /// No description provided for @languageEnglish.
  ///
  /// In th, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @activeProjects.
  ///
  /// In th, this message translates to:
  /// **'Active Projects'**
  String get activeProjects;

  /// No description provided for @cashflowOverview.
  ///
  /// In th, this message translates to:
  /// **'Cashflow Overview'**
  String get cashflowOverview;

  /// No description provided for @upcomingSchedule.
  ///
  /// In th, this message translates to:
  /// **'Upcoming Schedule'**
  String get upcomingSchedule;

  /// No description provided for @quickActions.
  ///
  /// In th, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @recentActivity.
  ///
  /// In th, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @createNewProject.
  ///
  /// In th, this message translates to:
  /// **'สร้างโปรเจกต์ใหม่'**
  String get createNewProject;

  /// No description provided for @recordPayment.
  ///
  /// In th, this message translates to:
  /// **'บันทึกการรับเงิน'**
  String get recordPayment;

  /// No description provided for @newCustomer.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มลูกค้าใหม่'**
  String get newCustomer;

  /// No description provided for @viewAllProjects.
  ///
  /// In th, this message translates to:
  /// **'ดูโปรเจกต์ทั้งหมด'**
  String get viewAllProjects;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'th':
      return STh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
