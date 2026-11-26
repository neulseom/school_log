import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:school_log/data/models.dart';
import 'package:school_log/data/neis_client.dart';
import 'package:school_log/data/school_log_api.dart';
import 'package:school_log/data/weather_client.dart';

void main() {
  test('school year and semester follow the Korean school calendar', () {
    expect(schoolYear(DateTime(2026, 11, 6)), 2026);
    expect(schoolSemester(DateTime(2026, 11, 6)), 2);
    expect(schoolYear(DateTime(2026, 2, 1)), 2025);
    expect(schoolSemester(DateTime(2026, 4, 1)), 1);
  });

  test('neis rows and school parser read a normal payload', () {
    final rows = neisRows({
      'schoolInfo': [
        {
          'head': [
            {'list_total_count': 1},
            {
              'RESULT': {'CODE': 'INFO-000', 'MESSAGE': '정상 처리되었습니다.'},
            },
          ],
        },
        {
          'row': [
            {
              'ATPT_OFCDC_SC_CODE': 'B10',
              'SD_SCHUL_CODE': '7010057',
              'SCHUL_NM': '한빛고등학교',
              'SCHUL_KND_SC_NM': '고등학교',
              'LCTN_SC_NM': '서울특별시',
              'ORG_RDNMA': '서울특별시 종로구 혜화로 1',
            },
          ],
        },
      ],
    }, 'schoolInfo');

    final schools = parseSchools(rows);
    expect(schools, hasLength(1));
    expect(schools.single.name, '한빛고등학교');
    expect(schools.single.officeCode, 'B10');
    expect(schools.single.kind, SchoolKind.high);
    expect(schools.single.address, contains('혜화로'));
  });

  test('missing neis data is an empty list', () {
    expect(
      neisRows({
        'RESULT': {'CODE': 'INFO-200', 'MESSAGE': '해당하는 데이터가 없습니다.'},
      }, 'mealServiceDietInfo'),
      isEmpty,
    );
  });

  test('meal parser strips markup and allergy numbers', () {
    final meal = parseMeal([
      {
        'MMEAL_SC_CODE': '2',
        'DDISH_NM': '흰쌀밥(1.2.3)<br/>된장찌개(5.6)<br/>배추김치',
        'CAL_INFO': '820.5 Kcal',
      },
    ]);

    expect(meal.items, ['흰쌀밥', '된장찌개', '배추김치']);
    expect(meal.kcal, 820);
  });

  test('timetable keeps subject and period only', () {
    final periods = parsePeriods([
      {'PERIO': '2', 'ITRT_CNTNT': '수학'},
      {'PERIO': '1', 'ITRT_CNTNT': '국어'},
      {'PERIO': '3', 'ITRT_CNTNT': ''},
    ]);

    expect(periods.map((period) => period.number), [1, 2]);
    expect(periods.map((period) => period.subject), ['국어', '수학']);
  });

  test('forecast keeps three-hour samples and noon as the focus', () {
    final report = parseForecast({
      'hourly': {
        'time': [
          for (var hour = 0; hour < 24; hour++)
            '2026-11-06T${hour.toString().padLeft(2, '0')}:00',
        ],
        'temperature_2m': [for (var hour = 0; hour < 24; hour++) hour],
        'relative_humidity_2m': [for (var hour = 0; hour < 24; hour++) 40 + hour],
        'precipitation_probability': [for (var hour = 0; hour < 24; hour++) hour],
        'wind_speed_10m': [for (var hour = 0; hour < 24; hour++) 1.5],
        'weather_code': [for (var hour = 0; hour < 24; hour++) hour == 12 ? 0 : 2],
      },
      'daily': {
        'time': ['2026-11-06', '2026-11-07'],
        'weather_code': [0, 3],
        'temperature_2m_max': [20.4, 18.2],
        'temperature_2m_min': [4.2, 3.6],
      },
    }, day: DateTime(2026, 11, 6));

    expect(report.hours.map((hour) => hour.time.hour), [0, 3, 6, 9, 12, 15, 18, 21]);
    expect(report.focus.hour, 12);
    expect(report.condition, '맑음');
    expect(report.temperatureC, 12);
    expect(report.humidity, 52);
    expect(report.days.first.high, 20);
    expect(report.days.first.low, 4);
  });

  test('nominatim uses the first coordinate pair', () {
    final point = parseNominatim([
      {'lat': '37.58', 'lon': '126.99'},
    ]);
    expect(point?.latitude, 37.58);
    expect(point?.longitude, 126.99);
    expect(parseNominatim(const []), isNull);
  });

  test('empty neis key fails before a request', () async {
    final client = http.Client();
    addTearDown(client.close);
    final api = LiveSchoolLogApi(client: client, key: '  ');
    await expectLater(api.searchSchools('한빛'), throwsA(isA<ApiException>()));
  });
}
