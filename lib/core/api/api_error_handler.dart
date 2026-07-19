import 'package:dio/dio.dart';

class ApiErrorHandler {
  /// แปลง Error หรือ Exception จากการเชื่อมต่อ API ให้เป็นข้อความภาษาไทยที่อ่านง่ายและเหมาะสมสำหรับแสดงผลกับผู้ใช้งาน
  static String parseError(dynamic e) {
    if (e is DioException) {
      final responseData = e.response?.data;
      if (responseData is Map && responseData['success'] == false) {
        final err = responseData['error'];
        if (err is Map) {
          final message = err['message'] ?? "เกิดข้อผิดพลาดในการบันทึก";
          final details = err['details'];
          
          if (details is Map) {
            final List<String> lines = [];
            details.forEach((key, val) {
              // แปลงชื่อฟิลด์เป็นภาษาไทยให้เข้าใจง่าย
              String fieldThai = key;
              if (key == 'name') fieldThai = 'ชื่อบริษัท/ลูกค้า';
              if (key == 'tax_id') fieldThai = 'เลขประจำตัวผู้เสียภาษี (Tax ID)';
              if (key == 'billing_address') fieldThai = 'ที่อยู่ออกบิล';
              if (key == 'phone') fieldThai = 'เบอร์โทรศัพท์';
              if (key == 'email') fieldThai = 'อีเมล';
              if (key == 'status') fieldThai = 'สถานะ';
              if (key == 'type') fieldThai = 'ประเภทลูกค้า';
              if (key == 'branch') fieldThai = 'สาขา';
              if (key == 'industry') fieldThai = 'ประเภทธุรกิจ';
              if (key == 'lead_source') fieldThai = 'ช่องทางลูกค้า';

              String valStr = "";
              if (val is List) {
                valStr = val.map((item) {
                  // แปลข้อความผิดพลาดหลักๆ จาก Laravel เป็นภาษาไทย
                  String msg = item.toString();
                  if (msg.contains("already been taken")) {
                    return "มีข้อมูลนี้อยู่ในระบบแล้ว (ซ้ำซ้อน)";
                  }
                  if (msg.contains("required")) {
                    return "จำเป็นต้องกรอกข้อมูลช่องนี้";
                  }
                  if (msg.contains("invalid") || msg.contains("must be")) {
                    return "รูปแบบข้อมูลไม่ถูกต้อง";
                  }
                  return msg;
                }).join(', ');
              } else {
                valStr = val.toString();
              }
              lines.add("• $fieldThai: $valStr");
            });
            
            if (lines.isNotEmpty) {
              return "$message:\n${lines.join('\n')}";
            }
          }
          return message;
        }
      }
      
      // กรณีไม่มี Body ตอบกลับมาแต่มีประเภทของ DioError อื่นๆ
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return "หมดเวลารอการเชื่อมต่อกับเซิร์ฟเวอร์ (Connection Timeout)";
        case DioExceptionType.sendTimeout:
          return "หมดเวลาส่งข้อมูล (Send Timeout)";
        case DioExceptionType.receiveTimeout:
          return "หมดเวลารับข้อมูลจากเซิร์ฟเวอร์ (Receive Timeout)";
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          return "เซิร์ฟเวอร์ตอบกลับด้วยข้อผิดพลาด (รหัส $statusCode)";
        case DioExceptionType.cancel:
          return "การเชื่อมต่อถูกยกเลิก";
        case DioExceptionType.connectionError:
          return "ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ตหรือเซิร์ฟเวอร์ API";
        default:
          return "เกิดข้อผิดพลาดในการเชื่อมต่ออินเทอร์เน็ต";
      }
    }
    
    // จัดการข้อความทั่วไป
    final rawMsg = e.toString();
    if (rawMsg.contains("Exception:")) {
      return rawMsg.replaceAll("Exception: ", "");
    }
    return rawMsg;
  }
}
