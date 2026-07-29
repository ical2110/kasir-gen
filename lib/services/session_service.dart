import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const inactivityLimit = Duration(hours: 12);
  static const maximumSessionAge = Duration(days: 7);
  static const _activityWriteInterval = Duration(minutes: 5);
  static const _lastActivityKey = 'session_last_activity_ms';

  static DateTime? _lastRecordedAt;

  static bool shouldExpire({
    required DateTime now,
    DateTime? lastActivity,
    DateTime? signedInAt,
  }) {
    final inactiveTooLong =
        lastActivity != null && now.difference(lastActivity) > inactivityLimit;
    final sessionTooOld =
        signedInAt != null && now.difference(signedInAt) > maximumSessionAge;
    return inactiveTooLong || sessionTooOld;
  }

  static Future<bool> validate(User user, {DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final preferences = await SharedPreferences.getInstance();
    final storedMilliseconds = preferences.getInt(_lastActivityKey);
    final lastActivity = storedMilliseconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(storedMilliseconds);
    final signedInAt = user.metadata.lastSignInTime;

    if (shouldExpire(
      now: currentTime,
      lastActivity: lastActivity,
      signedInAt: signedInAt,
    )) {
      await signOut();
      return false;
    }

    await recordActivity(force: true, now: currentTime);
    return true;
  }

  static Future<void> recordActivity({
    bool force = false,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    if (!force &&
        _lastRecordedAt != null &&
        currentTime.difference(_lastRecordedAt!) < _activityWriteInterval) {
      return;
    }

    _lastRecordedAt = currentTime;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _lastActivityKey,
      currentTime.millisecondsSinceEpoch,
    );
  }

  static Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lastActivityKey);
    _lastRecordedAt = null;
    await FirebaseAuth.instance.signOut();
  }
}

class SessionActivityTracker extends StatefulWidget {
  const SessionActivityTracker({
    required this.user,
    required this.child,
    super.key,
  });

  final User user;
  final Widget child;

  @override
  State<SessionActivityTracker> createState() => _SessionActivityTrackerState();
}

class _SessionActivityTrackerState extends State<SessionActivityTracker>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionService.validate(widget.user);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      SessionService.recordActivity(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SessionService.recordActivity(),
      child: widget.child,
    );
  }
}
