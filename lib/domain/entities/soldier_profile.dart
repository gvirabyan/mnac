import 'milestone.dart';

/// A soldier's service record — the single profile the app is built around.
///
/// Pure domain entity: no Flutter, no storage concerns.
class SoldierProfile {
  const SoldierProfile({
    required this.id,
    required this.serviceStart,
    required this.serviceDurationDays,
    required this.createdAt,
    this.name,
    this.unit,
    this.photoPath,
    this.customMilestones = const [],
  });

  final String id;
  final String? name;
  final String? unit;
  final DateTime serviceStart;
  final int serviceDurationDays;

  /// Absolute path to a profile photo copied into app storage, if any.
  final String? photoPath;
  final DateTime createdAt;

  /// Achievements the user added for this soldier, in the order added.
  final List<CustomMilestone> customMilestones;

  /// The estimated discharge ("զորացրում") date.
  DateTime get dischargeDate =>
      serviceStart.add(Duration(days: serviceDurationDays));

  SoldierProfile copyWith({
    String? id,
    String? name,
    String? unit,
    DateTime? serviceStart,
    int? serviceDurationDays,
    String? photoPath,
    DateTime? createdAt,
    List<CustomMilestone>? customMilestones,
    bool clearName = false,
    bool clearUnit = false,
    bool clearPhoto = false,
  }) {
    return SoldierProfile(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      unit: clearUnit ? null : (unit ?? this.unit),
      serviceStart: serviceStart ?? this.serviceStart,
      serviceDurationDays: serviceDurationDays ?? this.serviceDurationDays,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      createdAt: createdAt ?? this.createdAt,
      customMilestones: customMilestones ?? this.customMilestones,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SoldierProfile &&
      other.id == id &&
      other.name == name &&
      other.unit == unit &&
      other.serviceStart == serviceStart &&
      other.serviceDurationDays == serviceDurationDays &&
      other.photoPath == photoPath &&
      other.createdAt == createdAt &&
      _sameList(other.customMilestones, customMilestones);

  static bool _sameList(List<CustomMilestone> a, List<CustomMilestone> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        unit,
        serviceStart,
        serviceDurationDays,
        photoPath,
        createdAt,
        Object.hashAll(customMilestones),
      );
}
