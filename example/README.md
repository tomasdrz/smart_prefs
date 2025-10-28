# Example Usage

This directory contains example implementations for the `prefs` package.

## 📁 Files

### 1. `main.dart` - Basic Example
Simple demonstration of the prefs package with an in-memory mock backend.

**Features**:
- Local preferences (SharedPreferences)
- Remote preferences (mock in-memory)
- Volatile preferences (memory only)
- Custom logging
- Remote load callbacks

**Run**:
```bash
# Using Flutter (recommended)
flutter run -t example/main.dart

# Note: Cannot use 'dart run' because SharedPreferences requires Flutter
```

---

### 2. `sqlite_example.dart` - Offline-First Pattern
Advanced example showing SQLite as offline-first storage with cloud sync.

⚠️ **IMPORTANT**: This example is **commented out by default** to avoid dependency errors when running the basic example.

**To use this example**:

1. **Uncomment the code** in `sqlite_example.dart`
2. **Add dependencies** to your Flutter project's `pubspec.yaml`:
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

**Features**:
- SQLite local database for preferences
- Offline-first architecture
- Manual sync to cloud backend (Firebase/Supabase)
- Track unsynced changes
- Multi-device sync simulation
- Pull/push from cloud

**Why commented out?**

The prefs package is lightweight and doesn't force SQLite on users.
This example shows HOW to implement the pattern if you need it, but it's
commented out to prevent dependency errors in the main package.

**Important**: 
- This is a **template/pattern** to copy to your own project
- It shows HOW to implement offline-first with SQLite
- sqflite requires Flutter - won't run in pure Dart
- In a real app, you'd implement your own sync logic

---

## 🏗️ Architecture Comparison

### Basic Example (main.dart)
```
App → prefs → RemotePrefs (in-memory mock)
```

### SQLite Example (sqlite_example.dart)
```
App → prefs → SQLitePrefs → Local SQLite DB
                          ↓↑
                    Cloud Backend (Firebase/Supabase)
```

---

## 📚 Learn More

- **README.md**: Package documentation
- **REMOTE_SETUP.md**: Detailed guide for Firebase, Supabase, REST APIs, and SQLite
- **API Documentation**: Generated docs at pub.dev (after publication)

---

## 🎯 Quick Start

1. **Try the basic example first**:
   ```bash
   dart run example/main.dart
   ```

2. **Read REMOTE_SETUP.md** to understand backend implementations

3. **Review sqlite_example.dart** if you need offline-first architecture

4. **Implement your own RemotePrefs** based on your backend (Firebase, Supabase, etc.)
