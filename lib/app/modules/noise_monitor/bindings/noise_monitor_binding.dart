import 'package:get/get.dart';
import '../controllers/noise_monitor_controller.dart';

class NoiseMonitorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NoiseMonitorController>(
      () => NoiseMonitorController(),
    );
  }
}
