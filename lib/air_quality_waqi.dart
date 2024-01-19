/*
 * Copyright 2019 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
library air_quality_waqi;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Custom Exception for the plugin,
/// Thrown whenever the API responds with an error and body could not be parsed.

enum AirQualityWaqiLevel {
  UNKNOWN,
  GOOD,
  MODERATE,
  UNHEALTHY_FOR_SENSITIVE_GROUPS,
  UNHEALTHY,
  VERY_UNHEALTHY,
  HAZARDOUS
}

AirQualityWaqiLevel airQualityIndexToLevel(int index) {
  if (index < 0)
    return AirQualityWaqiLevel.UNKNOWN;
  else if (index <= 50)
    return AirQualityWaqiLevel.GOOD;
  else if (index <= 100)
    return AirQualityWaqiLevel.MODERATE;
  else if (index <= 150)
    return AirQualityWaqiLevel.UNHEALTHY_FOR_SENSITIVE_GROUPS;
  else if (index <= 200)
    return AirQualityWaqiLevel.UNHEALTHY;
  else if (index <= 300)
    return AirQualityWaqiLevel.VERY_UNHEALTHY;
  else
    return AirQualityWaqiLevel.HAZARDOUS;
}

class Iaqi {
  final double co;
  final double dew;
  final double h;
  final double no2;
  final double o3;
  final double p;
  final double pm10;
  final double pm25;
  final double r;
  final double so2;
  final double t;
  final double w;

  Iaqi({
    required this.co,
    required this.dew,
    required this.h,
    required this.no2,
    required this.o3,
    required this.p,
    required this.pm10,
    required this.pm25,
    required this.r,
    required this.so2,
    required this.t,
    required this.w,
  });
}

// Analogicznie twórz klasy dla pozostałych pól...

/// A class for storing Air Quality JSON Data fetched from the API.
class AirQualityWaqiData {
  late int airQualityIndex, idx;
  late String source, place, dominentpol, debugSync;
  late double latitude, longitude;
  late AirQualityWaqiLevel airQualityLevel;
  late bool status;
  late Iaqi iaqi;

  AirQualityWaqiData(Map<String, dynamic> airQualityJson) {
    airQualityIndex =
        int.tryParse(airQualityJson['data']['aqi'].toString()) ?? 0;
    idx = int.tryParse(airQualityJson['data']['idx'].toString()) ?? 0;
    place = airQualityJson['data']['city']['name'].toString();
    source = airQualityJson['data']['attributions'][0]['name'].toString();
    latitude =
        double.tryParse(airQualityJson['data']['city']['geo'][0].toString()) ??
            0;
    longitude =
        double.tryParse(airQualityJson['data']['city']['geo'][1].toString()) ??
            0;
    dominentpol = airQualityJson['data']['dominentpol'].toString();
    airQualityLevel = airQualityIndexToLevel(airQualityIndex);
    debugSync = airQualityJson['data']['debug']['sync'].toString();
    var statusString = airQualityJson['data']['status'].toString();
    status = statusString == 'ok';

    iaqi = Iaqi(
      co: airQualityJson['data']['iaqi']['co']?['v']?.toDouble() ?? 0,
      dew: airQualityJson['data']['iaqi']['dew']?['v']?.toDouble() ?? 0,
      h: airQualityJson['data']['iaqi']['h']?['v']?.toDouble() ?? 0,
      no2: airQualityJson['data']['iaqi']['no2']?['v']?.toDouble() ?? 0,
      o3: airQualityJson['data']['iaqi']['o3']?['v']?.toDouble() ?? 0,
      p: airQualityJson['data']['iaqi']['p']?['v']?.toDouble() ?? 0,
      pm10: airQualityJson['data']['iaqi']['pm10']?['v']?.toDouble() ?? 0,
      pm25: airQualityJson['data']['iaqi']['pm25']?['v']?.toDouble() ?? 0,
      r: airQualityJson['data']['iaqi']['r']?['v']?.toDouble() ?? 0,
      so2: airQualityJson['data']['iaqi']['so2']?['v']?.toDouble() ?? 0,
      t: airQualityJson['data']['iaqi']['t']?['v']?.toDouble() ?? 0,
      w: airQualityJson['data']['iaqi']['w']?['v']?.toDouble() ?? 0,
    );
  }

  @override
  String toString() {
    return '''
    Air Quality Level: ${airQualityLevel.toString().split('.').last}
    AQI: $airQualityIndex
    Place Name: $place
    Source: $source
    Location: ($latitude, $longitude)
    Dominant Pollutant: $dominentpol
    CO: ${iaqi.co}
    Dew: ${iaqi.dew}
    H: ${iaqi.h}
    NO2: ${iaqi.no2}
    O3: ${iaqi.o3}
    P: ${iaqi.p}
    PM10: ${iaqi.pm10}
    PM25: ${iaqi.pm25}
    R: ${iaqi.r}
    SO2: ${iaqi.so2}
    T: ${iaqi.t}
    W: ${iaqi.w}
    ''';
  }
}

/// Plugin for fetching weather data in JSON.
class AirQualityWaqi {
  String _token;
  String _endpoint = 'https://api.waqi.info/feed/';

  AirQualityWaqi(this._token);

  /// Returns an [AirQualityWaqiData] object given a city name or a weather station ID
  Future<AirQualityWaqiData> feedFromCity(String city) async =>
      await _airQualityFromUrl(city);

  /// Returns an [AirQualityWaqiData] object given a city name or a weather station ID
  Future<AirQualityWaqiData> feedFromStationId(String stationId) async =>
      await _airQualityFromUrl('@$stationId');

  /// Returns an [AirQualityWaqiData] object given a latitude and longitude.
  Future<AirQualityWaqiData> feedFromGeoLocation(
          double lat, double lon) async =>
      await _airQualityFromUrl('geo:$lat;$lon');

  // /// Returns an [AirQualityWaqiData] object given using the IP address.
  // Future<AirQualityWaqiData> feedFromIP() async =>
  //     await _airQualityFromUrl('here');

  /// Send API request given a URL
  Future<Map<String, dynamic>?> _requestAirQualityWaqiFromURL(
      String keyword) async {
    final url = '$_endpoint/$keyword/?token=$_token';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>?;
    }

    throw Exception("OpenWeather API Exception: ${response.body}");
  }

  /// Fetch current weather based on geographical coordinates
  /// Result is JSON.
  /// For API documentation, see: https://openweathermap.org/current
  Future<AirQualityWaqiData> _airQualityFromUrl(String url) async {
    Map<String, dynamic>? airQualityJson =
        await _requestAirQualityWaqiFromURL(url);
    return AirQualityWaqiData(airQualityJson!);
  }
}
