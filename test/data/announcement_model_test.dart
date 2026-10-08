import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:depitun/data/models/announcement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnnouncementModel.fromDoc', () {
    test('reads title, body and sendAt', () {
      final at = DateTime.utc(2026, 10, 8, 10);
      final a = AnnouncementModel.fromDoc('x', {
        'title': 'Բարև',
        'body': 'Տեքստ',
        'sendAt': Timestamp.fromDate(at),
        'status': 'sent',
      })!;
      expect(a.id, 'x');
      expect(a.title, 'Բարև');
      expect(a.body, 'Տեքստ');
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
      expect(a.title, '');
      expect(a.body, 'only body');
    });
  });
}
