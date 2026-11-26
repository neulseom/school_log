import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:school_log/data/models.dart';
import 'package:school_log/format.dart';

const _userAgent = 'school_log/1.0 (school timetable app)';

String weatherCondition(int code) {
  if (code == 0) return '맑음';
  if (code == 1 || code == 2) return '구름 조금';
  if (code == 3) return '흐림';
  if (code == 45 || code == 48) return '안개';
  if (code >= 51 && code <= 67) return '비';
  if (code >= 71 && code <= 77) return '눈';
  if (code >= 80 && code <= 82) return '소나기';
  if (code >= 85 && code <= 86) return '눈';
  if (code >= 95) return '뇌우';
  return '흐림';
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

GeoPoint? parseNominatim(Object? decoded) {
  if (decoded is! List || decoded.isEmpty) return null;
  final first = decoded.first;
  if (first is! Map) return null;
  final latitude = double.tryParse('${first['lat']}');
  final longitude = double.tryParse('${first['lon']}');
  if (latitude == null || longitude == null) return null;
  return GeoPoint(latitude, longitude);
}

DateTime? _hourTime(Object? value) {
  final text = '$value';
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})').firstMatch(text);
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
  );
}

DateTime? _dayTime(Object? value) {
  final text = '$value';
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

double _asDouble(Object? value) => value is num ? value.toDouble() : 0;

int _asInt(Object? value) => value is num ? value.round() : 0;

List<Object?> _series(Map<dynamic, dynamic>? block, String key) {
  final value = block?[key];
  if (value is List) return value;
  return const [];
}

WeatherReport parseForecast(Object? decoded, {required DateTime day}) {
  if (decoded is! Map) {
    throw ApiException('날씨 응답을 해석하지 못했습니다.');
  }
  final reason = decoded['reason'];
  if (reason is String && reason.isNotEmpty) {
    throw ApiException('선택한 날짜의 예보가 없습니다.');
  }
  final anchor = dateOnly(day);
  final hourly = decoded['hourly'] is Map ? decoded['hourly'] as Map : null;
  final times = _series(hourly, 'time');
  final temps = _series(hourly, 'temperature_2m');
  final humidity = _series(hourly, 'relative_humidity_2m');
  final rain = _series(hourly, 'precipitation_probability');
  final wind = _series(hourly, 'wind_speed_10m');
  final codes = _series(hourly, 'weather_code');

  final hours = <WeatherHour>[];
  for (var index = 0; index < times.length; index++) {
    final time = _hourTime(times[index]);
    if (time == null || !isSameDate(time, anchor)) continue;
    if (time.hour % 3 != 0) continue;
    hours.add(
      WeatherHour(
        time: time,
        temperatureC: index < temps.length ? _asDouble(temps[index]) : 0,
        rainPercent: index < rain.length ? _asInt(rain[index]) : 0,
        windMps: index < wind.length ? _asDouble(wind[index]) : 0,
        weatherCode: index < codes.length ? _asInt(codes[index]) : 0,
      ),
    );
  }
  if (hours.isEmpty) {
    throw ApiException('선택한 날짜의 예보가 없습니다.');
  }

  WeatherHour focus = hours.first;
  for (final hour in hours) {
    if (hour.time.hour == 12) {
      focus = hour;
      break;
    }
  }
  final focusIndex = times.indexWhere((value) {
    final time = _hourTime(value);
    return time != null &&
        time.year == focus.time.year &&
        time.month == focus.time.month &&
        time.day == focus.time.day &&
        time.hour == focus.time.hour;
  });
  final focusHumidity = focusIndex >= 0 && focusIndex < humidity.length
      ? _asInt(humidity[focusIndex])
      : 0;

  final daily = decoded['daily'] is Map ? decoded['daily'] as Map : null;
  final dayTimes = _series(daily, 'time');
  final dayCodes = _series(daily, 'weather_code');
  final highs = _series(daily, 'temperature_2m_max');
  final lows = _series(daily, 'temperature_2m_min');
  final days = <WeatherDay>[];
  for (var index = 0; index < dayTimes.length && days.length < 8; index++) {
    final date = _dayTime(dayTimes[index]);
    if (date == null || date.isBefore(anchor)) continue;
    days.add(
      WeatherDay(
        date: date,
        weatherCode: index < dayCodes.length ? _asInt(dayCodes[index]) : 0,
        high: index < highs.length ? _asDouble(highs[index]).round() : 0,
        low: index < lows.length ? _asDouble(lows[index]).round() : 0,
      ),
    );
  }

  return WeatherReport(
    focus: focus.time,
    weatherCode: focus.weatherCode,
    condition: weatherCondition(focus.weatherCode),
    temperatureC: focus.temperatureC,
    humidity: focusHumidity,
    rainPercent: focus.rainPercent,
    windMps: focus.windMps,
    hours: hours,
    days: days,
  );
}

class WeatherClient {
  WeatherClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, GeoPoint?> _locations = {};

  Future<GeoPoint?> geocode(String query) async {
    final key = query.trim();
    if (key.isEmpty) return null;
    if (_locations.containsKey(key)) return _locations[key];
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': key,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'kr',
    });
    final response = await _send(uri, {
      'User-Agent': _userAgent,
      'Accept-Language': 'ko',
    });
    final point = parseNominatim(jsonDecode(response.body));
    _locations[key] = point;
    return point;
  }

  Future<WeatherReport> forecast({
    required double latitude,
    required double longitude,
    required DateTime day,
  }) async {
    final start = dateOnly(day);
    final end = start.add(const Duration(days: 7));
    final today = dateOnly(DateTime.now());
    final archive = start.isBefore(today);
    final host = archive ? 'archive-api.open-meteo.com' : 'api.open-meteo.com';
    final path = archive ? '/v1/archive' : '/v1/forecast';
    final uri = Uri.https(host, path, {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'hourly':
          'temperature_2m,relative_humidity_2m,precipitation_probability,wind_speed_10m,weather_code',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'timezone': 'Asia/Seoul',
      'start_date': _iso(start),
      'end_date': _iso(end),
      'wind_speed_unit': 'ms',
    });
    final response = await _send(uri, const {'User-Agent': _userAgent});
    return parseForecast(jsonDecode(response.body), day: start);
  }

  Future<http.Response> _send(Uri uri, Map<String, String> headers) async {
    try {
      final response = await _client.get(uri, headers: headers);
      if (response.statusCode != 200) {
        throw ApiException('날씨 정보를 가져오지 못했습니다.');
      }
      return response;
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw ApiException('인터넷 연결을 확인해 주세요.');
    }
  }
}

String _iso(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
