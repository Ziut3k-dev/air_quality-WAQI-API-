# Air Quality Index

Collects air quality index from the [World's Air Quality Index](https://waqi.info/) service.

## Permissions
No permissions needed.

## Usage
### Imports
The location package is also needed for the AirQualityWaqi package.
```dart
import 'package:air_quality_waqi/air_quality_waqi.dart';
```

### Initialization
An API key is needed in order to perform queries. An API key is obtained here: https://aqicn.org/api/

Example:

```dart
String key = 'XXX38456b2b85c92647d8b65090e29f957638c77';
AirQualityWaqi airQualityWaqi = new AirQualityWaqi(key);
```

### Air Quality Feed Examples

```dart
/// Via city name (Munich)
AirQualityWaqiData feedFromCity = 
    await airQualityWaqi.feedFromCity('munich');

/// Via station ID (Gothenburg weather station)
AirQualityWaqiData feedFromStationId = 
    await airQualityWaqi.feedFromStationId('7867');

/// Via Geo Location (Berlin)
AirQualityWaqiData feedFromGeoLocation = 
    await airQualityWaqi.feedFromGeoLocation('52.6794', '12.5346');

/// Via IP (depends on service provider)
AirQualityWaqiData fromIP = 
    await airQualityWaqi.feedFromIP();
```
