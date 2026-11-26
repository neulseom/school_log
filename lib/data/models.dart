enum SchoolKind { elementary, middle, high, special, other }

class School {
  const School({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.levelLabel,
    required this.grades,
    required this.officeCode,
    required this.schoolCode,
    required this.address,
    required this.kind,
  });

  final String id;
  final String name;
  final String city;
  final String district;
  final String levelLabel;
  final int grades;
  final String officeCode;
  final String schoolCode;
  final String address;
  final SchoolKind kind;

  String get regionLabel {
    if (city.isEmpty) return district;
    if (district.isEmpty) return city;
    return '$city $district';
  }

  @override
  bool operator ==(Object other) => other is School && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Period {
  const Period({required this.number, required this.subject});

  final int number;
  final String subject;
}

class MealMenu {
  const MealMenu({required this.items, this.kcal});

  final List<String> items;
  final int? kcal;

  bool get isServed => items.isNotEmpty;
}

class WeatherHour {
  const WeatherHour({
    required this.time,
    required this.temperatureC,
    required this.rainPercent,
    required this.windMps,
    required this.weatherCode,
  });

  final DateTime time;
  final double temperatureC;
  final int rainPercent;
  final double windMps;
  final int weatherCode;
}

class WeatherDay {
  const WeatherDay({
    required this.date,
    required this.weatherCode,
    required this.low,
    required this.high,
  });

  final DateTime date;
  final int weatherCode;
  final int low;
  final int high;
}

class WeatherReport {
  const WeatherReport({
    required this.focus,
    required this.weatherCode,
    required this.condition,
    required this.temperatureC,
    required this.humidity,
    required this.rainPercent,
    required this.windMps,
    required this.hours,
    required this.days,
  });

  final DateTime focus;
  final int weatherCode;
  final String condition;
  final double temperatureC;
  final int humidity;
  final int rainPercent;
  final double windMps;
  final List<WeatherHour> hours;
  final List<WeatherDay> days;
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
