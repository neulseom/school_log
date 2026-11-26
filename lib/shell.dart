import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_log/pages/home_page.dart';
import 'package:school_log/pages/schedule_page.dart';
import 'package:school_log/pages/weather_page.dart';
import 'package:school_log/theme/app_theme.dart';

class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        if (!wide) return ColoredBox(color: Colors.white, child: child);

        final available = constraints.maxHeight - 40;
        final height = available < 520
            ? constraints.maxHeight
            : math.min(844.0, available);
        return ColoredBox(
          color: AppColors.canvas,
          child: Center(
            child: SizedBox(
              width: 400,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SchoolLogShell extends StatefulWidget {
  const SchoolLogShell({super.key});

  @override
  State<SchoolLogShell> createState() => _SchoolLogShellState();
}

class _SchoolLogShellState extends State<SchoolLogShell> {
  late final PageController _controller = PageController(initialPage: 1);
  final _pageSnap = _PageSnap(1);
  int _index = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) {
    if (page < 0 || page > 2) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                _go(_index - 1),
            const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                _go(_index + 1),
          },
          child: Focus(
            autofocus: true,
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    key: const Key('pager'),
                    controller: _controller,
                    physics: _SoftPageScrollPhysics(
                      parent: const BouncingScrollPhysics(),
                      snap: _pageSnap,
                    ),
                    onPageChanged: (index) {
                      _pageSnap.settled = index.toDouble();
                      setState(() => _index = index);
                    },
                    children: [
                      SchedulePage(onGoHome: () => _go(1)),
                      const HomePage(),
                      WeatherPage(onGoHome: () => _go(1)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  switch (_index) {
                    0 => '시간표 · 급식',
                    1 => '좌우로 밀어 시간표와 날씨를 보세요',
                    _ => '날씨',
                  },
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    color: AppColors.hint,
                  ),
                ),
                const SizedBox(height: 8),
                _PageDots(index: _index, onSelect: _go),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Remembers the page a drag started from so a short slide still changes pages.
class _PageSnap {
  _PageSnap(this.settled);

  double settled;
}

class _SoftPageScrollPhysics extends PageScrollPhysics {
  const _SoftPageScrollPhysics({super.parent, required this.snap});

  final _PageSnap snap;

  @override
  _SoftPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SoftPageScrollPhysics(parent: buildParent(ancestor), snap: snap);
  }

  @override
  double get minFlingVelocity => 12;

  @override
  double get minFlingDistance => 4;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.viewportDimension <= 0) {
      return super.createBallisticSimulation(position, velocity);
    }
    final atStart =
        velocity <= 0 && position.pixels <= position.minScrollExtent;
    final atEnd = velocity >= 0 && position.pixels >= position.maxScrollExtent;
    if (atStart || atEnd) {
      return super.createBallisticSimulation(position, velocity);
    }

    final page = position.pixels / position.viewportDimension;
    final delta = page - snap.settled;
    final flung = velocity.abs() > 80;
    var target = snap.settled;
    if (delta > 0.18 || (flung && velocity > 0 && delta >= 0)) {
      target = snap.settled + 1;
    } else if (delta < -0.18 || (flung && velocity < 0 && delta <= 0)) {
      target = snap.settled - 1;
    }

    final maxPage = position.maxScrollExtent / position.viewportDimension;
    final clamped = target.clamp(0.0, maxPage);
    final tolerance = toleranceFor(position);
    final targetPixels = clamped * position.viewportDimension;
    if ((targetPixels - position.pixels).abs() < tolerance.distance) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: tolerance,
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          GestureDetector(
            key: ValueKey('dot-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: i == index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == index ? AppColors.ink : const Color(0xFFD4D4D4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
