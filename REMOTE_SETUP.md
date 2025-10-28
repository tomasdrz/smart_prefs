# Remote Preferences Setup Guide

This guide shows how to set up remote storage backends for the `prefs` package.

## 📋 Table of Contents

- [Database Schema](#database-schema)
- [Firebase Firestore](#firebase-firestore)
- [Supabase (PostgreSQL)](#supabase-postgresql)
- [Custom REST API](#custom-rest-api)
- [SQLite (Local Database)](#sqlite-local-database)

---

## 🗄️ Database Schema

All remote implementations store preferences in a similar structure:

| Field | Type | Description |
|-------|------|-------------|
| `user_id` | String/UUID | User identifier |
| `key` | String | Preference key (e.g., "theme", "language") |
| `value` | String | String representation of the value |
| `data_type` | String | Type: "string", "bool", "int", or "double" |
| `updated_at` | Timestamp | Last modification time (optional) |

**Composite Primary Key**: `(user_id, key)`

---

## Firebase Firestore

### Structure

```
preferences (collection)
  └── {userId} (document)
      ├── theme: {value: "dark", data_type: "string"}
      ├── language: {value: "en", data_type: "string"}
      └── isPremium: {value: "true", data_type: "bool"}
```

### Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /preferences/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Implementation

```dart
import 'package:prefs/prefs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebasePrefs extends RemotePrefs {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('preferences')
          .doc(userId)
          .get();

      if (!doc.exists) return {};

      final data = doc.data()!;
      final Map<String, dynamic> preferences = {};

      for (var entry in data.entries) {
        final map = entry.value as Map<String, dynamic>;
        preferences[entry.key] = parseFromString(
          map['value'] as String,
          map['data_type'] as String,
        );
      }

      return preferences;
    } catch (e) {
      print('Error loading Firebase preferences: $e');
      return null;
    }
  }

  @override
  Future<void> setPreference(String key, dynamic value) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final typedValue = toTypedValue(value);
      
      await _firestore
          .collection('preferences')
          .doc(userId)
          .set({
        key: typedValue.toMap(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving Firebase preference: $e');
    }
  }
}
```

---

## Supabase (PostgreSQL)

### SQL Schema

```sql
-- Create preferences table
CREATE TABLE preferences (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    data_type TEXT NOT NULL CHECK (data_type IN ('string', 'bool', 'int', 'double')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, key)
);

-- Enable Row Level Security
ALTER TABLE preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own preferences
CREATE POLICY "Users can manage own preferences"
    ON preferences
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Index for faster queries
CREATE INDEX idx_preferences_user_id ON preferences(user_id);

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_preferences_updated_at
    BEFORE UPDATE ON preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### Implementation

```dart
import 'package:prefs/prefs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePrefs extends RemotePrefs {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('preferences')
          .select('key, value, data_type')
          .eq('user_id', userId);

      if (response.isEmpty) return {};

      final Map<String, dynamic> preferences = {};
      
      for (var row in response) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        final dataType = row['data_type'] as String;
        
        preferences[key] = parseFromString(value, dataType);
      }

      return preferences;
    } catch (e) {
      print('Error loading Supabase preferences: $e');
      return null;
    }
  }

  @override
  Future<void> setPreference(String key, dynamic value) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final typedValue = toTypedValue(value);
      
      await _client.from('preferences').upsert({
        'user_id': userId,
        'key': key,
        'value': typedValue.value,
        'data_type': typedValue.dataType,
      });
    } catch (e) {
      print('Error saving Supabase preference: $e');
    }
  }
}
```

---

## Custom REST API

### API Endpoints

```
GET    /api/users/{userId}/preferences       - Get all preferences
PUT    /api/users/{userId}/preferences/{key} - Set a preference
DELETE /api/users/{userId}/preferences/{key} - Delete a preference
```

### Request/Response Format

**GET Response:**
```json
{
  "preferences": {
    "theme": {"value": "dark", "data_type": "string"},
    "isPremium": {"value": "true", "data_type": "bool"},
    "coins": {"value": "100", "data_type": "int"}
  }
}
```

**PUT Request:**
```json
{
  "value": "light",
  "data_type": "string"
}
```

### Implementation

```dart
import 'package:prefs/prefs.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RestApiPrefs extends RemotePrefs {
  final String baseUrl;
  final String Function() getAuthToken;
  final String Function() getUserId;

  RestApiPrefs({
    required this.baseUrl,
    required this.getAuthToken,
    required this.getUserId,
  });

  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    final userId = getUserId();
    if (userId.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/preferences'),
        headers: {
          'Authorization': 'Bearer ${getAuthToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 401) return null; // Not authenticated
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final prefsData = data['preferences'] as Map<String, dynamic>;
      final Map<String, dynamic> preferences = {};

      for (var entry in prefsData.entries) {
        final map = entry.value as Map<String, dynamic>;
        preferences[entry.key] = parseFromString(
          map['value'] as String,
          map['data_type'] as String,
        );
      }

      return preferences;
    } catch (e) {
      print('Error loading REST API preferences: $e');
      return null;
    }
  }

  @override
  Future<void> setPreference(String key, dynamic value) async {
    final userId = getUserId();
    if (userId.isEmpty) return;

    try {
      final typedValue = toTypedValue(value);
      
      await http.put(
        Uri.parse('$baseUrl/api/users/$userId/preferences/$key'),
        headers: {
          'Authorization': 'Bearer ${getAuthToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(typedValue.toMap()),
      );
    } catch (e) {
      print('Error saving REST API preference: $e');
    }
  }
}
```

---

## SQLite (Offline-First Pattern)

**Important**: This is an **advanced implementation pattern** for offline-first apps. The `prefs` package does NOT include SQLite support built-in. This section shows how YOU would implement a local database backend that syncs to a remote server.

### When to use this pattern

Use SQLite as your `RemotePrefs` implementation when you need:
- **Offline-first architecture**: App works fully offline, syncs when online
- **Large datasets**: Storing thousands of preferences per user
- **Complex queries**: Need to filter/search preferences locally
- **Sync control**: Manual control over when data syncs to remote server

### Architecture Overview

```
┌─────────────────┐
│   Your App      │
│  (uses prefs)   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│  SQLitePrefs (RemotePrefs impl) │ ← You implement this
│  - Stores in local SQLite       │
│  - Implements getPreferences()  │
│  - Implements setPreference()   │
│  - Has syncToRemote() method    │
└────────┬──────────────┬─────────┘
         │              │
         ▼              ▼
  ┌──────────┐   ┌────────────┐
  │  SQLite  │   │   Remote   │
  │   (DB)   │   │  Backend   │
  └──────────┘   │(Firebase,  │
                 │ Supabase,  │
                 │ REST API)  │
                 └────────────┘
```

**Two components needed**:
1. **SQLitePrefs**: Your `RemotePrefs` implementation using local database
2. **Actual remote backend**: Firebase/Supabase/REST API for syncing

### Why this pattern?

The prefs package treats SQLite as a "remote" storage because:
- It's **separate from SharedPreferences** (local storage)
- It requires **async initialization** (database setup)
- It supports **multi-user** scenarios (user_id column)
- It needs **sync logic** to actual cloud storage

### Schema

```sql
CREATE TABLE preferences (
    user_id TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    data_type TEXT NOT NULL CHECK (data_type IN ('string', 'bool', 'int', 'double')),
    synced INTEGER DEFAULT 0,
    updated_at INTEGER DEFAULT (strftime('%s', 'now')),
    PRIMARY KEY (user_id, key)
);

CREATE INDEX idx_preferences_synced ON preferences(synced);
```

### Implementation

```dart
import 'package:prefs/prefs.dart';
import 'package:sqflite/sqflite.dart';

class SQLitePrefs extends RemotePrefs {
  final Database db;
  final String userId;

  SQLitePrefs({required this.db, required this.userId});

  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    if (userId.isEmpty) return null;

    try {
      final List<Map<String, dynamic>> results = await db.query(
        'preferences',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final Map<String, dynamic> preferences = {};
      
      for (var row in results) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        final dataType = row['data_type'] as String;
        
        preferences[key] = parseFromString(value, dataType);
      }

      return preferences;
    } catch (e) {
      print('Error loading SQLite preferences: $e');
      return null;
    }
  }

  @override
  Future<void> setPreference(String key, dynamic value) async {
    if (userId.isEmpty) return;

    try {
      final typedValue = toTypedValue(value);
      
      await db.insert(
        'preferences',
        {
          'user_id': userId,
          'key': key,
          'value': typedValue.value,
          'data_type': typedValue.dataType,
          'synced': 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error saving SQLite preference: $e');
    }
  }

  // Sync unsynced preferences to actual remote backend
  Future<void> syncToRemote(RemotePrefs actualRemoteBackend) async {
    final unsynced = await db.query(
      'preferences',
      where: 'user_id = ? AND synced = 0',
      whereArgs: [userId],
    );

    for (var row in unsynced) {
      final key = row['key'] as String;
      final value = parseFromString(
        row['value'] as String,
        row['data_type'] as String,
      );

      // Send to actual cloud backend (Firebase, Supabase, etc.)
      await actualRemoteBackend.setPreference(key, value);
      
      // Mark as synced in local database
      await db.update(
        'preferences',
        {'synced': 1},
        where: 'user_id = ? AND key = ?',
        whereArgs: [userId, key],
      );
    }
  }
}
```

### Usage Example

```dart
// 1. Create your SQLite implementation
final sqlitePrefs = SQLitePrefs(userId: currentUserId);

// 2. Create actual remote backend (for syncing)
final firebaseBackend = FirebasePrefs();

// 3. Use SQLite as "remote" storage in prefs
final prefsManager = PrefsManager(
  remote: sqlitePrefs,  // Uses local SQLite database
  enumValues: [UserPrefs.values],
);
await prefsManager.init();

// 4. App works offline with SQLite
UserPrefs.theme.set('dark');  // Saved to SQLite instantly

// 5. Sync to cloud when online
await sqlitePrefs.syncToRemote(firebaseBackend);
```

**Key insight**: You're using SQLite as a "caching layer" between the prefs package and your actual cloud backend. The prefs package doesn't know or care that you're syncing to another remote—it just sees SQLite as the remote storage.
```

---

## 🔄 Sync Strategies

### Strategy 1: Immediate Sync
```dart
// Set preference locally and remotely
await localPrefs.setPreference(key, value);
await remotePrefs.setPreference(key, value);
```

### Strategy 2: Batch Sync
```dart
// Queue changes locally, sync periodically
final queue = <String, dynamic>{};

void setPreference(String key, dynamic value) {
  localPrefs.setPreference(key, value);
  queue[key] = value;
}

Future<void> syncAll() async {
  for (var entry in queue.entries) {
    await remotePrefs.setPreference(entry.key, entry.value);
  }
  queue.clear();
}
```

### Strategy 3: Conflict Resolution
```dart
enum SyncStrategy {
  localWins,   // Local changes override remote
  remoteWins,  // Remote changes override local
  newerWins,   // Most recent timestamp wins
}
```

---

## 📱 Example: Complete Setup

```dart
import 'package:flutter/material.dart';
import 'package:prefs/prefs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_ANON_KEY',
  );
  
  // Initialize preferences
  final prefsManager = PrefsManager(
    remote: SupabasePrefs(),
    enumValues: [AppPrefs.values],
  );
  await prefsManager.init();
  
  runApp(MyApp());
}
```

---

## 🔐 Security Best Practices

1. **Always use Row Level Security (RLS)** in databases
2. **Validate user authentication** before accessing preferences
3. **Sanitize input** to prevent injection attacks
4. **Encrypt sensitive data** before storing
5. **Use HTTPS** for all API communications
6. **Implement rate limiting** to prevent abuse
7. **Audit log** for preference changes (optional)

---

## 🧪 Testing

```dart
class MockRemotePrefs extends RemotePrefs {
  final Map<String, dynamic> _storage = {};
  
  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    await Future.delayed(Duration(milliseconds: 100)); // Simulate network
    return Map.from(_storage);
  }
  
  @override
  Future<void> setPreference(String key, dynamic value) async {
    await Future.delayed(Duration(milliseconds: 50));
    _storage[key] = value;
  }
  
  // Helper for testing
  void simulateOffline() => throw Exception('Network unavailable');
}
```

---

## 📚 Additional Resources

- [Firebase Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
