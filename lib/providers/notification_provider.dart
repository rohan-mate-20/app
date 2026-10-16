import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  static const String _defaultStorageKey = 'kmart_notifications_v1';
  String? _currentCustomerId;
  List<NotificationModel> _notifications = [];
  bool _isLoaded = false;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
  bool get isLoaded => _isLoaded;

  String _getStorageKey() {
    if (_currentCustomerId != null && _currentCustomerId!.isNotEmpty) {
      return 'kmart_notifications_cust_$_currentCustomerId';
    }
    return _defaultStorageKey;
  }

  NotificationProvider() {
    _loadFromStorage();
  }

  Future<void> loadForCustomer(String? customerId) async {
    _currentCustomerId = customerId;
    _notifications = [];
    _isLoaded = false;
    notifyListeners();
    await _loadFromStorage();
  }

  /// Clears notifications from in-memory state and UI immediately after logout
  void clearOnLogout() {
    _notifications = [];
    _currentCustomerId = null;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentCustomerId == null) {
        final cachedUser = prefs.getString('kmart_cached_customer');
        if (cachedUser != null && cachedUser.isNotEmpty) {
          final decodedCust = json.decode(cachedUser);
          if (decodedCust['id'] != null) {
            _currentCustomerId = decodedCust['id'].toString();
          }
        }
      }
      final key = _getStorageKey();
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw);
        _notifications = decoded
            .map((item) => NotificationModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        _notifications = [];
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error loading notifications: $e');
      _notifications = [];
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey();
      final raw = json.encode(_notifications.map((n) => n.toMap()).toList());
      await prefs.setString(key, raw);
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
