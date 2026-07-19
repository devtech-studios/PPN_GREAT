import 'package:url_launcher/url_launcher.dart';

Future<void> openUrl(String url) async {
  final Uri uri = Uri.parse(url);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri);
    }
  } catch (e) {
    // Fallback if launcher fails
  }
}
