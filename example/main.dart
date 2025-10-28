import 'package:smart_prefs/smart_prefs.dart';

/// Example implementation of remote preferences using a simple in-memory store.
///
/// In a real application, this would connect to Firebase, Supabase, or another
/// backend service.
class ExampleRemotePrefs extends RemotePrefs {
  ExampleRemotePrefs({required this.userId});

  // Simulate a remote database with an in-memory map
  static final Map<String, Map<String, String>> _database = {};
  final String userId;

  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Return null to simulate offline or not authenticated
    if (userId.isEmpty) {
      return null;
    }

    // Get user's preferences from "database"
    final userPrefs = _database[userId];
    if (userPrefs == null) {
      return {}; // User has no preferences yet
    }

    // Parse stored values back to their original types
    final Map<String, dynamic> preferences = {};
    for (final entry in userPrefs.entries) {
      final parts = entry.value.split('|');
      if (parts.length == 2) {
        final dataType = parts[0];
        final value = parts[1];
        preferences[entry.key] = parseFromString(value, dataType);
      }
    }

    return preferences;
  }

  @override
  Future<void> setPreference(String key, dynamic value) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (userId.isEmpty) return;

    // Store preference in "database"
    _database.putIfAbsent(userId, () => {});

    final typedValue = toTypedValue(value);
    _database[userId]![key] = '${typedValue.dataType}|${typedValue.value}';

    print('[RemotePrefs] Saved: $key = $value (${typedValue.dataType})');
  }
}

/// Example preferences for demonstration.
enum AppPrefs implements Pref {
  // Local preferences
  theme(PrefType.local, 'dark'),
  language(PrefType.local, 'en'),
  notificationsEnabled(PrefType.local, true),
  fontSize(PrefType.local, 14),

  // Remote preferences
  username(PrefType.remote, ''),
  isPremium(PrefType.remote, false),
  coins(PrefType.remote, 0),

  // Volatile preferences
  sessionId(PrefType.volatile, ''),
  lastApiCall(PrefType.volatile, ''),
  ;

  @override
  final PrefType storageType;
  @override
  final dynamic defaultValue;
  @override
  String get key => name;

  const AppPrefs(this.storageType, this.defaultValue);
}

void main() async {
  print('🚀 Prefs Package Example\n');

  // Initialize the preference system
  print('📦 Initializing preferences...');
  final prefsManager = PrefsManager(
    remote: ExampleRemotePrefs(userId: 'user123'),
    enumValues: [AppPrefs.values],
  );

  // Configure custom logger
  Prefs.setLogger((level, message) {
    final icon = switch (level) {
      PrefsLogLevel.debug => '🔍',
      PrefsLogLevel.info => 'ℹ️',
      PrefsLogLevel.warning => '⚠️',
      PrefsLogLevel.error => '❌',
      _ => '📝',
    };
    print('$icon [${level.name.toUpperCase()}] $message');
  });

  // Configure max retries
  Prefs.setMaxRetries(3);

  // Configure connectivity checker (optional - requires connectivity_plus package)
  // Prefs.setConnectivityChecker(() async {
  //   final result = await Connectivity().checkConnectivity();
  //   return result != ConnectivityResult.none;
  // });

  // Configure remote load callback to monitor loading progress
  Prefs.setRemoteLoadCallback((success, attempts) {
    if (success) {
      print(
          '✅ Remote preferences loaded successfully after $attempts attempt(s)!');
    } else {
      print('❌ Failed to load remote preferences after $attempts attempts');
      print('   (The app will continue with local preferences only)');
    }
  });

  await prefsManager.init();
  print('✅ Preferences initialized!\n');

  // Demonstrate local preferences
  print('📱 LOCAL PREFERENCES (SharedPreferences)');
  print('─' * 50);

  print('Current theme: ${AppPrefs.theme.get<String>()}');
  await AppPrefs.theme.set('light');
  print('Updated theme: ${AppPrefs.theme.get<String>()}');

  print('Font size: ${AppPrefs.fontSize.get<int>()}');
  await AppPrefs.fontSize.set(18);
  print('Updated font size: ${AppPrefs.fontSize.get<int>()}');

  print('Notifications: ${AppPrefs.notificationsEnabled.get<bool>()}');
  print('');

  // Demonstrate remote preferences
  print('☁️  REMOTE PREFERENCES (Cloud Storage)');
  print('─' * 50);

  print('Username: ${AppPrefs.username.get<String>()}');
  await AppPrefs.username.set('JohnDoe');
  print('Updated username: ${AppPrefs.username.get<String>()}');

  print('Premium status: ${AppPrefs.isPremium.get<bool>()}');
  await AppPrefs.isPremium.set(true);
  print('Updated premium: ${AppPrefs.isPremium.get<bool>()}');

  print('Coins: ${AppPrefs.coins.get<int>()}');
  await AppPrefs.coins.set(150);
  print('Updated coins: ${AppPrefs.coins.get<int>()}');
  print('');

  // Demonstrate volatile preferences
  print('💨 VOLATILE PREFERENCES (Memory Only)');
  print('─' * 50);

  print('Session ID: ${AppPrefs.sessionId.get<String>()}');
  await AppPrefs.sessionId.set('session-abc-123');
  print('Updated session ID: ${AppPrefs.sessionId.get<String>()}');
  print('(This will be lost when the app restarts)');
  print('');

  // Demonstrate clear
  print('🧹 CLEARING PREFERENCES');
  print('─' * 50);

  print('Before clear - Theme: ${AppPrefs.theme.get<String>()}');
  await AppPrefs.theme.clear();
  print('After clear - Theme: ${AppPrefs.theme.get<String>()}');
  print('(Reset to default value: ${AppPrefs.theme.defaultValue})');
  print('');

  // Demonstrate default value override
  print('🎯 DEFAULT VALUE OVERRIDE');
  print('─' * 50);

  print('Getting with normal default: ${AppPrefs.language.get<String>()}');
  print(
      'Getting with override default: ${AppPrefs.language.get<String>(defaultValueOverride: 'es')}');
  print('');

  print('✨ Example completed successfully!');
  print('\n📚 Supported types:');
  print('  • String');
  print('  • bool');
  print('  • int');
  print('  • double');
  print('  • List<String>');
}

// // =================== OFFLINE-FIRST EXAMPLE WITH SQLITE ===================

// // NOTE: This example requires the following packages in your pubspec.yaml:
// // dependencies:
// //   sqflite: ^2.3.0
// //   path: ^1.8.3
// //
// // This example demonstrates the SQLite offline-first pattern.
// // It will NOT run without adding these dependencies!
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// /// Example implementation of SQLite-based preferences with cloud sync.
// ///
// /// This demonstrates the offline-first pattern where:
// /// 1. SQLite stores preferences locally
// /// 2. Changes are marked as "unsynced"
// /// 3. Periodic sync uploads unsynced data to cloud backend
// /// 4. App works fully offline, syncs when online
// ///
// /// **Important**: This is YOUR implementation, not built into the prefs package.
// class SQLitePrefs extends RemotePrefs {
//   SQLitePrefs({required this.userId});

//   final String userId;
//   Database? _db;

//   /// Initialize the SQLite database
//   Future<void> init() async {
//     final databasePath = await getDatabasesPath();
//     final path = join(databasePath, 'preferences.db');

//     _db = await openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {
//         await db.execute('''
//           CREATE TABLE preferences (
//             user_id TEXT NOT NULL,
//             key TEXT NOT NULL,
//             value TEXT NOT NULL,
//             data_type TEXT NOT NULL,
//             synced INTEGER NOT NULL DEFAULT 0,
//             updated_at INTEGER NOT NULL,
//             PRIMARY KEY (user_id, key)
//           )
//         ''');
//         print('[SQLite] Database created');
//       },
//     );
//     print('[SQLite] Database initialized at: $path');
//   }

//   @override
//   Future<Map<String, dynamic>?> getPreferences() async {
//     if (_db == null) {
//       print('[SQLite] Database not initialized');
//       return null;
//     }

//     if (userId.isEmpty) {
//       print('[SQLite] No user ID provided');
//       return null;
//     }

//     try {
//       final results = await _db!.query(
//         'preferences',
//         where: 'user_id = ?',
//         whereArgs: [userId],
//       );

//       final Map<String, dynamic> preferences = {};

//       for (final row in results) {
//         final key = row['key'] as String;
//         final value = row['value'] as String;
//         final dataType = row['data_type'] as String;

//         preferences[key] = parseFromString(value, dataType);
//       }

//       print('[SQLite] Loaded ${preferences.length} preferences for user: $userId');
//       return preferences;
//     } catch (e) {
//       print('[SQLite] Error loading preferences: $e');
//       return null;
//     }
//   }

//   @override
//   Future<void> setPreference(String key, dynamic value) async {
//     if (_db == null || userId.isEmpty) return;

//     try {
//       final typedValue = toTypedValue(value);

//       await _db!.insert(
//         'preferences',
//         {
//           'user_id': userId,
//           'key': key,
//           'value': typedValue.value,
//           'data_type': typedValue.dataType,
//           'synced': 0, // Mark as unsynced
//           'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
//         },
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );

//       print('[SQLite] Saved: $key = $value (unsynced)');
//     } catch (e) {
//       print('[SQLite] Error saving preference: $e');
//     }
//   }

//   /// Get count of unsynced preferences
//   Future<int> getUnsyncedCount() async {
//     if (_db == null) return 0;

//     final result = await _db!.rawQuery(
//       'SELECT COUNT(*) as count FROM preferences WHERE user_id = ? AND synced = 0',
//       [userId],
//     );

//     return Sqflite.firstIntValue(result) ?? 0;
//   }

//   /// Sync unsynced preferences to a cloud backend
//   Future<bool> syncToCloud(RemotePrefs cloudBackend) async {
//     if (_db == null) {
//       print('[SQLite] Cannot sync: database not initialized');
//       return false;
//     }

//     try {
//       // Get all unsynced preferences
//       final unsynced = await _db!.query(
//         'preferences',
//         where: 'user_id = ? AND synced = 0',
//         whereArgs: [userId],
//       );

//       if (unsynced.isEmpty) {
//         print('[SQLite] Nothing to sync');
//         return true;
//       }

//       print('[SQLite] Syncing ${unsynced.length} preferences to cloud...');

//       // Upload each unsynced preference
//       for (final row in unsynced) {
//         final key = row['key'] as String;
//         final value = parseFromString(
//           row['value'] as String,
//           row['data_type'] as String,
//         );

//         // Upload to cloud backend (Firebase, Supabase, etc.)
//         await cloudBackend.setPreference(key, value);

//         // Mark as synced in SQLite
//         await _db!.update(
//           'preferences',
//           {'synced': 1},
//           where: 'user_id = ? AND key = ?',
//           whereArgs: [userId, key],
//         );

//         print('[SQLite] ✓ Synced: $key');
//       }

//       print('[SQLite] ✅ Sync completed successfully');
//       return true;
//     } catch (e) {
//       print('[SQLite] ❌ Sync failed: $e');
//       return false;
//     }
//   }

//   /// Pull remote changes from cloud to SQLite
//   Future<bool> pullFromCloud(RemotePrefs cloudBackend) async {
//     if (_db == null) return false;

//     try {
//       print('[SQLite] Pulling preferences from cloud...');

//       // Get all preferences from cloud
//       final cloudPrefs = await cloudBackend.getPreferences();
//       if (cloudPrefs == null) {
//         print('[SQLite] No cloud preferences available');
//         return false;
//       }

//       // Update local SQLite with cloud data
//       for (final entry in cloudPrefs.entries) {
//         final typedValue = toTypedValue(entry.value);

//         await _db!.insert(
//           'preferences',
//           {
//             'user_id': userId,
//             'key': entry.key,
//             'value': typedValue.value,
//             'data_type': typedValue.dataType,
//             'synced': 1, // Already synced with cloud
//             'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
//           },
//           conflictAlgorithm: ConflictAlgorithm.replace,
//         );
//       }

//       print('[SQLite] ✅ Pulled ${cloudPrefs.length} preferences from cloud');
//       return true;
//     } catch (e) {
//       print('[SQLite] ❌ Pull failed: $e');
//       return false;
//     }
//   }

//   /// Close the database connection
//   Future<void> close() async {
//     await _db?.close();
//     _db = null;
//     print('[SQLite] Database closed');
//   }
// }

// /// Mock cloud backend for demonstration
// class MockFirebasePrefs extends RemotePrefs {
//   MockFirebasePrefs({required this.userId});

//   final String userId;

//   // Simulate Firebase with in-memory storage
//   static final Map<String, Map<String, String>> _cloudStorage = {};

//   @override
//   Future<Map<String, dynamic>?> getPreferences() async {
//     // Simulate network delay
//     await Future<void>.delayed(const Duration(milliseconds: 800));

//     if (userId.isEmpty) return null;

//     final userPrefs = _cloudStorage[userId];
//     if (userPrefs == null) return {};

//     final Map<String, dynamic> preferences = {};
//     for (final entry in userPrefs.entries) {
//       final parts = entry.value.split('|');
//       if (parts.length == 2) {
//         preferences[entry.key] = parseFromString(parts[1], parts[0]);
//       }
//     }

//     print('[Firebase] Retrieved ${preferences.length} preferences from cloud');
//     return preferences;
//   }

//   @override
//   Future<void> setPreference(String key, dynamic value) async {
//     // Simulate network delay
//     await Future<void>.delayed(const Duration(milliseconds: 300));

//     if (userId.isEmpty) return;

//     _cloudStorage.putIfAbsent(userId, () => {});

//     final typedValue = toTypedValue(value);
//     _cloudStorage[userId]![key] = '${typedValue.dataType}|${typedValue.value}';

//     print('[Firebase] Saved to cloud: $key = $value');
//   }
// }

// /// Example preferences
// enum UserPrefs implements Pref {
//   // Settings that sync to cloud
//   theme(PrefType.remote, 'dark'),
//   language(PrefType.remote, 'en'),
//   fontSize(PrefType.remote, 14),

//   // User data that syncs to cloud
//   username(PrefType.remote, ''),
//   email(PrefType.remote, ''),
//   isPremium(PrefType.remote, false),

//   // Session data (memory only)
//   sessionToken(PrefType.volatile, ''),
//   ;

//   @override
//   final PrefType storageType;
//   @override
//   final dynamic defaultValue;
//   @override
//   String get key => name;

//   const UserPrefs(this.storageType, this.defaultValue);
// }

// void main() async {
//   print('🗄️  SQLite Offline-First Example\n');
//   print('═' * 60);
//   print('This example demonstrates:');
//   print('  • SQLite as local database for preferences');
//   print('  • Offline-first architecture (works without internet)');
//   print('  • Periodic sync to cloud backend (Firebase/Supabase)');
//   print('  • Tracking unsynced changes');
//   print('═' * 60);
//   print('');

//   // Step 1: Initialize SQLite database
//   print('📦 Step 1: Initialize SQLite database');
//   print('─' * 60);
//   final sqlitePrefs = SQLitePrefs(userId: 'user_alice');
//   await sqlitePrefs.init();
//   print('');

//   // Step 2: Initialize the prefs package with SQLite as "remote"
//   print('📦 Step 2: Initialize prefs package with SQLite');
//   print('─' * 60);
//   final prefsManager = PrefsManager(
//     remote: sqlitePrefs, // SQLite acts as "remote" storage
//     enumValues: [UserPrefs.values],
//   );

//   Prefs.setLogger((level, message) {
//     final icon = switch (level) {
//       PrefsLogLevel.debug => '🔍',
//       PrefsLogLevel.info => 'ℹ️',
//       PrefsLogLevel.warning => '⚠️',
//       PrefsLogLevel.error => '❌',
//       _ => '📝',
//     };
//     print('$icon $message');
//   });

//   await prefsManager.init();
//   print('');

//   // Step 3: Work offline - save preferences to SQLite
//   print('💾 Step 3: Save preferences (OFFLINE - stored in SQLite)');
//   print('─' * 60);
//   print('🌐 Simulating OFFLINE mode...\n');

//   await UserPrefs.theme.set('light');
//   await UserPrefs.language.set('es');
//   await UserPrefs.fontSize.set(16);
//   await UserPrefs.username.set('Alice');
//   await UserPrefs.email.set('alice@example.com');
//   await UserPrefs.isPremium.set(true);

//   final unsyncedCount = await sqlitePrefs.getUnsyncedCount();
//   print('\n📊 Status: $unsyncedCount preferences saved locally (unsynced)');
//   print('');

//   // Step 4: Read preferences from SQLite
//   print('📖 Step 4: Read preferences from SQLite');
//   print('─' * 60);
//   print('Theme: ${UserPrefs.theme.get<String>()}');
//   print('Language: ${UserPrefs.language.get<String>()}');
//   print('Font Size: ${UserPrefs.fontSize.get<int>()}');
//   print('Username: ${UserPrefs.username.get<String>()}');
//   print('Email: ${UserPrefs.email.get<String>()}');
//   print('Premium: ${UserPrefs.isPremium.get<bool>()}');
//   print('');

//   // Step 5: Sync to cloud when online
//   print('☁️  Step 5: Sync to cloud backend');
//   print('─' * 60);
//   print('🌐 Simulating ONLINE mode...\n');

//   // Create the actual cloud backend
//   final firebaseBackend = MockFirebasePrefs(userId: 'user_alice');

//   // Sync SQLite → Cloud
//   final syncSuccess = await sqlitePrefs.syncToCloud(firebaseBackend);

//   if (syncSuccess) {
//     final remainingUnsynced = await sqlitePrefs.getUnsyncedCount();
//     print('\n📊 Status: $remainingUnsynced unsynced preferences');
//     print('✅ All data backed up to cloud!');
//   }
//   print('');

//   // Step 6: Simulate another device pulling data
//   print('📱 Step 6: Simulate another device (pull from cloud)');
//   print('─' * 60);
//   print('Device B connects and pulls data from cloud...\n');

//   final sqlitePrefsDeviceB = SQLitePrefs(userId: 'user_alice');
//   await sqlitePrefsDeviceB.init();

//   await sqlitePrefsDeviceB.pullFromCloud(firebaseBackend);

//   // Verify data on device B
//   final deviceBPrefs = await sqlitePrefsDeviceB.getPreferences();
//   print('\n📱 Device B preferences:');
//   deviceBPrefs?.forEach((key, value) {
//     print('  • $key: $value');
//   });
//   print('');

//   // Step 7: Make changes on device B
//   print('✏️  Step 7: Make changes on Device B');
//   print('─' * 60);
//   await sqlitePrefsDeviceB.setPreference('fontSize', 20);
//   await sqlitePrefsDeviceB.setPreference('theme', 'dark');

//   final unsyncedB = await sqlitePrefsDeviceB.getUnsyncedCount();
//   print('📊 Device B has $unsyncedB unsynced changes');
//   print('');

//   // Step 8: Sync device B to cloud
//   print('☁️  Step 8: Device B syncs to cloud');
//   print('─' * 60);
//   await sqlitePrefsDeviceB.syncToCloud(firebaseBackend);
//   print('');

//   // Step 9: Device A pulls latest changes
//   print('🔄 Step 9: Device A pulls latest changes from cloud');
//   print('─' * 60);
//   await sqlitePrefs.pullFromCloud(firebaseBackend);

//   // Reload preferences in prefs package
//   await Prefs.reloadRemotePreferences();

//   print('\n📱 Device A updated preferences:');
//   print('  • Theme: ${UserPrefs.theme.get<String>()} (updated by Device B)');
//   print('  • Font Size: ${UserPrefs.fontSize.get<int>()} (updated by Device B)');
//   print('');

//   // Cleanup
//   await sqlitePrefs.close();
//   await sqlitePrefsDeviceB.close();

//   // Summary
//   print('═' * 60);
//   print('✨ SUMMARY');
//   print('═' * 60);
//   print('✅ SQLite provides offline-first functionality');
//   print('✅ Changes are tracked as "synced" or "unsynced"');
//   print('✅ Manual sync to cloud when network is available');
//   print('✅ Multiple devices can sync through cloud backend');
//   print('✅ App works fully offline, syncs later');
//   print('');
//   print('🏗️  Architecture:');
//   print('  App → prefs package → SQLitePrefs → Local SQLite DB');
//   print('                                   ↓↑');
//   print('                              Cloud Backend (Firebase/Supabase)');
//   print('');
//   print('📚 Remember: This SQLite implementation is YOUR code,');
//   print('   not built into the prefs package. You implement');
//   print('   RemotePrefs interface with your sync logic.');
// }
