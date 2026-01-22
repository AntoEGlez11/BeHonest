
import 'package:flutter_test/flutter_test.dart';
import 'package:behonest/features/business/domain/business.dart';

void main() {
  group('Business Model', () {
    test('parses JSON with numeric lat/lng correctly', () {
      final json = {
        'id': '123',
        'name': 'Tacos El Paisa',
        'description': 'Best tacos',
        'location': 'POINT(-99.163 19.354)', // PostGIS format assumption
        'score': 4.5,
      };

      final business = Business.fromJson(json);

      expect(business.id, '123');
      expect(business.name, 'Tacos El Paisa');
      expect(business.longitude, closeTo(-99.163, 0.001));
      expect(business.latitude, closeTo(19.354, 0.001));
    });

    test('handles missing description and score', () {
      final json = {
        'id': '124',
        'name': 'Unknown Tacos',
        'location': 'POINT(0 0)',
      };

      final business = Business.fromJson(json);

      expect(business.description, isNull);
      expect(business.score, isNull);
    });
  });
}
