import 'dart:async';

import '_imports.dart';

/// Core class for managing preferences with local, remote, and volatile storage.
///
/// This class handles loading, caching, and saving preferences across different
/// storage types. All operations are cached in memory for fast access.
class Prefs {
  static final Map<String, dynamic> _preferencesCache = {};
  static RemotePrefs? _remotePreferences;
  static PrefsLogger _logger = defaultPrefsLogger;
  static const int _defaultMaxRetries = 6; // 1 minute with 10s intervals
  static int _maxRetries = _defaultMaxRetries;
  static ConnectivityChecker? _connectivityChecker;
  static RemoteLoadCallback? _remoteLoadCallback;

  /// Configures the logger for preference operations.
  ///
  /// By default, uses [defaultPrefsLogger] which prints to console.
  /// Set to a custom implementation to redirect logs.
  ///
  /// Example:
  /// ```dart
  /// Prefs.setLogger((level, message) {
  ///   if (level == PrefsLogLevel.error) {
  ///     Sentry.captureMessage(message);
  ///   }
  /// });
  /// ```
  static void setLogger(PrefsLogger logger) {
    _logger = logger;
  }

  /// Configures the maximum number of retries for loading remote preferences.
  ///
  /// Default is 6 retries (1 minute with 10-second intervals).
  /// Set to 0 to disable retries.
  static void setMaxRetries(int maxRetries) {
    _maxRetries = maxRetries;
  }

  /// Configures a connectivity checker for smarter retry logic.
  ///
  /// When set, the system will check connectivity before retrying remote loads.
  /// This prevents unnecessary retry attempts when offline.
  ///
  /// Example:
  /// ```dart
  /// Prefs.setConnectivityChecker(() async {
  ///   final result = await Connectivity().checkConnectivity();
  ///   return result != ConnectivityResult.none;
  /// });
  /// ```
  static void setConnectivityChecker(ConnectivityChecker? checker) {
    _connectivityChecker = checker;
  }

  /// Configures a callback to be notified when remote preferences load.
  ///
  /// This is useful for updating UI or triggering actions when remote data
  /// becomes available.
  ///
  /// Example:
  /// ```dart
  /// Prefs.setRemoteLoadCallback((success, attempt) {
  ///   if (success) {
  ///     print('Remote preferences loaded successfully!');
  ///     // Trigger UI update
  ///   } else {
  ///     print('Failed to load after $attempt attempts');
  ///     // Show offline mode banner
  ///   }
  /// });
  /// ```
  static void setRemoteLoadCallback(RemoteLoadCallback? callback) {
    _remoteLoadCallback = callback;
  }

  /// Configures the remote preferences implementation.
  ///
  /// This should be called once during initialization, typically by [PrefsManager].
  static void setRemotePreferences(RemotePrefs remotePrefs) {
    _remotePreferences = remotePrefs;
  }

  /// Manually triggers a remote preferences reload.
  ///
  /// This method allows you to manually load remote preferences on demand,
  /// bypassing the automatic retry mechanism. This is useful when:
  /// - User just authenticated and you want immediate remote data
  /// - Network connectivity was restored and you want to retry immediately
  /// - App returned from background and you want to refresh data
  ///
  /// Example:
  /// ```dart
  /// // After user login
  /// await userAuth.signIn();
  /// await Prefs.reloadRemotePreferences(); // Load user's remote prefs immediately
  /// ```
  ///
  /// Returns `true` if preferences were loaded successfully, `false` otherwise.
  static Future<bool> reloadRemotePreferences() async {
    if (_remotePreferences == null) {
      _logger(PrefsLogLevel.warning,
          'Cannot reload: Remote preferences not configured');
      return false;
    }

    try {
      final remoteValues = await _remotePreferences!.getPreferences();

      if (remoteValues == null) {
        _logger(PrefsLogLevel.warning,
            'Remote preferences returned null (user not authenticated?)');
        return false;
      }

      // Update cache with remote values
      _preferencesCache.addAll(remoteValues);
      _logger(PrefsLogLevel.info,
          'Successfully reloaded ${remoteValues.length} remote preferences');

      // Notify callback if set
      _remoteLoadCallback?.call(true, 1);

      return true;
    } catch (e) {
      _logger(PrefsLogLevel.error, 'Failed to reload remote preferences: $e');
      _remoteLoadCallback?.call(false, 1);
      return false;
    }
  }

  /// Loads all preferences into the in-memory cache.
  ///
  /// This method:
  /// 1. Loads local preferences from SharedPreferences
  /// 2. Loads remote preferences with automatic retry logic
  /// 3. Initializes volatile preferences (empty until set)
  ///
  /// Called automatically by [PrefsManager.init()].
  ///
  /// [preferences] is a map of preference keys to their storage types.
  static Future<void> loadPreferences(Map<String, PrefType> preferences) async {
    final localPrefs = await SharedPreferences.getInstance();

    // Load local preferences
    for (final entry in preferences.entries) {
      final key = entry.key;
      final type = entry.value;

      if (type == PrefType.local) {
        try {
          _preferencesCache[key] = localPrefs.get(key);
          if (_preferencesCache[key] is List) {
            _preferencesCache[key] = localPrefs.getStringList(key);
          }
        } catch (e) {
          _logger(
              PrefsLogLevel.error, 'Error loading local preference "$key": $e');
        }
      }
      // Volatile preferences are not loaded from any persistent storage
      // They are initialized with null or their default value when using get()
    }

    // Load remote preferences with retry logic and connectivity awareness
    if (_remotePreferences != null) {
      await _loadRemotePreferencesWithRetry(preferences);
    }
  }

  /// Gets a preference value from the cache.
  ///
  /// [key] is the unique identifier for the preference.
  /// [defaultValue] is returned if the preference is not found in cache.
  ///
  /// Returns the cached value or [defaultValue] if not present.
  ///
  /// Example:
  /// ```dart
  /// final theme = Prefs.get<String>('theme', defaultValue: 'dark');
  /// ```
  static T get<T>(String key, {required T defaultValue}) =>
      _preferencesCache[key] as T? ?? defaultValue;

  /// Sets a preference value and updates the cache.
  ///
  /// [k] is the preference key.
  /// [v] is the value to store.
  /// [type] determines where the value is persisted:
  /// - [PrefType.local]: Saved to SharedPreferences
  /// - [PrefType.remote]: Saved to remote backend (if configured)
  /// - [PrefType.volatile]: Stored only in memory cache
  ///
  /// Example:
  /// ```dart
  /// await Prefs.set('theme', 'light', type: PrefType.local);
  /// ```
  static Future<void> set<T>(String k, T v, {required PrefType type}) async {
    _preferencesCache[k] = v;

    if (type == PrefType.local) {
      await _saveLocal(k, v);
    } else if (type == PrefType.remote && _remotePreferences != null) {
      await _remotePreferences!.setPreference(k, v);
    }
    // If type == PrefType.volatile, only save in _preferencesCache (memory)
  }

  /// Loads remote preferences with automatic retry logic and connectivity awareness.
  ///
  /// Attempts to load preferences every 10 seconds until successful or
  /// max retries is reached. The retry count is configured via [setMaxRetries()].
  ///
  /// If [_connectivityChecker] is set, checks network status before each attempt.
  /// Notifies [_remoteLoadCallback] when loading completes.
  ///
  /// If max retries is 0, will retry indefinitely until successful.
  static Future<void> _loadRemotePreferencesWithRetry(
      Map<String, PrefType> preferences) async {
    final completer = Completer<void>();
    var retryCount = 0;

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      // Check connectivity before attempting load
      if (_connectivityChecker != null) {
        final hasConnectivity = await _connectivityChecker!();
        if (!hasConnectivity) {
          _logger(
            PrefsLogLevel.warning,
            'No connectivity detected, skipping remote load (attempt ${retryCount + 1})',
          );
          // Don't increment retry count for connectivity issues
          return;
        }
      }

      final remoteValues = await _remotePreferences!.getPreferences();

      if (remoteValues != null) {
        // Filter and store only defined preferences
        for (final entry in preferences.entries) {
          if (entry.value != PrefType.remote) {
            continue;
          }

          final key = entry.key;

          if (remoteValues.containsKey(key)) {
            _preferencesCache[key] = remoteValues[key];
          }
        }

        _logger(
          PrefsLogLevel.info,
          'Remote preferences loaded successfully after ${retryCount + 1} attempt(s)',
        );
        _remoteLoadCallback?.call(true, retryCount + 1);
        timer.cancel();
        completer.complete();
      } else {
        retryCount++;
        if (_maxRetries > 0 && retryCount >= _maxRetries) {
          _logger(
            PrefsLogLevel.warning,
            'Failed to load remote preferences after $_maxRetries attempts. Giving up.',
          );
          _remoteLoadCallback?.call(false, retryCount);
          timer.cancel();
          completer.complete();
        } else {
          _logger(
            PrefsLogLevel.warning,
            'Could not load remote preferences, retrying in 10 seconds... (attempt $retryCount/${_maxRetries > 0 ? _maxRetries : "∞"})',
          );
        }
      }
    });

    // Wait until remote preferences load successfully
    return completer.future;
  }

  /// Saves a value to local storage (SharedPreferences).
  static Future<bool> _saveLocal(String key, dynamic value) async {
    try {
      final localPrefs = await SharedPreferences.getInstance();

      bool success;
      if (value is String) {
        success = await localPrefs.setString(key, value);
      } else if (value is bool) {
        success = await localPrefs.setBool(key, value);
      } else if (value is int) {
        success = await localPrefs.setInt(key, value);
      } else if (value is double) {
        success = await localPrefs.setDouble(key, value);
      } else if (value is List<String>) {
        success = await localPrefs.setStringList(key, value);
      } else {
        _logger(
          PrefsLogLevel.error,
          'Unsupported data type for preference "$key": ${value.runtimeType}. '
          'Supported types: String, bool, int, double, List<String>',
        );
        return false;
      }

      if (!success) {
        _logger(
            PrefsLogLevel.warning, 'Failed to save local preference "$key"');
      }
      return success;
    } catch (e, stackTrace) {
      _logger(
        PrefsLogLevel.error,
        'Error saving local preference "$key": $e\n$stackTrace',
      );
      return false;
    }
  }
}
