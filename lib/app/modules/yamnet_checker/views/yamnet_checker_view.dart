import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/yamnet_checker_controller.dart';

class YamnetCheckerView extends GetView<YamnetCheckerController> {
  const YamnetCheckerView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Acoustic Monitor',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Color(0xFF00695C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Obx(() => Opacity(
                    opacity: controller.isMonitoring.value ? 1.0 : 0.3,
                    child: const Icon(
                      Icons.graphic_eq,
                      size: 80,
                      color: Colors.white24,
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
                  const Text(
                    'LIVE SPECTROGRAM ANALYSIS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Obx(() {
            if (controller.topPredictions.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        size: 48,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.isMonitoring.value 
                          ? 'Waiting for audio input...'
                          : 'Monitoring is offline',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final prediction = controller.topPredictions[index];
                    return _buildPredictionTile(context, prediction, index == 0);
                  },
                  childCount: controller.topPredictions.length,
                ),
              ),
            );
          }),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
        onPressed: controller.toggleMonitoring,
        elevation: 4,
        label: Text(
          controller.isMonitoring.value ? 'STOP MONITORING' : 'START MONITORING',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
        ),
        icon: Icon(controller.isMonitoring.value ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white),
        backgroundColor: controller.isMonitoring.value ? Colors.redAccent : Colors.teal,
      )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() => Container(
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
              _buildPulseIndicator(controller.isMonitoring.value),
              const SizedBox(width: 12),
              Text(
                controller.isMonitoring.value ? 'SYSTEM ACTIVE' : 'SYSTEM READY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: controller.isMonitoring.value ? Colors.teal : Colors.grey,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            controller.isMonitoring.value 
              ? 'YAMNet is currently classifying sounds at 16,000Hz.'
              : 'The neural network is ready to analyze your surroundings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildPulseIndicator(bool active) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.teal : Colors.grey[300],
        boxShadow: active ? [
          BoxShadow(
            color: Colors.teal.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ] : null,
      ),
    );
  }

  Widget _buildPredictionTile(BuildContext context, MapEntry<String, double> prediction, bool isTop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confidence = prediction.value;
    final color = _getColorForConfidence(confidence);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isTop ? Border.all(color: Colors.teal.withOpacity(0.3), width: 2) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    prediction.key,
                    style: TextStyle(
                      fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                      fontSize: isTop ? 18 : 16,
                    ),
                  ),
                ),
                Text(
                  '${(confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: confidence,
                minHeight: 8,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForConfidence(double confidence) {
    if (confidence > 0.7) return Colors.teal;
    if (confidence > 0.4) return Colors.orange;
    return Colors.grey;
  }
}

