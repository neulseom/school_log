import 'package:flutter/material.dart';
import 'package:school_log/data/models.dart';
import 'package:school_log/data/school_log_api.dart';
import 'package:school_log/format.dart';
import 'package:school_log/state/api_scope.dart';
import 'package:school_log/state/selection.dart';
import 'package:school_log/theme/app_theme.dart';
import 'package:school_log/widgets/section.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key, required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final selection = SelectionScope.of(context);
    final school = selection.school;
    final date = selection.selectedDate;

    return ListView(
      key: const Key('page-schedule'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
      children: [
        if (school == null)
          ..._emptySchool(onGoHome)
        else if (!selection.hasClass)
          ..._needsClass(school, onGoHome, date)
        else
          _PlanLoader(
            key: ValueKey(
              '${school.id}-${selection.grade}-${selection.classNumber}-${date.year}${date.month}${date.day}',
            ),
            school: school,
            grade: selection.grade!,
            classNumber: selection.classNumber!,
            date: date,
            classLabel: selection.classButtonLabel,
          ),
      ],
    );
  }

  List<Widget> _emptySchool(VoidCallback onGoHome) {
    return [
      const SectionTitle('시간표'),
      const SizedBox(height: 16),
      BodyNote(
        '학교를 선택하면 시간표가 표시됩니다.',
        actionLabel: '홈에서 선택하기',
        onAction: onGoHome,
      ),
      const SizedBox(height: 40),
      const SectionTitle('급식'),
      const SizedBox(height: 16),
      BodyNote(
        '학교를 선택하면 급식이 표시됩니다.',
        actionLabel: '홈에서 선택하기',
        onAction: onGoHome,
      ),
    ];
  }

  List<Widget> _needsClass(School school, VoidCallback onGoHome, DateTime date) {
    return [
      SectionTitle('${school.name} 시간표'),
      const SizedBox(height: 16),
      BodyNote(
        '학년과 반을 선택하면 시간표가 표시됩니다.',
        actionLabel: '홈에서 선택하기',
        onAction: onGoHome,
      ),
      const SizedBox(height: 40),
      _MealLoader(
        key: ValueKey('meal-${school.id}-${date.year}${date.month}${date.day}'),
        school: school,
        date: date,
      ),
    ];
  }
}

class _MealLoader extends StatefulWidget {
  const _MealLoader({super.key, required this.school, required this.date});

  final School school;
  final DateTime date;

  @override
  State<_MealLoader> createState() => _MealLoaderState();
}

class _MealLoaderState extends State<_MealLoader> {
  SchoolLogApi? _api;
  Future<MealMenu>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = LogApiScope.of(context);
    _future ??= _api!.meal(school: widget.school, date: widget.date);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MealMenu>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
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
                : '급식을 가져오지 못했습니다.',
            actionLabel: '다시 시도',
            onAction: () => setState(() {
              _future = _api!.meal(school: widget.school, date: widget.date);
            }),
          );
        }
        final meal = snapshot.data!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('${widget.school.name} 급식'),
            const SizedBox(height: 6),
            SectionCaption(
              meal.kcal == null
                  ? '${widget.school.name} · ${formatMonthDay(widget.date)}'
                  : '${widget.school.name} · ${formatMonthDay(widget.date)} · ${meal.kcal}kcal',
            ),
            const SizedBox(height: 16),
            if (!meal.isServed)
              const BodyNote('해당 날짜의 급식이 없습니다.')
            else
              for (final item in meal.items) BulletLine(item),
          ],
        );
      },
    );
  }
}

class _Plan {
  const _Plan(this.periods, this.meal);

  final List<Period> periods;
  final MealMenu meal;
}

class _PlanLoader extends StatefulWidget {
  const _PlanLoader({
    super.key,
    required this.school,
    required this.grade,
    required this.classNumber,
    required this.date,
    required this.classLabel,
  });

  final School school;
  final int grade;
  final int classNumber;
  final DateTime date;
  final String classLabel;

  @override
  State<_PlanLoader> createState() => _PlanLoaderState();
}

class _PlanLoaderState extends State<_PlanLoader> {
  SchoolLogApi? _api;
  Future<_Plan>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api = LogApiScope.of(context);
    _future ??= _fetch();
  }

  Future<_Plan> _fetch() {
    final api = _api!;
    return Future.wait([
      api.timetable(
        school: widget.school,
        grade: widget.grade,
        classNumber: widget.classNumber,
        date: widget.date,
      ),
      api.meal(school: widget.school, date: widget.date),
    ]).then((values) => _Plan(values[0] as List<Period>, values[1] as MealMenu));
  }

  @override
  Widget build(BuildContext context) {
    final school = widget.school;
    final date = widget.date;
    return FutureBuilder<_Plan>(
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
                : '시간표와 급식을 가져오지 못했습니다.',
            actionLabel: '다시 시도',
            onAction: () => setState(() => _future = _fetch()),
          );
        }
        final plan = snapshot.data!;
        final meal = plan.meal;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('${school.name} 시간표'),
            const SizedBox(height: 6),
            SectionCaption(
              '${school.name} · ${widget.classLabel} · ${formatMonthDay(date)}',
            ),
            const SizedBox(height: 16),
            if (plan.periods.isEmpty)
              const BodyNote('해당 날짜의 시간표가 없습니다.')
            else
              for (final period in plan.periods) PeriodRow(period: period),
            const SizedBox(height: 40),
            SectionTitle('${school.name} 급식'),
            const SizedBox(height: 6),
            SectionCaption(
              meal.kcal == null
                  ? '${school.name} · ${formatMonthDay(date)}'
                  : '${school.name} · ${formatMonthDay(date)} · ${meal.kcal}kcal',
            ),
            const SizedBox(height: 16),
            if (!meal.isServed)
              const BodyNote('해당 날짜의 급식이 없습니다.')
            else
              for (final item in meal.items) BulletLine(item),
          ],
        );
      },
    );
  }
}

class PeriodRow extends StatelessWidget {
  const PeriodRow({super.key, required this.period});

  final Period period;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${period.number}교시',
              style: const TextStyle(
                fontSize: 15,
                height: 1.2,
                color: AppColors.body,
              ),
            ),
          ),
          Expanded(
            child: Text(
              period.subject,
              style: const TextStyle(
                fontSize: 15,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
