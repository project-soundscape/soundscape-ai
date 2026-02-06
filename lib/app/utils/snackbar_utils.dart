import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();

void showCustomSnackBar(String title, String message, {bool isError = true}) {
  print("Snackbar Request: $title - $message");
  
  SchedulerBinding.instance.addPostFrameCallback((_) {
    final messenger = snackbarKey.currentState;
    
    if (messenger != null) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                const SizedBox(height: 2),
                Text(message, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
          backgroundColor: isError ? Colors.redAccent : Colors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      print("FALLBACK: snackbarKey.currentState is NULL! Trying Get.context...");
      
      // Secondary Fallback: Use Get.context with native ScaffoldMessenger
      if (Get.context != null) {
        try {
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            SnackBar(
              content: Text("$title: $message"),
              backgroundColor: isError ? Colors.redAccent : Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        } catch (e) {
          print("Secondary fallback failed: $e");
        }
      }

      // Tertiary Fallback: Get.rawSnackbar (will fail if no overlay, but last resort)
      Get.rawSnackbar(
        title: title,
        message: message,
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  });
}
