import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionState {
  granted,
  denied,
  permanentlyDenied,
  unknown,
}

class PermissionService extends GetxService {
  PermissionState _convertStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return PermissionState.granted;
      case PermissionStatus.denied:
        return PermissionState.denied;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return PermissionState.permanentlyDenied;
      default:
        return PermissionState.unknown;
    }
  }

  Future<PermissionState> getCameraPermissionStatus() async {
    final status = await Permission.camera.status;
    return _convertStatus(status);
  }

  Future<PermissionState> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return _convertStatus(status);
  }

  Future<PermissionState> getLocationPermissionStatus() async {
    final status = await Permission.location.status;
    return _convertStatus(status);
  }

  Future<PermissionState> requestLocationPermission() async {
    final status = await Permission.location.request();
    return _convertStatus(status);
  }

  Future<void> openSystemSettings() async {
    await openAppSettings();
  }
}
