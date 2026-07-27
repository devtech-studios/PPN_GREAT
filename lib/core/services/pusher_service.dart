import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class PusherService {
  static final PusherService instance = PusherService._internal();
  PusherService._internal();

  bool _initialized = false;

  void initPusher({
    String appKey = "4a413d88db5afa161283",
    String cluster = "ap1",
    Function(String message)? onMessageReceived,
  }) {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      try {
        js.context['onPusherEventReceived'] = (String data) {
          debugPrint("[Pusher Flutter] Event payload: $data");
          if (onMessageReceived != null) {
            onMessageReceived(data);
          }
        };

        js.context.callMethod('initPusherNotification', [appKey, cluster]);
        debugPrint("[Pusher Service] Initialized Pusher Real-time Client!");
      } catch (e) {
        debugPrint("[Pusher Service Error] $e");
      }
    }
  }
}
