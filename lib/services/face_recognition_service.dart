import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:developer' as dev;
import '../utils/app_constants.dart';
import '../utils/app_utils.dart';

class FaceRecognitionService extends GetxService {
  late FaceDetector _faceDetector;
  Interpreter? _interpreter;
  static const int inputSize = 112;

  final RxBool isModelLoaded = false.obs;
  final RxString modelStatus = 'Initializing...'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeFaceDetector();
    _loadModel();
  }

  void _initializeFaceDetector() {
    try {
      final options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableContours: false,
        enableClassification: false,
        enableTracking: false,
        enableLandmarks: false,
        minFaceSize: 0.15,
      );
      _faceDetector = FaceDetector(options: options);
    } catch (e) {
      dev.log('Error initializing face detector: $e');
    }
  }

  Future<void> _loadModel() async {
    try {
      modelStatus.value = 'Downloading model...';

      // Coba download dari Firebase ML
      final modelFile = await _downloadFirebaseModel();

      if (modelFile != null && await modelFile.exists()) {
        _interpreter = Interpreter.fromFile(modelFile);
        isModelLoaded.value = true;
        modelStatus.value = 'Model loaded successfully';
        dev.log('TFLite model successfully loaded from Firebase ML');
      } else {
        // Fallback ke model lokal di assets
        await _loadLocalModel();
      }
    } catch (e) {
      dev.log('Failed to load TFLite model: $e');
      modelStatus.value = 'Model load failed: $e';
      await _loadLocalModel();
    }
  }

  Future<File?> _downloadFirebaseModel() async {
    try {
      dev.log('Starting Firebase ML model download...');

      final model = await FirebaseModelDownloader.instance.getModel(
        Constant.modelName,
        FirebaseModelDownloadType.localModel,
        FirebaseModelDownloadConditions(
          androidChargingRequired: false,
          androidWifiRequired: false,
          androidDeviceIdleRequired: false,
          iosAllowsCellularAccess: true,
          iosAllowsBackgroundDownloading: false,
        ),
      );

      dev.log('Model downloaded successfully: ${model.file.path}');
      return model.file;
    } catch (e) {
      dev.log('Firebase ML download failed: $e');

      // Jika error karena API tidak diaktifkan, beri instruksi
      if (e.toString().contains('API has not been used')) {
        modelStatus.value = 'Please enable Firebase ML API in console';
        AppUtils.showError(
          'Model Download Error',
          'Please enable Firebase ML API in Firebase Console:\n'
              '1. Go to Firebase Console\n'
              '2. Select your project\n'
              '3. Go to Build > ML Kit\n'
              '4. Enable ML API',
        );
      }
      return null;
    }
  }

  Future<void> _loadLocalModel() async {
    try {
      modelStatus.value = 'Loading local model...';

      // Cek apakah model sudah ada di local storage
      final localPath = await _getLocalModelPath();
      if (await localPath.exists()) {
        _interpreter = Interpreter.fromFile(File(localPath.path));
        isModelLoaded.value = true;
        modelStatus.value = 'Local model loaded';
        dev.log('Local model loaded successfully');
        return;
      }

      // Jika tidak ada, copy dari assets
      await _copyModelFromAssets();
    } catch (e) {
      dev.log('Failed to load local model: $e');
      modelStatus.value = 'No model available';
      AppUtils.showError(
        'Model Error',
        'Face recognition model is not available. Please check your internet connection.',
      );
    }
  }

  Future<Directory> _getLocalModelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return Directory('${directory.path}/models');
  }

  Future<void> _copyModelFromAssets() async {
    // Implementasi copy model dari assets ke local storage
    // Anda perlu menyimpan model .tflite di folder assets
    modelStatus.value = 'Model not found in assets';
  }

  Future<List<Face>> detectFaces(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw 'Image file does not exist';
      }

      final inputImage = InputImage.fromFile(imageFile);
      return await _faceDetector.processImage(inputImage);
    } catch (e) {
      dev.log('Error detecting faces: $e');
      return [];
    }
  }

  Future<Float32List> _preprocessImage(File imageFile, Face face) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) throw 'Failed to decode image';

      final rect = face.boundingBox;

      // Ensure crop coordinates are within image bounds
      final x = rect.left.clamp(0, originalImage.width - 1).toInt();
      final y = rect.top.clamp(0, originalImage.height - 1).toInt();
      final width = rect.width.clamp(1, originalImage.width - x).toInt();
      final height = rect.height.clamp(1, originalImage.height - y).toInt();

      img.Image croppedFace = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      img.Image resizedFace = img.copyResize(
        croppedFace,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.cubic,
      );

      // Convert to Float32List with normalization
      final imageAsList = Float32List(inputSize * inputSize * 3);
      int pixelIndex = 0;

      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resizedFace.getPixel(x, y);
          // Normalize to [-1, 1]
          imageAsList[pixelIndex++] = (pixel.r - 127.5) / 127.5;
          imageAsList[pixelIndex++] = (pixel.g - 127.5) / 127.5;
          imageAsList[pixelIndex++] = (pixel.b - 127.5) / 127.5;
        }
      }

      return imageAsList;
    } catch (e) {
      dev.log('Error preprocessing image: $e');
      rethrow;
    }
  }

  Future<List<double>?> getEmbedding(File imageFile, Face face) async {
    if (!isModelLoaded.value || _interpreter == null) {
      dev.log('Model is not loaded');
      return null;
    }

    try {
      final inputList = await _preprocessImage(imageFile, face);

      // Reshape input for model [1, 112, 112, 3]
      final input = inputList.reshape([1, inputSize, inputSize, 3]);

      // Prepare output tensor
      final output = List.filled(1 * 192, 0.0).reshape([1, 192]);

      // Run inference
      _interpreter!.run(input, output);

      // Convert to List<double>
      final outputList = output[0] as List<dynamic>;
      final embedding = outputList.map((e) => e as double).toList();

      // Normalize embedding
      return _normalizeEmbedding(embedding);
    } catch (e) {
      dev.log('Error getting embedding: $e');
      return null;
    }
  }

  List<double> _normalizeEmbedding(List<double> embedding) {
    // Calculate L2 norm
    double sum = 0.0;
    for (final value in embedding) {
      sum += value * value;
    }
    final norm = math.sqrt(sum);

    // Normalize if norm is not zero
    if (norm > 0) {
      return embedding.map((value) => value / norm).toList();
    }

    return embedding;
  }

  double calculateDistance(List<double> emb1, List<double> emb2) {
    if (emb1.length != emb2.length) {
      return double.infinity;
    }

    double distance = 0.0;
    for (int i = 0; i < emb1.length; i++) {
      final diff = emb1[i] - emb2[i];
      distance += diff * diff;
    }

    return math.sqrt(distance);
  }

  bool compareFace(
    List<double> emb1,
    List<double> emb2, {
    double threshold = 0.8,
  }) {
    final distance = calculateDistance(emb1, emb2);
    dev.log('Face distance: $distance, threshold: $threshold');
    return distance < threshold;
  }

  @override
  void onClose() {
    _faceDetector.close();
    _interpreter?.close();
    super.onClose();
  }
}
