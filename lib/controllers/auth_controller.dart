import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app_utils.dart';
import '../services/user_service.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State
  final RxBool isLoading = false.obs;
  final RxBool isPasswordHidden = true.obs;
  final RxBool isConfirmPasswordHidden = true.obs;

  // Getters for UI
  RxBool get isAdmin =>
      (Get.find<UserService>().firestoreUser.value?.role == 'admin').obs;
  RxList get attendanceHistory =>
      <dynamic>[].obs; // Placeholder as it's not implemented yet

  // Form Controllers
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() => isPasswordHidden.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordHidden.toggle();

  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // Navigation is handled by UserService listener
    } on FirebaseAuthException catch (e) {
      AppUtils.showError('Login Failed', e.message ?? 'Unknown error occurred');
    } catch (e) {
      AppUtils.showError('Error', 'An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (credential.user != null) {
        final displayName = nameController.text.trim();

        // Create user doc in Firestore FIRST to avoid race condition in auth listener
        final userService = Get.find<UserService>();
        await userService.createUserDoc(credential.user!, displayName);

        await credential.user!.updateDisplayName(displayName);
      }

      AppUtils.showSuccess(
        'Registration Success',
        'Your account has been created',
      );
    } on FirebaseAuthException catch (e) {
      AppUtils.showError(
        'Registration Failed',
        e.message ?? 'Unknown error occurred',
      );
    } catch (e) {
      AppUtils.showError('Error', 'An unexpected error occurred');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    try {
      await Get.find<UserService>().logout();
    } catch (e) {
      AppUtils.showError('Logout Failed', 'Could not sign out');
    }
  }
}
