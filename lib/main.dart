import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'app/data/services/appwrite_service.dart';
import 'app/data/services/location_service.dart';
import 'app/data/services/noise_service.dart';
import 'app/data/services/notification_service.dart';
import 'app/data/services/storage_service.dart';
import 'app/data/services/sync_service.dart';
import 'app/data/services/wiki_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => AppwriteService().init());
  await Get.putAsync(() => WikiService().init());
  await Get.putAsync(() => NotificationService().init());
  Get.put(LocationService());
  Get.put(NoiseService());
  await Get.putAsync(() => SyncService().init());

  runApp(
    GetMaterialApp(
      title: "Project Soundscape",
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[50],
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system, // Will be overridden by controller logic
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}
