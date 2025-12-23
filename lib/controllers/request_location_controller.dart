import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/permission_service.dart';
import '../pages/request_location_page.dart';

class RequestLocationController extends GetxController with WidgetsBindingObserver {
  final PermissionService _permissionService = Get.find<PermissionService>();
  
  final Rx<PermissionState> locationStatus = PermissionState.unknown.obs;
  final RxString feedbackMessage = ''.obs;
  
  late RequestLocationProps props;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    props = Get.arguments as RequestLocationProps;
    checkLocationPermission();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkLocationPermission();
    }
  }

  Future<void> checkLocationPermission() async {
    final status = await _permissionService.getLocationPermissionStatus();
    _updateStatus(status);
  }

  Future<void> requestPermission() async {
    final status = await _permissionService.requestLocationPermission();
    _updateStatus(status);
  }

  void _updateStatus(PermissionState status) {
    locationStatus.value = status;
    switch (status) {
      case PermissionState.granted:
        feedbackMessage.value = 'Location access granted! You can proceed now.';
        break;
      case PermissionState.denied:
        feedbackMessage.value = 'Location access is required for attendance.';
        break;
      case PermissionState.permanentlyDenied:
        feedbackMessage.value = 'Location access is permanently denied. Please enable it in settings.';
        break;
      case PermissionState.unknown:
        feedbackMessage.value = 'Checking location permission...';
        break;
    }
  }

  Future<void> onAction() async {
    if (locationStatus.value == PermissionState.granted) {
      if (props.targetRoute != null) {
        final cameraStatus = await _permissionService.getCameraPermissionStatus();
        if (cameraStatus == PermissionState.granted) {
          Get.offNamed(props.targetRoute!);
          return;
        }
      }
      Get.offNamed(props.nextRoute, arguments: props.targetRoute);
    } else if (locationStatus.value == PermissionState.permanentlyDenied) {
      _permissionService.openSystemSettings();
    } else {
      requestPermission();
    }
  }
}
