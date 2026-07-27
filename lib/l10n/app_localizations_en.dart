// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PPN GREAT';

  @override
  String get appSubtitle => 'Import Operation Platform';

  @override
  String get importOperation => 'Import Operation';

  @override
  String dashboardGreeting(String name) {
    return 'Hello, $name 👋';
  }

  @override
  String activeProjectsToday(int count) {
    return 'You have $count active projects today';
  }

  @override
  String get loadingActiveProjects => 'Loading active projects...';

  @override
  String get searchHint => 'Search projects, customers...';

  @override
  String get overviewSection => 'Overview';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get operations => 'Operations';

  @override
  String get projects => 'Projects';

  @override
  String get samples => 'Samples';

  @override
  String get artwork => 'Artwork';

  @override
  String get containers => 'Containers';

  @override
  String get delivery => 'Delivery';

  @override
  String get contacts => 'Contacts';

  @override
  String get customers => 'Customers';

  @override
  String get suppliers => 'Suppliers';

  @override
  String get financeAndInventory => 'Finance & Inventory';

  @override
  String get finance => 'Finance';

  @override
  String get inventory => 'Inventory';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get settings => 'Settings';

  @override
  String get ownerOnly => 'Owner Only';

  @override
  String get reports => 'Reports';

  @override
  String get logOut => 'Log Out';

  @override
  String get logOutConfirm => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data';

  @override
  String get retry => 'Retry';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get signIn => 'Sign In';

  @override
  String get emailUsername => 'Email / Username';

  @override
  String get password => 'Password';

  @override
  String get loginValidation => 'Please enter Email and Password';

  @override
  String get loginFailed => 'Login failed';

  @override
  String loginFailedWithCode(int statusCode) {
    return 'Login failed ($statusCode)';
  }

  @override
  String get connectionError =>
      'Cannot connect to server. Please check your connection.';

  @override
  String get splashTitle => 'PPN GREAT';

  @override
  String get splashSubtitle => 'Import Operation Platform';

  @override
  String get activeProjectsHeader => 'Active Projects';

  @override
  String get activeProjectsSubtitle =>
      'Track the status of all orders in the system';

  @override
  String filterAllActive(int count) {
    return 'All Active ($count)';
  }

  @override
  String filterInquiry(int count) {
    return 'Inquiry ($count)';
  }

  @override
  String filterArtwork(int count) {
    return 'Artwork ($count)';
  }

  @override
  String filterDeposit(int count) {
    return 'Deposit ($count)';
  }

  @override
  String filterSample(int count) {
    return 'Sample ($count)';
  }

  @override
  String filterProduction(int count) {
    return 'Production ($count)';
  }

  @override
  String filterShipping(int count) {
    return 'Shipping ($count)';
  }

  @override
  String get cardBudget => 'Budget';

  @override
  String get cardQuantity => 'Quantity';

  @override
  String get cardProgress => 'Progress';

  @override
  String get cardDue => 'Due:';

  @override
  String get quickActionsHeader => 'Quick Actions';

  @override
  String get btnCreateNewProject => 'Create New Project';

  @override
  String get btnManageSamples => 'Manage Samples';

  @override
  String get btnUploadArtwork => 'Upload Artwork';

  @override
  String get btnGeneratePI => 'Generate PI';

  @override
  String get btnBookContainer => 'Book Container';

  @override
  String get btnRecordPayment => 'Record Payment';

  @override
  String get activityLogHeader => 'Activity Log';

  @override
  String get cashflowHeader => 'Cashflow Overview';

  @override
  String get filterThisMonth => 'This month';

  @override
  String get labelIncoming => 'Incoming';

  @override
  String get labelOutgoing => 'Outgoing';

  @override
  String get labelNetBalance => 'Net Balance';

  @override
  String get upcomingScheduleHeader => 'Upcoming Schedule';

  @override
  String get viewFullCalendar => 'View full calendar →';

  @override
  String containerArriving(String code) {
    return 'Container arriving ($code)';
  }

  @override
  String customerMeeting(String customer) {
    return 'Customer meeting ($customer)';
  }

  @override
  String sampleDelivery(String customer) {
    return 'Sample delivery to ($customer)';
  }

  @override
  String get mobileGreeting => 'Hello, Executive 👋';

  @override
  String get businessOverviewToday => 'Business Overview Today';

  @override
  String get netCashBalance => 'Net Cash Balance';

  @override
  String get arPending => 'AR (Receivable)';

  @override
  String get apPending => 'AP (Payable)';

  @override
  String get profit => 'Profit';

  @override
  String get deliveryLabel => 'Delivery';

  @override
  String get stock => 'Stock';

  @override
  String get customerLabel => 'Customers';

  @override
  String get projectPipeline => 'Project Pipeline';

  @override
  String get quoteStep => 'Quote';

  @override
  String get depositStep => 'Deposit';

  @override
  String get productionStep => 'Production';

  @override
  String get shippingStep => 'Shipping';

  @override
  String get avgLeadTime => 'Avg Lead Time';

  @override
  String daysUnit(int count) {
    return '$count days';
  }

  @override
  String get pendingTaxClearance => 'Pending Tax Clearance';

  @override
  String containersUnit(int count) {
    return '$count containers';
  }

  @override
  String get ownerPortal => 'Owner Portal';

  @override
  String get companyName => 'PPN GREAT CO., LTD.';

  @override
  String get financials => 'Financials';

  @override
  String get profitability => 'Profit per Project';

  @override
  String get cashFlow => 'Cash Flow & AR/AP';

  @override
  String get taxAnalytics => 'Import Tax & Clearance';

  @override
  String get deliveryStatus => 'Delivery Status';

  @override
  String get leadTimeAnalysis => 'Lead Time Analysis';

  @override
  String get inventoryAging => 'Inventory Aging';

  @override
  String get supplierRating => 'Supplier Ranking';

  @override
  String get focAnalytics => 'FOC (Claim Reserve) Stats';

  @override
  String get customerPortfolio => 'Customer Portfolio';

  @override
  String get categoryDemand => 'Best-Selling Categories';

  @override
  String get logisticsEfficiency => 'Logistics Efficiency';

  @override
  String get companyOverview => 'Company Overview';

  @override
  String get netProfitByProject => 'Net Profit by Project';

  @override
  String get cashFlowTitle => 'Cash Flow';

  @override
  String get cashAvailable => 'Cash Available';

  @override
  String get arReceivable => 'AR (Receivable)';

  @override
  String get apPayable => 'AP (Payable)';

  @override
  String get importTaxTitle => 'Import Tax & Clearance';

  @override
  String get vatAccumulated => 'Accumulated VAT';

  @override
  String get dutyAccumulated => 'Accumulated Duty';

  @override
  String shipRound(String month) {
    return 'Ship Round: $month';
  }

  @override
  String get deliveryOverview => 'Delivery';

  @override
  String leadTimeAvgDays(int days) {
    return 'Avg Lead Time: $days days';
  }

  @override
  String get leadTimeSubtitle => 'Duration from start to delivery';

  @override
  String get inventoryAgingTitle => 'Inventory Aging';

  @override
  String get supplierRankingTitle => 'Supplier Ranking';

  @override
  String get focClaimStats => 'FOC Claim Stats';

  @override
  String get customerRevenueShare => 'Customer Revenue Share';

  @override
  String get bestSellingCategories => 'Best-Selling Categories';

  @override
  String get logisticsEfficiencyTitle => 'Logistics Efficiency';

  @override
  String get errorSaving => 'An error occurred while saving';

  @override
  String get fieldCompanyName => 'Company/Customer Name';

  @override
  String get fieldTaxId => 'Tax ID';

  @override
  String get fieldBillingAddress => 'Billing Address';

  @override
  String get fieldPhone => 'Phone Number';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldStatus => 'Status';

  @override
  String get fieldType => 'Customer Type';

  @override
  String get fieldBranch => 'Branch';

  @override
  String get fieldIndustry => 'Industry';

  @override
  String get fieldLeadSource => 'Lead Source';

  @override
  String get errorDuplicate =>
      'This data already exists in the system (duplicate)';

  @override
  String get errorRequired => 'This field is required';

  @override
  String get errorInvalidFormat => 'Invalid format';

  @override
  String get errorConnectionTimeout => 'Connection Timeout';

  @override
  String get errorSendTimeout => 'Send Timeout';

  @override
  String get errorReceiveTimeout => 'Receive Timeout';

  @override
  String errorBadResponse(int statusCode) {
    return 'Server responded with an error (Code $statusCode)';
  }

  @override
  String get errorCancelled => 'Connection was cancelled';

  @override
  String get errorConnection =>
      'Cannot connect to server. Please check your internet or the API server.';

  @override
  String get errorGenericConnection => 'A network error occurred';

  @override
  String get selectProject => 'Select Project';

  @override
  String get searchSupplier => 'Search factory name...';

  @override
  String get savePaymentSuccess =>
      'Payment transfer to supplier saved successfully';

  @override
  String get addBillSuccess => 'New expense bill added successfully';

  @override
  String get createBillForFactory => 'Create new expense bill for this factory';

  @override
  String get unnamedProduct => 'Unnamed product';

  @override
  String uploadFileSuccess(String fileType) {
    return 'File $fileType uploaded successfully';
  }

  @override
  String get quotesTab => 'Quotes';

  @override
  String get samplesTab => 'Samples';

  @override
  String get paymentsTab => 'Payments (AP)';

  @override
  String get quoteListDesc => 'Items for this factory to estimate pricing';

  @override
  String get noQuotes => 'No quote requests from this factory yet';

  @override
  String get unitCost => 'Unit Cost';

  @override
  String get sampleListDesc => 'Sample items requested from this factory';

  @override
  String get noSamples => 'No sample requests from this factory yet';

  @override
  String get editSpecCost => 'Edit spec/cost';

  @override
  String get monthlyAP => 'Monthly Accounts Payable';

  @override
  String get monthlyAPDesc =>
      'Consolidate Deposit and Balance bills for month-end batch payment';

  @override
  String get noPendingBills => 'Excellent! No pending bills for this factory';

  @override
  String get postponeBills => 'Postpone bills to next month';

  @override
  String get postponeSuccess =>
      'Selected bills postponed successfully (Local Mock)';

  @override
  String get languageSwitch => 'Switch Language';

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
  String get createNewProject => 'Create New Project';

  @override
  String get recordPayment => 'Record Payment';

  @override
  String get newCustomer => 'New Customer';

  @override
  String get viewAllProjects => 'View All Projects';
}
