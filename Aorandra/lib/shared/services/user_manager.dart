import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// UserManager
/// ------------------------------------------------------------
/// A global singleton service responsible for:
/// - Caching user profiles locally
/// - Providing fast access to user data (username, avatar, etc.)
/// - Syncing profile updates in real-time using Supabase Realtime
/// - Notifying UI listeners when data changes
///
/// This eliminates repeated database calls (FutureBuilder)
/// and significantly improves performance across the app.
/// ============================================================
class UserManager extends ChangeNotifier {
  // ============================================================
  // SINGLETON SETUP
  // ============================================================

  static final UserManager instance = UserManager._internal();
  UserManager._internal();

  final SupabaseClient supabase = Supabase.instance.client;

  // ============================================================
  // LOCAL CACHE
  // ============================================================

  /// Stores user data in memory
  /// Key: userId
  /// Value: user object (Map)
  final Map<String, Map<String, dynamic>> _users = {};

  // ============================================================
  // SAFE NOTIFY (avoids setState during build issues)
  // ============================================================

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // ============================================================
  // SET SINGLE USER
  // ============================================================

  /// Inserts or replaces a single user in cache
  void setUser(String userId, Map<String, dynamic> data) {
    _users[userId] = data;
    _safeNotify();
  }

  // ============================================================
  // SET MULTIPLE USERS
  // ============================================================

  /// Inserts multiple users into cache (used on initial load)
  void setUsers(List users) {
    for (var user in users) {
      final id = user['id']?.toString();
      if (id != null) {
        _users[id] = user;
      }
    }
    _safeNotify();
  }

  // ============================================================
  // UPDATE USER
  // ============================================================

  /// Merges new data into an existing cached user
  /// If the user does not exist, it will be created
  void updateUser(String userId, Map<String, dynamic> newData) {
    if (_users.containsKey(userId)) {
      _users[userId] = {
        ..._users[userId]!,
        ...newData,
      };
    } else {
      _users[userId] = newData;
    }

    _safeNotify();
  }

  // ============================================================
  // REMOVE USER
  // ============================================================

  /// Removes a user from cache
  void removeUser(String userId) {
    _users.remove(userId);
    _safeNotify();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  /// Returns full user object
  Map<String, dynamic>? getUser(String userId) {
    return _users[userId];
  }

  /// Returns all cached users
  List<Map<String, dynamic>> getAllUsers() {
    return _users.values.toList();
  }

  /// Returns username safely
  String getUsername(String userId) {
    final user = _users[userId];
    return (user?['username'] ?? 'User').toString();
  }

  /// Returns avatar URL safely
  /// Ensures it's a valid HTTP URL
  String getAvatar(String userId) {
    final user = _users[userId];

    final avatar = (user?['avatar_url'] ?? '')
        .toString()
        .trim();

    if (avatar.isEmpty ||
        avatar == 'null' ||
        !avatar.toLowerCase().startsWith('http')) {
      return '';
    }

    return avatar;
  }

  // ============================================================
  // REALTIME SYNC
  // ============================================================

  bool _isListening = false;

  /// Subscribes to real-time updates on the profiles table
  /// Keeps the cache synced instantly when profile data changes
  void listenToProfileChanges() {
    if (_isListening) return;
    _isListening = true;

    supabase
        .channel('profiles_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            final newData = payload.newRecord;

            final userId = newData['id']?.toString();
            if (userId == null) return;

            updateUser(userId, newData);
          },
        )
        .subscribe();
  }

  // ============================================================
  // CLEAR CACHE
  // ============================================================

  /// Clears all cached users (use on logout)
  void clear() {
    _users.clear();
    _safeNotify();
  }
}