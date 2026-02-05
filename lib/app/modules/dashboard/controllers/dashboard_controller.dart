import 'package:get/get.dart';
import '../../map/controllers/map_controller.dart';

class DashboardController extends GetxController {
  final  tabIndex = 1.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to tab changes to pause/resume sensors
    ever(tabIndex, (index) {
      final mapController = Get.find<SoundMapController>();
      if (index == 1) {
        mapController.startHeadingTracking();
      } else {
        mapController.stopHeadingTracking();
      }
    });
  }

  void changeTabIndex(int index) {
    tabIndex.value = index;
  }
}
