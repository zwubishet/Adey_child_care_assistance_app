import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsProvider extends ChangeNotifier {
  bool _showPopupNotifications = true;
  static const String _popupNotificationsKey = 'show_popup_notifications';

  NotificationSettingsProvider() {
    loadSettings();
  }

  bool get showPopupNotifications => _showPopupNotifications;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showPopupNotifications = prefs.getBool(_popupNotificationsKey) ?? true;
    notifyListeners();
  }

  Future<void> togglePopupNotifications(bool enabled) async {
    _showPopupNotifications = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_popupNotificationsKey, _showPopupNotifications);
    notifyListeners();
  }
}
