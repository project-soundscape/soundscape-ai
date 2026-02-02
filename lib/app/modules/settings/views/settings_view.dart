import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/settings_controller.dart';

import 'edit_profile_view.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200.0,
            backgroundColor: Colors.teal,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          controller.userName.isNotEmpty ? controller.userName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(() => Text(
                      controller.userName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    )),
                    Obx(() => Text(
                      controller.userEmail,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                    )),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Preferences'),
                  _buildSettingsCard(context, [
                    _buildSwitchTile(
                      'Dark Mode',
                      Icons.dark_mode_outlined,
                      controller.isDarkMode,
                      (val) => controller.toggleTheme(val),
                    ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      'Notifications',
                      Icons.notifications_outlined,
                      controller.notificationsEnabled,
                      (val) => controller.toggleNotifications(val),
                    ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      'Recording Tips',
                      Icons.help_outline,
                      controller.showRecordingInstructions,
                      (val) => controller.toggleRecordingInstructions(val),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Intelligence'),
                  _buildSettingsCard(context, [
                    _buildSwitchTile(
                      'BirdNET-Lite ID',
                      Icons.biotech_outlined,
                      controller.useAdvancedModel,
                      (val) => controller.toggleAdvancedModel(val),
                    ),
                    Obx(() {
                      if (controller.isDownloading.value) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: controller.downloadProgress.value,
                                backgroundColor: Colors.grey[200],
                                color: Colors.teal,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                controller.downloadStatus.value,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    Obx(() => controller.isModelDownloaded.value 
                      ? _buildActionTile(
                          'Delete Acoustic Model',
                          Icons.delete_sweep_outlined,
                          () => controller.deleteAdvancedModel(),
                          isDestructive: true,
                        )
                      : const SizedBox.shrink()
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Account'),
                  _buildSettingsCard(context, [
                    _buildActionTile(
                      'Edit Profile',
                      Icons.person_outline,
                      () => Get.to(() => const EditProfileView()),
                    ),
                    _buildDivider(isDark),
                    _buildActionTile(
                      'Logout',
                      Icons.logout,
                      () => _showLogoutDialog(context),
                      isDestructive: true,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Diagnostics'),
                  _buildSettingsCard(context, [
                    _buildActionTile(
                      'YAMNet Checker',
                      Icons.analytics_outlined,
                      () => Get.toNamed(Routes.YAMNET_CHECKER),
                    ),
                    _buildDivider(isDark),
                    _buildActionTile(
                      'Noise Monitor',
                      Icons.volume_up_outlined,
                      () => Get.toNamed(Routes.NOISE_MONITOR),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('About'),
                  _buildSettingsCard(context, [
                    _buildActionTile(
                      'About SoundScape',
                      Icons.info_outline,
                      () => showAboutDialog(
                        context: context,
                        applicationName: 'Project Soundscape',
                        applicationVersion: controller.appVersion.value,
                        applicationLegalese: '© 2026 SoundScape Team',
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text('A citizen science app to monitor biodiversity and noise pollution.'),
                          ),
                        ],
                      ),
                    ),
                    _buildDivider(isDark),
                    Obx(() => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.verified_outlined, color: Colors.grey),
                      ),
                      title: const Text('Version', style: TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          controller.appVersion.value,
                          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    )),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, RxBool value, Function(bool) onChanged) {
    return Obx(() => SwitchListTile(
      value: value.value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.teal),
      ),
      activeColor: Colors.teal,
    ));
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : Colors.teal;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.redAccent : null, // Uses theme default if null
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, thickness: 1, color: isDark ? Colors.grey[800] : Colors.grey.withValues(alpha: 0.1));
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of your account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
