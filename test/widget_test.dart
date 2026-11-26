import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_log/main.dart';

import 'fake_school_log_api.dart';

void main() {
  testWidgets('school, class, and date drive the swiped pages', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateTime(2026, 11, 3);
    await tester.pumpWidget(
      SchoolLogApp(today: today, api: FakeSchoolLogApi()),
    );
    await tester.pumpAndSettle();

    expect(find.text('스쿨로그'), findsOneWidget);
    expect(find.text('학교 선택창'), findsOneWidget);
    expect(find.text('학년 반 선택창'), findsOneWidget);

    await tester.tap(find.text('학년 반 선택'));
    await tester.pumpAndSettle();
    expect(find.text('학교 먼저 선택'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('학교명'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('school-search')), '한빛');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한빛고등학교'));
    await tester.pumpAndSettle();
    expect(find.text('한빛고등학교'), findsOneWidget);

    await tester.tap(find.text('학년 반 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2학년'));
    await tester.pump();
    await tester.tap(find.text('3반'));
    await tester.pumpAndSettle();
    expect(find.text('2학년 3반'), findsOneWidget);

    await tester.drag(find.byKey(const Key('pager')), const Offset(480, 0));
    await tester.pumpAndSettle();

    expect(find.text('한빛고등학교 시간표'), findsOneWidget);
    expect(find.text('1교시'), findsOneWidget);
    expect(find.text('배추김치'), findsOneWidget);

    await tester.drag(find.byKey(const Key('pager')), const Offset(-480, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('pager')), const Offset(-480, 0));
    await tester.pumpAndSettle();

    expect(find.text('한빛고등학교 날씨'), findsOneWidget);
    expect(find.text('맑음'), findsOneWidget);
    expect(find.textContaining('강수확률'), findsWidgets);
    expect(find.text('기온'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dot-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('day-2026-11-10')));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('pager')), const Offset(480, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('11월 10일'), findsWidgets);
  });
}
