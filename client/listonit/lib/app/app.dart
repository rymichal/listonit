import 'package:flutter/material.dart';

import 'theme.dart';
import '../features/lists/presentation/lists_screen.dart';

class ListonitApp extends StatelessWidget {
  const ListonitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Listonit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ListsScreen(),
    );
  }
}
