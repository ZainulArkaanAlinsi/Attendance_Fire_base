import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:developer' as dev;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/face_recognition_service.dart';
import '../services/user_service.dart';
import '../services/target_location_service.dart';
import '../utils/app_utils.dart';
import '../routes/app_router.dart';

class AttendanceController extends GetxController {
  CameraController? cameraController;
  List<CameraDescription> _cameras = [];
  CameraDescription? frontCamera;

  final FaceRecognitionService _faceService = Get.find<FaceRecognitionService>();
  final UserService _userService = Get.find<UserService>();
  final TargetLocationService _targetLocationService = Get.find<TargetLocationService>();
  
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  final RxBool isInitialized = false.obs;
  final RxBool isProcessing = false.obs;
  final RxString feedbackMessage = 'Place your face in the frame'.obs;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    _faceDetector.close();
    super.onClose();
  }

  Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      frontCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      if (frontCamera != null) {
        cameraController = CameraController(
          frontCamera!,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await cameraController!.initialize();
        isInitialized.value = true;
      } else {
        feedbackMessage.value = 'No camera found';
      }
    } catch (e) {
      dev.log('Error initializing camera: $e');
      feedbackMessage.value = 'Error initializing camera';
    }
  }

  Future<void> captureAndProcess() async {
    if (isProcessing.value || !isInitialized.value) return;

    try {
      isProcessing.value = true;
      
      // 1. Get Location
      feedbackMessage.value = 'Verifying location...';
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final targetLoc = _targetLocationService.targetLocation.value;
      if (targetLoc == null) {
        throw 'Target location configuration not found.';
      }

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLoc.coordinates.latitude,
        targetLoc.coordinates.longitude,
      );

      if (distanceInMeters > targetLoc.radius) {
        int kmSuffix = (distanceInMeters / 1000).floor();
        double mRemainder = distanceInMeters % 1000;
        String distStr = kmSuffix > 0 ? '$kmSuffix km ${mRemainder.toInt()}m' : '${distanceInMeters.toInt()}m';
        throw 'You are $distStr away from the target location.';
      }

      feedbackMessage.value = 'Location verified! Capturing...';

      // 2. Capture Image
      final XFile photo = await cameraController!.takePicture();
      final File imageFile = File(photo.path);
      
      // 3. Detect Face
      feedbackMessage.value = 'Detecting face...';
      final List<Face> faces = await _faceDetector.processImage(InputImage.fromFile(imageFile));
      
      if (faces.isEmpty) throw 'No face detected.';
      if (faces.length > 1) throw 'Multiple faces detected.';

      final face = faces.first;

      // 4. Get Embedding
      feedbackMessage.value = 'Comparing identity...';
      final List<double>? newEmbedding = await _faceService.getEmbedding(imageFile, face);
      
      if (newEmbedding == null || newEmbedding.isEmpty) {
        throw 'Failed to extract face data.';
      }

      final existingEmbedding = _userService.faceEmbedding;
      if (existingEmbedding == null) {
        throw 'No face enrolled. Please enroll first.';
      }

      // 5. Compare Embeddings
      bool isMatch = _faceService.compareFace(newEmbedding, existingEmbedding, threshold: 1.0);
      
      if (!isMatch) {
        throw 'Identity not verified. Please try again.';
      }

      // 6. Record Attendance
      feedbackMessage.value = 'Identity verified! Recording...';
      await _userService.recordAttendance(
        GeoPoint(position.latitude, position.longitude),
        distanceInMeters,
      );

      Get.offAllNamed(AppRouter.home);
      
    } catch (e) {
      dev.log('Attendance Process Error: $e');
      String errorMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', '');
      AppUtils.showError('Verification Failed', errorMsg);
      feedbackMessage.value = 'Verification failed. Try again.';
    } finally {
      isProcessing.value = false;
      if (!feedbackMessage.value.contains('Verified')) {
         feedbackMessage.value = 'Place your face in the frame';
      }
    }
  }
}
