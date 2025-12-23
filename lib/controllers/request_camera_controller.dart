import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/permission_service.dart';

class RequestCameraController extends GetxController with WidgetsBindingObserver {
  final PermissionService _permissionService = Get.find<PermissionService>();
  
  final Rx<PermissionState> cameraStatus = PermissionState.unknown.obs;
  final RxString feedbackMessage = ''.obs;
  
  late String nextRoute;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    nextRoute = Get.arguments as String? ?? '';
    checkCameraPermission();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkCameraPermission();
    }
  }

  Future<void> checkCameraPermission() async {
    final status = await _permissionService.getCameraPermissionStatus();
    _updateStatus(status);
  }

  Future<void> requestPermission() async {
    final status = await _permissionService.requestCameraPermission();
    _updateStatus(status);
  }

  void _updateStatus(PermissionState status) {
    cameraStatus.value = status;
    switch (status) {
      case PermissionState.granted:
        feedbackMessage.value = 'Camera access granted! You can proceed now.';
        break;
      case PermissionState.denied:
        feedbackMessage.value = 'Camera access is required for face enrollment.';
        break;
      case PermissionState.permanentlyDenied:
        feedbackMessage.value = 'Camera access is permanently denied. Please enable it in settings.';
        break;
      case PermissionState.unknown:
        feedbackMessage.value = 'Checking camera permission...';
        break;
    }
  }

  void onAction() {
    if (cameraStatus.value == PermissionState.granted) {
      Get.offNamed(nextRoute);
    } else if (cameraStatus.value == PermissionState.permanentlyDenied) {
      _permissionService.openSystemSettings();
    } else {
      requestPermission();
    }
  }
}
