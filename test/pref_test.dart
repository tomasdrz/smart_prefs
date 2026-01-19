// ignore_for_file: sort_constructors_first
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

  group('Pref Interface', () {
    test('should have correct default values', () {
      expect(TestPrefs.stringPref.defaultValue, 'default');
      expect(TestPrefs.intPref.defaultValue, 42);
      expect(TestPrefs.boolPref.defaultValue, true);
      expect(TestPrefs.doublePref.defaultValue, 3.14);
    });

    test('should have correct storage types', () {
      expect(TestPrefs.stringPref.storageType, PrefType.local);
      expect(TestPrefs.remotePref.storageType, PrefType.remote);
      expect(TestPrefs.volatilePref.storageType, PrefType.volatile);
    });

    test('should use enum name as key', () {
      expect(TestPrefs.stringPref.key, 'stringPref');
      expect(TestPrefs.intPref.key, 'intPref');
      expect(TestPrefs.remotePref.key, 'remotePref');
    });
  });

  group('PrefType Enum', () {
    test('should have all three types', () {
      expect(PrefType.values.length, 3);
      expect(PrefType.values, contains(PrefType.local));
      expect(PrefType.values, contains(PrefType.remote));
      expect(PrefType.values, contains(PrefType.volatile));
    });
  });

  group('PrefExtensions', () {
    test('get should return default value when not set', () {
      final value = TestPrefs.stringPref.get<String>();
      expect(value, 'default');
    });

    test('set and get should work correctly', () async {
      await TestPrefs.stringPref.set('new value');
      final value = TestPrefs.stringPref.get<String>();
      expect(value, 'new value');
    });

    test('clear should reset to default value', () async {
      await TestPrefs.intPref.set(100);
      expect(TestPrefs.intPref.get<int>(), 100);

      await TestPrefs.intPref.clear();
      expect(TestPrefs.intPref.get<int>(), 42);
    });

    test('should handle different types correctly', () async {
      // String
      await TestPrefs.stringPref.set('test');
      expect(TestPrefs.stringPref.get<String>(), 'test');

      // Int
      await TestPrefs.intPref.set(999);
      expect(TestPrefs.intPref.get<int>(), 999);

      // Bool
      await TestPrefs.boolPref.set(false);
      expect(TestPrefs.boolPref.get<bool>(), false);

      // Double
      await TestPrefs.doublePref.set(2.71);
      expect(TestPrefs.doublePref.get<double>(), 2.71);
    });
  });
}

// Test enum for testing purposes
enum TestPrefs implements Pref {
  stringPref(PrefType.local, 'default'),
  intPref(PrefType.local, 42),
  boolPref(PrefType.local, true),
  doublePref(PrefType.local, 3.14),
  remotePref(PrefType.remote, ''),
  volatilePref(PrefType.volatile, ''),
  ;

  @override
  final PrefType storageType;
  @override
  final dynamic defaultValue;
  @override
  String get key => name;

  const TestPrefs(this.storageType, this.defaultValue);
}
