import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  static const String _storageKey = 'stored_notifications';

  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString(_storageKey);

      if (notificationsJson != null) {
        final List<dynamic> decoded = jsonDecode(notificationsJson);
        _notifications = decoded
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  // Static method to save notification from background handler
  static Future<void> saveNotificationStatic(
    NotificationModel notification,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? existingJson = prefs.getString(_storageKey);

      List<NotificationModel> notifications = [];
      if (existingJson != null) {
        final List<dynamic> decoded = jsonDecode(existingJson);
        notifications = decoded
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      }

      // Add new notification at the beginning
      notifications.insert(0, notification);

      // Save back to storage
      final String encoded = jsonEncode(
        notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);

      if (kDebugMode) {
        print('✅ Notification saved: ${notification.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving notification: $e');
      }
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notifications: $e');
      }
    }
  }
}
