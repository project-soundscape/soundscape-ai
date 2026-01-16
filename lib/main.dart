import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'app/data/services/appwrite_service.dart';
import 'app/data/services/location_service.dart';
import 'app/data/services/storage_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => AppwriteService().init());
  Get.put(LocationService());

  runApp(
    GetMaterialApp(
      title: "Project Soundscape",
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}
