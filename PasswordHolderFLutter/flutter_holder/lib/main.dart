import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'controllers/theme_controller.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PasswordHolderApp());
}

class PasswordHolderApp extends StatelessWidget {
  const PasswordHolderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Password Holder',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const LoginScreen(),
            },
          );
        },
      ),
    );
  }
}
