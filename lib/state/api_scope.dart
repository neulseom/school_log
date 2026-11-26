import 'package:flutter/widgets.dart';
import 'package:school_log/data/school_log_api.dart';

class LogApiScope extends InheritedWidget {
  const LogApiScope({super.key, required this.api, required super.child});

  final SchoolLogApi api;

  static SchoolLogApi of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LogApiScope>();
    assert(scope != null, 'LogApiScope가 상위 트리에 없습니다.');
    return scope!.api;
  }

  @override
  bool updateShouldNotify(LogApiScope oldWidget) => oldWidget.api != api;
}
