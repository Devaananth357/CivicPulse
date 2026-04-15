import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:civic_pulse/models/incident.dart';

class AlertCard extends StatelessWidget {
  final Incident? incident;

  const AlertCard({super.key, this.incident});

  @override
  Widget build(BuildContext context) {
    if (incident == null) {
      return const SizedBox.shrink(); // Hide if no active incident
    }

    final timeAgo = DateTime.now().difference(incident!.createdAt);
    final timeString = timeAgo.inMinutes < 60 
        ? '${timeAgo.inMinutes}m ago' 
        : '${timeAgo.inHours}h ago';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryStrong.withOpacity(0.3),
              AppColors.surfaceLow,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryStrong.withOpacity(0.12),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryStrong,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryStrong.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      incident!.severity.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    timeString,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${incident!.type.toUpperCase()} — ${incident!.location}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                incident!.description,
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.75),
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const _AiTag(label: 'VERIFIED', icon: Icons.shutter_speed_rounded),
                  const SizedBox(width: 8),
                  _AiTag(
                    label: 'CONFIDENCE: ${incident!.aiConfidence}%', 
                    icon: Icons.analytics_rounded
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _AiTag(
                    label: 'ANALYSIS: ${incident!.aiAnalysisTime}', 
                    icon: Icons.bolt_rounded
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiTag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _AiTag({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF000000).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.surfaceHigh.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
