final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$',
);

String normalizeEmail(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  if (!trimmed.contains('@')) {
    return '$trimmed@gmail.com';
  }
  return trimmed;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'E-posta gerekli';
  }
  final normalized = normalizeEmail(value);
  if (!_emailRegex.hasMatch(normalized)) {
    return 'Geçerli bir e-posta girin';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Şifre gerekli';
  }
  return null;
}

String? validateFlexiblePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Şifre gerekli';
  }
  return null;
}

String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'İsim gerekli';
  }
  return null;
}

String? validateDepartment(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Departman gerekli';
  }
  return null;
}
