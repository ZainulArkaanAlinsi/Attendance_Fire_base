import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import '../models/user_model.dart';
import '../utils/app_constants.dart';
import '../routes/app_router.dart';
import '../utils/app_utils.dart';
import '../services/permission_service.dart';

class UserService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Rxn<User> firebaseUser = Rxn<User>();
  final Rxn<UserModel> firestoreUser = Rxn<UserModel>();
  final RxList<Map<String, dynamic>> attendanceHistory =
      <Map<String, dynamic>>[].obs;

  List<double>? get faceEmbedding {
    final embedding = firestoreUser.value?.faceEmbedding;
    if (embedding == null) return null;
    return List<double>.from(embedding.map((e) => (e as num).toDouble()));
  }

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _handleAuthChange);
  }

  Future<void> _handleAuthChange(User? user) async {
    if (user == null) {
      firestoreUser.value = null;
      Get.offAllNamed(AppRouter.login);
    } else {
      await loadUserDoc(user.uid);

      if (firestoreUser.value != null) {
        if (firestoreUser.value!.faceEmbedding == null) {
          // Check for camera permission before choosing route
          final PermissionService permissionService =
              Get.find<PermissionService>();
          final cameraStatus = await permissionService
              .getCameraPermissionStatus();
          if (cameraStatus == PermissionState.granted) {
            Get.offAllNamed(AppRouter.enrollFace);
          } else {
            Get.offAllNamed(
              AppRouter.requestCamera,
              arguments: AppRouter.enrollFace,
            );
          }
        } else {
          Get.offAllNamed(AppRouter.home);
        }
      } else {
        // Doc might not exist yet during registration, handled in AuthController
        // but if we're just logging in and doc is missing:
        Get.offAllNamed(AppRouter.login);
      }
    }
    FlutterNativeSplash.remove();
  }

  Future<void> createUserDoc(User user, String displayName) async {
    try {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName,
        createdAt: Timestamp.now(),
      );

      await _db
          .collection(Constant.usersCollection)
          .doc(user.uid)
          .set(newUser.toMap());

      firestoreUser.value = newUser;

      // Explicitly trigger navigation check after doc creation
      _handleAuthChange(user);
    } catch (e) {
      AppUtils.showError('Error', 'Failed to create user profile');
    }
  }

  Future<void> loadUserDoc(String uid) async {
    try {
      final doc = await _db.collection(Constant.usersCollection).doc(uid).get();
      if (doc.exists) {
        firestoreUser.value = UserModel.fromMap(doc.data()!);
      } else {
        firestoreUser.value = null;
      }
    } catch (e) {
      dev.log('Failed to load user document: $e');
      firestoreUser.value = null;
    }
  }

  Future<void> saveEmbedding(List<double> embedding, String imageUrl) async {
    try {
      final uid = firebaseUser.value?.uid;
      if (uid == null) {
        AppUtils.showError('Not Login', 'User session expired.');
        return;
      }

      await _db.collection(Constant.usersCollection).doc(uid).update({
        'faceEmbedding': embedding,
        'faceImageUrl': imageUrl,
      });

      // Reload state
      await loadUserDoc(uid);

      AppUtils.showSuccess(
        'Enrollment Success',
        'Face enrollment complete. Welcome!',
      );
      Get.offAllNamed(AppRouter.home);
    } catch (e) {
      dev.log('Error saving face data: $e');
      throw Exception('Failed to save face data to Firestore.');
    }
  }

  Future<void> updateFaceData(List<double> embedding, String imageUrl) async {
    // Keeping this for backward compatibility if any, but routing to saveEmbedding
    await saveEmbedding(embedding, imageUrl);
  }

  Future<void> recordAttendance(GeoPoint location, double distance) async {
    try {
      final uid = firebaseUser.value?.uid;
      final displayName = firestoreUser.value?.displayName ?? 'User';
      if (uid == null) throw 'User session expired';

      final docRef = _db.collection(Constant.attendancesCollection).doc();
      final data = {
        'uid': uid,
        'displayName': displayName,
        'location': location,
        'distance': distance,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);
      AppUtils.showSuccess(
        'Attendance Recorded',
        'Your attendance has been successfully recorded.',
      );
    } catch (e) {
      dev.log('Error recording attendance: $e');
      throw e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
