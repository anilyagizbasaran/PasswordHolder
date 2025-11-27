import 'package:shared_preferences/shared_preferences.dart';

class HolderOrderCache {
  HolderOrderCache._internal();

  static final HolderOrderCache instance = HolderOrderCache._internal();

  Future<List<int>> loadOrder({
    required int userId,
    required bool isAdminView,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key(userId, isAdminView));
    if (stored == null) {
      return const [];
    }
    return stored
        .map((value) => int.tryParse(value))
        .whereType<int>()
        .toList();
  }

  Future<void> saveOrder({
    required int userId,
    required bool isAdminView,
    required List<int> order,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key(userId, isAdminView),
      order.map((id) => id.toString()).toList(),
    );
  }

  Future<void> clear({
    required int userId,
    required bool isAdminView,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId, isAdminView));
  }

  String _key(int userId, bool isAdminView) =>
      'holder_order_${isAdminView ? 'admin' : 'user'}_$userId';
}

