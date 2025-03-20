import 'package:farmers_record/main.dart';
import 'package:farmers_record/database_helper.dart';
import 'package:farmers_record/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, exit; // Import for platform detection and exit

class LoginPage extends StatefulWidget {
  final void Function(Map<String, dynamic> admin) onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'admins',
        where: 'username = ? AND password = ?',
        whereArgs: [_usernameController.text, _passwordController.text],
      );

      if (result.isNotEmpty) {
        widget.onLogin(result.first);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(
                admin: result.first,
                onLogout: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(onLogin: widget.onLogin),
                    ),
                  );
                },
              ),
            ),
          );
        }
      } else {
        _showErrorDialog('Invalid Credentials');
      }
    } catch (e) {
      _showErrorDialog('Connection error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;
    const textStyle = TextStyle(
      fontFamily: 'Gilroy',
      fontSize: 16,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode
                ? const Color.fromARGB(255, 60, 60, 62)
                : const Color.fromARGB(255, 255, 255, 255),
            width: 0.7,
          ),
        ),
        title: Text(
          'Password Assistance',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Please contact the developer for password recovery.',
          style: textStyle.copyWith(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        backgroundColor:
            isDarkMode ? const Color.fromARGB(255, 38, 38, 42) : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.blue[200] : Colors.blue,
            ),
            child: Text(
              'OK',
              style: textStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _closeApp() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop(); // Works for mobile platforms
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      exit(0); // Closes the app on desktop platforms
    } else {
      SystemNavigator
          .pop(); // Fallback for other platforms (e.g., web might not work)
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeToggleProvider.of(context)?.isDarkMode ?? false;
    final textTheme = Theme.of(context).textTheme;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: isDarkMode
            ? const Color.fromARGB(255, 60, 60, 62)
            : const Color.fromARGB(255, 200, 200, 200),
        width: 1.0,
      ),
    );

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color.fromARGB(255, 24, 24, 27)
          : const Color.fromARGB(255, 237, 237, 240),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icons/logo.png', width: 80, height: 80),
                    const SizedBox(height: 16),
                    Text('Farmers Record',
                        style: textTheme.headlineSmall?.copyWith(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        prefixIcon: const Icon(Icons.person),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: BorderSide(
                            color:
                                isDarkMode ? Colors.greenAccent : Colors.green,
                            width: 1.0,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder.copyWith(
                          borderSide: BorderSide(
                            color:
                                isDarkMode ? Colors.greenAccent : Colors.green,
                            width: 1.0,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: _closeApp, // Updated to use _closeApp
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 45, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                              side: BorderSide(
                                color: isDarkMode
                                    ? const Color.fromARGB(255, 110, 110, 114)
                                    : const Color.fromARGB(255, 200, 200, 200),
                                width: 1.0,
                              ),
                            ),
                            foregroundColor:
                                isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 45, vertical: 20),
                            backgroundColor: isDarkMode
                                ? const Color.fromARGB(255, 152, 240, 197)
                                : Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            side: BorderSide(
                              color: isDarkMode
                                  ? const Color.fromARGB(255, 56, 126, 92)
                                  : const Color.fromARGB(255, 29, 122, 32),
                              width: 1.0,
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
