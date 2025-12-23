import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import '../env/env.dart';
import '../utils/app_utils.dart';

class CloudinaryService extends GetxService {
  late CloudinaryPublic _cloudinary;

  @override
  void onInit() {
    super.onInit();
    _initializeCloudinary();
  }

  void _initializeCloudinary() {
    try {
      _cloudinary = CloudinaryPublic(
        Env.cloudinaryCloudName,
        Env.cloudinaryUploadPreset,
        cache: false,
      );
    } catch (e) {
      dev.log('Error initializing Cloudinary: $e');
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'attendance/faces',
          resourceType: CloudinaryResourceType.Image,
          context: {
            'alt': 'selfie',
            'caption': 'Face enrollment ${DateTime.now()}',
          },
        ),
      );

      if (response.secureUrl.isNotEmpty) {
        return response.secureUrl;
      } else {
        throw 'Gagal mendapatkan URL dari Cloudinary.';
      }
    } catch (e) {
      dev.log('Cloudinary Upload Error: $e');
      AppUtils.showError('Upload Gagal', 'Gagal upload foto profil.');
      return null;
    }
  }
}
