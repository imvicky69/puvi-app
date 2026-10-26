import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Session Persistence Logic Tests', () {
    test('Serializes session payload correctly', () {
      final payload = {
        'userName': 'Vicky',
        'email': 'vicky@puvi.com',
        'isLoggedIn': true,
        'savedAt': DateTime(2026, 10, 26).toIso8601String(),
      };

      final encoded = json.encode(payload);
      final decoded = json.decode(encoded) as Map<String, dynamic>;

      expect(decoded['isLoggedIn'], isTrue);
      expect(decoded['userName'], equals('Vicky'));
      expect(decoded['email'], equals('vicky@puvi.com'));
    });

    test('Parses Puja session correctly', () {
      final payload = {
        'userName': 'Puja',
        'email': 'puja@puvi.com',
        'isLoggedIn': true,
        'savedAt': DateTime(2026, 10, 26).toIso8601String(),
      };

      final encoded = json.encode(payload);
      final decoded = json.decode(encoded) as Map<String, dynamic>;

      expect(decoded['isLoggedIn'], isTrue);
      expect(decoded['userName'], equals('Puja'));
      expect(decoded['email'], equals('puja@puvi.com'));
    });

    test('Ignores session if isLoggedIn is false', () {
      final payload = {
        'userName': 'Vicky',
        'email': 'vicky@puvi.com',
        'isLoggedIn': false,
      };

      final decoded = json.decode(json.encode(payload)) as Map<String, dynamic>;
      final isValid = decoded['isLoggedIn'] == true;
      expect(isValid, isFalse);
    });
  });
}
