import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/duration_breakdown.dart';
import 'unit_breakdown_row.dart';

/// A horizontally swipeable card showing the time breakdown as two pages —
/// remaining ("ՄՆԱՑ") and elapsed ("ԱՆՑԱՎ") — with a page indicator.
///
/// Tapping a page cycles it through its alternative views (hierarchical →
/// total days → total months → back), independently per page. When
/// [autoScroll] is enabled it advances to the next page every 10 seconds; the
/// timer resets on manual swipe or tap.
class BreakdownCarousel extends StatefulWidget {
  const BreakdownCarousel({
    super.key,
    required this.pages,
    this.animateCounters = true,
    this.autoScroll = true,
  });

  /// The pages to show, in order. Each page holds one or more tappable views.
  final List<BreakdownPage> pages;
  final bool animateCounters;
  final bool autoScroll;

  @override
  State<BreakdownCarousel> createState() => _BreakdownCarouselState();
}

/// One representation of a page's time span (a title plus unit rows).
class BreakdownView {
  const BreakdownView({required this.title, required this.rows});

  /// The classic hierarchical view: Y / M / W / D over H / Min / Sec.
  BreakdownView.hierarchical({
    required this.title,
    required DurationBreakdown breakdown,
  }) : rows = UnitBreakdownRow.hierarchicalRows(breakdown);

  final String title;
  final List<List<UnitValue>> rows;
}

/// A swipeable page: a cycle of views the user steps through by tapping.
class BreakdownPage {
  const BreakdownPage({required this.views}) : assert(views.length > 0);
  final List<BreakdownView> views;
}

class _BreakdownCarouselState extends State<BreakdownCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  /// Per-page index of the currently shown view (persists across the
  /// per-second data rebuilds because only the widget is replaced, not state).
  late List<int> _viewIndex =
      List.filled(widget.pages.length, 0, growable: false);

  static const Duration _interval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _scheduleAuto();
  }

  @override
  void didUpdateWidget(BreakdownCarousel old) {
    super.didUpdateWidget(old);
    if (widget.pages.length != old.pages.length) {
      _viewIndex = List.filled(widget.pages.length, 0, growable: false);
    }
    // Only react to the auto-scroll setting changing — not to the per-second
    // breakdown updates, which would otherwise keep resetting the timer.
    if (widget.autoScroll != old.autoScroll) _scheduleAuto();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAuto() {
    _timer?.cancel();
    if (!widget.autoScroll || widget.pages.length < 2) return;
    _timer = Timer(_interval, () {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.pages.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    _scheduleAuto(); // restart the countdown from the new page
  }

  void _cycleView(int page) {
    final count = widget.pages[page].views.length;
    if (count < 2) return;
    setState(() => _viewIndex[page] = (_viewIndex[page] + 1) % count);
    _scheduleAuto(); // the user is interacting — hold the page a while longer
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: _onPageChanged,
            itemCount: widget.pages.length,
            itemBuilder: (context, index) {
              final views = widget.pages[index].views;
              final view = views[_viewIndex[index] % views.length];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _cycleView(index),
                child: _Page(
                  title: view.title,
                  rows: view.rows,
                  animate: widget.animateCounters,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSizes.md),
        _Dots(count: widget.pages.length, index: _page),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.rows,
    required this.animate,
  });

  final String title;
  final List<List<UnitValue>> rows;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        UnitBreakdownRow(rows: rows, animate: animate),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
          ),
      ],
    );
  }
}
