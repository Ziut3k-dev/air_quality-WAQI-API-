import 'package:air_quality_waqi/air_quality_waqi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String key = '9e538456b2b85c92647d8b65090e29f957638c77';
  AirQualityWaqi airQuality = new AirQualityWaqi(key);

  group('Air Quality Tests', () {
    setUpAll(() {});
    setUp(() {});

    test('- via city name (Wloclawek)', () async {
      AirQualityWaqiData feedFromCity =
          await airQuality.feedFromCity('wloclawek');
      print(feedFromCity);
    });

    test('- via station ID (Wloclawek)', () async {
      AirQualityWaqiData feedFromStationId =
          await airQuality.feedFromStationId('6525');
      print(feedFromStationId);
    });

    test('- via geo-location (Wloclawek)', () async {
      AirQualityWaqiData feedFromGeoLocation = await airQuality
          .feedFromGeoLocation(52.658611111111, 19.059166666667);
      print(feedFromGeoLocation);
    });

    test('- via  IP (depends on service provider)', () async {
      AirQualityWaqiData fromIP = await airQuality.feedFromIP();
      print(fromIP);
    });
  });
}
