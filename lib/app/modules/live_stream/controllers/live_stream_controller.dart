import 'package:get/get.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class LiveStreamController extends GetxController {
  late VlcPlayerController vlcController;
  late String streamUrl;
  final RxBool isBuffering = true.obs;
  final RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    streamUrl = Get.arguments as String;
    vlcController = VlcPlayerController.network(
      streamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    vlcController.addListener(() {
      if (vlcController.value.hasError) {
        hasError.value = true;
        isBuffering.value = false;
      }
      isBuffering.value = vlcController.value.isBuffering;
    });
  }

  @override
  void onClose() {
    vlcController.dispose();
    super.onClose();
  }
}
