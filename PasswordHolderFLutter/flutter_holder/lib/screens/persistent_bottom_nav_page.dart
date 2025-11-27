import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/theme_controller.dart';
import '../services/holder_order_cache.dart';
import '../services/password_holder_api.dart';
import '../services/user_api.dart';
import '../services/user_preferences.dart';
import '../utils/backend_config.dart';
import '../utils/card_size_option.dart';
import '../utils/user_validators.dart';
import '../widgets/password_holder_list.dart';
import '../widgets/profile_info_sheet.dart';

class PersistentBottomNavPage extends StatefulWidget {
  const PersistentBottomNavPage({super.key, required this.api});

  final UserApi api;

  @override
  State<PersistentBottomNavPage> createState() =>
      _PersistentBottomNavPageState();
}

enum _SettingsAction { profile, cardSize, theme, clearCache, logout }

class _PersistentBottomNavPageState extends State<PersistentBottomNavPage> {
  late final PasswordHolderApi _passwordHolderApi;
  final HolderOrderCache _orderCache = HolderOrderCache.instance;
  final UserPreferences _userPreferences = UserPreferences.instance;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = const [];
  bool _loggingOut = false;
  bool _clearingCache = false;
  CardSizeOption _cardSizeOption = CardSizeOption.normal;
  bool get _isAdmin => (widget.api.department ?? '').toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _passwordHolderApi = PasswordHolderApi(
      client: widget.api.client,
      baseUrl: resolvePasswordHolderBaseUrl(),
    );
    _loadCardSizePreference();
    final token = widget.api.jwtToken;
    if (token == null || token.isEmpty) {
      _loading = false;
      _error = 'Oturum bilgisi bulunamadı. Lütfen yeniden giriş yapın.';
    } else {
      _passwordHolderApi.attachBearerToken(token);
      _fetchEntries();
    }
  }

  Future<void> _fetchEntries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final entries = await _passwordHolderApi.listHolders();
      debugPrint(
        'Password holders fetched: '
        '${entries.map((e) => e.toString()).join(', ')}',
      );
      final orderedEntries = await _applyCachedOrder(entries);
      if (!mounted) return;
      setState(() {
        _entries = orderedEntries;
      });
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
    final themeController = context.watch<ThemeController>();
    final bool isDarkTheme = themeController.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BarPass'),
        actions: [
          PopupMenuButton<_SettingsAction>(
            enabled: !_loading && !_loggingOut,
            tooltip: 'Ayarlar',
            icon: _loggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.settings),
            onSelected: (action) {
              switch (action) {
                case _SettingsAction.cardSize:
                  _handleAdjustCardSize();
                  break;
                case _SettingsAction.profile:
                  _handleProfile();
                  break;
                case _SettingsAction.theme:
                  _handleThemeToggle();
                  break;
                case _SettingsAction.clearCache:
                  _handleClearCache();
                  break;
                case _SettingsAction.logout:
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<_SettingsAction>(
                value: _SettingsAction.profile,
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('Profil'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<_SettingsAction>(
                value: _SettingsAction.cardSize,
                child: Row(
                  children: [
                    const Icon(Icons.view_agenda_outlined),
                    const SizedBox(width: 12),
                    Text('Kart boyutu (${_cardSizeOption.label})'),
                  ],
                ),
              ),
              PopupMenuItem<_SettingsAction>(
                value: _SettingsAction.theme,
                child: Row(
                  children: [
                    Icon(isDarkTheme ? Icons.light_mode : Icons.dark_mode),
                    const SizedBox(width: 12),
                    Text(isDarkTheme ? 'Açık Tema' : 'Koyu Tema'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<_SettingsAction>(
                value: _SettingsAction.clearCache,
                enabled: !_clearingCache,
                child: Row(
                  children: [
                    _clearingCache
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cleaning_services_outlined),
                    const SizedBox(width: 12),
                    Text(_clearingCache ? 'Temizleniyor...' : 'Cache temizle'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<_SettingsAction>(
                value: _SettingsAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text('Çıkış'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: _buildContent(context),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _showCreateDialog,
        tooltip: 'Yeni kayıt ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleProfile() {
    if (!mounted) return;
    final email = widget.api.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı e-postası bulunamadı.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ProfileInfoSheet(
          profileFuture: widget.api.getUser(email),
          email: email,
          department: widget.api.department,
        ),
      ),
    );
  }

  void _handleThemeToggle() {
    final controller = context.read<ThemeController>();
    controller.toggleTheme();
  }

  Future<void> _handleAdjustCardSize() async {
    final selected = await showDialog<CardSizeOption>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Kart Boyutu'),
          children: CardSizeOption.values
              .map(
                (option) => RadioListTile<CardSizeOption>(
                  title: Text(option.label),
                  subtitle: Text(option.description),
                  value: option,
                  groupValue: _cardSizeOption,
                  onChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
              )
              .toList(),
        );
      },
    );
    if (selected == null || selected == _cardSizeOption) return;
    setState(() {
      _cardSizeOption = selected;
    });
    await _userPreferences.saveCardSize(selected);
  }

  Future<void> _handleClearCache() async {
    final userId = widget.api.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı kimliği bulunamadı.')),
      );
      return;
    }
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Temizle'),
        content: const Text(
          'Kart sıralaması ve önbellekteki veriler temizlenecek. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (shouldClear != true) return;
    setState(() {
      _clearingCache = true;
    });
    try {
      await _orderCache.clear(userId: userId, isAdminView: false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cache temizlendi')));
      await _fetchEntries();
    } finally {
      if (mounted) {
        setState(() {
          _clearingCache = false;
        });
      }
    }
  }

  Future<void> _loadCardSizePreference() async {
    final option = await _userPreferences.loadCardSize();
    if (!mounted) return;
    setState(() {
      _cardSizeOption = option;
    });
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Text(
            _error!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else if (_entries.isEmpty)
          const Text('Henüz kayıtlı bir şifre bulunmuyor.')
        else
          PasswordHolderList(
            entries: _entries,
            resolveField: _resolveField,
            resolveIdentifier: _resolveIdentifier,
            onEdit: _showUpdateDialog,
            onDelete: _confirmAndDelete,
            onReorder: _handleReorder,
            canEditEntry: _canModifyEntry,
            canDeleteEntry: _canModifyEntry,
            cardSizeOption: _cardSizeOption,
          ),
      ],
    );
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? dialogError;
    bool submitting = false;

    Future<void> submit(void Function(void Function()) setDialogState) async {
      if (!formKey.currentState!.validate()) {
        return;
      }

      setDialogState(() {
        submitting = true;
        dialogError = null;
      });

      try {
        await _passwordHolderApi.createHolder(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        if (context.mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Kayıt oluşturuldu')));
        }
      } catch (e) {
        setDialogState(() {
          dialogError = e.toString();
          submitting = false;
        });
      }
    }

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Yeni Şifre Kaydı'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ad',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                          validator: validateName,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-posta / Kullanıcı Adı',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bu alan gerekli';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Şifre',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          keyboardType: TextInputType.text,
                          validator: validateFlexiblePassword,
                        ),
                        if (dialogError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            dialogError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('İptal'),
                  ),
                  FilledButton(
                    onPressed: submitting ? null : () => submit(setDialogState),
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kaydet'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == true) {
        await _fetchEntries();
      }
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
    }
  }

  String? _resolveField(Map<String, dynamic> data, List<String> possibleKeys) {
    for (final key in possibleKeys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  Future<void> _handleLogout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      await widget.api.logout();
      if (!mounted) return;
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loggingOut = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış işlemi sırasında hata: $e')),
        );
      }
    }
  }

  Future<void> _showUpdateDialog(Map<String, dynamic> entry) async {
    if (!_canModifyEntry(entry)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu kartı yalnızca admin düzenleyebilir.'),
          ),
        );
      }
      return;
    }
    final id = _resolveIdentifier(entry);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt kimliği bulunamadı.')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _SimpleHolderEditDialog(
        title: 'Kaydı Güncelle',
        initialName:
            _resolveField(entry, const [
              'name',
              'holder_title',
              'holderTitle',
              'title',
            ]) ??
            '',
        initialEmail:
            _resolveField(entry, const [
              'email',
              'holder_email',
              'holderEmail',
              'mail',
              'username',
            ]) ??
            '',
        initialPassword:
            _resolveField(entry, const [
              'password',
              'holder_password',
              'holderPassword',
              'secret',
            ]) ??
            '',
        onSubmit:
            ({
              required String name,
              required String email,
              required String password,
            }) async {
              await _passwordHolderApi.updateHolder(
                id: id,
                name: name,
                email: email,
                password: password,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kayıt güncellendi')),
              );
            },
      ),
    );

    if (result == true) {
      await _fetchEntries();
    }
  }

  bool _canModifyEntry(Map<String, dynamic> entry) {
    if (_isAdmin) {
      return true;
    }
    final controlValue = _parseInt(entry['control']);
    return controlValue == null || controlValue == 0;
  }

  Future<void> _confirmAndDelete(Map<String, dynamic> entry) async {
    if (!_canModifyEntry(entry)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu kartı yalnızca admin silebilir.')),
        );
      }
      return;
    }
    final id = _resolveIdentifier(entry);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt kimliği bulunamadı.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text('Bu kaydı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _passwordHolderApi.deleteHolder(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kayıt silindi')));
      await _fetchEntries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme başarısız: $e')));
    }
  }

  int? _resolveIdentifier(Map<String, dynamic> entry) {
    final possibleKeys = [
      'id',
      'holder_id',
      'holderId',
      'password_id',
      'passwordId',
      'identifier',
    ];
    for (final key in possibleKeys) {
      final value = entry[key];
      final parsed = _parseInt(value);
      if (parsed != null) {
        return parsed;
      }
    }
    // Fallback: look for numeric key named 'ID' case-insensitive
    for (final entryKey in entry.keys) {
      if (entryKey.toLowerCase().contains('id')) {
        final parsed = _parseInt(entry[entryKey]);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, item);
    });
    _persistCurrentOrder();
  }

  Future<List<Map<String, dynamic>>> _applyCachedOrder(
    List<Map<String, dynamic>> entries,
  ) async {
    final userId = widget.api.userId;
    if (userId == null) {
      return entries;
    }
    final savedOrder = await _orderCache.loadOrder(
      userId: userId,
      isAdminView: false,
    );
    if (savedOrder.isEmpty) {
      await _orderCache.saveOrder(
        userId: userId,
        isAdminView: false,
        order: _extractIds(entries),
      );
      return entries;
    }

    final savedSet = savedOrder.toSet();
    final Map<int, Map<String, dynamic>> savedEntries = {};
    final List<Map<String, dynamic>> newEntries = [];

    for (final entry in entries) {
      final id = _resolveIdentifier(entry);
      if (id != null && savedSet.contains(id)) {
        savedEntries[id] = entry;
      } else {
        newEntries.add(entry);
      }
    }

    final ordered = <Map<String, dynamic>>[];
    ordered.addAll(newEntries);

    final keptSavedIds = <int>[];
    for (final id in savedOrder) {
      final entry = savedEntries[id];
      if (entry != null) {
        ordered.add(entry);
        keptSavedIds.add(id);
      }
    }

    await _orderCache.saveOrder(
      userId: userId,
      isAdminView: false,
      order: [..._extractIds(newEntries), ...keptSavedIds],
    );
    return ordered;
  }

  Future<void> _persistCurrentOrder() async {
    final userId = widget.api.userId;
    if (userId == null) {
      return;
    }
    final order = _extractIds(_entries);
    if (order.isEmpty) {
      return;
    }
    await _orderCache.saveOrder(
      userId: userId,
      isAdminView: false,
      order: order,
    );
  }

  List<int> _extractIds(List<Map<String, dynamic>> entries) =>
      entries.map(_resolveIdentifier).whereType<int>().toList();
}

typedef _SimpleEditSubmit =
    Future<void> Function({
      required String name,
      required String email,
      required String password,
    });

class _SimpleHolderEditDialog extends StatefulWidget {
  const _SimpleHolderEditDialog({
    required this.title,
    required this.initialName,
    required this.initialEmail,
    required this.initialPassword,
    required this.onSubmit,
  });

  final String title;
  final String initialName;
  final String initialEmail;
  final String initialPassword;
  final _SimpleEditSubmit onSubmit;

  @override
  State<_SimpleHolderEditDialog> createState() =>
      _SimpleHolderEditDialogState();
}

class _SimpleHolderEditDialogState extends State<_SimpleHolderEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _dialogError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController(text: widget.initialPassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _dialogError = null;
    });

    try {
      await widget.onSubmit(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dialogError = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                validator: validateName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta / Kullanıcı Adı',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bu alan gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                keyboardType: TextInputType.text,
                validator: validateFlexiblePassword,
              ),
              if (_dialogError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _dialogError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _handleSubmit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
