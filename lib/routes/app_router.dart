import 'package:get/get.dart';
import '../pages/root_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/home_page.dart';
import '../pages/enroll_face_page.dart';
import '../pages/attendance_page.dart';
import '../pages/request_camera_page.dart';
import '../pages/request_location_page.dart';
import '../controllers/request_location_controller.dart';

import '../bindings/auth_binding.dart';

class AppRouter {
  static const String root = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String requestCamera = '/request-camera';
  static const String requestLocation = '/request-location';
  static const String enrollFace = '/enroll-face';
  static const String attendance = '/attendance';

  static const String initialRoute = root;

  static final List<GetPage> pages = [
    GetPage(
      name: root,
      page: () => const RootPage(),
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
    ),
    GetPage(
      name: requestCamera,
      page: () => const RequestCameraPage(),
    ),
    GetPage(
      name: requestLocation,
      page: () => const RequestLocationPage(),
      binding: BindingsBuilder(() => Get.lazyPut(() => RequestLocationController())),
    ),
    GetPage(
      name: login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: register,
      page: () => const RegisterPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: enrollFace,
      page: () => const EnrollFacePage(),
    ),
    GetPage(
      name: attendance,
      page: () => const AttendancePage(),
    ),
  ];
}
