import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/request_location_controller.dart';
import '../services/permission_service.dart';

class RequestLocationProps {
  final String nextRoute;
  final String? targetRoute;

  RequestLocationProps({required this.nextRoute, this.targetRoute});
}

class RequestLocationPage extends StatelessWidget {
  const RequestLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RequestLocationController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Permission'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() {
              IconData icon;
              Color color;
              switch (controller.locationStatus.value) {
                case PermissionState.granted:
                  icon = Icons.check_circle_outline;
                  color = Colors.green;
                  break;
                case PermissionState.permanentlyDenied:
                  icon = Icons.settings_suggest_outlined;
                  color = Colors.orange;
                  break;
                default:
                  icon = Icons.location_on_outlined;
                  color = Theme.of(context).colorScheme.primary;
              }
              return Icon(icon, size: 100, color: color);
            }),
            const SizedBox(height: 40),
            Obx(
              () => Text(
                controller.feedbackMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: Obx(() {
                final isGranted =
                    controller.locationStatus.value == PermissionState.granted;
                return ElevatedButton(
                  onPressed: controller.onAction,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    backgroundColor: isGranted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isGranted
                        ? 'Continue'
                        : (controller.locationStatus.value ==
                                  PermissionState.permanentlyDenied
                              ? 'Open Settings'
                              : 'Grant Access'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
