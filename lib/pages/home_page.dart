import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_log/data/models.dart';
import 'package:school_log/state/selection.dart';
import 'package:school_log/widgets/month_calendar.dart';
import 'package:school_log/widgets/pickers.dart';
import 'package:school_log/widgets/school_logo.dart';
import 'package:school_log/widgets/section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final selection = SelectionScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoWidth = math.min(248.0, constraints.maxWidth * 0.7);
        return SingleChildScrollView(
          key: const Key('page-home'),
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Center(child: SchoolLogo(width: logoWidth)),
              const SizedBox(height: 52),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OutlineChoiceButton(
                      label: '학교 선택창',
                      value: selection.schoolButtonLabel,
                      onTap: () => _pickSchool(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlineChoiceButton(
                      label: '학년 반 선택창',
                      value: selection.classButtonLabel,
                      onTap: () => _pickClass(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              MonthCalendar(
                selectedDate: selection.selectedDate,
                today: selection.today,
                onSelect: selection.selectDate,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickSchool(BuildContext context) async {
    final current = SelectionScope.of(context).school;
    final selected = await showModalBottomSheet<School>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SchoolPickerSheet(selectedId: current?.id),
    );
    if (selected == null || !context.mounted) return;
    SelectionScope.of(context).selectSchool(selected);
  }

  Future<void> _pickClass(BuildContext context) async {
    final selection = SelectionScope.of(context);
    final school = selection.school;
    if (school == null) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('학교 먼저 선택'),
            content: const Text('학년과 반을 고르려면 학교를 먼저 선택해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
      return;
    }

    final selected = await showModalBottomSheet<({int grade, int number})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => ClassPickerSheet(
        school: school,
        date: selection.selectedDate,
        initialGrade: selection.grade,
        initialClass: selection.classNumber,
      ),
    );
    if (selected == null || !context.mounted) return;
    SelectionScope.of(context).selectClass(selected.grade, selected.number);
  }
}
