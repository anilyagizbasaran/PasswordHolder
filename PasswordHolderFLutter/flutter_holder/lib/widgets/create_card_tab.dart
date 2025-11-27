import 'package:flutter/material.dart';

import '../utils/user_validators.dart';
import 'user_assignment_field.dart';

class CreateCardTab extends StatelessWidget {
  const CreateCardTab({
    super.key,
    required this.usersLoading,
    required this.usersError,
    required this.users,
    required this.onFetchUsers,
    required this.onNavigateToCreateUser,
    required this.formKey,
    required this.titleController,
    required this.emailController,
    required this.passwordController,
    required this.submitting,
    required this.submitError,
    required this.canAssignMultiple,
    required this.selectedUserIds,
    required this.onSelectUsers,
    required this.onSubmitCard,
    required this.departments,
    required this.departmentsLoading,
    required this.selectedDepartmentId,
    required this.onSelectDepartment,
  });

  final bool usersLoading;
  final String? usersError;
  final List<Map<String, dynamic>> users;
  final Future<void> Function() onFetchUsers;
  final VoidCallback onNavigateToCreateUser;
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool submitting;
  final String? submitError;
  final bool canAssignMultiple;
  final Set<int> selectedUserIds;
  final void Function(Set<int>) onSelectUsers;
  final Future<void> Function() onSubmitCard;
  final List<Map<String, dynamic>> departments;
  final bool departmentsLoading;
  final int? selectedDepartmentId;
  final void Function(int?) onSelectDepartment;

  @override
  Widget build(BuildContext context) {
    if (usersLoading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (usersError != null && users.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              usersError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: usersLoading ? null : () => onFetchUsers(),
              child: const Text('Kullanıcıları Yenile'),
            ),
          ],
        ),
      );
    }
    if (users.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Şifre kartı ekleyebilmek için önce kullanıcı oluşturmanız gerekiyor.',
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onNavigateToCreateUser,
              child: const Text('Kullanıcı Oluştur'),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Yeni Şifre Kartı Oluştur',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _buildDepartmentSelector(),
                    const SizedBox(height: 16),
                    if (selectedDepartmentId != null) ...[
                      Text(
                        'Seçilen departmandaki tüm kullanıcılar bu karta erişebilecek.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    AbsorbPointer(
                      absorbing: selectedDepartmentId != null,
                      child: Opacity(
                        opacity: selectedDepartmentId != null ? 0.6 : 1,
                        child: UserAssignmentField(
                          users: users,
                          selectedUserIds: selectedUserIds,
                          canSelectMultiple: canAssignMultiple,
                          onSelectionChanged: onSelectUsers,
                          validator: (selection) {
                            if (selectedDepartmentId != null) {
                              return null;
                            }
                            if (users.isEmpty) {
                              return 'Önce kullanıcı oluşturun';
                            }
                            if (selection == null || selection.isEmpty) {
                              return canAssignMultiple
                                  ? 'En az bir kullanıcı seçin'
                                  : 'Bir kullanıcı seçin';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Kart Adı',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                      validator: validateName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı Adı / E-posta',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Şifre',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                      validator: validateFlexiblePassword,
                    ),
                    if (submitError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        submitError!,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: submitting ? null : () => onSubmitCard(),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kartı Oluştur'),
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

  Widget _buildDepartmentSelector() {
    return DropdownButtonFormField<int?>(
      value: selectedDepartmentId,
      decoration: const InputDecoration(
        labelText: 'Departman (opsiyonel)',
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Departman seçme'),
        ),
        ...departments.map((dept) {
          final id = _parseInt(dept['id']);
          if (id == null) {
            return null;
          }
          final name = (dept['name'] ?? 'Departman').toString();
          return DropdownMenuItem<int?>(value: id, child: Text(name));
        }).whereType<DropdownMenuItem<int?>>(),
      ],
      onChanged: departmentsLoading ? null : onSelectDepartment,
    );
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
