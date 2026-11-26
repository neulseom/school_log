import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:school_log/data/models.dart';

int schoolYear(DateTime date) => date.month >= 3 ? date.year : date.year - 1;

int schoolSemester(DateTime date) =>
    date.month >= 3 && date.month <= 8 ? 1 : 2;

String compactDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}$month$day';
}

String timetableService(SchoolKind kind) {
  return switch (kind) {
    SchoolKind.elementary => 'elsTimetable',
    SchoolKind.middle => 'misTimetable',
    SchoolKind.special => 'spsTimetable',
    SchoolKind.high || SchoolKind.other => 'hisTimetable',
  };
}

SchoolKind kindFromLabel(String label) {
  if (label.contains('초등')) return SchoolKind.elementary;
  if (label.contains('중학')) return SchoolKind.middle;
  if (label.contains('고등')) return SchoolKind.high;
  if (label.contains('특수')) return SchoolKind.special;
  return SchoolKind.other;
}

int gradesFor(SchoolKind kind) {
  return switch (kind) {
    SchoolKind.elementary => 6,
    _ => 3,
  };
}

List<Map<String, dynamic>> neisRows(Object? decoded, String service) {
  if (decoded is! Map) {
    throw ApiException('나이스 응답을 해석하지 못했습니다.');
  }
  final top = decoded['RESULT'];
  if (top is Map) {
    return _rowsFromResult(top.cast<dynamic, dynamic>(), const []);
  }
  final block = decoded[service];
  if (block is! List) return [];

  Map<dynamic, dynamic>? result;
  final rows = <Map<String, dynamic>>[];
  for (final part in block) {
    if (part is! Map) continue;
    final head = part['head'];
    if (head is List) {
      for (final item in head) {
        if (item is Map && item['RESULT'] is Map) {
          result = item['RESULT'] as Map;
        }
      }
    }
    final row = part['row'];
    if (row is List) {
      for (final item in row) {
        if (item is Map) {
          rows.add(item.map((key, value) => MapEntry('$key', value)));
        }
      }
    }
  }
  if (result == null) return rows;
  return _rowsFromResult(result, rows);
}

List<Map<String, dynamic>> _rowsFromResult(
  Map<dynamic, dynamic> result,
  List<Map<String, dynamic>> rows,
) {
  final code = '${result['CODE']}';
  if (code == 'INFO-000' || code == 'null') return rows;
  if (code == 'INFO-200') return [];
  final message = '${result['MESSAGE'] ?? ''}'.trim();
  throw ApiException(message.isEmpty ? '나이스 요청이 거절되었습니다.' : message);
}

List<School> parseSchools(List<Map<String, dynamic>> rows) {
  final schools = <School>[];
  for (final row in rows) {
    final office = '${row['ATPT_OFCDC_SC_CODE'] ?? ''}'.trim();
    final code = '${row['SD_SCHUL_CODE'] ?? ''}'.trim();
    final name = '${row['SCHUL_NM'] ?? ''}'.trim();
    if (office.isEmpty || code.isEmpty || name.isEmpty) continue;
    final level = '${row['SCHUL_KND_SC_NM'] ?? ''}'.trim();
    final kind = kindFromLabel(level);
    schools.add(
      School(
        id: '$office:$code',
        name: name,
        city: '${row['LCTN_SC_NM'] ?? ''}'.trim(),
        district: '',
        levelLabel: level.isEmpty ? '학교' : level,
        grades: gradesFor(kind),
        officeCode: office,
        schoolCode: code,
        address: '${row['ORG_RDNMA'] ?? ''}'.trim(),
        kind: kind,
      ),
    );
  }
  return schools;
}

Map<int, List<int>> parseClasses(List<Map<String, dynamic>> rows) {
  final grouped = <int, Set<int>>{};
  for (final row in rows) {
    final grade = int.tryParse('${row['GRADE'] ?? ''}');
    final number = int.tryParse('${row['CLASS_NM'] ?? ''}');
    if (grade == null || number == null || grade <= 0 || number <= 0) continue;
    grouped.putIfAbsent(grade, () => <int>{}).add(number);
  }
  return {
    for (final entry in grouped.entries)
      entry.key: (entry.value.toList()..sort()),
  };
}

List<Period> parsePeriods(List<Map<String, dynamic>> rows) {
  final periods = <Period>[];
  for (final row in rows) {
    final number = int.tryParse('${row['PERIO'] ?? ''}');
    final subject = '${row['ITRT_CNTNT'] ?? ''}'.trim();
    if (number == null || number <= 0 || subject.isEmpty) continue;
    periods.add(Period(number: number, subject: subject));
  }
  periods.sort((a, b) => a.number.compareTo(b.number));
  return periods;
}

MealMenu parseMeal(List<Map<String, dynamic>> rows) {
  Map<String, dynamic>? lunch;
  for (final row in rows) {
    final type = '${row['MMEAL_SC_CODE'] ?? ''}';
    if (type.isEmpty || type == '2') {
      lunch = row;
      if (type == '2') break;
    }
  }
  lunch ??= rows.isEmpty ? null : rows.first;
  if (lunch == null) return const MealMenu(items: []);

  final raw = '${lunch['DDISH_NM'] ?? ''}'
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  final items = raw
      .split('\n')
      .map(
        (item) => item.replaceAll(RegExp(r'\s*\([0-9.\s]+\)\s*'), ' ').trim(),
      )
      .where((item) => item.isNotEmpty)
      .toList();
  final calories = RegExp(r'(\d+)').firstMatch('${lunch['CAL_INFO'] ?? ''}');
  return MealMenu(
    items: items,
    kcal: calories == null ? null : int.tryParse(calories.group(1)!),
  );
}

class NeisClient {
  NeisClient({required this.key, http.Client? client})
    : _client = client ?? http.Client();

  final String key;
  final http.Client _client;

  Future<List<School>> searchSchools(String query) async {
    final rows = await _get('schoolInfo', {'SCHUL_NM': query, 'pSize': '30'});
    return parseSchools(rows);
  }

  Future<Map<int, List<int>>> classes({
    required School school,
    required DateTime date,
  }) async {
    final rows = await _get('classInfo', {
      'ATPT_OFCDC_SC_CODE': school.officeCode,
      'SD_SCHUL_CODE': school.schoolCode,
      'AY': '${schoolYear(date)}',
      'pSize': '300',
    });
    return parseClasses(rows);
  }

  Future<List<Period>> timetable({
    required School school,
    required int grade,
    required int classNumber,
    required DateTime date,
  }) async {
    final rows = await _get(timetableService(school.kind), {
      'ATPT_OFCDC_SC_CODE': school.officeCode,
      'SD_SCHUL_CODE': school.schoolCode,
      'AY': '${schoolYear(date)}',
      'SEM': '${schoolSemester(date)}',
      'ALL_TI_YMD': compactDate(date),
      'GRADE': '$grade',
      'CLASS_NM': '$classNumber',
      'pSize': '20',
    });
    return parsePeriods(rows);
  }

  Future<MealMenu> meal({required School school, required DateTime date}) async {
    final day = compactDate(date);
    final rows = await _get('mealServiceDietInfo', {
      'ATPT_OFCDC_SC_CODE': school.officeCode,
      'SD_SCHUL_CODE': school.schoolCode,
      'MLSV_YMD': day,
      'MMEAL_SC_CODE': '2',
      'pSize': '5',
    });
    return parseMeal(rows);
  }

  Future<List<Map<String, dynamic>>> _get(
    String service,
    Map<String, String> query,
  ) async {
    final uri = Uri.https('open.neis.go.kr', '/hub/$service', {
      'KEY': key,
      'Type': 'json',
      'pIndex': '1',
      ...query,
    });
    final response = await _send(uri);
    final decoded = jsonDecode(response.body);
    return neisRows(decoded, service);
  }

  Future<http.Response> _send(Uri uri) async {
    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        throw ApiException('나이스 응답 오류 (${response.statusCode})');
      }
      return response;
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw ApiException('인터넷 연결을 확인해 주세요.');
    }
  }
}
