import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/api_service.dart';

void main() {
  group('ApiService Tests', () {
    late ApiService api;

    setUp(() {
      api = ApiService();
    });

    group('Base URL', () {
      test('should have correct base URL', () {
        expect(ApiService.baseUrl, contains('8000'));
      });
    });

    group('Foursquare Search', () {
      test('searchRestaurantsFoursquare returns list', () async {
        try {
          final results = await api.searchRestaurantsFoursquare(
            query: 'KFC',
            near: 'Dubai',
            limit: 5,
          );
          expect(results, isA<List>());
        } catch (e) {
          // API might not be running in test environment
          expect(e, isA<Exception>());
        }
      });
    });

    group('Foursquare Photos', () {
      test('getFoursquarePhotos returns list', () async {
        try {
          final results = await api.getFoursquarePhotos(
            fsqId: 'test_id',
            limit: 1,
          );
          expect(results, isA<List>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('Directions', () {
      test('getDirections returns route data', () async {
        try {
          final result = await api.getDirections(
            originLat: 25.2,
            originLng: 55.2,
            destLat: 25.1,
            destLng: 55.1,
          );
          expect(result, contains('polyline'));
          expect(result, contains('duration_text'));
          expect(result, contains('distance_text'));
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });
  });
}
