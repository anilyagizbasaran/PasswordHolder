import 'package:flutter/foundation.dart';

import '../services/password_holder_api.dart';

class CreateCardController extends ChangeNotifier {
  CreateCardController({
    required this.passwordHolderApi,
    required this.onRefreshHolders,
    required this.onShowMessage,
    required this.currentUserId,
    required this.currentUserEmail,
    required this.usersProvider,
  });

  final PasswordHolderApi passwordHolderApi;
  final Future<void> Function() onRefreshHolders;
  final void Function(String message) onShowMessage;
  final int? currentUserId;
  final String? currentUserEmail;
  final List<Map<String, dynamic>> Function() usersProvider;

  final Set<int> _selectedUserIds = <int>{};
  int? selectedDepartmentId;
  bool submitting = false;
  String? submitError;

  Set<int> get selectedUserIds => Set.unmodifiable(_selectedUserIds);

  void setSelectedUsers(Set<int> selection) {
    if (selectedDepartmentId != null) {
      return;
    }
    _selectedUserIds
      ..clear()
      ..addAll(selection);
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedUserIds.isEmpty) {
      return;
    }
    _selectedUserIds.clear();
    notifyListeners();
  }

  void clearDepartmentSelection() {
    if (selectedDepartmentId == null) {
      return;
    }
    selectedDepartmentId = null;
    notifyListeners();
  }

  void setDepartment(int? departmentId) {
    if (selectedDepartmentId == departmentId) {
      return;
    }
    selectedDepartmentId = departmentId;
    if (departmentId != null) {
      final departmentUserIds = _userIdsForDepartment(
        departmentId,
        usersProvider(),
      ).toList();
      _selectedUserIds
        ..clear()
        ..addAll(departmentUserIds);
      notifyListeners();
      return;
    }
    _selectedUserIds.clear();
    notifyListeners();
  }

  void retainValidSelections(List<Map<String, dynamic>> users) {
    if (selectedDepartmentId != null) {
      final deptUserIds =
          _userIdsForDepartment(selectedDepartmentId!, users).toSet();
      final current = Set<int>.from(_selectedUserIds);
      final changed =
          current.length != deptUserIds.length ||
              current.any((id) => !deptUserIds.contains(id));
      if (changed) {
        _selectedUserIds
          ..clear()
          ..addAll(deptUserIds);
        notifyListeners();
      }
      return;
    }
    final validIds = users.map((user) => user['id']).whereType<int>().toSet();
    final previousLength = _selectedUserIds.length;
    _selectedUserIds.removeWhere(
      (id) => !validIds.contains(id),
    );
    if (_selectedUserIds.length != previousLength) {
      notifyListeners();
    }
  }

  Future<bool> submit({
    required String name,
    required String email,
    required String password,
  }) async {
    submitError = null;
    final bool usingDepartment = selectedDepartmentId != null;
    List<int> targetUserIds = _selectedUserIds.toList();
    if (!usingDepartment && targetUserIds.isEmpty && currentUserId != null) {
      targetUserIds = [currentUserId!];
    }
    if (!usingDepartment && targetUserIds.isEmpty && currentUserEmail != null) {
      final fallback = usersProvider().firstWhere(
        (user) =>
            (user['email'] as String?)?.toLowerCase() == currentUserEmail,
        orElse: () => {},
      );
      final fallbackId = fallback['id'];
      if (fallbackId is int) {
        targetUserIds = [fallbackId];
      }
    }
    targetUserIds = targetUserIds.whereType<int>().toSet().toList();
    if (!usingDepartment && targetUserIds.isEmpty) {
      submitError = 'Lütfen kart için bir kullanıcı seçin.';
      notifyListeners();
      return false;
    }

    submitting = true;
    notifyListeners();
    try {
      await passwordHolderApi.createHolder(
        name: name.trim(),
        email: email.trim(),
        password: password,
        userIds: usingDepartment ? null : targetUserIds,
        departmentId: selectedDepartmentId,
      );
      onShowMessage('Şifre kartı başarıyla oluşturuldu');
      await onRefreshHolders();
      return true;
    } catch (e) {
      submitError = e.toString();
      return false;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  Iterable<int> _userIdsForDepartment(
    int departmentId,
    List<Map<String, dynamic>> users,
  ) sync* {
    for (final user in users) {
      final deptId = user['departmentId'];
      final userId = user['id'];
      if (deptId is int && userId is int && deptId == departmentId) {
        yield userId;
      }
    }
  }
}

