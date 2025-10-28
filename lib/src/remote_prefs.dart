/// Abstract interface for implementing remote preference storage.
///
/// Extend this class to integrate with any backend service like Firebase,
/// Supabase, custom REST APIs, etc.
///
/// The mixin [_PrefsConverter] provides helper methods for type conversion
/// between Dart types and string representations suitable for storage.
///
/// Example implementation:
/// ```dart
/// class FirebasePrefs extends RemotePrefs {
///   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
///
///   @override
///   Future<Map<String, dynamic>?> getPreferences() async {
///     final userId = FirebaseAuth.instance.currentUser?.uid;
///     if (userId == null) return null;
///
///     final doc = await _firestore.collection('prefs').doc(userId).get();
///     // ... parse and return preferences
///   }
///
///   @override
///   Future<void> setPreference(String key, dynamic value) async {
///     final userId = FirebaseAuth.instance.currentUser?.uid;
///     if (userId == null) return;
///
///     final typed = toTypedValue(value);
///     await _firestore.collection('prefs').doc(userId).update({
///       key: typed.toMap(),
///     });
///   }
/// }
/// ```
abstract class RemotePrefs with _PrefsConverter {
  /// Fetches all remote preferences for the current user.
  ///
  /// Returns a map of preference keys to their values, or `null` if the user
  /// is not authenticated or preferences cannot be loaded.
  ///
  /// Return an empty map `{}` if the user has no preferences yet.
  Future<Map<String, dynamic>?> getPreferences();

  /// Saves a single preference to remote storage.
  ///
  /// [key] is the unique identifier for the preference.
  /// [value] is the value to store (String, bool, int, double, etc.).
  ///
  /// Use [toTypedValue()] to convert the value to a storable format.
  Future<void> setPreference(String key, dynamic value);
}

/// Helper mixin for converting between Dart types and storage formats.
///
/// Provides methods to serialize and deserialize preference values.
mixin _PrefsConverter {
  /// Parses a string value back to its original Dart type.
  ///
  /// [value] is the string representation.
  /// [dataType] indicates the target type: 'bool', 'int', 'double', or 'string'.
  ///
  /// Example:
  /// ```dart
  /// final result = parseFromString('true', 'bool'); // Returns bool true
  /// ```
  dynamic parseFromString(String value, String dataType) {
    switch (dataType) {
      case 'bool':
        return value.toLowerCase() == 'true';
      case 'int':
        return int.tryParse(value) ?? 0;
      case 'double':
        return double.tryParse(value) ?? 0.0;
      default:
        return value;
    }
  }

  /// Converts a Dart value to a typed storage format.
  ///
  /// Analyzes the runtime type and creates a [TypedValue] containing
  /// both the type name and string representation.
  ///
  /// Supported types: String, bool, int, double (defaults to 'string' for others).
  ///
  /// Example:
  /// ```dart
  /// final typed = toTypedValue(42);
  /// // TypedValue(dataType: 'int', value: '42')
  /// ```
  TypedValue toTypedValue(dynamic value) {
    String dataType;

    switch (value.runtimeType) {
      case const (bool):
        dataType = 'bool';
        break;
      case const (int):
        dataType = 'int';
        break;
      case const (double):
        dataType = 'double';
        break;
      default:
        dataType = 'string';
    }

    return TypedValue(dataType, value.toString());
  }
}

/// Represents a value with its type information for storage.
///
/// Used to store preferences in remote backends that require explicit
/// type information (like storing everything as strings).
class TypedValue {
  TypedValue(this.dataType, this.value);

  /// The data type: 'string', 'bool', 'int', or 'double'.
  final String dataType;

  /// The string representation of the value.
  final String value;

  /// Converts to a map suitable for storage.
  ///
  /// Returns a map with 'value' and 'data_type' keys.
  Map<String, String> toMap() => {
        'value': value,
        'data_type': dataType,
      };
}
