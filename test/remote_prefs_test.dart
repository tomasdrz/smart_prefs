import 'package:flutter_test/flutter_test.dart';
import 'package:smart_prefs/smart_prefs.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Remote Prefs', () {
    late TestRemotePrefs remotePrefs;

    setUp(() {
      remotePrefs = TestRemotePrefs();
    });

    test('getPreferences should return null when no data', () async {
      final result = await remotePrefs.getPreferences();
      expect(result, <String, dynamic>{});
    });

    test('setPreference should store values', () async {
      await remotePrefs.setPreference('key1', 'value1');
      await remotePrefs.setPreference('key2', 42);

      final prefs = await remotePrefs.getPreferences();
      expect(prefs?['key1'], 'value1');
      expect(prefs?['key2'], 42);
    });

    test('should handle multiple set and get operations', () async {
      await remotePrefs.setPreference('string', 'test');
      await remotePrefs.setPreference('int', 123);
      await remotePrefs.setPreference('bool', true);
      await remotePrefs.setPreference('double', 3.14);

      final prefs = await remotePrefs.getPreferences();
      expect(prefs?['string'], 'test');
      expect(prefs?['int'], 123);
      expect(prefs?['bool'], true);
      expect(prefs?['double'], 3.14);
    });
  });

  group('PrefsConverter Mixin', () {
    late TestRemotePrefs converter;

    setUp(() {
      converter = TestRemotePrefs();
    });

    group('parseFromString', () {
      test('should parse bool values', () {
        expect(converter.parseFromString('true', 'bool'), true);
        expect(converter.parseFromString('false', 'bool'), false);
        expect(converter.parseFromString('TRUE', 'bool'), true);
        expect(converter.parseFromString('FALSE', 'bool'), false);
      });

      test('should parse int values', () {
        expect(converter.parseFromString('42', 'int'), 42);
        expect(converter.parseFromString('-10', 'int'), -10);
        expect(converter.parseFromString('0', 'int'), 0);
      });

      test('should parse double values', () {
        expect(converter.parseFromString('3.14', 'double'), 3.14);
        expect(converter.parseFromString('-2.5', 'double'), -2.5);
        expect(converter.parseFromString('0.0', 'double'), 0.0);
      });

      test('should return string for unknown types', () {
        expect(converter.parseFromString('test', 'string'), 'test');
        expect(converter.parseFromString('anything', 'unknown'), 'anything');
      });

      test('should handle invalid int gracefully', () {
        expect(converter.parseFromString('not_a_number', 'int'), 0);
        expect(converter.parseFromString('', 'int'), 0);
      });

      test('should handle invalid double gracefully', () {
        expect(converter.parseFromString('not_a_number', 'double'), 0.0);
        expect(converter.parseFromString('', 'double'), 0.0);
      });
    });

    group('toTypedValue', () {
      test('should convert bool to TypedValue', () {
        final typed = converter.toTypedValue(true);
        expect(typed.dataType, 'bool');
        expect(typed.value, 'true');

        final typed2 = converter.toTypedValue(false);
        expect(typed2.dataType, 'bool');
        expect(typed2.value, 'false');
      });

      test('should convert int to TypedValue', () {
        final typed = converter.toTypedValue(42);
        expect(typed.dataType, 'int');
        expect(typed.value, '42');

        final typed2 = converter.toTypedValue(-10);
        expect(typed2.dataType, 'int');
        expect(typed2.value, '-10');
      });

      test('should convert double to TypedValue', () {
        final typed = converter.toTypedValue(3.14);
        expect(typed.dataType, 'double');
        expect(typed.value, '3.14');
      });

      test('should convert string to TypedValue', () {
        final typed = converter.toTypedValue('test');
        expect(typed.dataType, 'string');
        expect(typed.value, 'test');
      });

      test('should default to string for unknown types', () {
        final typed = converter.toTypedValue([1, 2, 3]);
        expect(typed.dataType, 'string');
        expect(typed.value, '[1, 2, 3]');
      });
    });

    group('TypedValue.toMap', () {
      test('should create correct map structure', () {
        final typed = TypedValue('int', '42');
        final map = typed.toMap();

        expect(map.containsKey('value'), true);
        expect(map.containsKey('data_type'), true);
        expect(map['value'], '42');
        expect(map['data_type'], 'int');
      });
    });

    group('Round-trip conversion', () {
      test('should preserve values through conversion cycle', () {
        // bool
        final boolTyped = converter.toTypedValue(true);
        final boolParsed = converter.parseFromString(
          boolTyped.value,
          boolTyped.dataType,
        );
        expect(boolParsed, true);

        // int
        final intTyped = converter.toTypedValue(123);
        final intParsed = converter.parseFromString(
          intTyped.value,
          intTyped.dataType,
        );
        expect(intParsed, 123);

        // double
        final doubleTyped = converter.toTypedValue(3.14);
        final doubleParsed = converter.parseFromString(
          doubleTyped.value,
          doubleTyped.dataType,
        );
        expect(doubleParsed, 3.14);

        // string
        final stringTyped = converter.toTypedValue('test');
        final stringParsed = converter.parseFromString(
          stringTyped.value,
          stringTyped.dataType,
        );
        expect(stringParsed, 'test');
      });
    });
  });
}

class TestRemotePrefs extends RemotePrefs {
  final Map<String, dynamic> _storage = {};

  @override
  Future<Map<String, dynamic>?> getPreferences() async => Map.from(_storage);

  @override
  Future<void> setPreference(String key, dynamic value) async {
    _storage[key] = value;
  }
}
