import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../routes/app_pages.dart';

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

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields', backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
      return;
    }

    isLoading.value = true;
    try {
      await _appwriteService.login(emailController.text, passwordController.text);
      Get.offAllNamed(Routes.DASHBOARD);
    } catch (e) {
      Get.snackbar('Login Failed', e.toString().replaceAll('Exception: ', ''), backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signup() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty || nameController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields', backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
      return;
    }

    isLoading.value = true;
    try {
      await _appwriteService.signup(emailController.text, passwordController.text, nameController.text);
      Get.snackbar('Success', 'Account created! Logging in...', backgroundColor: Colors.green.withValues(alpha: 0.1), colorText: Colors.green);
      await login(); 
    } catch (e) {
      Get.snackbar('Signup Failed', e.toString().replaceAll('Exception: ', ''), backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }
}
