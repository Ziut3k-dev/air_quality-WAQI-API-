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
class AirQualityWaqiAPIException implements Exception {
  String _cause;

  AirQualityWaqiAPIException(this._cause);

  String toString() => '${this.runtimeType} - $_cause';
}

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
  late double co;
  late double dew;
  late double h;
  late double no2;
  late double o3;
  late double p;
  late double pm10;
  late double pm25;
  late double r;
  late double so2;
  late double t;
  late double w;

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
  late int _airQualityIndex;
  late String _source, _place, _dominentpol;
  late double _latitude, _longitude;
  late AirQualityWaqiLevel _airQualityLevel;
  late bool _status;
  late Iaqi _iaqi;
  AirQualityWaqiData(Map<String, dynamic> airQualityJson) {
    _airQualityIndex =
        int.tryParse(airQualityJson['data']['aqi'].toString()) ?? -1;

    _place = airQualityJson['data']['city']['name'].toString();

    _source = airQualityJson['data']['attributions'][0]['name'].toString();

    _latitude =
        double.tryParse(airQualityJson['data']['city']['geo'][0].toString()) ??
            -1.0;

    _longitude =
        double.tryParse(airQualityJson['data']['city']['geo'][1].toString()) ??
            -1.0;

    _dominentpol = airQualityJson['data']['dominentpol'].toString();

    _airQualityLevel = airQualityIndexToLevel(_airQualityIndex);

    var status = airQualityJson['data']['status'].toString();

    if (status == 'ok') {
      this._status = true;
    } else {
      this._status = false;
    }
    _iaqi = Iaqi(
      co: airQualityJson['data']['iaqi']['co']['v'].toDouble(),
      dew: airQualityJson['data']['iaqi']['dew']['v'].toDouble(),
      h: airQualityJson['data']['iaqi']['h']['v'].toDouble(),
      no2: airQualityJson['data']['iaqi']['no2']['v'].toDouble(),
      o3: airQualityJson['data']['iaqi']['o3']['v'].toDouble(),
      p: airQualityJson['data']['iaqi']['p']['v'].toDouble(),
      pm10: airQualityJson['data']['iaqi']['pm10']['v'].toDouble(),
      pm25: airQualityJson['data']['iaqi']['pm25']['v'].toDouble(),
      r: airQualityJson['data']['iaqi']['r']['v'].toDouble(),
      so2: airQualityJson['data']['iaqi']['so2']['v'].toDouble(),
      t: airQualityJson['data']['iaqi']['t']['v'].toDouble(),
      w: airQualityJson['data']['iaqi']['w']['v'].toDouble(),
    );
  }

  int get airQualityIndex => _airQualityIndex;

  String get place => _place;

  String get source => _source;

  double get latitude => _latitude;

  String get dominentpol => _dominentpol;

  double get longitude => _longitude;

  bool get status => _status;

  AirQualityWaqiLevel get airQualityLevel => _airQualityLevel;

  String toString() {
    return '''
    Air Quality Level: ${_airQualityLevel.toString().split('.').last}
    AQI: $_airQualityIndex
    Place Name: $_place
    Source: $_source
    Location: ($_latitude, $_longitude)
    Dominentpol: $_dominentpol
    CO: ${_iaqi.co}
    Dew: ${_iaqi.dew}
    H: ${_iaqi.h}
    NO2: ${_iaqi.no2}
    O3: ${_iaqi.o3}
    P: ${_iaqi.p}
    PM10: ${_iaqi.pm10}
    PM25: ${_iaqi.pm25}
    R: ${_iaqi.r}
    SO2: ${_iaqi.so2}
    T: ${_iaqi.t}
    W: ${_iaqi.w}
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

  /// Returns an [AirQualityWaqiData] object given using the IP address.
  Future<AirQualityWaqiData> feedFromIP() async =>
      await _airQualityFromUrl('here');

  /// Send API request given a URL
  Future<Map<String, dynamic>?> _requestAirQualityWaqiFromURL(
      String keyword) async {
    /// Make url using the keyword
    String url = '$_endpoint/$keyword/?token=$_token';

    /// Send HTTP get response with the url
    http.Response response = await http.get(Uri.parse(url));

    /// Perform error checking on response:
    /// Status code 200 means everything went well
    if (response.statusCode == 200) {
      Map<String, dynamic>? jsonBody = json.decode(response.body);
      return jsonBody;
    }
    throw AirQualityWaqiAPIException(
        "OpenWeather API Exception: ${response.body}");
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
