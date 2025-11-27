import 'package:flutter/material.dart';

import '../services/user_api.dart';
import 'persistent_bottom_nav_page.dart';
import 'admin_panel_screen.dart';
import '../utils/backend_config.dart';
import '../utils/user_validators.dart';
import '../widgets/theme_toggle.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final UserApi _api;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _error;
  bool _loading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _api = UserApi(baseUrl: resolveUserApiBaseUrl());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = normalizeEmail(_emailController.text);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.login(email, _passwordController.text);

      if (!mounted) return;
      final destination = _api.department?.toLowerCase() == 'admin'
          ? AdminPanelScreen(api: _api)
          : PersistentBottomNavPage(api: _api);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => destination,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BarPass'),
        actions: const [
          ThemeToggle(),
        ],
      ),
      body: Center(
        child: isSmallScreen
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(isSmallScreen),
                  _gap(24),
                  _buildForm(),
                ],
              )
            : Container(
                padding: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 800),
                child: Row(
                  children: [
                    Expanded(child: _buildLogo(isSmallScreen)),
                    Expanded(
                      child: Center(
                        child: _buildForm(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLogo(bool isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlutterLogo(size: isSmallScreen ? 100 : 200),
        const SizedBox(height: 16),
        Text(
          'BarPass\'a hoş geldin!',
          textAlign: TextAlign.center,
          style: isSmallScreen
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                hintText: 'ornek',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: validateEmail,
            ),
            _gap(16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Şifre',
                hintText: 'Şifrenizi girin',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              validator: validatePassword,
            ),
            _gap(8),
            CheckboxListTile(
              value: _rememberMe,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _rememberMe = value;
                });
              },
              title: const Text('Beni hatırla'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            _gap(24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Giriş Yap',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _gap(16),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _gap(double size) => SizedBox(height: size);
}

