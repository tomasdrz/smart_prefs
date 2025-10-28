# Smart Prefs - Roadmap and Future Improvements

**Package**: smart_prefs  
**Version**: 0.1.0  
**Last Updated**: January 28, 2025  
**Status**: ✅ Published on pub.dev

---

## ✅ Completed (v0.1.0)

### Core Features
- ✅ Three storage types: local, remote, volatile
- ✅ Type-safe enum-based API
- ✅ Configurable logging system
- ✅ Automatic retry with connectivity checking
- ✅ Remote load callbacks
- ✅ Manual reload method
- ✅ Robust error handling
- ✅ Comprehensive documentation
- ✅ 100% test coverage (39 tests passing)

### Publication Requirements
- ✅ LICENSE (MIT)
- ✅ Complete pubspec.yaml
- ✅ Professional README.md
- ✅ CHANGELOG.md
- ✅ Working examples
- ✅ API documentation
- ✅ Package validation (0 warnings)

---

## 🎯 Future Roadmap

### Version 0.2.0 (Planned)

#### Stream-based Change Notifications (watch API)
```dart
// Watch a preference for changes
UserPrefs.theme.watch().listen((newTheme) {
  print('Theme changed to: $newTheme');
});
```

**Benefits:**
- Reactive programming support
- Real-time UI updates
- Memory-efficient with StreamController

**Implementation:**
- Add `Stream<T> watch()` extension method
- Maintain StreamController per preference
- Auto-dispose when no listeners

---

#### Batch Operations
```dart
// Set multiple preferences in one transaction
await Prefs.setBatch({
  'theme': 'dark',
  'locale': 'es',
  'notifications': true,
});
```

**Benefits:**
- Better performance (single write operation)
- Atomic transactions (all-or-nothing)
- Cleaner code for bulk updates

**Implementation:**
- `Prefs.setBatch(Map<String, dynamic>)`
- `Prefs.clearBatch(List<String> keys)`
- Transaction support for remote backends

---

#### Value Validation Framework
```dart
enum UserPrefs implements Pref {
  age(
    PrefType.local,
    18,
    validator: RangeValidator(min: 13, max: 120),
  ),
  email(
    PrefType.remote,
    '',
    validator: RegexValidator(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'),
  ),
  ;
}
```

**Benefits:**
- Prevent invalid data at the source
- Clear error messages for users
- Type-safe validation rules

**Implementation:**
- `PrefValidator<T>` interface
- Built-in validators: `RangeValidator`, `RegexValidator`, `EnumValidator`
- Custom validators support

---

#### Schema Migration System
```dart
class PrefsMigration {
  static void migrate(int fromVersion, int toVersion) {
    if (fromVersion < 2) {
      // Migrate dashboardTab from int to String
      final oldValue = Prefs.get<int>('dashboardTab', -1);
      Prefs.set('dashboardTab', oldValue.toString());
    }
  }
}
```

**Benefits:**
- Safe upgrades between versions
- Preserve user data during migrations
- Backwards compatibility

**Implementation:**
- Version tracking in SharedPreferences
- Migration callbacks per version
- Automatic detection and execution

---

#### Secure Storage Option
```dart
enum SecurePrefs implements Pref {
  authToken(PrefType.secure, ''),  // Uses flutter_secure_storage
  apiKey(PrefType.secure, ''),
  ;
}
```

**Benefits:**
- Encrypted storage for sensitive data
- Platform-native secure storage (Keychain, KeyStore)
- Same API as regular preferences

**Implementation:**
- `PrefType.secure` storage type
- Integration with `flutter_secure_storage`
- Fallback to encrypted SharedPreferences on unsupported platforms

---

### Version 0.3.0 (Ideas)

#### JSON Serialization for Complex Objects
```dart
enum AppPrefs implements Pref<UserSettings> {
  settings(
    PrefType.local,
    UserSettings(),
    codec: JsonCodec<UserSettings>(),
  ),
  ;
}
```

**Benefits:**
- Store complex objects directly
- Type-safe serialization
- Custom codec support

**Implementation:**
- Generic type support in Pref
- `PrefCodec<T>` interface
- Auto-generated codecs with code generation

---

#### Bidirectional Remote Sync
```dart
// Listen for remote changes
Prefs.setRemoteSyncListener((changes) {
  print('Remote changes detected: $changes');
  // Update local cache automatically
});
```

**Benefits:**
- Multi-device synchronization
- Real-time updates from server
- Conflict resolution strategies

**Implementation:**
- WebSocket support (optional)
- Polling mechanism (fallback)
- Last-write-wins or custom conflict resolution

---

#### DevTools Extension
- Visual inspector for all preferences
- Edit values in real-time during development
- Debug panel showing sync status, retry attempts, logs
- Export/import preferences for testing

---

### Version 0.4.0+ (Future)

#### Type Safety Improvements
- Replace `dynamic` with sealed classes or union types
- `PrefValue` sealed class with subtypes: `StringValue`, `IntValue`, `BoolValue`, `DoubleValue`, `StringListValue`
- Compile-time validation of supported types

#### Performance Optimizations
- Lazy loading of preferences
- Batch reads from SharedPreferences
- Cache invalidation strategies
- Memory usage optimization

#### Developer Experience
- Better error messages with actionable suggestions
- Debugging utilities and performance profiler
- Migration assistant for breaking changes
- Comprehensive integration tests

---

## 🔍 Known Limitations (v0.1.0)

1. **Type System**: Uses `dynamic` for default values (runtime validation only)
2. **Synchronization**: One-way sync (local ← remote), no remote ← local polling
3. **Data Types**: Limited to primitives and `List<String>`, no complex objects
4. **Conflict Resolution**: Last-write-wins, no merge strategies
5. **Schema Versioning**: No automatic migration between versions

These will be addressed in future releases based on community feedback and usage patterns.

---

## 📚 Resources

- **Package on pub.dev**: [pub.dev/packages/smart_prefs](https://pub.dev/packages/smart_prefs)
- **GitHub Repository**: [github.com/tomasdrz/smile_baby](https://github.com/tomasdrz/smile_baby)
- **Issue Tracker**: [GitHub Issues](https://github.com/tomasdrz/smile_baby/issues)
- **Documentation**: See README.md and REMOTE_SETUP.md

---

## 🤝 Contributing

We welcome contributions! Please see the repository for:
- Feature requests and ideas
- Bug reports
- Pull requests with improvements
- Documentation updates

---

*This roadmap is subject to change based on community feedback and priorities.*
