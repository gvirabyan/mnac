import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depitun/core/l10n/app_language.dart';
import 'package:depitun/data/datasources/local_prefs_data_source.dart';
import 'package:depitun/data/repositories/announcements_repository_impl.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore db;
  late LocalPrefsDataSource local;

  Future<void> add(String id, String status, int day, {String? ru}) =>
      db.collection('announcements').doc(id).set({
        'status': status,
        'sendAt': Timestamp.fromDate(DateTime.utc(2026, 10, day, 18)),
        'title_hy': 'hy $id',
        'title_ru': ?ru,
      });

  /// Ids per emission of one open of the history screen.
  Future<List<List<String>>> open(AppLanguage language) async => [
    await for (final list in AnnouncementsRepositoryImpl(
      local,
      db,
    ).watchRecent(language))
      [for (final a in list) a.id],
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = LocalPrefsDataSource(await SharedPreferences.getInstance());
    db = FakeFirebaseFirestore();
    await add('a', 'sent', 1);
    await add('b', 'sent', 2);
    await add('draft', 'scheduled', 3);
  });

  test('first open loads from the server and saves it', () async {
    expect(await open(AppLanguage.hy), [
      ['b', 'a'],
    ]);
    expect(local.readAnnouncementsJson(), contains('"b"'));
  });

  test('next open shows the saved copy, then adds only what is new', () async {
    await open(AppLanguage.hy);
    await add('c', 'sent', 3);

    // Deleted on the server, yet still shown: proof it was not re-read.
    await db.collection('announcements').doc('a').delete();

    expect(await open(AppLanguage.hy), [
      ['b', 'a'],
      ['c', 'b', 'a'],
    ]);
  });

  test('the next fetch starts at the newest saved send time', () async {
    await open(AppLanguage.hy);
    await add('c', 'sent', 3);
    await add('old', 'sent', 1); // older than what is saved: not fetched

    expect((await open(AppLanguage.hy)).last, ['c', 'b', 'a']);
  });

  test('a push sharing the newest send time is not missed', () async {
    await open(AppLanguage.hy);
    await add('b2', 'sent', 2);

    expect((await open(AppLanguage.hy)).last.toSet(), {'b', 'b2', 'a'});
  });

  test('one-language pushes reach only that language', () async {
    await add('ru', 'sent_ru', 3, ru: 'Привет');

    expect((await open(AppLanguage.hy)).last, ['b', 'a']);
    expect((await open(AppLanguage.ru)).last, ['ru', 'b', 'a']);
    // Switching back serves Armenian from its own saved state.
    expect((await open(AppLanguage.hy)).first, ['b', 'a']);
  });

  test('offline with a saved copy shows it; without one fails', () async {
    await open(AppLanguage.hy);
    db = _OfflineFirestore();
    expect(await open(AppLanguage.hy), [
      ['b', 'a'],
    ]);

    SharedPreferences.setMockInitialValues({});
    local = LocalPrefsDataSource(await SharedPreferences.getInstance());
    expect(open(AppLanguage.hy), throwsA(isA<FirebaseException>()));
  });
}

/// Every query fails, as it does without a connection.
class _OfflineFirestore extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
}
