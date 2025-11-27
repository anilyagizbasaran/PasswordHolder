import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/theme_controller.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDark = themeController.themeMode == ThemeMode.dark;

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () {
        themeController.toggleTheme();
      },
      tooltip: isDark ? 'Açık temaya geç' : 'Koyu temaya geç',
    );
  }
}

