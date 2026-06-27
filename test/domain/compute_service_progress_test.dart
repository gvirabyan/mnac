import 'package:depitun/domain/entities/soldier_profile.dart';
import 'package:depitun/domain/usecases/compute_service_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeServiceProgress();

  SoldierProfile profile({required DateTime start, int durationDays = 730}) {
    return SoldierProfile(
      id: 'test',
      serviceStart: start,
      serviceDurationDays: durationDays,
      createdAt: start,
    );
  }

  test('halfway through service yields ~50% and balanced day counts', () {
    final now = DateTime(2026, 6, 27, 12);
    final start = now.subtract(const Duration(days: 365));
    final progress = compute(profile(start: start), now);

    expect(progress.percent, closeTo(0.5, 0.01));
    expect(progress.daysServed, 365);
    expect(progress.daysRemaining, 365);
    expect(progress.hasStarted, isTrue);
    expect(progress.isComplete, isFalse);
  });

  test('before start clamps to zero progress', () {
    final now = DateTime(2026, 1, 1);
    final start = now.add(const Duration(days: 10));
    final progress = compute(profile(start: start), now);

    expect(progress.percent, 0.0);
    expect(progress.daysServed, 0);
    expect(progress.daysRemaining, 730);
    expect(progress.hasStarted, isFalse);
  });

  test('after discharge clamps to full completion', () {
    final start = DateTime(2024, 1, 1);
    final now = DateTime(2026, 6, 27);
    final progress = compute(profile(start: start), now);

    expect(progress.percent, 1.0);
    expect(progress.daysRemaining, 0);
    expect(progress.isComplete, isTrue);
    expect(progress.percentInt, 100);
  });

  test('weeks and months served are derived correctly', () {
    final start = DateTime(2026, 1, 1);
    final now = DateTime(2026, 3, 1); // 2 months, 60 days
    final progress = compute(profile(start: start), now);

    expect(progress.monthsServed, 2);
    expect(progress.weeksServed, 60 ~/ 7);
  });
}
