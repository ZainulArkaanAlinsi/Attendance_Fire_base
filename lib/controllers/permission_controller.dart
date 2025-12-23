import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionController extends GetxController {
  final Rx<PermissionStatus> cameraStatus = PermissionStatus.denied.obs;
  final Rx<PermissionStatus> locationStatus = PermissionStatus.denied.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    cameraStatus.value = await Permission.camera.status;
    locationStatus.value = await Permission.location.status;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    cameraStatus.value = status;
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    
    return status.isGranted;
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    locationStatus.value = status;
    
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    
    return status.isGranted;
  }
}
