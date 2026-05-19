import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/session.dart';

void main() {
  group('Session Tests', () {
    setUp(() {
      Session.clear();
    });

    test('initial state is not logged in', () {
      expect(Session.isLoggedIn, false);
    });

    test('email starts empty', () {
      expect(Session.email, '');
    });

    test('clear resets all fields', () async {
      await Session.clear();
      expect(Session.email, '');
      expect(Session.firstName, '');
      expect(Session.lastName, '');
      expect(Session.isLoggedIn, false);
    });

    test('static fields are accessible', () {
      // These should not throw
      expect(Session.userId, isA<String>());
      expect(Session.email, isA<String>());
      expect(Session.firstName, isA<String>());
      expect(Session.lastName, isA<String>());
      expect(Session.displayName, isA<String>());
      expect(Session.handle, isA<String>());
      expect(Session.avatarUrl, isA<String>());
    });
  });
}
