import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depitun/core/l10n/app_language.dart';
import 'package:depitun/data/models/announcement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnnouncementModel.fromDoc', () {
    test('reads the plain title and body as Armenian', () {
      final at = DateTime.utc(2026, 10, 8, 10);
      final a = AnnouncementModel.fromDoc('x', {
        'title': 'Բարև',
        'body': 'Տեքստ',
        'sendAt': Timestamp.fromDate(at),
        'status': 'sent',
      })!;
      expect(a.id, 'x');
      expect(a.textIn(AppLanguage.hy)?.title, 'Բարև');
      expect(a.textIn(AppLanguage.hy)?.body, 'Տեքստ');
      expect(a.sentAt.toUtc(), at);
    });

    test('skips a document without a sendAt timestamp', () {
      expect(AnnouncementModel.fromDoc('x', {'title': 't'}), isNull);
      expect(
        AnnouncementModel.fromDoc('x', {'title': 't', 'sendAt': '2026-10-08'}),
        isNull,
      );
    });

    test('tolerates a missing title or body', () {
      final a = AnnouncementModel.fromDoc('x', {
        'body': 'only body',
        'sendAt': Timestamp.now(),
      })!;
      expect(a.textIn(AppLanguage.hy)?.title, '');
      expect(a.textIn(AppLanguage.hy)?.body, 'only body');
    });

    test('reads each language from its own fields', () {
      final a = AnnouncementModel.fromDoc('x', {
        'title_hy': 'Բարև',
        'title_ru': 'Привет',
        'body_ru': 'Текст',
        'title_en': 'Hello',
        'sendAt': Timestamp.now(),
      })!;
      expect(a.textIn(AppLanguage.hy)?.title, 'Բարև');
      expect(a.textIn(AppLanguage.ru)?.title, 'Привет');
      expect(a.textIn(AppLanguage.ru)?.body, 'Текст');
      expect(a.textIn(AppLanguage.en)?.title, 'Hello');
    });

    test('Russian and English fall back to each other, never to Armenian', () {
      final onlyRu = AnnouncementModel.fromDoc('x', {
        'title_ru': 'Привет',
        'sendAt': Timestamp.now(),
      })!;
      expect(onlyRu.textIn(AppLanguage.en)?.title, 'Привет');
      expect(onlyRu.textIn(AppLanguage.hy)?.title, 'Привет');

      final onlyHy = AnnouncementModel.fromDoc('x', {
        'title': 'Բարև',
        'sendAt': Timestamp.now(),
      })!;
      expect(onlyHy.textIn(AppLanguage.ru), isNull);
      expect(onlyHy.textIn(AppLanguage.en), isNull);
    });
  });
}
