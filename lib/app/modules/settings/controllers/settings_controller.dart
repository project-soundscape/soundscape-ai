import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../data/services/appwrite_service.dart';
import '../../../routes/app_pages.dart';

class SettingsController extends GetxController {
  final _appwriteService = Get.find<AppwriteService>();
  final appVersion = ''.obs;

  bool get isLoggedIn => _appwriteService.isLoggedIn.value;
  String get userName => _appwriteService.currentUser.value?.name ?? 'Anonymous';
  String get userEmail => _appwriteService.currentUser.value?.email ?? 'No email';

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion.value = '${info.version} (${info.buildNumber})';
  }

  Future<void> logout() async {
    await _appwriteService.logout();
    Get.offAllNamed(Routes.LOGIN);
  }
}
