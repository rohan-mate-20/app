import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  static const String _storageKey = 'kmart_notifications_v1';
  List<NotificationModel> _notifications = [];
  bool _isLoaded = false;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
  bool get isLoaded => _isLoaded;

  NotificationProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw);
        _notifications = decoded
            .map((item) => NotificationModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error loading notifications: $e');
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = json.encode(_notifications.map((n) => n.toMap()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('[NotificationProvider] Error saving notifications: $e');
    }
  }

  void addNotification({
    required String title,
    required String body,
    String? orderId,
    String type = 'order',
  }) {
    final newNotification = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      isRead: false,
      orderId: orderId,
      type: type,
    );

    _notifications.insert(0, newNotification);
    notifyListeners();
    _saveToStorage();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index >= 0 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      _saveToStorage();
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      _saveToStorage();
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
    _saveToStorage();
  }
}
