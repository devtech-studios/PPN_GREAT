/// API Endpoints — ค่าคงที่ URL ทุกเส้น API ของระบบ PPN GREAT
class ApiConfig {
  // 🔧 เปลี่ยน URL นี้เมื่อ deploy production
  static const String baseUrl = String.fromEnvironment(
    'PPN_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );
}

class AuthEndpoints {
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
}

class CustomerEndpoints {
  static const String index = '/customers';
  static String show(int id) => '/customers/$id';
  static const String store = '/customers';
  static String update(int id) => '/customers/$id';
  static String contacts(int id) => '/customers/$id/contacts';
  static String updateContact(int id, int cid) =>
      '/customers/$id/contacts/$cid';
  static String deleteContact(int id, int cid) =>
      '/customers/$id/contacts/$cid';
  static String addresses(int id) => '/customers/$id/addresses';
  static String updateAddress(int id, int aid) =>
      '/customers/$id/addresses/$aid';
  static String deleteAddress(int id, int aid) =>
      '/customers/$id/addresses/$aid';
  static String stats(int id) => '/customers/$id/stats';
}

class ProjectEndpoints {
  static const String index = '/projects';
  static String show(int id) => '/projects/$id';
  static const String store = '/projects';
  static String update(int id) => '/projects/$id';
  static String status(int id) => '/projects/$id/status';
  static String products(int id) => '/projects/$id/products';
  static String updateProduct(int id, int pid) =>
      '/projects/$id/products/$pid';
  static String deleteProduct(int id, int pid) =>
      '/projects/$id/products/$pid';
  static String additionalRequests(int id) =>
      '/projects/$id/additional-requests';
  static String logs(int id) => '/projects/$id/logs';
}

class SupplierEndpoints {
  static const String index = '/suppliers';
  static String show(int id) => '/suppliers/$id';
  static const String store = '/suppliers';
  static String update(int id) => '/suppliers/$id';

  // Quotes
  static String quotes(int id) => '/suppliers/$id/quotes';
  static String updateQuote(int id, int qid) => '/suppliers/$id/quotes/$qid';
  static String quoteStatus(int id, int qid) =>
      '/suppliers/$id/quotes/$qid/status';
  static String generateQuoteLink(int id, int qid) =>
      '/suppliers/$id/quotes/$qid/generate-link';

  // Supplier Samples
  static String samples(int id) => '/suppliers/$id/samples';
  static String updateSample(int id, int sid) =>
      '/suppliers/$id/samples/$sid';
  static String sampleStatus(int id, int sid) =>
      '/suppliers/$id/samples/$sid/status';

  // Bills
  static String bills(int id) => '/suppliers/$id/bills';
  static String payBill(int id, int bid) => '/suppliers/$id/bills/$bid/pay';
  static String uploadBill(int id, int bid) =>
      '/suppliers/$id/bills/$bid/upload';
}

class SampleEndpoints {
  static const String index = '/samples';
  static String byProject(int pid) => '/samples/project/$pid';
  static const String store = '/samples';
  static String update(int id) => '/samples/$id';
  static String status(int id) => '/samples/$id/status';
}

class ArtworkEndpoints {
  static const String index = '/artworks';
  static String byProject(int pid) => '/artworks/project/$pid';
  static const String store = '/artworks';
  static const String upload = '/artworks/upload';
  static String update(int id) => '/artworks/$id';
  static String status(int id) => '/artworks/$id/status';
  static String feedback(int id) => '/artworks/$id/feedback';
}

class ContainerEndpoints {
  static const String index = '/containers';
  static String show(int id) => '/containers/$id';
  static const String store = '/containers';
  static String update(int id) => '/containers/$id';
  static String step(int id) => '/containers/$id/step';
  static String routeGoods(int id) => '/containers/$id/route-goods';
}

class InventoryEndpoints {
  static const String warehouses = '/inventory/warehouses';
  static String warehouseStocks(int id) => '/inventory/warehouses/$id/stocks';
  static const String receive = '/inventory/receive';
  static const String adjust = '/inventory/adjust';
  static const String movements = '/inventory/movements';
  static const String lowStock = '/inventory/low-stock';
}

class DeliveryEndpoints {
  static const String index = '/delivery/rounds';
  static String show(int id) => '/delivery/rounds/$id';
  static const String store = '/delivery/rounds';
  static String confirm(int id) => '/delivery/rounds/$id/confirm';
  static String complete(int id) => '/delivery/rounds/$id/complete';
}

class FinanceEndpoints {
  static const String documents = '/finance/documents';
  static String showDocument(int id) => '/finance/documents/$id';
  static const String storeDocument = '/finance/documents';
  static String updateDocument(int id) => '/finance/documents/$id';
  static String documentStatus(int id) => '/finance/documents/$id/status';

  static const String payments = '/finance/payments';
  static String verifyPayment(int id) => '/finance/payments/$id/verify';
  static String uploadSlip(int id) => '/finance/payments/$id/upload-slip';
}

class DashboardEndpoints {
  static const String summary = '/dashboard/summary';
  static const String activities = '/dashboard/activities';
  static const String revenueChart = '/dashboard/revenue-chart';
}

class ReportEndpoints {
  static const String financialSummary = '/reports/financial-summary';
  static const String operationalSummary = '/reports/operational-summary';
  static const String revenueByMonth = '/reports/revenue-by-month';
  static const String profitByProject = '/reports/profit-by-project';
}

class QuotePublicEndpoints {
  static String fillPrice(String token) => '/quotes/public/$token';
}
