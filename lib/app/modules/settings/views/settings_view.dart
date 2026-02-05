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
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      'Use Compass',
                      Icons.explore_outlined,
                      controller.useCompass,
                      (val) => controller.toggleCompass(val),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Intelligence'),
                  _buildSettingsCard(context, [
                    _buildActiveModelTile(context),
                    const Divider(height: 1),
                    _buildModelList(context),
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
                      'Acoustic Monitor',
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
      activeThumbColor: Colors.teal,
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
    // ... (existing code)
  }

  Widget _buildActiveModelTile(BuildContext context) {
    return Obx(() {
      final activeId = controller.activeModelId.value;
      final activeModel = activeId == 'yamnet' 
          ? 'Standard (YAMNet)' 
          : controller.availableModels.firstWhere((m) => m.id == activeId).name;
          
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.memory, color: Colors.teal),
        ),
        title: const Text('Active Engine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        subtitle: Text(activeModel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.check_circle, color: Colors.teal, size: 20),
      );
    });
  }

  Widget _buildModelList(BuildContext context) {
    return Column(
      children: [
        // Standard YAMNet (Built-in)
        _buildModelItem(
          context, 
          'Standard Acoustic ID', 
          'General sound classification (521 classes). Built-in.', 
          'yamnet',
          isBuiltIn: true
        ),
        // Marketplace Models
        ...controller.availableModels.map((model) => _buildModelItem(
          context, 
          model.name, 
          model.description, 
          model.id
        )),
      ],
    );
  }

  Widget _buildModelItem(BuildContext context, String name, String desc, String id, {bool isBuiltIn = false}) {
    return Obx(() {
      final isDownloaded = controller.downloadedModels.contains(id) || isBuiltIn;
      final isActive = controller.activeModelId.value == id;
      final isDownloading = controller.isDownloading.value && controller.downloadingModelId.value == id;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
              subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
              trailing: _buildModelTrailing(id, isDownloaded, isActive, isDownloading),
              onTap: isDownloaded ? () => controller.setActiveModel(id) : null,
            ),
            if (isDownloading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: controller.downloadProgress.value,
                backgroundColor: Colors.grey[200],
                color: Colors.teal,
                minHeight: 4,
              ),
              const SizedBox(height: 4),
              Text(controller.downloadStatus.value, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildModelTrailing(String id, bool isDownloaded, bool isActive, bool isDownloading) {
    if (isDownloading) return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    
    if (isActive) return const Icon(Icons.radio_button_checked, color: Colors.teal);
    
    if (isDownloaded) {
      if (id == 'yamnet') return const Icon(Icons.radio_button_off, color: Colors.grey);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
            onPressed: () => controller.deleteAcousticModel(id),
          ),
          const Icon(Icons.radio_button_off, color: Colors.grey),
        ],
      );
    }

    return ElevatedButton(
      onPressed: () => controller.setActiveModel(id),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(60, 30),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      child: const Text('GET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
