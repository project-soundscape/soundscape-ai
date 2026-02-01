import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../map/controllers/map_controller.dart';
import '../../library/controllers/library_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(),
    );
    // Initialize sub-controllers
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<SettingsController>(() => SettingsController());
    Get.lazyPut<SoundMapController>(() => SoundMapController());
    Get.lazyPut<LibraryController>(() => LibraryController());
  }
}
