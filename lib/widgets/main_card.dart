import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_router.dart';
import '../services/user_service.dart';
import '../services/permission_service.dart';
import '../pages/request_location_page.dart';
import '../widgets/glass_card.dart';
import '../utils/app_colors.dart';

class MainCard extends StatelessWidget {
  const MainCard({super.key});

  Future<void> _handleAttendance() async {
    final permissionService = Get.find<PermissionService>();
    final isLocationGranted =
        await permissionService.getLocationPermissionStatus() ==
        PermissionState.granted;
    final isCameraGranted =
        await permissionService.getCameraPermissionStatus() ==
        PermissionState.granted;

    if (isLocationGranted && isCameraGranted) {
      Get.toNamed(AppRouter.attendance);
    } else if (!isLocationGranted) {
      Get.toNamed(
        AppRouter.requestLocation,
        arguments: RequestLocationProps(
          nextRoute: AppRouter.requestCamera,
          targetRoute: AppRouter.attendance,
        ),
      );
    } else {
      Get.toNamed(AppRouter.requestCamera, arguments: AppRouter.attendance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = Get.find<UserService>();
    final user = userService.firestoreUser.value;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.displayName ?? 'Employee',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/icon/icon_attendance.png',
                  height: 40,
                  width: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                SizedBox(width: 6),
                Text(
                  'Active Session',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _handleAttendance,
              icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
              label: const Text(
                'TAKE ATTENDANCE',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
