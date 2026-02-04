import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();

  @override
  void onReady() {
    super.onReady();
    _handleSplashLogic();
  }

  Future<void> _handleSplashLogic() async {
    // Add a small delay for branding visibility
    await Future.delayed(const Duration(seconds: 2));

    // Check if we have actual internet connectivity
    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      print("Splash: Offline, going to Dashboard as guest");
      Get.offAllNamed(Routes.DASHBOARD);
    } else {
      await _checkAuth();
    }
  }

  /// Check actual internet connectivity by pinging a reliable endpoint
  Future<bool> _checkInternetConnection() async {
    // First check network interface
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    
    // Then verify actual internet access
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on Exception catch (_) {
      return false;
    }
  }

  Future<void> _checkAuth() async {
    try {
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
      // Network error likely means offline - go to dashboard as guest
      Get.offAllNamed(Routes.DASHBOARD);
    }
  }
}
