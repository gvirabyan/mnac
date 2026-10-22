import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/l10n/app_language.dart';
import '../../domain/entities/announcement.dart';

/// Firestore document <-> [Announcement].
///
/// Documents are written by hand in the console as well as by the Cloud
/// Function, so a malformed one is skipped ([fromDoc] returns null) rather
/// than allowed to break the whole list.
///
/// Each language has its own pair of fields, `title_<id>` / `body_<id>`
/// (`title_ru`, `body_en`, …). The plain `title` / `body` are what pushes
/// had before they were translated, and are read as Armenian.
///
/// A push sent to one language only has the status `sent_<id>` instead of
/// `sent`; that language is its [Announcement.audience].
abstract final class AnnouncementModel {
  AnnouncementModel._();

  static Announcement? fromDoc(String id, Map<String, dynamic> data) {
    final sendAt = data['sendAt'];
    if (sendAt is! Timestamp) return null;
    // Written by the Cloud Function at the moment of sending; absent on
    // pushes backfilled by hand, which fall back to the scheduled time.
    final sentAt = data['sentAt'];
    final status = data['status'];
    return Announcement(
      id: id,
      texts: {
        for (final language in AppLanguage.values)
          language: ?_textIn(data, language),
      },
      sentAt: (sentAt is Timestamp ? sentAt : sendAt).toDate(),
      audience: status is String && status.startsWith('sent_')
          ? AppLanguage.tryFromId(status.substring('sent_'.length))
          : null,
    );
  }

  /// [data] in the plain-JSON form the history is saved on the phone in:
  /// only the fields [fromDoc] reads, timestamps as epoch ms.
  static Map<String, dynamic> toSaved(String id, Map<String, dynamic> data) => {
    'id': id,
    for (final MapEntry(:key, :value) in data.entries)
      if (key == 'status' ||
          key.startsWith('title') ||
          key.startsWith('body'))
        key: value
      else if ((key == 'sendAt' || key == 'sentAt') && value is Timestamp)
        key: value.millisecondsSinceEpoch,
  };

  /// Reads back what [toSaved] wrote; null for an entry it cannot use.
  static Announcement? fromSaved(Map<String, dynamic> saved) {
    final id = saved['id'];
    if (id is! String) return null;
    return fromDoc(id, {
      for (final MapEntry(:key, :value) in saved.entries)
        key: (key == 'sendAt' || key == 'sentAt') && value is int
            ? Timestamp.fromMillisecondsSinceEpoch(value)
            : value,
    });
  }

  static AnnouncementText? _textIn(
    Map<String, dynamic> data,
    AppLanguage language,
  ) {
    String field(String name) {
      final own = data['${name}_${language.id}'];
      if (own is String && own.isNotEmpty) return own;
      final legacy = data[name];
      return language == AppLanguage.hy && legacy is String ? legacy : '';
    }

    final text = AnnouncementText(title: field('title'), body: field('body'));
    return text.isEmpty ? null : text;
  }
}
