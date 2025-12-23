import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:developer' as dev;
import '../services/face_recognition_service.dart';
import '../services/cloudinary_service.dart';
import '../services/user_service.dart';
import '../utils/app_utils.dart';

class EnrollFaceController extends GetxController {
  CameraController? cameraController;
  List<CameraDescription> _cameras = [];
  CameraDescription? frontCamera;

  final FaceRecognitionService _faceService = Get.find<FaceRecognitionService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final UserService _userService = Get.find<UserService>();
  
  // Instance for face detection within the controller if needed or from service
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // Observables
  final RxBool isInitialized = false.obs;
  final RxBool isProcessing = false.obs;
  final RxString feedbackMessage = 'Place your face in the oval'.obs;

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
    // This is called captureAndEnrollFace in transcript, keeping it captureAndProcess to match existing UI calls
    if (isProcessing.value || !isInitialized.value) return;

    try {
      isProcessing.value = true;
      feedbackMessage.value = 'Processing...';
      
      // 1. Capture Image
      final XFile photo = await cameraController!.takePicture();
      final File imageFile = File(photo.path);
      
      // 2. Detect Faces
      feedbackMessage.value = 'Detecting face...';
      final List<Face> faces = await _faceDetector.processImage(InputImage.fromFile(imageFile));
      
      if (faces.isEmpty) {
        throw 'No face detected. Please try again.';
      }
      if (faces.length > 1) {
        throw 'Multiple faces detected. Please make sure only one person is in the frame.';
      }

      final face = faces.first;

      // 3. Get Face Embedding
      feedbackMessage.value = 'Getting embedding...';
      final List<double>? embedding = await _faceService.getEmbedding(imageFile, face);

      if (embedding == null || embedding.isEmpty) {
        throw 'Failed to extract face data.';
      }

      // 4. Upload to Cloudinary
      feedbackMessage.value = 'Uploading image...';
      final String? imageUrl = await _cloudinaryService.uploadImage(imageFile);
      
      if (imageUrl == null) {
        throw 'Failed to upload profile picture.';
      }

      // 5. Save Embedding to User Document
      feedbackMessage.value = 'Saving face data...';
      await _userService.saveEmbedding(embedding, imageUrl);
      
    } catch (e) {
      dev.log('Enrollment Process Error: $e');
      String errorMsg = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', '');
      AppUtils.showError('Enrollment Failed', errorMsg);
      feedbackMessage.value = 'Enrollment failed. Try again.';
    } finally {
      isProcessing.value = false;
      if (!feedbackMessage.value.contains('complete')) {
        feedbackMessage.value = 'Place your face in the oval';
      }
    }
  }
}
