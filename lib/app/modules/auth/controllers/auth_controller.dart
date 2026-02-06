import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../routes/app_pages.dart';
import 'package:frontend/app/utils/snackbar_utils.dart';

class AuthController extends GetxController {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isObscure = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.onClose();
  }

  void toggleObscure() {
    isObscure.value = !isObscure.value;
  }

  String _formatErrorMessage(dynamic e) {
    if (e is AppwriteException) {
      switch (e.code) {
        case 401:
          return 'Incorrect email or password. Please try again.';
        case 404:
          return 'Account not found. Please sign up first.';
        case 409:
          return 'An account with this email already exists.';
        case 429:
          return 'Too many attempts. Please try again later.';
        default:
          return e.message ?? 'An authentication error occurred.';
      }
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  void _showFeedback(String title, String message, {bool isError = true}) {
    showCustomSnackBar(title, message, isError: isError);
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showFeedback('Error', 'Please enter both email and password');
      return;
    }

    isLoading.value = true;
    try {
      await _appwriteService.login(email, password);
      Get.offAllNamed(Routes.DASHBOARD);
    } catch (e) {
      _showFeedback('Login Failed', _formatErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showFeedback('Error', 'Please fill in all fields');
      return;
    }

    if (password.length < 8) {
      _showFeedback('Error', 'Password must be at least 8 characters long');
      return;
    }

    isLoading.value = true;
    try {
      await _appwriteService.signup(email, password, name);
      _showFeedback('Success', 'Account created! Logging in...', isError: false);
      await login(); 
    } catch (e) {
      _showFeedback('Signup Failed', _formatErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showFeedback('Email Required', 'Please enter your email address first');
      return;
    }

    isLoading.value = true;
    try {
      await _appwriteService.createRecovery(email);
      _showFeedback('Recovery Sent', 'Please check your email for the reset link', isError: false);
    } catch (e) {
      _showFeedback('Request Failed', _formatErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }
}
