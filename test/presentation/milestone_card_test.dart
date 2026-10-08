import 'package:depitun/core/utils/date_utils.dart';
import 'package:depitun/domain/entities/milestone.dart';
import 'package:depitun/presentation/milestones/widgets/milestone_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpCard(WidgetTester tester, Milestone m) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MilestoneCard(milestone: m))),
      );

  Milestone milestone({required bool unlocked, required DateTime date}) =>
      Milestone(
        id: 'day100',
        kind: MilestoneKind.daysServed,
        value: 100,
        unlocked: unlocked,
        estimatedDate: date,
        justUnlocked: false,
      );

  testWidgets('locked: the day it opens and how far off', (tester) async {
    final date = AppDateUtils.dateOnly(DateTime.now())
        .add(const Duration(days: 35));
    await pumpCard(tester, milestone(unlocked: false, date: date));
    expect(
      find.text('Կբացվի՝ ${AppDateUtils.formatLong(date)} · 35 օր հետո'),
      findsOneWidget,
    );
  });

  testWidgets('locked, due tomorrow', (tester) async {
    final date = AppDateUtils.dateOnly(DateTime.now())
        .add(const Duration(days: 1));
    await pumpCard(tester, milestone(unlocked: false, date: date));
    expect(find.textContaining('· վաղը'), findsOneWidget);
  });

  testWidgets('unlocked: the day it opened', (tester) async {
    final date = DateTime(2026, 3, 5);
    await pumpCard(tester, milestone(unlocked: true, date: date));
    expect(
      find.text('Բացվել է՝ ${AppDateUtils.formatLong(date)}'),
      findsOneWidget,
    );
  });
}
