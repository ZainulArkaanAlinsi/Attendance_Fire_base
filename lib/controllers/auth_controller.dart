import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import '../routes/app_router.dart';
import '../services/user_service.dart';
import '../utils/app_utils.dart';
import '../services/storage_service.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = Get.find<UserService>();
  final StorageService _storageService = Get.find<StorageService>();

  // State observables
  final RxBool isLoading = false.obs;
  final RxBool isPasswordHidden = true.obs;
  final RxBool isConfirmPasswordHidden = true.obs;
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxString errorMessage = ''.obs;

  // Form keys
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> forgotPasswordFormKey = GlobalKey<FormState>();

  // Text controllers - dibuat local di setiap page
  String? get email => _storageService.getString('last_email');
  set email(String? value) => _storageService.setString('last_email', value);

  @override
  void onInit() {
    super.onInit();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      currentUser.value = user;
      if (user != null) {
        // User is signed in
        _userService
            .loadUserDoc(user.uid)
            .then((_) {
              // Navigate based on user role
              _navigateBasedOnRole();
            })
            .catchError((error) {
              dev.log('Error fetching user data: $error');
              Get.offAllNamed(AppRouter.login);
            });
      } else {
        // User is signed out
        Get.offAllNamed(AppRouter.login);
      }
    });
  }

  void _navigateBasedOnRole() {
    final userRole = _userService.firestoreUser.value?.role;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (userRole == 'admin') {
        Get.offAllNamed(AppRouter.adminDashboard);
      } else {
        Get.offAllNamed(AppRouter.home);
      }
    });
  }

  void togglePasswordVisibility() => isPasswordHidden.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordHidden.toggle();

  Future<void> login({required String email, required String password}) async {
    if (!loginFormKey.currentState!.validate()) {
      AppUtils.showError('Validation Error', 'Please check your inputs');
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Save email for future use
      this.email = email;

      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        AppUtils.showSuccess('Login Success', 'Welcome back!');

        // Log to Crashlytics
        await FirebaseCrashlytics.instance.setUserIdentifier(
          credential.user!.uid,
        );
        await FirebaseCrashlytics.instance.log('User logged in: $email');
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      AppUtils.showError('Login Failed', errorMessage.value);

      // Report to Crashlytics
      await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String confirmPassword,
  }) async {
    if (!registerFormKey.currentState!.validate()) {
      AppUtils.showError('Validation Error', 'Please check your inputs');
      return;
    }

    if (password != confirmPassword) {
      AppUtils.showError('Password Mismatch', 'Passwords do not match');
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Create user in Firebase Auth
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name.trim());

        // Create user document in Firestore
        await _userService.createUserDoc(credential.user!, name.trim());

        AppUtils.showSuccess(
          'Registration Successful',
          'Your account has been created successfully!',
        );

        // Save email
        this.email = email;

        // Log to Crashlytics
        await FirebaseCrashlytics.instance.setUserIdentifier(
          credential.user!.uid,
        );
        await FirebaseCrashlytics.instance.log('User registered: $email');
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      errorMessage.value = 'Registration failed. Please try again.';
      AppUtils.showError('Registration Failed', errorMessage.value);

      // Report to Crashlytics
      await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    if (!forgotPasswordFormKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      AppUtils.showSuccess(
        'Password Reset Email Sent',
        'Please check your email for instructions to reset your password.',
      );

      Get.back(); // Go back to login page
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      errorMessage.value = 'Failed to send reset email. Please try again.';
      AppUtils.showError('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        errorMessage.value = 'No account found with this email.';
        break;
      case 'wrong-password':
        errorMessage.value = 'Incorrect password. Please try again.';
        break;
      case 'invalid-email':
        errorMessage.value = 'Invalid email address.';
        break;
      case 'email-already-in-use':
        errorMessage.value = 'This email is already registered.';
        break;
      case 'weak-password':
        errorMessage.value = 'Password is too weak. Use at least 6 characters.';
        break;
      case 'network-request-failed':
        errorMessage.value = 'Network error. Please check your connection.';
        break;
      case 'too-many-requests':
        errorMessage.value = 'Too many attempts. Please try again later.';
        break;
      default:
        errorMessage.value =
            e.message ?? 'An error occurred. Please try again.';
    }

    AppUtils.showError('Authentication Error', errorMessage.value);

    // Log error to Crashlytics
    FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _auth.signOut();
      await _userService.clearUserData();
      AppUtils.showSuccess(
        'Logged Out',
        'You have been logged out successfully.',
      );
    } catch (e) {
      AppUtils.showError(
        'Logout Failed',
        'Could not sign out. Please try again.',
      );
      await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      isLoading.value = true;
      try {
        final user = _auth.currentUser;
        if (user != null) {
          // Delete from Firestore first
          await _userService.deleteUserData(user.uid);
          // Then delete auth account
          await user.delete();
          AppUtils.showSuccess(
            'Account Deleted',
            'Your account has been deleted.',
          );
        }
      } catch (e) {
        AppUtils.showError(
          'Deletion Failed',
          'Could not delete account. Please try again.',
        );
        await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
        }
        if (photoURL != null && photoURL.isNotEmpty) {
          await user.updatePhotoURL(photoURL);
        }

        // Update in Firestore
        await _userService.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        );

        AppUtils.showSuccess(
          'Profile Updated',
          'Your profile has been updated.',
        );
      }
    } catch (e) {
      AppUtils.showError(
        'Update Failed',
        'Could not update profile. Please try again.',
      );
      await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }

  @override
  void onClose() {
    // Cleanup jika diperlukan
    super.onClose();
  }
}
