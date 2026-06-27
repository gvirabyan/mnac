import '../../domain/entities/soldier_profile.dart';

/// Data-layer representation of [SoldierProfile] with JSON (de)serialization.
class SoldierProfileModel {
  const SoldierProfileModel({
    required this.id,
    required this.serviceStart,
    required this.serviceDurationDays,
    required this.createdAt,
    this.name,
    this.unit,
    this.photoPath,
  });

  final String id;
  final String? name;
  final String? unit;
  final DateTime serviceStart;
  final int serviceDurationDays;
  final String? photoPath;
  final DateTime createdAt;

  factory SoldierProfileModel.fromEntity(SoldierProfile e) =>
      SoldierProfileModel(
        id: e.id,
        name: e.name,
        unit: e.unit,
        serviceStart: e.serviceStart,
        serviceDurationDays: e.serviceDurationDays,
        photoPath: e.photoPath,
        createdAt: e.createdAt,
      );

  SoldierProfile toEntity() => SoldierProfile(
        id: id,
        name: name,
        unit: unit,
        serviceStart: serviceStart,
        serviceDurationDays: serviceDurationDays,
        photoPath: photoPath,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'serviceStart': serviceStart.toIso8601String(),
        'serviceDurationDays': serviceDurationDays,
        'photoPath': photoPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SoldierProfileModel.fromJson(Map<String, dynamic> json) =>
      SoldierProfileModel(
        id: json['id'] as String,
        name: json['name'] as String?,
        unit: json['unit'] as String?,
        serviceStart: DateTime.parse(json['serviceStart'] as String),
        serviceDurationDays: (json['serviceDurationDays'] as num).toInt(),
        photoPath: json['photoPath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
