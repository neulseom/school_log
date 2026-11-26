import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_log/data/school_log_api.dart';
import 'package:school_log/shell.dart';
import 'package:school_log/state/api_scope.dart';
import 'package:school_log/state/selection.dart';
import 'package:school_log/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SchoolLogApp());
}

class SchoolLogApp extends StatefulWidget {
  const SchoolLogApp({super.key, this.today, this.api});

  /// Fixed calendar day for tests. The running app uses the device date.
  final DateTime? today;
  final SchoolLogApi? api;

  @override
  State<SchoolLogApp> createState() => _SchoolLogAppState();
}

class _SchoolLogAppState extends State<SchoolLogApp> {
  late final SelectionController _selection = SelectionController(
    today: widget.today,
  );
  late final SchoolLogApi _api = widget.api ?? LiveSchoolLogApi();

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LogApiScope(
      api: _api,
      child: SelectionScope(
        controller: _selection,
        child: MaterialApp(
          title: '스쿨로그',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          scrollBehavior: const SchoolLogScrollBehavior(),
          home: const AppFrame(child: SchoolLogShell()),
        ),
      ),
    );
  }
}

class SchoolLogScrollBehavior extends MaterialScrollBehavior {
  const SchoolLogScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
