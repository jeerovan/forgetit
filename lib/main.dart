// main.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'page_home.dart';
import 'database_helper.dart';
import 'model_setting.dart';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'themes.dart';

// Set to false if running on Desktop
bool mobile = Platform.isAndroid || Platform.isIOS;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!mobile) {
    // Initialize sqflite for FFI (non-mobile platforms)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // initialize the db
  DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> keyValuePairs = await dbHelper.queryAll('setting');
  ModelSetting.appJson = {
    for (var pair in keyValuePairs) pair['id']: jsonDecode(pair['value'])
  };

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool isDark = true;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  Future<void> loadTheme() async {
    // Load the theme from saved preferences
    bool? savedDark = await ModelSetting.getForKey("is_dark",null);
    setState(() {
      switch (savedDark) {
        case false:
          _themeMode = ThemeMode.light;
          isDark = false;
          break;
        case true:
          _themeMode = ThemeMode.dark;
          isDark = true;
          break;
        default:
          // Default to system theme
          _themeMode = ThemeMode.system;
          isDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
          break;
      }  
    });
  }

  // Toggle between light and dark modes
  void _toggleTheme() {
    setState(() {
      _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
      isDark = !isDark;
      ModelSetting.update("is_dark", isDark);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: _themeMode,
      home: HomePage(
        isDarkMode: isDark,
        onThemeToggle: _toggleTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
