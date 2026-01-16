import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized (lazy loaded usually via binding)
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Anonymous User'),
            subtitle: const Text('Signed in anonymously'),
            trailing: const Icon(Icons.logout, color: Colors.grey),
            onTap: () {
               Get.snackbar("Info", "Anonymous session cannot be signed out manually.");
            },
          ),
          const Divider(),
          _buildSectionHeader('App Info'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Project Soundscape'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Project Soundscape',
                applicationVersion: controller.appVersion.value,
                applicationLegalese: '© 2026 SoundScape Team',
                children: [
                  const Text('A citizen science app to monitor biodiversity and noise pollution.'),
                ],
              );
            },
          ),
          Obx(() => ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('Version'),
            trailing: Text(controller.appVersion.value, style: const TextStyle(color: Colors.grey)),
          )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.teal[800],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}