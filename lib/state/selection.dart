import 'package:flutter/widgets.dart';
import 'package:school_log/data/models.dart';
import 'package:school_log/format.dart';

class SelectionController extends ChangeNotifier {
  SelectionController({DateTime? today})
    : today = dateOnly(today ?? DateTime.now()),
      selectedDate = dateOnly(today ?? DateTime.now());

  final DateTime today;
  School? school;
  int? grade;
  int? classNumber;
  DateTime selectedDate;

  bool get hasClass => school != null && grade != null && classNumber != null;

  String get schoolButtonLabel => school?.name ?? '학교명';

  String get classButtonLabel {
    if (grade == null || classNumber == null) return '학년 반 선택';
    return '$grade학년 $classNumber반';
  }

  void selectSchool(School value) {
    final changed = school?.id != value.id;
    school = value;
    if (changed) {
      grade = null;
      classNumber = null;
    }
    notifyListeners();
  }

  void selectDate(DateTime value) {
    final next = dateOnly(value);
    if (next == selectedDate) return;
    selectedDate = next;
    notifyListeners();
  }

  void selectClass(int nextGrade, int nextClass) {
    grade = nextGrade;
    classNumber = nextClass;
    notifyListeners();
  }
}

class SelectionScope extends InheritedNotifier<SelectionController> {
  const SelectionScope({
    super.key,
    required SelectionController controller,
    required super.child,
  }) : super(notifier: controller);

  static SelectionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SelectionScope>();
    assert(scope != null, 'SelectionScope가 상위 트리에 없습니다.');
    return scope!.notifier!;
  }
}
