import 'package:school_log/data/models.dart';
import 'package:school_log/data/school_log_api.dart';

class FakeSchoolLogApi implements SchoolLogApi {
  static const school = School(
    id: 'B10:7010057',
    name: '한빛고등학교',
    city: '서울특별시',
    district: '종로구',
    levelLabel: '고등학교',
    grades: 3,
    officeCode: 'B10',
    schoolCode: '7010057',
    address: '서울특별시 종로구 혜화로',
    kind: SchoolKind.high,
  );

  @override
  Future<List<School>> searchSchools(String query) async {
    if (school.name.contains(query.trim())) return const [school];
    return const [];
  }

  @override
  Future<Map<int, List<int>>> classesFor(School school, DateTime date) async {
    return const {
      1: [1, 2, 3, 4],
      2: [1, 2, 3, 4],
      3: [1, 2, 3, 4],
    };
  }

  @override
  Future<List<Period>> timetable({
    required School school,
    required int grade,
    required int classNumber,
    required DateTime date,
  }) async {
    return const [
      Period(number: 1, subject: '국어'),
      Period(number: 2, subject: '수학'),
    ];
  }

  @override
  Future<MealMenu> meal({required School school, required DateTime date}) async {
    return const MealMenu(items: ['배추김치', '된장찌개'], kcal: 820);
  }

  @override
  Future<WeatherReport> weather({
    required School school,
    required DateTime date,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    return WeatherReport(
      focus: DateTime(day.year, day.month, day.day, 12),
      weatherCode: 0,
      condition: '맑음',
      temperatureC: 12,
      humidity: 35,
      rainPercent: 10,
      windMps: 4,
      hours: [
        for (final hour in [0, 3, 6, 9, 12, 15, 18, 21])
          WeatherHour(
            time: DateTime(day.year, day.month, day.day, hour),
            temperatureC: 8 + hour / 3,
            rainPercent: 10,
            windMps: 4,
            weatherCode: 0,
          ),
      ],
      days: [
        for (var index = 0; index < 8; index++)
          WeatherDay(
            date: day.add(Duration(days: index)),
            weatherCode: index == 2 ? 3 : 0,
            low: 4,
            high: 12,
          ),
      ],
    );
  }
}
