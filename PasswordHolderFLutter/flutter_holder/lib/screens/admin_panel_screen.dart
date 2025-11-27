import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../controllers/create_card_controller.dart';
import '../controllers/password_holders_controller.dart';
import '../controllers/register_user_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/department_api.dart';
import '../services/holder_order_cache.dart';
import '../services/password_holder_api.dart';
import '../services/user_api.dart';
import '../services/user_preferences.dart';
import '../utils/backend_config.dart';
import '../utils/card_size_option.dart';
import '../utils/user_validators.dart';
import '../widgets/create_card_tab.dart';
import '../widgets/user_assignment_field.dart';
import '../widgets/profile_info_sheet.dart';
import 'admin_panel/password_holders_tab.dart';
import 'admin_panel/register_user_tab.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key, required this.api});

  final UserApi api;

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

enum _AdminSettingsAction { profile, cardSize, theme, clearCache, logout }

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static const List<String> _holderEmailKeys = [
    'email',
    'holder_email',
    'holderEmail',
    'mail',
    'username',
  ];
  static const List<String> _holderOwnerKeys = [
    'ownerName',
    'assigned_to',
    'assignedTo',
    'user_name',
    'owner_name',
  ];
  static const List<String> _holderDepartmentKeys = [
    'department',
    'department_name',
    'departmentName',
  ];
  late final PasswordHolderApi _passwordHolderApi;
  late final DepartmentApi _departmentApi;
  final UserPreferences _userPreferences = UserPreferences.instance;

  bool _loggingOut = false;
  int _selectedIndex = 0;
  bool _clearingCache = false;
  CardSizeOption _cardSizeOption = CardSizeOption.normal;

  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();
  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _cardFormKey = GlobalKey<FormState>();
  final TextEditingController _cardTitleController = TextEditingController();
  final TextEditingController _cardEmailController = TextEditingController();
  final TextEditingController _cardPasswordController = TextEditingController();
  final GlobalKey<FormState> _departmentFormKey = GlobalKey<FormState>();
  final TextEditingController _departmentNameController =
      TextEditingController();
  final TextEditingController _holderSearchController = TextEditingController();
  String _holderSearchTerm = '';
  String? _currentUserEmail;
  int? _currentUserId;
  late final RegisterUserController _registerController;
  late final CreateCardController _createCardController;
  late final PasswordHoldersController _holdersController;

  bool get _isAdmin => (widget.api.department ?? '').toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _passwordHolderApi = PasswordHolderApi(
      client: widget.api.client,
      baseUrl: resolvePasswordHolderBaseUrl(),
    );
    _passwordHolderApi.attachBearerToken(widget.api.jwtToken);
    _departmentApi = DepartmentApi(
      client: widget.api.client,
      baseUrl: resolveDepartmentBaseUrl(),
    );
    _departmentApi.attachBearerToken(widget.api.jwtToken);
    _currentUserEmail = widget.api.email?.toLowerCase();
    _currentUserId = widget.api.userId;
    _holdersController = PasswordHoldersController(
      passwordHolderApi: _passwordHolderApi,
      orderCache: HolderOrderCache.instance,
      currentUserId: _currentUserId,
      isAdminView: true,
    )..addListener(_handleHoldersControllerChanged);
    _registerController = RegisterUserController(
      userApi: widget.api,
      departmentApi: _departmentApi,
      onShowMessage: _showSnack,
      isAdmin: _isAdmin,
      currentUserId: _currentUserId,
      onUsersUpdated: _handleUsersUpdated,
    )..addListener(_handleRegisterControllerChanged);
    _createCardController = CreateCardController(
      passwordHolderApi: _passwordHolderApi,
      onRefreshHolders: _fetchHolders,
      onShowMessage: _showSnack,
      currentUserId: _currentUserId,
      currentUserEmail: _currentUserEmail,
      usersProvider: () => _registerController.users,
    )..addListener(_handleCreateCardControllerChanged);
    _fetchHolders();
    _registerController.fetchUsers();
    _registerController.fetchDepartments();
    _loadCardSizePreference();
  }

  Future<void> _fetchHolders() => _holdersController.fetchHolders();

  void _handleHoldersControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleRegisterControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleCreateCardControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleUsersUpdated(List<Map<String, dynamic>> users) {
    if (!mounted) return;
    _createCardController.retainValidSelections(users);
  }

  Future<void> _handleLogout() async {
    if (_loggingOut) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      await widget.api.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loggingOut = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış işlemi sırasında hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final bool isDarkTheme = themeController.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_selectedIndex) {
          0 => 'Yönetici Paneli',
          1 => 'Yeni Şifre Kartı',
          _ => 'Kullanıcı Kaydı',
        }),
        actions: [
          PopupMenuButton<_AdminSettingsAction>(
            enabled: !_loggingOut,
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
                case _AdminSettingsAction.cardSize:
                  _handleAdjustCardSize();
                  break;
                case _AdminSettingsAction.profile:
                  _handleProfileTap();
                  break;
                case _AdminSettingsAction.theme:
                  _handleThemeToggle();
                  break;
                case _AdminSettingsAction.clearCache:
                  _handleClearCache();
                  break;
                case _AdminSettingsAction.logout:
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<_AdminSettingsAction>(
                value: _AdminSettingsAction.profile,
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('Profil'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<_AdminSettingsAction>(
                value: _AdminSettingsAction.cardSize,
                child: Row(
                  children: [
                    const Icon(Icons.view_agenda_outlined),
                    const SizedBox(width: 12),
                    Text('Kart boyutu (${_cardSizeOption.label})'),
                  ],
                ),
              ),
              PopupMenuItem<_AdminSettingsAction>(
                value: _AdminSettingsAction.theme,
                child: Row(
                  children: [
                    Icon(isDarkTheme ? Icons.light_mode : Icons.dark_mode),
                    const SizedBox(width: 12),
                    Text(isDarkTheme ? 'Açık Tema' : 'Koyu Tema'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<_AdminSettingsAction>(
                value: _AdminSettingsAction.clearCache,
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
              const PopupMenuItem<_AdminSettingsAction>(
                value: _AdminSettingsAction.logout,
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
      body: SafeArea(child: _buildContent(context)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _handleTabSelection,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Kayıtlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            activeIcon: Icon(Icons.credit_card),
            label: 'Yeni Kart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_outlined),
            activeIcon: Icon(Icons.person_add),
            label: 'Kullanıcı Ekle',
          ),
        ],
      ),
    );
  }

  void _handleProfileTap() {
    if (!mounted) return;
    final email = widget.api.email ?? _currentUserEmail;
    if (email == null || email.isEmpty) {
      _showSnack('Kullanıcı e-postası bulunamadı.');
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
      builder: (context) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kart Boyutu'),
        children: CardSizeOption.values
            .map(
              (option) => RadioListTile<CardSizeOption>(
                title: Text(option.label),
                subtitle: Text(option.description),
                value: option,
                groupValue: _cardSizeOption,
                onChanged: (value) => Navigator.of(context).pop(value),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || selected == _cardSizeOption) return;
    setState(() {
      _cardSizeOption = selected;
    });
    await _userPreferences.saveCardSize(selected);
  }

  Future<void> _handleClearCache() async {
    final userId = _currentUserId;
    if (userId == null) {
      _showSnack('Kullanıcı kimliği bulunamadı.');
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
      await HolderOrderCache.instance.clear(userId: userId, isAdminView: true);
      if (!mounted) return;
      _showSnack('Cache temizlendi.');
      await _fetchHolders();
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

  bool get _isHolderSearchActive => _holderSearchTerm.trim().isNotEmpty;

  List<Map<String, dynamic>> get _filteredHolders {
    final term = _holderSearchTerm.trim().toLowerCase();
    final holders = _holdersController.holders;
    if (term.isEmpty) {
      return holders;
    }
    return holders.where((entry) {
      final name = _holdersController
          .resolveHolderBaseName(entry)
          .toLowerCase();
      final email =
          (_holdersController.resolveField(entry, _holderEmailKeys) ?? '')
              .toLowerCase();
      final owner =
          (_holdersController.resolveField(entry, _holderOwnerKeys) ?? '')
              .toLowerCase();
      final department =
          (_holdersController.resolveField(entry, _holderDepartmentKeys) ?? '')
              .toLowerCase();
      return name.contains(term) ||
          email.contains(term) ||
          owner.contains(term) ||
          department.contains(term);
    }).toList();
  }

  void _handleHolderSearchChanged(String value) {
    setState(() {
      _holderSearchTerm = value;
    });
  }

  void _clearHolderSearch() {
    if (_holderSearchTerm.isEmpty) {
      return;
    }
    _holderSearchController.clear();
    setState(() {
      _holderSearchTerm = '';
    });
  }

  Widget _buildContent(BuildContext context) {
    return switch (_selectedIndex) {
      0 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: TextField(
              controller: _holderSearchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Kart, kullanıcı veya departman ara',
                border: const OutlineInputBorder(),
                suffixIcon: _isHolderSearchActive
                    ? IconButton(
                        tooltip: 'Aramayı temizle',
                        onPressed: _clearHolderSearch,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: _handleHolderSearchChanged,
            ),
          ),
          Expanded(
            child: PasswordHoldersTab(
              loading: _holdersController.loading,
              error: _holdersController.error,
              holders: _filteredHolders,
              onRefresh: _fetchHolders,
              onResolveField: _holdersController.resolveField,
              onResolveIdentifier: _holdersController.resolveIdentifier,
              onEditHolder: _handleEditHolder,
              onDeleteHolder: _handleDeleteHolder,
              onReorder: _holdersController.reorderHolders,
              cardSizeOption: _cardSizeOption,
              hasAnyHolder: _holdersController.holders.isNotEmpty,
              isSearching: _isHolderSearchActive,
              allowReorder: !_isHolderSearchActive,
            ),
          ),
        ],
      ),
      1 => CreateCardTab(
        usersLoading: _registerController.usersLoading,
        usersError: _registerController.usersError,
        users: _registerController.users,
        onFetchUsers: _registerController.fetchUsers,
        onNavigateToCreateUser: () => _handleTabSelection(2),
        formKey: _cardFormKey,
        titleController: _cardTitleController,
        emailController: _cardEmailController,
        passwordController: _cardPasswordController,
        submitting: _createCardController.submitting,
        submitError: _createCardController.submitError,
        canAssignMultiple: _isAdmin,
        selectedUserIds: _createCardController.selectedUserIds,
        onSelectUsers: _createCardController.setSelectedUsers,
        onSubmitCard: _handleSubmitCard,
        departments: _registerController.departments,
        departmentsLoading: _registerController.departmentsLoading,
        selectedDepartmentId: _createCardController.selectedDepartmentId,
        onSelectDepartment: (value) {
          _createCardController.setDepartment(value);
        },
      ),
      _ => RegisterUserTab(
        controller: _registerController,
        canManageDepartments: _isAdmin,
        registerFormKey: _registerFormKey,
        registerNameController: _registerNameController,
        registerEmailController: _registerEmailController,
        registerPasswordController: _registerPasswordController,
        onSubmitRegister: _handleSubmitRegister,
        onRefreshUsers: _registerController.fetchUsers,
        onDeleteUser: (id, {required name}) =>
            _handleDeleteUser(id, name: name),
        onRefreshDepartments: _registerController.fetchDepartments,
        departmentFormKey: _departmentFormKey,
        departmentNameController: _departmentNameController,
        onSubmitDepartment: _handleSubmitDepartment,
        onDeleteDepartment: (id, {name}) =>
            _handleDeleteDepartment(id, name: name),
        onShowMessage: _showSnack,
        currentUserId: _currentUserId,
      ),
    };
  }

  Future<void> _handleEditHolder(Map<String, dynamic> entry) async {
    final id = _holdersController.resolveIdentifier(entry);
    if (id == null) {
      _showSnack('Bu kaydın kimliği çözümlenemedi. Lütfen sayfayı yenileyin.');
      return;
    }

    if (_registerController.users.isEmpty &&
        !_registerController.usersLoading) {
      await _registerController.fetchUsers();
    }

    final bool? updated = await showDialog<bool>(
      context: context,
      builder: (context) => _EditHolderDialog(
        users: _registerController.users,
        canAssignMultiple: _isAdmin,
        initialName: _holdersController.resolveHolderBaseName(entry),
        initialEmail:
            _holdersController.resolveField(entry, const [
              'email',
              'holder_email',
              'holderEmail',
              'username',
            ]) ??
            '',
        initialPassword:
            _holdersController.resolveField(entry, const [
              'password',
              'holder_password',
              'holderPassword',
              'secret',
            ]) ??
            '',
        initialUserIds: _holdersController.resolveEntryUserIds(entry),
        onSubmit:
            ({
              required String name,
              required String email,
              required String password,
              required Set<int> userIds,
            }) async {
              await _holdersController.updateHolder(
                id: id,
                name: name,
                email: email,
                password: password,
                userIds: userIds.toList(),
              );
            },
      ),
    );

    if (updated == true) {
      _showSnack('Kayıt başarıyla güncellendi.');
      await _fetchHolders();
    }
  }

  Future<void> _handleDeleteHolder(Map<String, dynamic> entry) async {
    final id = _holdersController.resolveIdentifier(entry);
    if (id == null) {
      _showSnack('Bu kaydın kimliği çözümlenemedi. Lütfen sayfayı yenileyin.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text(
          'Bu şifre kartını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      await _holdersController.deleteHolder(id);
      _showSnack('Kayıt silindi.');
      await _fetchHolders();
    } catch (e) {
      _showSnack('Kayıt silinirken hata oluştu: $e');
    }
  }

  Future<void> _handleSubmitCard() async {
    if (!_cardFormKey.currentState!.validate()) {
      return;
    }
    final success = await _createCardController.submit(
      name: _cardTitleController.text,
      email: _cardEmailController.text,
      password: _cardPasswordController.text,
    );
    if (!success || !mounted) {
      return;
    }
    _cardTitleController.clear();
    _cardEmailController.clear();
    _cardPasswordController.clear();
    _createCardController.clearDepartmentSelection();
    _createCardController.clearSelection();
  }

  void _handleTabSelection(int value) {
    if (value == _selectedIndex) {
      if (value == 0 &&
          !_holdersController.loading &&
          _holdersController.holders.isEmpty) {
        _fetchHolders();
      }
      if (value == 1 &&
          !_registerController.departmentsLoading &&
          _registerController.departments.isEmpty) {
        _registerController.fetchDepartments();
      }
      if (value == 1 &&
          !_registerController.usersLoading &&
          _registerController.users.isEmpty) {
        _registerController.fetchUsers();
      }
      if (value == 2 &&
          !_registerController.departmentsLoading &&
          _registerController.departments.isEmpty) {
        _registerController.fetchDepartments();
      }
      return;
    }
    setState(() {
      _selectedIndex = value;
      if (value == 1) {
        _createCardController.clearDepartmentSelection();
        _createCardController.clearSelection();
      }
    });
    if (value == 0 &&
        !_holdersController.loading &&
        _holdersController.holders.isEmpty) {
      _fetchHolders();
    }
    if (value == 1 &&
        !_registerController.departmentsLoading &&
        _registerController.departments.isEmpty) {
      _registerController.fetchDepartments();
    }
    if (value == 1 &&
        !_registerController.usersLoading &&
        _registerController.users.isEmpty) {
      _registerController.fetchUsers();
    }
    if (value == 2 &&
        !_registerController.departmentsLoading &&
        _registerController.departments.isEmpty) {
      _registerController.fetchDepartments();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSubmitRegister() async {
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }
    final success = await _registerController.submitRegister(
      name: _registerNameController.text.trim(),
      email: _registerEmailController.text,
      password: _registerPasswordController.text,
    );
    if (!success || !mounted) {
      return;
    }
    _registerFormKey.currentState?.reset();
    _registerNameController.clear();
    _registerEmailController.clear();
    _registerPasswordController.clear();
    _registerController.selectDepartment(null);
  }

  Future<void> _handleSubmitDepartment() async {
    if (!_departmentFormKey.currentState!.validate()) {
      return;
    }
    final success = await _registerController.submitDepartment(
      _departmentNameController.text.trim(),
    );
    if (!success) {
      return;
    }
    _departmentFormKey.currentState?.reset();
    _departmentNameController.clear();
  }

  Future<void> _handleDeleteDepartment(int id, {String? name}) async {
    if ((name ?? '').trim().toLowerCase() == 'admin') {
      _showSnack('Admin departmanı silinemez.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Departmanı Sil'),
        content: const Text(
          'Bu departmanı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    await _registerController.deleteDepartment(id);
  }

  Future<void> _handleDeleteUser(int id, {required String? name}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text(
          name != null && name.isNotEmpty
              ? '"$name" kullanıcısını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'
              : 'Bu kullanıcıyı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    final success = await _registerController.deleteUser(id, name: name);
    if (success && mounted) {
      _createCardController.retainValidSelections(_registerController.users);
      await _fetchHolders();
    }
  }

  @override
  void dispose() {
    _holdersController.removeListener(_handleHoldersControllerChanged);
    _holdersController.dispose();
    _createCardController.removeListener(_handleCreateCardControllerChanged);
    _createCardController.dispose();
    _registerController.removeListener(_handleRegisterControllerChanged);
    _registerController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _cardTitleController.dispose();
    _cardEmailController.dispose();
    _cardPasswordController.dispose();
    _departmentNameController.dispose();
    _holderSearchController.dispose();
    super.dispose();
  }
}

typedef _EditHolderSubmit =
    Future<void> Function({
      required String name,
      required String email,
      required String password,
      required Set<int> userIds,
    });

class _EditHolderDialog extends StatefulWidget {
  const _EditHolderDialog({
    required this.users,
    required this.canAssignMultiple,
    required this.initialName,
    required this.initialEmail,
    required this.initialPassword,
    required this.initialUserIds,
    required this.onSubmit,
  });

  final List<Map<String, dynamic>> users;
  final bool canAssignMultiple;
  final String initialName;
  final String initialEmail;
  final String initialPassword;
  final Set<int> initialUserIds;
  final _EditHolderSubmit onSubmit;

  @override
  State<_EditHolderDialog> createState() => _EditHolderDialogState();
}

class _EditHolderDialogState extends State<_EditHolderDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late Set<int> _selectedUserIds;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _dialogError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController(text: widget.initialPassword);
    _selectedUserIds = Set<int>.from(widget.initialUserIds);
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
        userIds: _selectedUserIds,
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
      title: const Text('Kayıt Düzenle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAssignmentField(
                users: widget.users,
                selectedUserIds: _selectedUserIds,
                canSelectMultiple: widget.canAssignMultiple,
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedUserIds = Set<int>.from(selection);
                  });
                },
                validator: (selection) {
                  if (widget.users.isEmpty) {
                    return 'Önce kullanıcı oluşturun';
                  }
                  if (selection == null || selection.isEmpty) {
                    return widget.canAssignMultiple
                        ? 'En az bir kullanıcı seçin'
                        : 'Bir kullanıcı seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Kart Adı',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                validator: validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı / E-posta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
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
