import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
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

  @override
  void onInit() {
    super.onInit();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final modelFile = await _downloadModel(Constant.modelName);
      if (modelFile != null) {
        _interpreter = Interpreter.fromFile(modelFile);
        dev.log('TFLite model successfully loaded');
      }
    } catch (e) {
      dev.log('Fail to load TFLite model: $e');
      AppUtils.showError('Error', 'Fail to load model');
    }
  }

  Future<File?> _downloadModel(String name) async {
    try {
      final model = await FirebaseModelDownloader.instance.getModel(
        name,
        FirebaseModelDownloadType.localModelUpdateInBackground,
        FirebaseModelDownloadConditions(
          androidChargingRequired: false,
          androidWifiRequired: false,
          androidDeviceIdleRequired: false,
        ),
      );
      return model.file;
    } catch (e) {
      dev.log('Error downloading model: $e');
      return null;
    }
  }

  Future<List<Face>> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return await _faceDetector.processImage(inputImage);
  }

  Future<Float32List> _preprocessImage(File imageFile, Face face) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) throw 'Fail to decode image';

    final rect = face.boundingBox;
    img.Image croppedFace = img.copyCrop(
      originalImage,
      x: rect.left.toInt(),
      y: rect.top.toInt(),
      width: rect.width.toInt(),
      height: rect.height.toInt(),
    );

    img.Image resizedFace = img.copyResize(
      croppedFace,
      width: inputSize,
      height: inputSize,
    );

    var imageAsList = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (var pixel in resizedFace) {
      // Normalize to [-1, 1] using 127.5
      imageAsList[pixelIndex++] = (pixel.r - 127.5) / 127.5;
      imageAsList[pixelIndex++] = (pixel.g - 127.5) / 127.5;
      imageAsList[pixelIndex++] = (pixel.b - 127.5) / 127.5;
    }

    return imageAsList;
  }

  Future<List<double>?> getEmbedding(File imageFile, Face face) async {
    if (_interpreter == null) {
      dev.log('Interpreter is not loaded');
      return null;
    }

    try {
      final inputList = await _preprocessImage(imageFile, face);

      // Reshape input to 4D tensor [1, 112, 112, 3]
      final input = inputList.reshape([1, inputSize, inputSize, 3]);

      // Prepare output buffer [1, 192] with dummy values
      final outputBuffer = List.generate(1, (index) => List.filled(192, 0.0));

      _interpreter!.run(input, outputBuffer);

      // Type conversion from dynamic to double
      final outputList = outputBuffer[0];
      List<double> embeddingList = [];

      for (var i in outputList) {
        embeddingList.add((i as num).toDouble());
      }

      return embeddingList;
    } catch (e) {
      dev.log('Error running TFLite model: $e');
      AppUtils.showError('Error', 'Error running model');
      return [];
    }
  }

  bool compareFace(
    List<double> newEmbedding,
    List<double> existingEmbedding, {
    double threshold = 1.0,
  }) {
    double sumOfSquare = 0.0;
    for (int i = 0; i < newEmbedding.length; i++) {
      double diff = newEmbedding[i] - existingEmbedding[i];
      sumOfSquare += diff * diff;
    }
    double distance = math.sqrt(sumOfSquare);
    dev.log('Face Distance: $distance');
    return distance < threshold;
  }

  @override
  void onClose() {
    _faceDetector.close();
    _interpreter?.close();
    super.onClose();
  }
}
