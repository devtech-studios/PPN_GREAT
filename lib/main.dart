import 'package:flutter/material.dart';
import 'app.dart';
import 'core/locale/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localeProvider.loadSavedLocale();
  runApp(const PPNGreatApp());
}

