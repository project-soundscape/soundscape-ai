import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Obx(
        () => ListView(
          children: [
            const SizedBox(height: 20),
            _buildSectionHeader('Account'),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(controller.userName),
              subtitle: Text(controller.userEmail),
              trailing: controller.isLoggedIn
                  ? const Icon(Icons.logout, color: Colors.redAccent)
                  : const Icon(Icons.login, color: Colors.teal),
              onTap: () {
                if (controller.isLoggedIn) {
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.back();
                            controller.logout();
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  Get.toNamed('/login'); // Adjust route as needed
                }
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
                    const Text(
                      'A citizen science app to monitor biodiversity and noise pollution.',
                    ),
                  ],
                );
              },
            ),
            Obx(
              () => ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: const Text('Version'),
                trailing: Text(
                  controller.appVersion.value,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
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
