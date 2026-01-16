import 'dart:developer';

import 'package:get/get.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();

  @override
  void onReady() {
    super.onReady();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Add a small delay for branding visibility
      await Future.delayed(const Duration(seconds: 2));
      
      print("Splash: Checking current user...");
      final user = await _appwriteService.getCurrentUser().timeout(const Duration(seconds: 5));
      print("Splash: User is ${user?.email ?? 'null'}");
      
      if (user != null && user.email.isNotEmpty) {
        Get.offAllNamed(Routes.DASHBOARD);
      } else {
        // If anonymous (no email) or null, go to login
        if (user != null) {
          await _appwriteService.logout();
        }
        Get.offAllNamed(Routes.LOGIN);
      }
    } catch (e) {
      print("Splash Error: $e");
      // Fallback to login on error
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}
