import 'package:depitun/services/rate_app_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReview implements InAppReview {
  int opened = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => opened++;

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async =>
      opened++;
}

void main() {
  late RateAppService service;
  late _FakeReview review;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    review = _FakeReview();
    service = RateAppService(
      await SharedPreferences.getInstance(),
      review: review,
    );
  });

  Future<void> launches(int n) async {
    for (var i = 0; i < n; i++) {
      await service.recordLaunch();
    }
  }

  test('first asks on the fifth launch', () async {
    await launches(4);
    expect(service.shouldAsk, isFalse);
    await launches(1);
    expect(service.shouldAsk, isTrue);
  });

  test('"not now" waits ten more launches', () async {
    await launches(5);
    await service.markAsked();
    expect(service.shouldAsk, isFalse);
    await launches(9);
    expect(service.shouldAsk, isFalse);
    await launches(1);
    expect(service.shouldAsk, isTrue);
  });

  test('gives up after three asks', () async {
    await launches(5);
    for (var i = 0; i < 3; i++) {
      await service.markAsked();
      await launches(10);
    }
    expect(service.shouldAsk, isFalse);
  });

  test('the system sheet does not stop the next asks', () async {
    await launches(5);
    await service.markAsked();
    await service.requestSystemReview();
    expect(review.opened, 1);
    await launches(10);
    expect(service.shouldAsk, isTrue);
  });

  test('never asks again once the user went to rate', () async {
    await launches(5);
    await service.markAsked();
    await service.rate();
    expect(review.opened, 1);
    await launches(50);
    expect(service.shouldAsk, isFalse);
  });
}
