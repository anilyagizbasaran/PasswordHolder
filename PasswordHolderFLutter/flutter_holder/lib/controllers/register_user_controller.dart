import 'package:flutter/foundation.dart';

import '../services/department_api.dart';
import '../services/user_api.dart';
import '../utils/user_validators.dart';

class RegisterUserController extends ChangeNotifier {
  RegisterUserController({
    required this.userApi,
    required this.departmentApi,
    required this.onShowMessage,
    required this.isAdmin,
    required this.currentUserId,
    this.onUsersUpdated,
  });

  final UserApi userApi;
  final DepartmentApi departmentApi;
  final void Function(String message) onShowMessage;
  final bool isAdmin;
  final int? currentUserId;
  final void Function(List<Map<String, dynamic>> users)? onUsersUpdated;

  List<Map<String, dynamic>> users = const [];
  bool usersLoading = false;
  String? usersError;

  List<Map<String, dynamic>> departments = const [];
  bool departmentsLoading = false;
  String? departmentsError;
  int? selectedDepartmentId;
  bool departmentSubmitting = false;

  bool registerSubmitting = false;
  String? registerError;

  Future<void> fetchUsers() async {
    usersLoading = true;
    usersError = null;
    notifyListeners();
    try {
      final fetched = await userApi.listUsers();
      final sanitized = <Map<String, dynamic>>[];
      for (final user in fetched) {
        final id = _parseInt(
              user['id'] ??
                  user['user_id'] ??
                  user['userId'] ??
                  user['userID'],
            ) ??
            _parseInt(user['holder_user_id']);
        if (id == null) continue;
        final name =
            _resolveField(user, const ['name', 'fullName']) ?? 'Kullanıcı $id';
        final email = _resolveField(user, const ['email']) ?? '';
        final departmentId = _parseInt(
          user['departmentId'] ?? user['department_id'] ?? user['departmentID'],
        );
        final departmentName = _resolveField(
              user,
              const ['departmentName', 'department_name', 'department'],
            ) ??
            '';
        sanitized.add({
          'id': id,
          'name': name,
          'email': email,
          'departmentId': departmentId,
          'departmentName': departmentName,
        });
      }
      users = sanitized;
      onUsersUpdated?.call(users);
    } catch (e) {
      usersError = e.toString();
    } finally {
      usersLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDepartments() async {
    departmentsLoading = true;
    departmentsError = null;
    notifyListeners();
    try {
      final fetched = await departmentApi.listDepartments();
      fetched.sort(
        (a, b) => (a['name'] ?? '').toString().compareTo(
              (b['name'] ?? '').toString(),
            ),
      );
      departments = fetched;
      if (departments.isEmpty) {
        selectedDepartmentId = null;
      } else if (selectedDepartmentId != null &&
          !departments.any(
            (dept) => _parseInt(dept['id']) == selectedDepartmentId,
          )) {
        selectedDepartmentId = null;
      }
    } catch (e) {
      departmentsError = e.toString();
    } finally {
      departmentsLoading = false;
      notifyListeners();
    }
  }

  void selectDepartment(int? id) {
    selectedDepartmentId = id;
    notifyListeners();
  }

  Future<bool> submitRegister({
    required String name,
    required String email,
    required String password,
  }) async {
    registerError = null;
    registerSubmitting = true;
    notifyListeners();
    try {
      await userApi.createUser(
        name: name,
        email: normalizeEmail(email),
        password: password,
        departmentId: selectedDepartmentId,
      );
      onShowMessage('Kullanıcı başarıyla oluşturuldu');
      await fetchUsers();
      return true;
    } catch (e) {
      registerError = e.toString();
      return false;
    } finally {
      registerSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> submitDepartment(String name) async {
    if (!isAdmin) {
      onShowMessage('Bu işlem için yetkiniz bulunmuyor.');
      return false;
    }
    departmentSubmitting = true;
    departmentsError = null;
    notifyListeners();
    int? createdId;
    try {
      final created = await departmentApi.createDepartment(name: name);
      createdId = _parseInt(created['id']);
      onShowMessage('Departman başarıyla oluşturuldu.');
    } catch (e) {
      departmentsError = e.toString();
      return false;
    } finally {
      departmentSubmitting = false;
      notifyListeners();
    }
    await fetchDepartments();
    if (createdId != null) {
      final exists = departments.any(
        (dept) => _parseInt(dept['id']) == createdId,
      );
      selectedDepartmentId = exists ? createdId : null;
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteDepartment(int id) async {
    if (!isAdmin) {
      onShowMessage('Bu işlem için yetkiniz bulunmuyor.');
      return false;
    }
    try {
      await departmentApi.deleteDepartment(id);
      if (selectedDepartmentId == id) {
        selectedDepartmentId = null;
      }
      onShowMessage('Departman silindi.');
    } catch (e) {
      onShowMessage('Departman silinirken hata oluştu: $e');
      return false;
    }
    await fetchDepartments();
    return true;
  }

  Future<bool> deleteUser(int id, {String? name}) async {
    if (!isAdmin) {
      onShowMessage('Bu işlem için yetkiniz bulunmuyor.');
      return false;
    }
    if (currentUserId != null && id == currentUserId) {
      onShowMessage('Kendi hesabınızı bu panelden silemezsiniz.');
      return false;
    }
    try {
      await userApi.deleteUser(id);
      onShowMessage('Kullanıcı silindi.');
    } catch (e) {
      onShowMessage('Kullanıcı silinirken hata oluştu: $e');
      return false;
    }
    await fetchUsers();
    return true;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _resolveField(
    Map<String, dynamic> data,
    List<String> possibleKeys,
  ) {
    for (final key in possibleKeys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}

