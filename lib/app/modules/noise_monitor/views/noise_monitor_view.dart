import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/noise_monitor_controller.dart';
import 'dart:math' as math;

class NoiseMonitorView extends GetView<NoiseMonitorController> {
  const NoiseMonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Noise Level Monitor',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Obx(() => Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.currentDb.value.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'dB',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(context),
                  const SizedBox(height: 32),
                  _buildStatsGrid(context),
                  const SizedBox(height: 32),
                  const Text(
                    'ENVIRONMENTAL IMPACT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNoiseLevelGuide(context),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
        onPressed: controller.toggleMonitoring,
        elevation: 4,
        label: Text(
          controller.isMonitoring.value ? 'STOP MONITOR' : 'START MONITOR',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
        ),
        icon: Icon(controller.isMonitoring.value ? Icons.stop_rounded : Icons.graphic_eq, color: Colors.white),
        backgroundColor: controller.isMonitoring.value ? Colors.redAccent : Colors.orange,
      )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final db = controller.currentDb.value;
      final status = _getNoiseStatus(db);
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: status.color,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  status.label.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status.color,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.volume_up_outlined, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: db / 120,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(status.color),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 16),
            Text(
              status.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            'MAXIMUM',
            controller.maxDb,
            Icons.arrow_upward,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            context,
            'AVERAGE',
            controller.avgDb,
            Icons.horizontal_rule,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, RxDouble value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() => Text(
            '${value.value.toStringAsFixed(1)} dB',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )),
        ],
      ),
    );
  }

  Widget _buildNoiseLevelGuide(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levels = [
      _NoiseStatus(0, 30, 'Very Quiet', 'Whispering, library', Colors.green),
      _NoiseStatus(30, 60, 'Moderate', 'Quiet office, rain', Colors.lightGreen),
      _NoiseStatus(60, 85, 'Loud', 'Traffic, noisy restaurant', Colors.orange),
      _NoiseStatus(85, 120, 'Very Loud', 'Siren, rock concert, harmful', Colors.red),
    ];

    return Column(
      children: levels.map((l) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: l.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.info_outline, color: l.color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(l.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Text('${l.min}-${l.max} dB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      )).toList(),
    );
  }

  _NoiseStatus _getNoiseStatus(double db) {
    if (db < 30) return _NoiseStatus(0, 30, 'Very Quiet', 'A very peaceful environment, healthy for biodiversity.', Colors.green);
    if (db < 60) return _NoiseStatus(30, 60, 'Moderate', 'Standard ambient noise levels. Typical for residential areas.', Colors.lightGreen);
    if (db < 85) return _NoiseStatus(60, 85, 'Loud Noise', 'Potential noise pollution detected. May impact local bird species.', Colors.orange);
    return _NoiseStatus(85, 120, 'Danger / Harmful', 'Severe noise pollution. High risk of habitat displacement.', Colors.red);
  }
}

class _NoiseStatus {
  final double min;
  final double max;
  final String label;
  final String description;
  final Color color;

  _NoiseStatus(this.min, this.max, this.label, this.description, this.color);
}
