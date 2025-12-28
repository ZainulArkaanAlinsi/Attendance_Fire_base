import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_utils.dart';
import '../utils/validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: authController.registerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up to get started',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: nameController,
                validator: AppValidators.validateName,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                onTapOutside: AppUtils.onTapOutside,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                validator: AppValidators.validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onTapOutside: AppUtils.onTapOutside,
              ),
              const SizedBox(height: 20),
              Obx(
                () => TextFormField(
                  controller: passwordController,
                  validator: AppValidators.validatePassword,
                  obscureText: authController.isPasswordHidden.value,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        authController.isPasswordHidden.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: authController.togglePasswordVisibility,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  onTapOutside: AppUtils.onTapOutside,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => TextFormField(
                  controller: confirmPasswordController,
                  validator: (value) => AppValidators.validateConfirmPassword(
                    value,
                    passwordController.text,
                  ),
                  obscureText: authController.isConfirmPasswordHidden.value,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(
                        authController.isConfirmPasswordHidden.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: authController.toggleConfirmPasswordVisibility,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onTapOutside: AppUtils.onTapOutside,
                ),
              ),
              const SizedBox(height: 40),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : () => authController.register(
                            name: nameController.text,
                            email: emailController.text,
                            password: passwordController.text,
                            confirmPassword: confirmPasswordController.text,
                          ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: authController.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Get.back(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
