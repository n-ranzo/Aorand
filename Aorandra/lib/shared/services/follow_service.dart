import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowService extends ChangeNotifier {
  FollowService._internal();
  static final FollowService instance = FollowService._internal();

  final SupabaseClient _sb = Supabase.instance.client;

  final Map<String, bool> _followStates = {};
  final Map<String, int> _followersCounts = {};
  final Map<String, int> _followingCounts = {};

  final Map<String, Future<bool>> _followRequests = {};
  final Map<String, Future<void>> _statsRequests = {};
  final Set<String> _togglingUsers = {};
  final Set<String> _primingUsers = {};
  final Map<String, int> _followVersions = {};

  bool followStateOf(String userId) => _followStates[userId] ?? false;
  bool hasFollowState(String userId) => _followStates.containsKey(userId);

  int followersCountOf(String userId) => _followersCounts[userId] ?? 0;
  int followingCountOf(String userId) => _followingCounts[userId] ?? 0;

  bool isToggling(String userId) => _togglingUsers.contains(userId);

  // =========================
  // PRIME
  // =========================

  Future<void> primeUser(
    String userId, {
    bool includeFollowState = true,
    bool includeStats = false,
  }) async {
    if (userId.isEmpty) return;

    final futures = <Future<void>>[];

    if (includeFollowState && !hasFollowState(userId)) {
      futures.add(isFollowing(userId).then((_) {}));
    }

    if (includeStats &&
        (!_followersCounts.containsKey(userId) ||
            !_followingCounts.containsKey(userId))) {
      futures.add(_ensureStatsLoaded(userId));
    }

    if (futures.isEmpty) return;
    await Future.wait(futures);
  }

  Future<void> primeUsers(Iterable<String> userIds) async {
    final currentUserId = _sb.auth.currentUser?.id;
    if (currentUserId == null) return;

    final targets = userIds
        .map((id) => id.toString())
        .where((id) => id.isNotEmpty && id != currentUserId)
        .toSet()
        .where((id) =>
            !_followStates.containsKey(id) &&
            !_followRequests.containsKey(id) &&
            !_primingUsers.contains(id))
        .toList();

    if (targets.isEmpty) return;

    _primingUsers.addAll(targets);

    final capturedVersions = <String, int>{
      for (final id in targets) id: (_followVersions[id] ?? 0),
    };

    try {
      final rows = await _sb
          .from('followers')
          .select('following_id')
          .eq('follower_id', currentUserId)
          .inFilter('following_id', targets);

      final followedIds = <String>{
        for (final row in rows) row['following_id'].toString(),
      };

      for (final targetId in targets) {
        if (_togglingUsers.contains(targetId)) continue;
        if ((_followVersions[targetId] ?? 0) != capturedVersions[targetId]) continue;
        _followStates[targetId] = followedIds.contains(targetId);
      }

      notifyListeners();
    } finally {
      _primingUsers.removeAll(targets);
    }
  }

  // =========================
  // REFRESH
  // =========================

  Future<void> refreshUser(
    String userId, {
    bool includeFollowState = true,
    bool includeStats = true,
  }) async {
    if (userId.isEmpty) return;

    final futures = <Future<void>>[];

    // 🔒 لا تخرب الحالة أثناء التوجل
    if (includeFollowState && !_togglingUsers.contains(userId)) {
      futures.add(isFollowing(userId, forceRefresh: true).then((_) {}));
    }

    if (includeStats) {
      futures.add(_ensureStatsLoaded(userId, forceRefresh: true));
    }

    if (futures.isEmpty) return;
    await Future.wait(futures);
  }

  // =========================
  // FOLLOW STATE
  // =========================

  Future<bool> isFollowing(
    String targetUserId, {
    bool forceRefresh = false,
  }) async {
    final currentUserId = _sb.auth.currentUser?.id;

    if (currentUserId == null ||
        targetUserId.isEmpty ||
        currentUserId == targetUserId) {
      return false;
    }

    if (!forceRefresh && _followStates.containsKey(targetUserId)) {
      return _followStates[targetUserId]!;
    }

    // forceRefresh always spawns a fresh request — never reuse a stale
    // in-flight result that may have been started before the last toggle.
    if (!forceRefresh) {
      final existingRequest = _followRequests[targetUserId];
      if (existingRequest != null) return existingRequest;
    }

    final request = _fetchFollowState(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );

    if (!forceRefresh) {
      _followRequests[targetUserId] = request;
    }

    try {
      return await request;
    } finally {
      if (!forceRefresh) {
        _followRequests.remove(targetUserId);
      }
    }
  }

  // =========================
  // TOGGLE FOLLOW
  // =========================

  Future<bool> toggleFollow(String targetUserId) async {
  final currentUserId = _sb.auth.currentUser?.id;

  if (currentUserId == null ||
      targetUserId.isEmpty ||
      currentUserId == targetUserId) {
    return false;
  }

  if (_togglingUsers.contains(targetUserId)) {
    return followStateOf(targetUserId);
  }

  // 🔒 Lock
  _togglingUsers.add(targetUserId);
  _followVersions[targetUserId] = (_followVersions[targetUserId] ?? 0) + 1;
  notifyListeners();

  final previousState = _followStates[targetUserId] ?? false;
  final optimisticState = !previousState;

  final prevFollowers = _followersCounts[targetUserId];
  final prevFollowing = _followingCounts[currentUserId];

  // =========================
  // OPTIMISTIC UI
  // =========================
  _followStates[targetUserId] = optimisticState;

  _applyCountDelta(
    targetUserId: targetUserId,
    currentUserId: currentUserId,
    delta: optimisticState ? 1 : -1,
  );

  notifyListeners();

  try {
    final response = await _sb.rpc(
      'toggle_follow',
      params: {
        'p_current_user': currentUserId,
        'p_target_user': targetUserId,
      },
    );

    debugPrint('✅ toggle_follow response: $response (${response.runtimeType})');

    // =========================
    // PARSE RESPONSE
    // =========================
    final bool serverState;
    if (response is bool) {
      serverState = response;
    } else if (response is List &&
        response.isNotEmpty &&
        response.first is bool) {
      serverState = response.first as bool;
    } else {
      debugPrint('⚠️ unexpected response → fallback fetch');
      serverState = await _fetchFollowState(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );
    }

    // =========================
    // APPLY REAL STATE
    // =========================
    _followStates[targetUserId] = serverState;

    _restoreCounts(
      targetUserId: targetUserId,
      currentUserId: currentUserId,
      followersCount: prevFollowers,
      followingCount: prevFollowing,
    );

    _applyCountDelta(
      targetUserId: targetUserId,
      currentUserId: currentUserId,
      delta: _stateDelta(previousState, serverState),
    );

    notifyListeners();

    // =========================
    // NOTIFICATION
    // =========================
    if (serverState) {
      unawaited(_insertFollowNotification(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      ));
    }

    // =========================
    // SAFE REFRESH
    // =========================
    return serverState;

  } catch (e, stack) {
    // =========================
    // 🔥 IMPORTANT DEBUG
    // =========================
    debugPrint("🔥 FOLLOW ERROR: $e");
    debugPrint("📍 STACK: $stack");

    // =========================
    // RESTORE UI STATE
    // =========================
    _followStates[targetUserId] = previousState;

    _restoreCounts(
      targetUserId: targetUserId,
      currentUserId: currentUserId,
      followersCount: prevFollowers,
      followingCount: prevFollowing,
    );

    notifyListeners();

    // ❗ لا ترمي error (هذا اللي كان يكسر الزر)
    return previousState;

  } finally {
    _togglingUsers.remove(targetUserId);
    notifyListeners();
  }
}

  // =========================
  // FETCH (FIXED)
  // =========================

  Future<bool> _fetchFollowState({
    required String currentUserId,
    required String targetUserId,
  }) async {
    // 🔒 لا تخرب أثناء toggle
    if (_togglingUsers.contains(targetUserId)) {
      return _followStates[targetUserId] ?? false;
    }

    final capturedVersion = _followVersions[targetUserId] ?? 0;

    try {
      // Same query pattern as primeUsers — known to work correctly.
      final rows = await _sb
          .from('followers')
          .select('following_id')
          .eq('follower_id', currentUserId)
          .inFilter('following_id', [targetUserId]);

      final bool isFollowing = (rows as List).isNotEmpty;

      debugPrint(
        '[FollowService] fetch: me=$currentUserId → target=$targetUserId '
        '| rows=${rows.length} | isFollowing=$isFollowing',
      );

      if (!_togglingUsers.contains(targetUserId) &&
          (_followVersions[targetUserId] ?? 0) == capturedVersion) {
        _followStates[targetUserId] = isFollowing;
        notifyListeners();
      }

      return isFollowing;
    } catch (e) {
      debugPrint('[FollowService] _fetchFollowState error: $e');
      return _followStates[targetUserId] ?? false;
    }
  }

  // =========================
  // STATS
  // =========================

  Future<void> _ensureStatsLoaded(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (userId.isEmpty) return;

    if (!forceRefresh &&
        _followersCounts.containsKey(userId) &&
        _followingCounts.containsKey(userId)) {
      return;
    }

    final existing = _statsRequests[userId];
    if (existing != null) {
      await existing;
      return;
    }

    final request = _loadStats(userId);
    _statsRequests[userId] = request;

    try {
      await request;
    } finally {
      _statsRequests.remove(userId);
    }
  }

  Future<void> _loadStats(String userId) async {
    final row = await _sb
        .from('profile_stats')
        .select('followers_count, following_count')
        .eq('id', userId)
        .maybeSingle();

    _followersCounts[userId] = row?['followers_count'] ?? 0;
    _followingCounts[userId] = row?['following_count'] ?? 0;

    notifyListeners();
  }

  // =========================
  // HELPERS
  // =========================

  void _applyCountDelta({
    required String targetUserId,
    required String currentUserId,
    required int delta,
  }) {
    if (delta == 0) return;

    if (_followersCounts.containsKey(targetUserId)) {
      _followersCounts[targetUserId] =
          (_followersCounts[targetUserId]! + delta).clamp(0, 1 << 31);
    }

    if (_followingCounts.containsKey(currentUserId)) {
      _followingCounts[currentUserId] =
          (_followingCounts[currentUserId]! + delta).clamp(0, 1 << 31);
    }
  }

  void _restoreCounts({
    required String targetUserId,
    required String currentUserId,
    required int? followersCount,
    required int? followingCount,
  }) {
    if (followersCount != null) {
      _followersCounts[targetUserId] = followersCount;
    }
    if (followingCount != null) {
      _followingCounts[currentUserId] = followingCount;
    }
  }

  int _stateDelta(bool prev, bool next) {
    if (prev == next) return 0;
    return next ? 1 : -1;
  }

  Future<void> _insertFollowNotification({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await _sb.from('notifications').insert({
        'receiver_id': targetUserId,
        'sender_id': currentUserId,
        'type': 'follow',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}