import '_imports.dart';

/// Base interface for defining type-safe preferences.
///
/// Implement this interface using enums to create strongly-typed preferences
/// with automatic key generation and default values.
///
/// Example:
/// ```dart
/// enum UserPrefs implements Pref {
///   theme(PrefType.local, 'dark'),
///   language(PrefType.local, 'en'),
///   userId(PrefType.remote, ''),
///   sessionToken(PrefType.volatile, ''),
///   ;
///
///   @override
///   final PrefType storageType;
///   @override
///   final dynamic defaultValue;
///   @override
///   String get key => name;
///
///   const UserPrefs(this.storageType, this.defaultValue);
/// }
/// ```
abstract class Pref {
  const Pref(this.storageType, this.defaultValue);

  /// The storage type for this preference.
  final PrefType storageType;

  /// The default value to use if the preference is not set.
  final dynamic defaultValue;

  /// The unique key for this preference.
  ///
  /// When using enums, this is typically the enum's name.
  String get key;
}

/// Storage types for preferences.
///
/// Each type has different persistence characteristics:
///
/// - [local]: Persisted locally using SharedPreferences (localStorage on web).
///   Survives app restarts but not reinstalls.
///
/// - [remote]: Persisted in remote storage (e.g., Supabase, Firebase).
///   Syncs across devices and survives reinstalls.
///
/// - [volatile]: Kept only in memory during the current session.
///   Lost when the app closes or reloads.
enum PrefType {
  /// Persists locally on the device using SharedPreferences.
  ///
  /// - ✅ Survives app restarts
  /// - ✅ Works offline
  /// - ❌ Lost on app reinstall
  /// - ❌ Not synced across devices
  local,

  /// Persists in remote storage configured via [RemotePrefs].
  ///
  /// - ✅ Survives app restarts and reinstalls
  /// - ✅ Syncs across devices
  /// - ⚠️ Requires network connection
  /// - ⚠️ Slower than local storage
  remote,

  /// Stored only in memory for the current session.
  ///
  /// - ✅ Very fast access
  /// - ❌ Lost on app close/reload
  /// - ❌ Not persisted anywhere
  volatile,
}

/// Extension methods for convenient preference access.
///
/// These methods allow you to read and write preferences directly from
/// enum values without accessing the underlying storage.
extension PrefExtensions on Pref {
  /// Gets the current value of this preference.
  ///
  /// [defaultValueOverride] can be used to provide a different default value
  /// than the one defined in the preference definition.
  ///
  /// Example:
  /// ```dart
  /// final theme = UserPrefs.theme.get<String>();
  /// final customDefault = UserPrefs.theme.get<String>(defaultValueOverride: 'light');
  /// ```
  T get<T>({T? defaultValueOverride}) {
    final defaultVal = defaultValueOverride ?? defaultValue as T;
    return Prefs.get<T>(key, defaultValue: defaultVal);
  }

  /// Sets a new value for this preference.
  ///
  /// The value is stored according to the preference's [storageType]:
  /// - [PrefType.local]: Saved to SharedPreferences
  /// - [PrefType.remote]: Saved to remote backend
  /// - [PrefType.volatile]: Stored only in memory
  ///
  /// Example:
  /// ```dart
  /// await UserPrefs.theme.set('dark');
  /// await UserPrefs.userId.set('user123');
  /// ```
  Future<void> set<T>(T value) async {
    await Prefs.set<T>(key, value, type: storageType);
  }

  /// Resets this preference to its default value.
  ///
  /// Example:
  /// ```dart
  /// await UserPrefs.theme.clear(); // Resets to default value
  /// ```
  Future<void> clear() async {
    await Prefs.set<dynamic>(key, defaultValue, type: storageType);
  }
}
