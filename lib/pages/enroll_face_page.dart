import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/enroll_face_controller.dart';
import '../widgets/glass_card.dart';
import '../widgets/face_scanner_overlay.dart';

class EnrollFacePage extends StatelessWidget {
  const EnrollFacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EnrollFaceController());

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Face Enrollment',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // Camera Preview Background
          Obx(
            () => controller.isInitialized.value
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller
                            .cameraController!
                            .value
                            .previewSize!
                            .height,
                        height: controller
                            .cameraController!
                            .value
                            .previewSize!
                            .width,
                        child: CameraPreview(controller.cameraController!),
                      ),
                    ),
                  )
                : Container(color: Colors.black),
          ),

          // Dark Overlay for focus
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),

          // Main UI Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Scanning Area
                Center(
                  child: Obx(
                    () => FaceScannerOverlay(
                      isScanning: controller.isProcessing.value,
                      isSuccess: controller.feedbackMessage.value.contains(
                        'success',
                      ),
                      isError:
                          controller.feedbackMessage.value.contains('failed') ||
                          controller.feedbackMessage.value.contains('error'),
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom Feedback and Controls
                Obx(
                  () => GlassCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 30,
                    ),
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.feedbackMessage.value,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Capture Button
                        GestureDetector(
                          onTap: controller.isProcessing.value
                              ? null
                              : controller.captureAndProcess,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: controller.isProcessing.value
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              controller.isProcessing.value
                                  ? Icons.hourglass_empty
                                  : Icons.camera_alt,
                              size: 35,
                              color: controller.isProcessing.value
                                  ? Colors.white54
                                  : Colors.blue.shade900,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Text(
                          'Tap to capture',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Initial Loading State
          Obx(() {
            if (!controller.isInitialized.value) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 20),
                      Text(
                        'Initializing Camera...',
                        style: GoogleFonts.outfit(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Processing Overlay
          Obx(() {
            if (!controller.isProcessing.value) return const SizedBox.shrink();

            return Container(
              color: Colors.black.withAlpha(150),
              child: Center(
                child: GlassCard(
                  blur: 10,
                  opacity: 0.1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.blue,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 25),
                      Text(
                        controller.feedbackMessage.value,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// End of EnrollFacePage
