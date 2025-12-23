import 'package:get/get.dart';
import '../services/user_service.dart';
import '../services/permission_service.dart';
import '../services/face_recognition_service.dart';
import '../services/storage_service.dart';
import '../services/cloudinary_service.dart';
import '../services/target_location_service.dart';
import '../controllers/theme_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ThemeController(), permanent: true);
    Get.put(PermissionService(), permanent: true);
    Get.put(UserService(), permanent: true);
    Get.put(FaceRecognitionService(), permanent: true);
    Get.put(StorageService(), permanent: true);
    Get.put(CloudinaryService(), permanent: true);
    Get.put(TargetLocationService(), permanent: true);
  }
}
