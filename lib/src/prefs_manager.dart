import '_imports.dart';

/// Manages initialization and configuration of the preference system.
///
/// This class coordinates loading preferences from different storage backends
/// and provides a centralized initialization point for the entire system.
///
/// Example:
/// ```dart
/// final prefsManager = PrefsManager(
///   remote: SupabasePreferences(),
///   enumValues: [UserPrefs.values, AppPrefs.values],
/// );
/// await prefsManager.init();
/// ```
class PrefsManager {
  /// Creates a preference manager.
  ///
  /// [remote] is the implementation for remote preference storage.
  /// [enumValues] is a list of enum values implementing [Pref] to register.
  PrefsManager({
    required this.remote,
    required List<List<Pref>> enumValues,
  }) {
    for (final enumGroup in enumValues) {
      _preferences.addAll(enumGroup);
    }
  }
  final RemotePrefs remote;
  final List<Pref> _preferences = [];

  /// Initializes the preference system.
  ///
  /// This method:
  /// 1. Configures the remote preferences backend
  /// 2. Builds a map of all registered preferences
  /// 3. Loads local and remote preferences into memory cache
  ///
  /// This should be called once during app initialization, before accessing
  /// any preferences.
  Future<void> init() async {
    // Configure the remote storage implementation
    Prefs.setRemotePreferences(remote);

    // Build the preferences map
    final preferences = {
      for (final pref in _preferences) pref.key: pref.storageType,
    };

    // Load the preferences
    await Prefs.loadPreferences(preferences);
  }
}
