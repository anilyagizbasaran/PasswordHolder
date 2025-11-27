import 'package:flutter/material.dart';

import '../../controllers/register_user_controller.dart';
import '../../utils/user_validators.dart';

class RegisterUserTab extends StatefulWidget {
  const RegisterUserTab({
    super.key,
    required this.controller,
    required this.canManageDepartments,
    required this.registerFormKey,
    required this.registerNameController,
    required this.registerEmailController,
    required this.registerPasswordController,
    required this.onSubmitRegister,
    required this.onRefreshUsers,
    required this.onDeleteUser,
    required this.onRefreshDepartments,
    required this.departmentFormKey,
    required this.departmentNameController,
    required this.onSubmitDepartment,
    required this.onDeleteDepartment,
    required this.onShowMessage,
    this.currentUserId,
  });

  final RegisterUserController controller;
  final bool canManageDepartments;
  final GlobalKey<FormState> registerFormKey;
  final TextEditingController registerNameController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPasswordController;
  final VoidCallback onSubmitRegister;

  final Future<void> Function() onRefreshUsers;
  final Future<void> Function(int id, {required String? name}) onDeleteUser;

  final Future<void> Function() onRefreshDepartments;

  final GlobalKey<FormState> departmentFormKey;
  final TextEditingController departmentNameController;
  final Future<void> Function() onSubmitDepartment;
  final Future<void> Function(int id, {String? name}) onDeleteDepartment;
  final void Function(String message) onShowMessage;
  final int? currentUserId;

  @override
  State<RegisterUserTab> createState() => _RegisterUserTabState();
}

class _RegisterUserTabState extends State<RegisterUserTab> {
  String _userSearchTerm = '';
  String _departmentSearchTerm = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = widget.controller.users;
    final usersLoading = widget.controller.usersLoading;
    final usersError = widget.controller.usersError;
    final registerSubmitting = widget.controller.registerSubmitting;
    final registerError = widget.controller.registerError;
    final departments = widget.controller.departments;
    final departmentsLoading = widget.controller.departmentsLoading;
    final departmentsError = widget.controller.departmentsError;
    final selectedDepartmentId = widget.controller.selectedDepartmentId;
    final departmentSubmitting = widget.controller.departmentSubmitting;
    final canManageDepartments = widget.canManageDepartments;
    final currentUserId = widget.currentUserId;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: widget.registerFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Yeni Kullanıcı Kaydı',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: widget.registerNameController,
                      decoration: const InputDecoration(
                        labelText: 'İsim',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                      validator: validateName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: widget.registerEmailController,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: widget.registerPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Şifre',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.text,
                      validator: validatePassword,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedDepartmentId,
                      decoration: const InputDecoration(
                        labelText: 'Departman',
                        border: OutlineInputBorder(),
                      ),
                      items: departments
                          .map((dept) {
                            final id = _parseInt(dept['id']);
                            if (id == null) {
                              return null;
                            }
                            final name = (dept['name'] ?? 'Departman')
                                .toString();
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(name),
                            );
                          })
                          .whereType<DropdownMenuItem<int>>()
                          .toList(),
                      onChanged: departmentsLoading
                          ? null
                          : (value) =>
                                widget.controller.selectDepartment(value),
                      validator: (value) {
                        if (departmentsLoading) {
                          return 'Departmanlar yükleniyor, lütfen bekleyin';
                        }
                        if (departments.isEmpty) {
                          return 'Önce departman oluşturmanız gerekiyor';
                        }
                        if (value == null) {
                          return 'Bir departman seçin';
                        }
                        return null;
                      },
                    ),
                    if (registerError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        registerError,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: registerSubmitting
                          ? null
                          : widget.onSubmitRegister,
                      child: registerSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kullanıcı Oluştur'),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        initiallyExpanded: false,
                        title: Text(
                          'Kullanıcı Listesi',
                          style: theme.textTheme.titleMedium,
                        ),
                        children: [
                          const SizedBox(height: 12),
                          if (!canManageDepartments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Kullanıcı silme işlemi yalnızca yöneticiler tarafından yapılabilir.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          if (usersLoading && users.isEmpty)
                            const Center(child: CircularProgressIndicator()),
                          if (usersError != null) ...[
                            Text(
                              usersError,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: usersLoading
                                  ? null
                                  : widget.onRefreshUsers,
                              child: const Text('Kullanıcıları Yenile'),
                            ),
                          ],
                          if (!usersLoading && users.isEmpty)
                            const Text('Henüz kullanıcı bulunmuyor.'),
                          if (users.isNotEmpty) ...[
                            TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Kullanıcı ara',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _userSearchTerm = value.trim().toLowerCase();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(height: 8),
                          ],
                          if (!usersLoading &&
                              users.isNotEmpty &&
                              _filteredUsers(users).isEmpty)
                            const Text('Aramaya uygun kullanıcı bulunamadı.'),
                          ..._filteredUsers(users).map((user) {
                            final int? id = _parseInt(user['id']);
                            final name = (user['name'] ?? 'Kullanıcı')
                                .toString();
                            final email = (user['email'] ?? '').toString();
                            final departmentName =
                                (user['departmentName'] ?? '').toString();
                            if (id == null) {
                              return const SizedBox.shrink();
                            }
                            final isSelf =
                                currentUserId != null && id == currentUserId;
                            final canDeleteUser =
                                canManageDepartments && !isSelf;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                title: Text(name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (email.isNotEmpty) Text(email),
                                    if (departmentName.isNotEmpty)
                                      Text(
                                        departmentName,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    if (isSelf)
                                      Text(
                                        'Kendi hesabınız',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: theme.colorScheme.error,
                                  onPressed: canDeleteUser
                                      ? () =>
                                            widget.onDeleteUser(id, name: name)
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        initiallyExpanded: false,
                        title: Text(
                          'Departman Yönetimi',
                          style: theme.textTheme.titleMedium,
                        ),
                        children: [
                          const SizedBox(height: 12),
                          if (!canManageDepartments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Departman ekleme ve silme yetkisi yalnızca yöneticilerde bulunur.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          if (departmentsLoading && departments.isEmpty)
                            const Center(child: CircularProgressIndicator()),
                          if (departmentsError != null) ...[
                            Text(
                              departmentsError,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: departmentsLoading
                                  ? null
                                  : () {
                                      widget.onRefreshDepartments();
                                    },
                              child: const Text('Departmanları Yenile'),
                            ),
                          ],
                          if (!departmentsLoading && departments.isEmpty)
                            const Text('Henüz departman oluşturulmamış.'),
                          const SizedBox(height: 12),
                          if (canManageDepartments) ...[
                            Form(
                              key: widget.departmentFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: widget.departmentNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Departman Adı',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.text,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Departman adı gerekli';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: departmentSubmitting
                                        ? null
                                        : () {
                                            if (widget
                                                    .departmentFormKey
                                                    .currentState
                                                    ?.validate() ??
                                                false) {
                                              widget.onSubmitDepartment();
                                            }
                                          },
                                    child: departmentSubmitting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Departman Ekle'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (departments.isNotEmpty) ...[
                            TextField(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Departman ara',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _departmentSearchTerm = value
                                      .trim()
                                      .toLowerCase();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (departments.isNotEmpty &&
                              _departmentSearchTerm.isNotEmpty &&
                              _filteredDepartments(departments).isEmpty)
                            const Text('Aradığınız departman bulunamadı.'),
                          ..._filteredDepartments(departments).map((dept) {
                            final id = _parseInt(dept['id']);
                            final name = (dept['name'] ?? 'Departman')
                                .toString();
                            final isProtected =
                                name.trim().toLowerCase() == 'admin';
                            final isSelected =
                                id != null && selectedDepartmentId == id;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: isSelected
                                  ? theme.colorScheme.surfaceVariant
                                  : null,
                              child: ListTile(
                                title: Text(name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: theme.colorScheme.error,
                                  onPressed:
                                      id == null ||
                                          !canManageDepartments ||
                                          isProtected
                                      ? null
                                      : () => widget.onDeleteDepartment(
                                          id,
                                          name: name,
                                        ),
                                ),
                                onTap: id == null
                                    ? null
                                    : () {
                                        widget.controller.selectDepartment(id);
                                        widget.onShowMessage(
                                          '"$name" departmanı kullanıcı kaydında seçildi.',
                                        );
                                      },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filteredUsers(List<Map<String, dynamic>> users) {
    if (_userSearchTerm.isEmpty) {
      return users;
    }
    return users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final department = (user['departmentName'] ?? '')
          .toString()
          .toLowerCase();
      final term = _userSearchTerm;
      return name.contains(term) ||
          email.contains(term) ||
          department.contains(term);
    }).toList();
  }

  List<Map<String, dynamic>> _filteredDepartments(
    List<Map<String, dynamic>> departments,
  ) {
    if (_departmentSearchTerm.isEmpty) {
      return departments;
    }
    final term = _departmentSearchTerm;
    return departments.where((dept) {
      final name = (dept['name'] ?? '').toString().toLowerCase();
      final description = (dept['description'] ?? '').toString().toLowerCase();
      return name.contains(term) || description.contains(term);
    }).toList();
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
