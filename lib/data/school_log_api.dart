import 'package:http/http.dart' as http;
import 'package:school_log/config/neis_key.dart';
import 'package:school_log/data/models.dart';
import 'package:school_log/data/neis_client.dart';
import 'package:school_log/data/weather_client.dart';

abstract class SchoolLogApi {
  Future<List<School>> searchSchools(String query);

  Future<Map<int, List<int>>> classesFor(School school, DateTime date);

  Future<List<Period>> timetable({
    required School school,
    required int grade,
    required int classNumber,
    required DateTime date,
  });

  Future<MealMenu> meal({required School school, required DateTime date});

  Future<WeatherReport> weather({required School school, required DateTime date});
}

class LiveSchoolLogApi implements SchoolLogApi {
  LiveSchoolLogApi({http.Client? client, String? key})
    : _neis = NeisClient(key: (key ?? neisApiKey).trim(), client: client),
      _weather = WeatherClient(client: client),
      _key = (key ?? neisApiKey).trim();

  final NeisClient _neis;
  final WeatherClient _weather;
  final String _key;

  void _requireKey() {
    if (_key.isEmpty) {
      throw ApiException(
        '나이스 API 키가 없습니다. lib/config/neis_key.dart 에 키를 넣어 주세요.',
      );
    }
  }

  @override
  Future<List<School>> searchSchools(String query) async {
    _requireKey();
    final name = query.trim();
    if (name.length < 2) return const [];
    return _neis.searchSchools(name);
  }

  @override
  Future<Map<int, List<int>>> classesFor(School school, DateTime date) async {
    _requireKey();
    return _neis.classes(school: school, date: date);
  }

  @override
  Future<List<Period>> timetable({
    required School school,
    required int grade,
    required int classNumber,
    required DateTime date,
  }) async {
    _requireKey();
    return _neis.timetable(
      school: school,
      grade: grade,
      classNumber: classNumber,
      date: date,
    );
  }

  @override
  Future<MealMenu> meal({required School school, required DateTime date}) async {
    _requireKey();
    return _neis.meal(school: school, date: date);
  }

  @override
  Future<WeatherReport> weather({
    required School school,
    required DateTime date,
  }) async {
    final address = school.address.trim();
    var point = address.isEmpty ? null : await _weather.geocode(address);
    point ??= await _weather.geocode('${school.name} ${school.city}'.trim());
    if (point == null) {
      throw ApiException('학교 위치를 찾지 못했습니다.');
    }
    return _weather.forecast(
      latitude: point.latitude,
      longitude: point.longitude,
      day: date,
    );
  }
}
