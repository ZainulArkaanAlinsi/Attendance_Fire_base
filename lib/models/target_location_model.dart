import 'package:cloud_firestore/cloud_firestore.dart';

class TargetLocationModel {
  final GeoPoint coordinates;
  final double radius; // in meters

  TargetLocationModel({
    required this.coordinates,
    required this.radius,
  });

  factory TargetLocationModel.fromMap(Map<String, dynamic> map) {
    return TargetLocationModel(
      coordinates: map['coordinates'] as GeoPoint,
      radius: (map['radius'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coordinates': coordinates,
      'radius': radius,
    };
  }
}
