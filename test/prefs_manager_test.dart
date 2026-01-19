// ignore_for_file: sort_constructors_first, prefer_expression_function_bodies
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_prefs/smart_prefs.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences for tests
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PrefsManager', () {
    late MockRemotePrefs mockRemote;
    late PrefsManager manager;

    setUp(() {
      mockRemote = MockRemotePrefs();
      manager = PrefsManager(
        remote: mockRemote,
        enumValues: [TestPrefs.values],
      );
    });

    test('should initialize successfully', () async {
      await manager.init();
      // If no exception thrown, initialization succeeded
      expect(true, true);
    });

    test('should register all preferences', () async {
      await manager.init();

      // All local preferences should be loadable
      final stringValue = TestPrefs.localString.get<String>();
      expect(stringValue, 'default'); // Default value
    });

    test('should load remote preferences during init', () async {
      // Setup mock to return some remote data
      mockRemote.setMockData({
        'remoteString': 'from-remote',
        'remoteInt': 123,
      });

      await manager.init();

      // Remote values should be loaded
      expect(TestPrefs.remoteString.get<String>(), 'from-remote');
      expect(TestPrefs.remoteInt.get<int>(), 123);
    });

    test('should handle multiple enum groups', () async {
      final managerMultiple = PrefsManager(
        remote: mockRemote,
        enumValues: [TestPrefs.values, AdditionalPrefs.values],
      );

      await managerMultiple.init();

      // Both enum groups should work
      expect(TestPrefs.localString.get<String>(), 'default');
      expect(AdditionalPrefs.setting1.get<bool>(), true);
    });
  });
}

// Mock implementation for testing
class MockRemotePrefs extends RemotePrefs {
  final Map<String, dynamic> _data = {};
  Map<String, dynamic> _mockData = {};

  void setMockData(Map<String, dynamic> data) {
    _mockData = Map.from(data);
  }

  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    // Return mock data if set, otherwise empty map
    return _mockData.isEmpty ? {} : Map.from(_mockData);
  }

  @override
  Future<void> setPreference(String key, dynamic value) async {
    _data[key] = value;
  }

  Map<String, dynamic> getSavedData() => Map.from(_data);
}

enum TestPrefs implements Pref {
  localString(PrefType.local, 'default'),
  localInt(PrefType.local, 0),
  localBool(PrefType.local, false),
  remoteString(PrefType.remote, ''),
  remoteInt(PrefType.remote, 0),
  volatileString(PrefType.volatile, ''),
  ;

  @override
  final PrefType storageType;
  @override
  final dynamic defaultValue;
  @override
  String get key => name;

  const TestPrefs(this.storageType, this.defaultValue);
}

enum AdditionalPrefs implements Pref {
  setting1(PrefType.local, true),
  setting2(PrefType.local, 'value'),
  ;

  @override
  final PrefType storageType;
  @override
  final dynamic defaultValue;
  @override
  String get key => name;

  const AdditionalPrefs(this.storageType, this.defaultValue);
}
