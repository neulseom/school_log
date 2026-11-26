import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_log/data/models.dart';
import 'package:school_log/format.dart';

enum _WeatherTab { temperature, rain, wind }

class WeatherBoard extends StatefulWidget {
  const WeatherBoard({super.key, required this.report});

  final WeatherReport report;

  @override
  State<WeatherBoard> createState() => _WeatherBoardState();
}

class _WeatherBoardState extends State<WeatherBoard> {
  _WeatherTab _tab = _WeatherTab.temperature;
  bool _fahrenheit = false;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final values = [
      for (final hour in report.hours) _chartValue(hour),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2430),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'NotoSansKR',
            color: Colors.white,
            fontSize: 14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                report: report,
                fahrenheit: _fahrenheit,
                onUnit: (fahrenheit) =>
                    setState(() => _fahrenheit = fahrenheit),
              ),
              const SizedBox(height: 18),
              _Tabs(
                selected: _tab,
                onSelect: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: 8),
              _Chart(values: values, labels: _labels(values)),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final hour in report.hours)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _hourLabel(hour.time),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFAEB8C4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (report.days.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: report.days.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = report.days[index];
                      return _DayChip(
                        day: day,
                        fahrenheit: _fahrenheit,
                        selected: isSameDate(day.date, report.focus),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _chartValue(WeatherHour hour) {
    return switch (_tab) {
      _WeatherTab.temperature => _fahrenheit
          ? hour.temperatureC * 9 / 5 + 32
          : hour.temperatureC,
      _WeatherTab.rain => hour.rainPercent.toDouble(),
      _WeatherTab.wind => hour.windMps,
    };
  }

  List<String> _labels(List<double> values) {
    return [
      for (final value in values)
        switch (_tab) {
          _WeatherTab.wind => _speedText(value),
          _ => '${value.round()}',
        },
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.report,
    required this.fahrenheit,
    required this.onUnit,
  });

  final WeatherReport report;
  final bool fahrenheit;
  final ValueChanged<bool> onUnit;

  @override
  Widget build(BuildContext context) {
    final shown = fahrenheit
        ? (report.temperatureC * 9 / 5 + 32).round()
        : report.temperatureC.round();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WeatherIcon(code: report.weatherCode, size: 40),
        const SizedBox(width: 6),
        Text(
          '$shown',
          style: const TextStyle(
            fontSize: 36,
            height: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _UnitToggle(fahrenheit: fahrenheit, onChanged: onUnit),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stat('강수확률', '${report.rainPercent}%'),
                _Stat('습도', '${report.humidity}%'),
                _Stat('풍속', '${_speedText(report.windMps)}m/s'),
              ],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '날씨',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 96,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _clockLabel(report.focus),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD5DCE6),
                  ),
                ),
              ),
            ),
            Text(
              report.condition,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Color(0xFFE6EBF2)),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.fahrenheit, required this.onChanged});

  final bool fahrenheit;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget unit(String text, bool selected, bool next) {
      return GestureDetector(
        onTap: () => onChanged(next),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF8E98A6),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        unit('°C', !fahrenheit, false),
        const Text(' | ', style: TextStyle(color: Color(0xFF8E98A6), fontSize: 13)),
        unit('°F', fahrenheit, true),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelect});

  final _WeatherTab selected;
  final ValueChanged<_WeatherTab> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tab(_WeatherTab value, String label) {
      final active = selected == value;
      return GestureDetector(
        onTap: () => onSelect(value),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFFE2B340) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : const Color(0xFF9AA4B2),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(_WeatherTab.temperature, '기온'),
        const SizedBox(width: 18),
        tab(_WeatherTab.rain, '강수확률'),
        const SizedBox(width: 18),
        tab(_WeatherTab.wind, '바람'),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final plotTop = 18.0;
          final plotHeight = constraints.maxHeight - plotTop;
          final points = _points(values, width, plotHeight);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: plotTop,
                height: plotHeight,
                child: CustomPaint(
                  painter: _ChartPainter(points),
                ),
              ),
              for (var index = 0; index < points.length; index++)
                Positioned(
                  left: (points[index].dx - 16).clamp(0.0, math.max(0, width - 32)),
                  top: (plotTop + points[index].dy - 16).clamp(0.0, constraints.maxHeight - 16),
                  width: 32,
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1,
                      color: Color(0xFFF3F6FA),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = const Color(0xFF6A5424));
    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0xFFE2B340)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.fahrenheit,
    required this.selected,
  });

  final WeatherDay day;
  final bool fahrenheit;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final high = fahrenheit ? _toF(day.high.toDouble()) : day.high;
    final low = fahrenheit ? _toF(day.low.toDouble()) : day.low;
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2C3848) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            weekdayKo[day.date.weekday - 1],
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          WeatherIcon(code: day.weatherCode, size: 28),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$high°'),
                  TextSpan(
                    text: ' $low°',
                    style: const TextStyle(color: Color(0xFFAEB8C4)),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherIcon extends StatelessWidget {
  const WeatherIcon({super.key, required this.code, this.size = 48});

  final int code;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _WeatherIconPainter(_kind(code)),
    );
  }
}

enum _Sky { clear, partly, cloudy, rain, snow, thunder, fog }

_Sky _kind(int code) {
  if (code == 0) return _Sky.clear;
  if (code == 1 || code == 2) return _Sky.partly;
  if (code == 3) return _Sky.cloudy;
  if (code == 45 || code == 48) return _Sky.fog;
  if (code >= 71 && code <= 77 || code >= 85 && code <= 86) return _Sky.snow;
  if (code >= 95) return _Sky.thunder;
  if (code >= 51) return _Sky.rain;
  return _Sky.cloudy;
}

class _WeatherIconPainter extends CustomPainter {
  const _WeatherIconPainter(this.kind);

  final _Sky kind;

  @override
  void paint(Canvas canvas, Size size) {
    final sun = Paint()..color = const Color(0xFFF0A03A);
    final cloud = Paint()..color = const Color(0xFFD5DDE8);
    final rain = Paint()
      ..color = const Color(0xFF8EC8F5)
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    final unit = size.width;

    void drawSun(Offset center, double radius) {
      canvas.drawCircle(center, radius, sun);
      final ray = Paint()
        ..color = const Color(0xFFF0A03A)
        ..strokeWidth = unit * 0.045
        ..strokeCap = StrokeCap.round;
      for (var index = 0; index < 8; index++) {
        final angle = index * math.pi / 4;
        final inner = Offset(
          center.dx + math.cos(angle) * radius * 1.35,
          center.dy + math.sin(angle) * radius * 1.35,
        );
        final outer = Offset(
          center.dx + math.cos(angle) * radius * 1.85,
          center.dy + math.sin(angle) * radius * 1.85,
        );
        canvas.drawLine(inner, outer, ray);
      }
    }

    void drawCloud(Offset center, double scale) {
      canvas.drawCircle(center.translate(-scale * 0.45, scale * 0.1), scale * 0.38, cloud);
      canvas.drawCircle(center.translate(0, -scale * 0.08), scale * 0.48, cloud);
      canvas.drawCircle(center.translate(scale * 0.48, scale * 0.12), scale * 0.34, cloud);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center.translate(0, scale * 0.28),
            width: scale * 1.45,
            height: scale * 0.42,
          ),
          Radius.circular(scale),
        ),
        cloud,
      );
    }

    switch (kind) {
      case _Sky.clear:
        drawSun(Offset(unit / 2, unit / 2), unit * 0.24);
      case _Sky.partly:
        drawSun(Offset(unit * 0.62, unit * 0.34), unit * 0.16);
        drawCloud(Offset(unit * 0.42, unit * 0.58), unit * 0.42);
      case _Sky.cloudy:
        drawCloud(Offset(unit * 0.5, unit * 0.52), unit * 0.5);
      case _Sky.rain:
        drawCloud(Offset(unit * 0.5, unit * 0.38), unit * 0.42);
        for (var index = 0; index < 3; index++) {
          final x = unit * (0.32 + index * 0.18);
          canvas.drawLine(
            Offset(x, unit * 0.68),
            Offset(x - unit * 0.06, unit * 0.86),
            rain,
          );
        }
      case _Sky.snow:
        drawCloud(Offset(unit * 0.5, unit * 0.36), unit * 0.4);
        final flake = Paint()..color = Colors.white;
        for (var index = 0; index < 3; index++) {
          canvas.drawCircle(
            Offset(unit * (0.32 + index * 0.18), unit * 0.78),
            unit * 0.045,
            flake,
          );
        }
      case _Sky.thunder:
        drawCloud(Offset(unit * 0.5, unit * 0.36), unit * 0.42);
        final bolt = Path()
          ..moveTo(unit * 0.56, unit * 0.58)
          ..lineTo(unit * 0.42, unit * 0.78)
          ..lineTo(unit * 0.52, unit * 0.78)
          ..lineTo(unit * 0.4, unit * 0.96)
          ..lineTo(unit * 0.66, unit * 0.7)
          ..lineTo(unit * 0.54, unit * 0.7)
          ..close();
        canvas.drawPath(bolt, Paint()..color = const Color(0xFFF0D15A));
      case _Sky.fog:
        final band = Paint()
          ..color = const Color(0xFFD5DDE8)
          ..strokeWidth = unit * 0.08
          ..strokeCap = StrokeCap.round;
        for (var index = 0; index < 3; index++) {
          final y = unit * (0.32 + index * 0.2);
          canvas.drawLine(Offset(unit * 0.18, y), Offset(unit * 0.82, y), band);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherIconPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

List<Offset> _points(List<double> values, double width, double height) {
  if (values.isEmpty) return const [];
  final minValue = values.reduce(math.min);
  final maxValue = values.reduce(math.max);
  final span = math.max(0.8, maxValue - minValue);
  final low = minValue - span * 0.35;
  final high = maxValue + span * 0.45;
  final last = math.max(1, values.length - 1);
  return [
    for (var index = 0; index < values.length; index++)
      Offset(
        values.length == 1 ? width / 2 : index * width / last,
        height - ((values[index] - low) / (high - low)) * (height - 6) - 3,
      ),
  ];
}

String _hourLabel(DateTime time) {
  final afternoon = time.hour >= 12;
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '${afternoon ? '오후' : '오전'} $hour시';
}

String _clockLabel(DateTime time) {
  final minute = time.minute.toString().padLeft(2, '0');
  final afternoon = time.hour >= 12;
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final weekday = weekdayKo[time.weekday - 1];
  return '($weekday요일) ${afternoon ? '오후' : '오전'} $hour:$minute';
}

String _speedText(double value) {
  final rounded = (value * 10).round() / 10;
  if ((rounded - rounded.round()).abs() < 0.05) return '${rounded.round()}';
  return rounded.toStringAsFixed(1);
}

int _toF(double celsius) => (celsius * 9 / 5 + 32).round();
