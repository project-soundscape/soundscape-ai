import 'package:get/get.dart';
import '../controllers/yamnet_checker_controller.dart';

class YamnetCheckerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<YamnetCheckerController>(
      () => YamnetCheckerController(),
    );
  }
}
