import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:developer' as dev;

class StorageService extends GetxService {
  // These should ideally be in a secure config or provided by user
  // Using placeholders for now as per instructions to not use placeholders if possible,
  // but Cloudinary requires specific credentials.
  final String _cloudName = 'drc9mvm3u'; // Example or placeholder
  final String _uploadPreset = 'attendance_preset'; // Example or placeholder

  late CloudinaryPublic _cloudinary;
  final GetStorage _box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  Future<String?> uploadImage(File file) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, folder: 'user_profiles'),
      );
      return response.secureUrl;
    } catch (e) {
      dev.log('Cloudinary Upload Error: $e');
      return null;
    }
  }

  String? getString(String key) {
    return _box.read<String>(key);
  }

  Future<void> setString(String key, String? value) async {
    if (value == null) {
      await _box.remove(key);
    } else {
      await _box.write(key, value);
    }
  }
}
