import 'package:dio/dio.dart';
import '../locale/locale_provider.dart';

class ApiErrorHandler {
  /// แปลง Error หรือ Exception จากการเชื่อมต่อ API ให้เป็นข้อความภาษาที่เหมาะสม (ไทย/อังกฤษ)
  static String parseError(dynamic e) {
    final isEn = localeProvider.isEnglish;

    if (e is DioException) {
      final responseData = e.response?.data;
      if (responseData is Map && responseData['success'] == false) {
        final err = responseData['error'];
        if (err is Map) {
          final message = err['message'] ?? (isEn ? "Error saving data" : "เกิดข้อผิดพลาดในการบันทึก");
          final details = err['details'];
          
          if (details is Map) {
            final List<String> lines = [];
            details.forEach((key, val) {
              String fieldLabel = key;
              if (isEn) {
                if (key == 'name') fieldLabel = 'Company/Customer Name';
                if (key == 'tax_id') fieldLabel = 'Tax ID';
                if (key == 'billing_address') fieldLabel = 'Billing Address';
                if (key == 'phone') fieldLabel = 'Phone Number';
                if (key == 'email') fieldLabel = 'Email';
                if (key == 'status') fieldLabel = 'Status';
                if (key == 'type') fieldLabel = 'Customer Type';
                if (key == 'branch') fieldLabel = 'Branch';
                if (key == 'industry') fieldLabel = 'Industry';
                if (key == 'lead_source') fieldLabel = 'Lead Source';
              } else {
                if (key == 'name') fieldLabel = 'ชื่อบริษัท/ลูกค้า';
                if (key == 'tax_id') fieldLabel = 'เลขประจำตัวผู้เสียภาษี (Tax ID)';
                if (key == 'billing_address') fieldLabel = 'ที่อยู่ออกบิล';
                if (key == 'phone') fieldLabel = 'เบอร์โทรศัพท์';
                if (key == 'email') fieldLabel = 'อีเมล';
                if (key == 'status') fieldLabel = 'สถานะ';
                if (key == 'type') fieldLabel = 'ประเภทลูกค้า';
                if (key == 'branch') fieldLabel = 'สาขา';
                if (key == 'industry') fieldLabel = 'ประเภทธุรกิจ';
                if (key == 'lead_source') fieldLabel = 'ช่องทางลูกค้า';
              }

              String valStr = "";
              if (val is List) {
                valStr = val.map((item) {
                  String msg = item.toString();
                  if (msg.contains("already been taken")) {
                    return isEn ? "Data already exists in system (duplicate)" : "มีข้อมูลนี้อยู่ในระบบแล้ว (ซ้ำซ้อน)";
                  }
                  if (msg.contains("required")) {
                    return isEn ? "This field is required" : "จำเป็นต้องกรอกข้อมูลช่องนี้";
                  }
                  if (msg.contains("invalid") || msg.contains("must be")) {
                    return isEn ? "Invalid data format" : "รูปแบบข้อมูลไม่ถูกต้อง";
                  }
                  return msg;
                }).join(', ');
              } else {
                valStr = val.toString();
              }
              lines.add("• $fieldLabel: $valStr");
            });
            
            if (lines.isNotEmpty) {
              return "$message:\n${lines.join('\n')}";
            }
          }
          return message;
        }
      }
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return isEn ? "Connection Timeout" : "หมดเวลารอการเชื่อมต่อกับเซิร์ฟเวอร์ (Connection Timeout)";
        case DioExceptionType.sendTimeout:
          return isEn ? "Send Timeout" : "หมดเวลาส่งข้อมูล (Send Timeout)";
        case DioExceptionType.receiveTimeout:
          return isEn ? "Receive Timeout" : "หมดเวลารับข้อมูลจากเซิร์ฟเวอร์ (Receive Timeout)";
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          return isEn ? "Server error (Code $statusCode)" : "เซิร์ฟเวอร์ตอบกลับด้วยข้อผิดพลาด (รหัส $statusCode)";
        case DioExceptionType.cancel:
          return isEn ? "Connection cancelled" : "การเชื่อมต่อถูกยกเลิก";
        case DioExceptionType.connectionError:
          return isEn ? "Cannot connect to server. Please check network." : "ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ตหรือเซิร์ฟเวอร์ API";
        default:
          return isEn ? "Network error" : "เกิดข้อผิดพลาดในการเชื่อมต่ออินเทอร์เน็ต";
      }
    }
    
    final rawMsg = e.toString();
    if (rawMsg.contains("Exception:")) {
      return rawMsg.replaceAll("Exception: ", "");
    }
    return rawMsg;
  }
}
