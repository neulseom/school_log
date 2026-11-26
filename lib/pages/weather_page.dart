import 'package:flutter/material.dart';
import 'package:school_log/data/models.dart';
import 'package:school_log/data/school_log_api.dart';
import 'package:school_log/state/api_scope.dart';
import 'package:school_log/state/selection.dart';
import 'package:school_log/widgets/section.dart';
import 'package:school_log/widgets/weather_board.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key, required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final selection = SelectionScope.of(context);
    final school = selection.school;
    final date = selection.selectedDate;

    return ListView(
      key: const Key('page-weather'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
      children: [
        SectionTitle(school == null ? '날씨' : '${school.name} 날씨'),
        const SizedBox(height: 16),
        if (school == null)
          BodyNote(
            '학교를 선택하면 그 지역 날씨가 표시됩니다.',
            actionLabel: '홈에서 선택하기',
            onAction: onGoHome,
          )
        else
          _WeatherLoader(
            key: ValueKey('${school.id}-${date.year}${date.month}${date.day}'),
            school: school,
            date: date,
          ),
      ],
    );
  }
}

class _WeatherLoader extends StatefulWidget {
  const _WeatherLoader({super.key, required this.school, required this.date});

  final School school;
  final DateTime date;

  @override
  State<_WeatherLoader> createState() => _WeatherLoaderState();
}

class _WeatherLoaderState extends State<_WeatherLoader> {
  SchoolLogApi? _api;
  Future<WeatherReport>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = LogApiScope.of(context);
    _future ??= _api!.weather(school: widget.school, date: widget.date);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherReport>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return BodyNote(
            snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : '날씨를 가져오지 못했습니다.',
            actionLabel: '다시 시도',
            onAction: () => setState(() {
              _future = _api!.weather(school: widget.school, date: widget.date);
            }),
          );
        }
        return WeatherBoard(report: snapshot.data!);
      },
    );
  }
}
