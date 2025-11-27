import 'package:flutter/foundation.dart';

import '../services/holder_order_cache.dart';
import '../services/password_holder_api.dart';

class PasswordHoldersController extends ChangeNotifier {
  PasswordHoldersController({
    required this.passwordHolderApi,
    required this.orderCache,
    required this.currentUserId,
    this.isAdminView = true,
  });

  final PasswordHolderApi passwordHolderApi;
  final HolderOrderCache orderCache;
  final int? currentUserId;
  final bool isAdminView;

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> holders = const [];

  Future<void> fetchHolders() async {
    loading = true;
    error = null;
    holders = const [];
    notifyListeners();

    try {
      final fetched = await passwordHolderApi.listHolders();
      final mapped = fetched.map<Map<String, dynamic>>((holder) {
        final map = Map<String, dynamic>.from(holder);
        final ownerName = _resolveField(
              map,
              const [
                'ownerName',
                'assigned_to',
                'assignedTo',
                'user_name',
                'owner_name',
              ],
            )
                ?.trim();
        final holderName = _resolveHolderBaseName(map);

        if (ownerName != null && ownerName.isNotEmpty) {
          map['uiName'] = '$holderName ($ownerName)';
          map['ownerName'] = ownerName;
        } else {
          map['uiName'] = holderName;
        }

        return map;
      }).toList();

      holders = await _applyCachedOrder(mapped);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteHolder(int id) async {
    await passwordHolderApi.deleteHolder(id);
    holders = holders.where((entry) => _resolveIdentifier(entry) != id).toList();
    notifyListeners();
    _persistOrder();
  }

  Future<void> updateHolder({
    required int id,
    required String name,
    required String email,
    required String password,
    required List<int> userIds,
  }) {
    return passwordHolderApi.updateHolder(
      id: id,
      name: name,
      email: email,
      password: password,
      userIds: userIds,
    );
  }

  void reorderHolders(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = holders.removeAt(oldIndex);
    holders.insert(newIndex, item);
    notifyListeners();
    _persistOrder();
  }

  String? resolveField(
    Map<String, dynamic> data,
    List<String> possibleKeys,
  ) =>
      _resolveField(data, possibleKeys);

  int? resolveIdentifier(Map<String, dynamic> entry) =>
      _resolveIdentifier(entry);

  Set<int> resolveEntryUserIds(Map<String, dynamic> entry) =>
      _resolveEntryUserIds(entry);

  String resolveHolderBaseName(Map<String, dynamic> data) =>
      _resolveHolderBaseName(data);

  String? _resolveField(
    Map<String, dynamic> data,
    List<String> possibleKeys,
  ) {
    final preferredKeys = <String>[];
    if (possibleKeys.contains('holder_title')) {
      preferredKeys.add('uiName');
    }
    for (final key in [...preferredKeys, ...possibleKeys]) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  String _resolveHolderBaseName(Map<String, dynamic> data) {
    const keys = [
      'holder_title',
      'holderTitle',
      'title',
      'name',
    ];
    String? raw;
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        raw = value.toString();
        break;
      }
    }
    raw ??= 'Kayıt';
    final ownerLabel = _resolveField(
      data,
      const [
        'ownerName',
        'assigned_to',
        'assignedTo',
        'user_name',
        'owner_name',
      ],
    );
    return _stripOwnerSuffix(raw, ownerLabel);
  }

  String _stripOwnerSuffix(String value, String? ownerLabel) {
    final trimmedValue = value.trim();
    if (ownerLabel == null || ownerLabel.trim().isEmpty) {
      return trimmedValue;
    }
    final suffix = '(${ownerLabel.trim()})';
    if (trimmedValue.endsWith(suffix)) {
      return trimmedValue.substring(
        0,
        trimmedValue.length - suffix.length,
      ).trimRight();
    }
    return trimmedValue;
  }

  Future<List<Map<String, dynamic>>> _applyCachedOrder(
    List<Map<String, dynamic>> entries,
  ) async {
    final userId = currentUserId;
    if (userId == null) {
      return entries;
    }
    final savedOrder = await orderCache.loadOrder(
      userId: userId,
      isAdminView: isAdminView,
    );
    if (savedOrder.isEmpty) {
      await orderCache.saveOrder(
        userId: userId,
        isAdminView: isAdminView,
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
    final keptIds = <int>[];

    for (final id in savedOrder) {
      final entry = savedEntries[id];
      if (entry != null) {
        ordered.add(entry);
        keptIds.add(id);
      }
    }

    await orderCache.saveOrder(
      userId: userId,
      isAdminView: isAdminView,
      order: [
        ..._extractIds(newEntries),
        ...keptIds,
      ],
    );

    return ordered;
  }

  Future<void> _persistOrder() async {
    final userId = currentUserId;
    if (userId == null) {
      return;
    }
    final order = _extractIds(holders);
    if (order.isEmpty) {
      return;
    }
    await orderCache.saveOrder(
      userId: userId,
      isAdminView: isAdminView,
      order: order,
    );
  }

  int? _resolveIdentifier(Map<String, dynamic> entry) {
    final possibleKeys = [
      'id',
      'holder_id',
      'holderId',
      'password_id',
      'passwordId',
    ];
    for (final key in possibleKeys) {
      final value = entry[key];
      final parsed = _parseInt(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  List<int> _extractIds(List<Map<String, dynamic>> entries) =>
      entries.map(_resolveIdentifier).whereType<int>().toList();

  Set<int> _resolveEntryUserIds(Map<String, dynamic> entry) {
    final resolved = <int>{};
    final assigned = entry['assigned_user_ids'];
    if (assigned is List) {
      for (final value in assigned) {
        final parsed = _parseInt(value);
        if (parsed != null) {
          resolved.add(parsed);
        }
      }
    }
    final single = _resolveEntryUserId(entry);
    if (single != null) {
      resolved.add(single);
    }
    return resolved;
  }

  int? _resolveEntryUserId(Map<String, dynamic> entry) {
    const possibleKeys = ['user_id', 'userId', 'holder_user_id', 'owner_id'];
    for (final key in possibleKeys) {
      final parsed = _parseInt(entry[key]);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

