import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_log/data/models.dart';
import 'package:school_log/state/api_scope.dart';
import 'package:school_log/theme/app_theme.dart';

class SchoolPickerSheet extends StatefulWidget {
  const SchoolPickerSheet({super.key, this.selectedId});

  final String? selectedId;

  @override
  State<SchoolPickerSheet> createState() => _SchoolPickerSheetState();
}

class _SchoolPickerSheetState extends State<SchoolPickerSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  int _token = 0;
  List<School> _results = const [];
  bool _loading = false;
  String? _error;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value);
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchSchools(query);
    });
  }

  Future<void> _searchSchools(String query) async {
    final token = ++_token;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await LogApiScope.of(context).searchSchools(query);
      if (!mounted || token != _token) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || token != _token) return;
      setState(() {
        _results = const [];
        _loading = false;
        _error = _errorText(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final query = _query.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '학교 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('school-search'),
                controller: _search,
                onChanged: _onChanged,
                cursorColor: AppColors.ink,
                decoration: InputDecoration(
                  hintText: '학교 이름을 입력하세요',
                  hintStyle: const TextStyle(color: AppColors.hint),
                  prefixIcon: const Icon(Icons.search, color: AppColors.caption),
                  filled: true,
                  fillColor: AppColors.field,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _body(query)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(String query) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.caption),
        ),
      );
    }
    if (query.length < 2) {
      return const Center(
        child: Text(
          '학교 이름을 두 글자 이상 입력하세요.',
          style: TextStyle(color: AppColors.caption),
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Text(
          '해당하는 학교가 없습니다.',
          style: TextStyle(color: AppColors.caption),
        ),
      );
    }
    return ListView.builder(
      key: const Key('school-list'),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final school = _results[index];
        final selected = school.id == widget.selectedId;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            school.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            '${school.regionLabel} · ${school.levelLabel}',
            style: const TextStyle(color: AppColors.caption, fontSize: 13),
          ),
          trailing: selected
              ? const Icon(Icons.check, color: AppColors.ink)
              : null,
          onTap: () => Navigator.pop(context, school),
        );
      },
    );
  }
}

class ClassPickerSheet extends StatefulWidget {
  const ClassPickerSheet({
    super.key,
    required this.school,
    required this.date,
    this.initialGrade,
    this.initialClass,
  });

  final School school;
  final DateTime date;
  final int? initialGrade;
  final int? initialClass;

  @override
  State<ClassPickerSheet> createState() => _ClassPickerSheetState();
}

class _ClassPickerSheetState extends State<ClassPickerSheet> {
  late int _grade = widget.initialGrade ?? 1;
  Future<Map<int, List<int>>>? _classes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _classes ??= LogApiScope.of(
      context,
    ).classesFor(widget.school, widget.date);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '학년 반 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.school.name,
              style: const TextStyle(fontSize: 13, color: AppColors.caption),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<int, List<int>>>(
              future: _classes,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Text(
                    _errorText(snapshot.error!),
                    style: const TextStyle(color: AppColors.caption),
                  );
                }
                final classes = snapshot.data ?? const {};
                final grades = classes.keys.toList()..sort();
                final shown = grades.isEmpty
                    ? [for (var grade = 1; grade <= widget.school.grades; grade++) grade]
                    : grades;
                final grade = shown.contains(_grade) ? _grade : shown.first;
                final numbers = classes[grade] ?? const <int>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in shown)
                          SizedBox(
                            width: 72,
                            height: 40,
                            child: _GradeButton(
                              label: '$item학년',
                              selected: grade == item,
                              onTap: () => setState(() => _grade = item),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (numbers.isEmpty)
                      const Text(
                        '반 정보가 없습니다.',
                        style: TextStyle(color: AppColors.caption),
                      )
                    else
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.1,
                        children: [
                          for (final number in numbers)
                            _GradeButton(
                              label: '$number반',
                              selected:
                                  widget.initialGrade == grade &&
                                  widget.initialClass == number,
                              onTap: () => Navigator.pop(context, (
                                grade: grade,
                                number: number,
                              )),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.ink : AppColors.line),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _errorText(Object error) {
  if (error is ApiException) return error.message;
  return '정보를 가져오지 못했습니다.';
}
