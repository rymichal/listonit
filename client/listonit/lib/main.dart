import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.initialize();
  await dotenv.load(fileName: ".env");

  runApp(
    const ProviderScope(
      child: ListonitApp(),
    ),
  );
}
