import 'package:get/get.dart';

class DashboardController extends GetxController {
  final  tabIndex = 1.obs;

  void changeTabIndex(int index) {
    tabIndex.value = index;
  }
}
