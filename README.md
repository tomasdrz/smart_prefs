# Smart Prefs

A flexible, type-safe preference management system for Flutter and Dart supporting local, remote, and volatile storage with an elegant enum-based API.

[![pub package](https://img.shields.io/pub/v/smart_prefs.svg)](https://pub.dev/packages/smart_prefs)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 🎯 **Type-safe**: Strongly-typed preferences using Dart enums
- 💾 **Triple storage**: Local (SharedPreferences), Remote (extensible), and Volatile (memory)
- 🚀 **Fast**: In-memory caching for instant access
- 🔌 **Extensible**: Implement `RemotePrefs` for any backend (Firebase, Supabase, etc.)
- 🪶 **Lightweight**: Minimal dependencies
- 📝 **Well-documented**: Comprehensive API documentation
- 🛡️ **Robust**: Built-in error handling and retry logic
- 🔍 **Observable**: Configurable logging system

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  smart_prefs: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### 1. Define your preferences

Create an enum that implements `Pref`:

```dart
import 'package:smart_prefs/smart_prefs.dart';

enum UserPrefs implements Pref {
  // Local preferences (persisted on device)
  theme(PrefType.local, 'dark'),
  language(PrefType.local, 'en'),
  isFirstLaunch(PrefType.local, true),
  
  // Remote preferences (synced across devices)
  userId(PrefType.remote, ''),
  isPremium(PrefType.remote, false),
  
  // Volatile preferences (session only)
  sessionToken(PrefType.volatile, ''),
  ;

  @override
  final PrefType storageType;
  @override
  final dynamic defaultValue;
  @override
  String get key => name;

  const UserPrefs(this.storageType, this.defaultValue);
}
```

### 2. Initialize the system

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize preferences
  final prefsManager = PrefsManager(
    remote: MyRemotePrefs(), // Your RemotePrefs implementation
    enumValues: [UserPrefs.values],
  );
  await prefsManager.init();
  
  runApp(MyApp());
}
```

### 3. Use preferences

```dart
// Read a preference
final theme = UserPrefs.theme.get<String>();
final isPremium = UserPrefs.isPremium.get<bool>();

// Write a preference
await UserPrefs.theme.set('light');
await UserPrefs.userId.set('user123');

// Reset to default
await UserPrefs.theme.clear();
```

## 🎨 Storage Types

### Local Storage (`PrefType.local`)

Persisted locally using SharedPreferences (localStorage on web).

- ✅ Survives app restarts
- ✅ Works offline
- ❌ Lost on app reinstall
- ❌ Not synced across devices

**Use for**: Settings, UI state, filters, onboarding status

### Remote Storage (`PrefType.remote`)

Persisted in remote storage (configurable backend).

- ✅ Survives app restarts and reinstalls
- ✅ Syncs across devices
- ⚠️ Requires network connection
- ⚠️ Slower than local storage

**Use for**: User profile data, subscription status, cross-device settings

### Volatile Storage (`PrefType.volatile`)

Stored only in memory for the current session.

- ✅ Very fast access
- ❌ Lost on app close/reload
- ❌ Not persisted anywhere

**Use for**: Session tokens, temporary flags, cache data

## 🔌 Implementing Remote Storage

Create a class that extends `RemotePrefs`:

```dart
import 'package:smart_prefs/smart_prefs.dart';

class FirebasePrefs extends RemotePrefs {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;
    
    final doc = await _firestore
        .collection('preferences')
        .doc(userId)
        .get();
    
    if (!doc.exists) return {};
    
    final data = doc.data()!;
    Map<String, dynamic> preferences = {};
    
    for (var entry in data.entries) {
      final typedValue = entry.value as Map<String, dynamic>;
      preferences[entry.key] = parseFromString(
        typedValue['value'],
        typedValue['data_type'],
      );
    }
    
    return preferences;
  }
  
  @override
  Future<void> setPreference(String key, dynamic value) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final typedValue = toTypedValue(value);
    
    await _firestore
        .collection('preferences')
        .doc(userId)
        .set({
      key: typedValue.toMap(),
    }, SetOptions(merge: true));
  }
}
```

## 🔍 Logging

Configure custom logging:

```dart
Prefs.setLogger((level, message) {
  if (level == PrefsLogLevel.error) {
    // Send to error tracking service
    Sentry.captureMessage(message);
  }
  print('[${level.name}] $message');
});
```

Disable logging:

```dart
Prefs.setLogger((level, message) {
  // Do nothing
});
```

## ⚙️ Configuration

### Set maximum retries for remote loading

```dart
// Default is 6 retries (1 minute with 10-second intervals)
Prefs.setMaxRetries(10);

// Disable retries (retry indefinitely)
Prefs.setMaxRetries(0);
```

### Configure connectivity checking

Improve retry logic by checking network connectivity before each attempt:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

Prefs.setConnectivityChecker(() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
});
```

This prevents unnecessary retry attempts when the device is offline.

### Manually reload remote preferences

Trigger an immediate reload of remote preferences (bypasses automatic retry):

```dart
// After user authentication
await userAuth.signIn();

// Manually load remote preferences immediately
final success = await Prefs.reloadRemotePreferences();

if (success) {
  print('Remote preferences loaded successfully!');
  // Update UI with user data
} else {
  print('Failed to load preferences (user not authenticated or network error)');
}
```

**Use cases**:
- After user login: Load their remote preferences immediately
- Network restored: Retry loading when connectivity is back
- Pull-to-refresh: Let users manually trigger a data refresh
- Background sync: Reload when app returns from background

### Monitor remote loading progress

Get notified when remote preferences finish loading:

```dart
Prefs.setRemoteLoadCallback((bool success, int attempts) {
  if (success) {
    print('✅ Remote preferences loaded after $attempts attempt(s)');
    // Update UI to show online features
  } else {
    print('❌ Failed to load remote preferences after $attempts attempts');
    // Show offline mode banner
  }
});
```

### Complete advanced setup

```dart
await Prefs.init(
  preferences: Pref.values,
  remotePreferences: MyRemotePrefs(),
);

// Configure intelligent retry
Prefs.setMaxRetries(5);
Prefs.setConnectivityChecker(() async {
  final result = await Connectivity().checkConnectivity();
  return result != ConnectivityResult.none;
});

Prefs.setRemoteLoadCallback((success, attempts) {
  if (success) {
    // Refresh UI with remote data
    MyApp.refreshRemoteData();
  }
});

// Manually reload when needed
ElevatedButton(
  onPressed: () async {
    await Prefs.reloadRemotePreferences();
  },
  child: Text('Refresh Data'),
);
```

For detailed guidance on implementing remote storage backends (Firebase, Supabase, REST APIs, SQLite offline-first, etc.), see [REMOTE_SETUP.md](REMOTE_SETUP.md).

## 📊 Supported Data Types

The following types are supported for local storage:

- `String`
- `bool`
- `int`
- `double`
- `List<String>`

Remote storage can support any type that your backend implementation handles.

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│  Your App (enum-based preferences)  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│       PrefExtensions (get/set)       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│      Prefs (core logic + cache)      │
└──┬──────────┬──────────────────┬────┘
   │          │                  │
   ▼          ▼                  ▼
┌─────┐  ┌─────────┐      ┌──────────┐
│Local│  │ Remote  │      │ Volatile │
│(SP) │  │(Custom) │      │ (Memory) │
└─────┘  └─────────┘      └──────────┘
```

## 🆚 Comparison with Other Solutions

| Feature                    | Prefs | shared_preferences | hive | get_storage |
|----------------------------|-------|-------------------|------|-------------|
| Type-safe enum API         | ✅    | ❌                | ❌   | ❌          |
| Remote storage support     | ✅    | ❌                | ❌   | ❌          |
| Volatile storage           | ✅    | ❌                | ❌   | ❌          |
| In-memory caching          | ✅    | ⚠️                | ✅   | ✅          |
| Multiple storage backends  | ✅    | ❌                | ❌   | ❌          |
| Automatic retry logic      | ✅    | ❌                | ❌   | ❌          |
| Configurable logging       | ✅    | ❌                | ❌   | ❌          |
| Web support                | ✅    | ✅                | ✅   | ✅          |

## 🧪 Testing

Use a mock `RemotePrefs` implementation for testing:

```dart
class MockRemotePrefs extends RemotePrefs {
  final Map<String, dynamic> _storage = {};
  
  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    return Map.from(_storage);
  }
  
  @override
  Future<void> setPreference(String key, dynamic value) async {
    _storage[key] = value;
  }
}
```

## 📚 Examples

The [example](example/) directory contains two complete examples:

### 1. Basic Example (`main.dart`)
Simple demonstration with in-memory mock backend:
```bash
dart run example/main.dart
```

Shows:
- Local, remote, and volatile preferences
- Custom logging
- Remote load callbacks
- Basic CRUD operations

### 2. SQLite Offline-First Example (`sqlite_example.dart`)
Advanced pattern for offline-first apps with cloud sync.

**⚠️ Note**: This example is **commented out** by default to avoid dependency errors. 

To use it:
1. Uncomment the code in `example/sqlite_example.dart`
2. Add required dependencies to your project:
   ```yaml
   dependencies:
     sqflite: ^2.3.0
     path: ^1.8.3
   ```
3. Run `flutter pub get`
4. Run the example:
   ```bash
   flutter run -t example/sqlite_example.dart
   ```

Demonstrates:
- SQLite as local database for offline-first architecture
- Manual sync to cloud backend (Firebase/Supabase)
- Multi-device synchronization
- Tracking unsynced changes
- Pull/push from cloud storage

See [REMOTE_SETUP.md](REMOTE_SETUP.md) for complete implementation details.

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) first.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Issues

Please file feature requests and bugs at the [issue tracker](https://github.com/tomasdrz/smile_baby/issues).

## 🙏 Acknowledgments

- Inspired by the simplicity of `shared_preferences`
- Built with Flutter and Dart best practices

---

Made with ❤️ by [Tomás Rueda](https://github.com/tomasdrz)
