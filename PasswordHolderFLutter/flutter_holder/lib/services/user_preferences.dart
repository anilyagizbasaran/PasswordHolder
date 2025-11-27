import 'package:shared_preferences/shared_preferences.dart';

import '../utils/card_size_option.dart';

class UserPreferences {
  UserPreferences._internal();

  static final UserPreferences instance = UserPreferences._internal();

  static const String _cardSizeKey = 'card_size_option';

  Future<CardSizeOption> loadCardSize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_cardSizeKey);
    return cardSizeOptionFromString(value);
  }

  Future<void> saveCardSize(CardSizeOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardSizeKey, option.storageKey);
  }
}

