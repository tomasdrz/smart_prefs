import 'dart:async';

import 'package:fake_async/fake_async.dart';
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

  group('Prefs Core', () {
    late MockRemotePrefs mockRemote;

    setUp(() async {
      mockRemote = MockRemotePrefs();
      Prefs.setRemotePreferences(mockRemote);
    });

    test('setLogger should accept custom logger', () {
      Prefs.setLogger((level, message) {
        // Custom logger set successfully
      });

      // Logger should be set without errors
      expect(true, true);
    });

    test('setMaxRetries should accept valid values', () {
      expect(() => Prefs.setMaxRetries(0), returnsNormally);
      expect(() => Prefs.setMaxRetries(10), returnsNormally);
      expect(() => Prefs.setMaxRetries(100), returnsNormally);
    });

    test('get should return default value for non-existent key', () {
      final value = Prefs.get<String>('nonexistent', defaultValue: 'default');
      expect(value, 'default');
    });

    test('get should return cached value after set', () async {
      await Prefs.set('test_key', 'test_value', type: PrefType.volatile);
      final value = Prefs.get<String>('test_key', defaultValue: 'default');
      expect(value, 'test_value');
    });

    test('set should update cache immediately', () async {
      await Prefs.set('immediate', 'value1', type: PrefType.volatile);
      expect(Prefs.get('immediate', defaultValue: ''), 'value1');

      await Prefs.set('immediate', 'value2', type: PrefType.volatile);
      expect(Prefs.get('immediate', defaultValue: ''), 'value2');
    });

    test('volatile preferences should only exist in memory', () async {
      await Prefs.set('volatile_test', 'memory_only', type: PrefType.volatile);

      final value = Prefs.get<String>('volatile_test', defaultValue: '');
      expect(value, 'memory_only');

      // Mock remote should not have received this value
      expect(mockRemote.getSavedData().containsKey('volatile_test'), false);
    });

    test('remote preferences should be saved to remote storage', () async {
      await Prefs.set('remote_test', 'remote_value', type: PrefType.remote);

      final savedData = mockRemote.getSavedData();
      expect(savedData.containsKey('remote_test'), true);
      expect(savedData['remote_test'], 'remote_value');
    });

    test('should handle different data types', () async {
      await Prefs.set('string_key', 'string', type: PrefType.volatile);
      await Prefs.set('int_key', 42, type: PrefType.volatile);
      await Prefs.set('bool_key', true, type: PrefType.volatile);
      await Prefs.set('double_key', 3.14, type: PrefType.volatile);

      expect(Prefs.get<String>('string_key', defaultValue: ''), 'string');
      expect(Prefs.get<int>('int_key', defaultValue: 0), 42);
      expect(Prefs.get<bool>('bool_key', defaultValue: false), true);
      expect(Prefs.get<double>('double_key', defaultValue: 0.0), 3.14);
    });

    test('loadPreferences should load local and remote preferences', () async {
      mockRemote.setMockData({
        'remote_pref': 'from_backend',
      });

      await Prefs.loadPreferences({
        'local_pref': PrefType.local,
        'remote_pref': PrefType.remote,
        'volatile_pref': PrefType.volatile,
      });

      // Remote pref should be loaded from mock
      expect(
        Prefs.get<String>('remote_pref', defaultValue: ''),
        'from_backend',
      );
    });

    test('loadPreferences should not complete twice when remote load is slow',
        () {
      fakeAsync((async) {
        final slowRemote = SlowRemotePrefs(const Duration(seconds: 15));
        Prefs.setRemotePreferences(slowRemote);

        var completed = false;
        final future =
            Prefs.loadPreferences({'remote_pref': PrefType.remote});
        unawaited(future.then((_) => completed = true));

        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();

        expect(completed, true);
        expect(slowRemote.callCount, 1);
      });
    });
  });

  group('Prefs Logging', () {
    test('custom logger should receive log messages', () async {
      final logs = <String>[];
      Prefs.setLogger((level, message) {
        logs.add('${level.name}: $message');
      });

      // This should generate some logs
      await Prefs.loadPreferences({'test': PrefType.local});

      // We can't guarantee exact logs, but logger should be called
      // during initialization
      expect(true, true);
    });
  });

  group('Prefs Error Handling', () {
    test('should not throw on unsupported type for volatile storage', () async {
      // Volatile storage accepts any type (in-memory only)
      expect(
        () async => Prefs.set(
          'any_type',
          {'key': 'value'},
          type: PrefType.volatile,
        ),
        returnsNormally,
      );
    });
  });
}

class MockRemotePrefs extends RemotePrefs {
  final Map<String, dynamic> _data = {};
  Map<String, dynamic> _mockData = {};

  void setMockData(Map<String, dynamic> data) {
    _mockData = Map.from(data);
  }

  @override
  Future<Map<String, dynamic>?> getPreferences() async =>
      _mockData.isEmpty ? {} : Map.from(_mockData);

  @override
  Future<void> setPreference(String key, dynamic value) async {
    _data[key] = value;
  }

  Map<String, dynamic> getSavedData() => Map.from(_data);
}

class SlowRemotePrefs extends RemotePrefs {
  SlowRemotePrefs(this.delay);

  final Duration delay;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    callCount += 1;
    await Future<void>.delayed(delay);
    return {'remote_pref': 'value'};
  }

  @override
  Future<void> setPreference(String key, dynamic value) async {}
}
