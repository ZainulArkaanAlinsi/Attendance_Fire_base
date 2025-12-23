import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final Timestamp createdAt;
  final List<dynamic>? faceEmbedding;
  final String? faceImageUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = 'user',
    required this.createdAt,
    this.faceEmbedding,
    this.faceImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': createdAt,
      'faceEmbedding': faceEmbedding,
      'faceImageUrl': faceImageUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      faceEmbedding: map['faceEmbedding'],
      faceImageUrl: map['faceImageUrl'],
    );
  }
}
