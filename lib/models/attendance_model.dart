import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String? id;
  final String uid;
  final String displayName;
  final GeoPoint location;
  final double distance;
  final Timestamp timestamp;

  AttendanceModel({
    this.id,
    required this.uid,
    required this.displayName,
    required this.location,
    required this.distance,
    required this.timestamp,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AttendanceModel(
      id: docId,
      uid: map['uid'] as String,
      displayName: map['displayName'] as String,
      location: map['location'] as GeoPoint,
      distance: (map['distance'] as num).toDouble(),
      timestamp: map['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'location': location,
      'distance': distance,
      'timestamp': timestamp,
    };
  }
}
