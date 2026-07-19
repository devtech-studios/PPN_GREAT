/**
 * PPN GREAT — Shared Selectors for Playwright Tests
 *
 * Flutter Web renders widgets as semantics nodes in the DOM.
 * These selectors target visible text, roles, and input types.
 *
 * NOTE: Flutter Web (with CanvasKit or HTML renderer) has limited
 * DOM accessibility. Most selectors rely on text content matching.
 */

// ===========================
// Login Screen
// ===========================
export const LOGIN = {
  emailInput: 'input[type="text"]',
  passwordInput: 'input[type="password"]',
  signInButton: 'text=Sign In',
  brandText: 'text=PPN GREAT',
  errorMessage: 'text=กรุณากรอก',
};

// ===========================
// Sidebar Navigation
// ===========================
export const SIDEBAR = {
  dashboard: 'text=Dashboard',
  projects: 'text=Projects',
  samples: 'text=Samples',
  artwork: 'text=Artwork',
  containers: 'text=Containers',
  delivery: 'text=Delivery',
  customers: 'text=Customers',
  suppliers: 'text=Suppliers',
  finance: 'text=Finance',
  inventory: 'text=Inventory',
  settings: 'text=Settings',
  reports: 'text=Reports',
  logout: 'text=Log Out',
};

// ===========================
// Common Patterns
// ===========================
export const COMMON = {
  backButton: 'text=Back',
  saveButton: 'text=Save',
  cancelButton: 'text=Cancel',
  deleteButton: 'text=Delete',
  editButton: 'text=Edit',
  createButton: 'text=Create',
  confirmButton: 'text=Confirm',
  searchInput: 'input[placeholder*="ค้นหา"]',
  snackBar: '[class*="SnackBar"]',
  loadingIndicator: 'role=progressbar',
};

// ===========================
// Customer Screen
// ===========================
export const CUSTOMER = {
  createCustomerButton: 'text=Create Customer',
  companyNameInput: 'input[placeholder*="ชื่อ"]',
  searchInput: 'input[placeholder*="ค้นหาชื่อบริษัท"]',
  saveButton: 'text=บันทึก',
  customerList: '[class*="ListView"]',
};

// ===========================
// Project Screen
// ===========================
export const PROJECT = {
  createProjectButton: 'text=Create New Project',
  searchInput: 'input[placeholder*="ค้นหา"]',
  statusFilter: {
    all: 'text=All',
    inquiry: 'text=Inquiry',
    sample: 'text=Sample',
    production: 'text=Production',
    shipping: 'text=Shipping',
    delivered: 'text=Delivered',
  },
};

// ===========================
// Supplier Portal (PHP — standard HTML)
// ===========================
export const SUPPLIER_PORTAL = {
  usernameInput: '#username',
  passwordInput: '#password',
  loginButton: 'button:has-text("Log In to Portal")',
  pendingTab: '#tab-pending',
  historyTab: '#tab-history',
  submitQuoteButton: 'button:has-text("Submit Quote")',
  reviseButton: 'button:has-text("Revise")',
  // Dynamic fields (use function)
  priceInput: (id: number) => `#price-${id}`,
  leadInput: (id: number) => `#lead-${id}`,
  moqInput: (id: number) => `#moq-${id}`,
  samplePriceInput: (id: number) => `#sample-price-${id}`,
  sampleLeadInput: (id: number) => `#sample-lead-${id}`,
  remarkInput: (id: number) => `#remark-${id}`,
  // Modal
  modalPrice: '#modal-price',
  modalLead: '#modal-lead',
  modalSamplePrice: '#modal-sample-price',
  modalRemark: '#modal-remark',
  submitRevisionButton: 'button:has-text("Submit Revision")',
  cancelModalButton: 'button:has-text("Cancel")',
  successBanner: '#success-banner',
};

// ===========================
// Finance Screen
// ===========================
export const FINANCE = {
  createDocButton: 'text=สร้างเอกสาร',
  docTypeQU: 'text=QU',
  docTypePI: 'text=PI',
  docTypeDP: 'text=DP',
  docTypeCI: 'text=CI',
};

// ===========================
// Delivery Screen
// ===========================
export const DELIVERY = {
  createRoundButton: 'text=สร้างรอบส่ง',
  confirmDepartButton: 'text=ปล่อยรถ',
  completeButton: 'text=ส่งสำเร็จ',
};

// ===========================
// Reports Screen
// ===========================
export const REPORTS = {
  tabRevenue: 'text=Revenue',
  tabProfitability: 'text=Profitability',
  tabCashFlow: 'text=Cash Flow',
  tabTax: 'text=Tax',
  tabDelivery: 'text=Delivery',
  tabLeadTime: 'text=Lead Time',
  tabCustomerPortfolio: 'text=Customer',
};
