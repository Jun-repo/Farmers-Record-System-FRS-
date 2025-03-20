import 'package:farmers_record/dashboard.dart';
import 'package:farmers_record/database_helper.dart';
import 'package:farmers_record/database_location_picker.dart';
import 'package:farmers_record/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MainApp());
}

Future<void> _insertDefaultAdmin(DatabaseHelper dbHelper) async {
  try {
    final admins = await dbHelper.database.then((db) => db.query('admins'));
    if (admins.isEmpty) {
      final defaultAdmin = {
        'profile_picture': '',
        'username': 'admin',
        'password': 'passw0rd123',
      };
      await dbHelper.insertAdmin(defaultAdmin);
      if (kDebugMode) {
        print('Default admin inserted: username=admin, password=passw0rd123');
      }
    } else {
      if (kDebugMode) {
        print('Admin already exists, skipping insertion');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error inserting default admin: $e');
    }
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Map<String, dynamic>? _currentAdmin;
  bool _isLoggedIn = false;
  bool _isDarkMode = false;

  void _handleLogin(Map<String, dynamic> admin) {
    setState(() {
      _isLoggedIn = true;
      _currentAdmin = admin;
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _currentAdmin = null;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Future<Widget> _onDatabaseSelected(DatabaseHelper dbHelper) async {
    await _insertDefaultAdmin(dbHelper);
    return ThemeToggleProvider(
      isDarkMode: _isDarkMode,
      toggleTheme: _toggleTheme,
      child: _isLoggedIn
          ? DashboardPage(
              admin: _currentAdmin,
              onLogout: _handleLogout,
            )
          : LoginPage(
              onLogin: _handleLogin,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemeToggleProvider(
      isDarkMode: _isDarkMode,
      toggleTheme: _toggleTheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Farmers Record',
        theme: _isDarkMode
            ? ThemeData.dark().copyWith(
                textTheme:
                    ThemeData.dark().textTheme.apply(fontFamily: 'Gilroy'),
                scaffoldBackgroundColor: const Color.fromARGB(255, 24, 24, 27),
                cardColor: const Color.fromARGB(255, 38, 38, 42),
              )
            : ThemeData.light().copyWith(
                textTheme:
                    ThemeData.light().textTheme.apply(fontFamily: 'Gilroy'),
                scaffoldBackgroundColor:
                    const Color.fromARGB(255, 237, 237, 240),
                cardColor: const Color.fromRGBO(245, 245, 247, 1),
              ),
        home: DatabaseLocationPicker(
          onDatabaseSelected: _onDatabaseSelected,
        ),
      ),
    );
  }
}

class ThemeToggleProvider extends InheritedWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const ThemeToggleProvider({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeToggleProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeToggleProvider>();
  }

  @override
  bool updateShouldNotify(ThemeToggleProvider oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}
