import 'package:shared_preferences/shared_preferences.dart';

/// Persists only the update notice the user explicitly asked not to see again.
///
/// The value is version-scoped: suppressing one release never suppresses the
/// next release because a newer [noticeId] no longer matches the stored id.
class UpdateNoticeService {
  UpdateNoticeService({SharedPreferencesAsync? preferences})
      : _preferences = preferences;

  static const suppressedNoticeStorageKey =
      'brightquest.update_notice.suppressed_version.v1';

  final SharedPreferencesAsync? _preferences;

  /// Reads the version-scoped dismissal lazily so constructing the app does not
  /// require a platform preferences backend. This matters for widget tests and
  /// also keeps startup resilient if preferences are temporarily unavailable.
  Future<bool> shouldShow(String noticeId) async {
    String? suppressedId;
    try {
      final preferences = _preferences ?? SharedPreferencesAsync();
      suppressedId =
          await preferences.getString(suppressedNoticeStorageKey);
    } catch (_) {
      // Fail open: an unavailable preference backend must never block startup
      // or hide release notes that the user has not positively dismissed.
      suppressedId = null;
    }
    return UpdateNoticePolicy.shouldShow(
      currentNoticeId: noticeId,
      suppressedNoticeId: suppressedId,
    );
  }

  Future<void> suppress(String noticeId) async {
    try {
      final preferences = _preferences ?? SharedPreferencesAsync();
      await preferences.setString(suppressedNoticeStorageKey, noticeId);
    } catch (_) {
      // Suppression is a convenience preference, not critical app state. If
      // persistence is unavailable, show the notice again rather than crash.
    }
  }
}

class UpdateNoticePolicy {
  const UpdateNoticePolicy._();

  static bool shouldShow({
    required String currentNoticeId,
    required String? suppressedNoticeId,
  }) {
    final current = currentNoticeId.trim();
    if (current.isEmpty) return false;
    return suppressedNoticeId?.trim() != current;
  }
}
