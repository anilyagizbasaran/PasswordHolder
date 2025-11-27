import 'package:flutter/foundation.dart';

const String _userDefaultBaseUrl = 'http://localhost:3000/api/users';
const String _userAndroidBaseUrl = 'http://10.0.2.2:3000/api/users';

const String _holderDefaultBaseUrl =
    'http://localhost:3000/api/passwordholder';
const String _holderAndroidBaseUrl =
    'http://10.0.2.2:3000/api/passwordholder';

const String _departmentDefaultBaseUrl =
    'http://localhost:3000/api/departments';
const String _departmentAndroidBaseUrl =
    'http://10.0.2.2:3000/api/departments';

String resolveUserApiBaseUrl() {
  if (kIsWeb) {
    return _userDefaultBaseUrl;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return _userAndroidBaseUrl;
  }

  return _userDefaultBaseUrl;
}

String resolvePasswordHolderBaseUrl() {
  if (kIsWeb) {
    return _holderDefaultBaseUrl;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return _holderAndroidBaseUrl;
  }

  return _holderDefaultBaseUrl;
}

String resolveDepartmentBaseUrl() {
  if (kIsWeb) {
    return _departmentDefaultBaseUrl;
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return _departmentAndroidBaseUrl;
  }

  return _departmentDefaultBaseUrl;
}

