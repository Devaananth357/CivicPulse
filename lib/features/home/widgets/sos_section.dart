import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../sos_provider.dart';
import '../../emergency/report_emergency_screen.dart';

class SOSSection extends StatelessWidget {
  const SOSSection({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final sosProvider = context.watch<SosProvider>();
    final userId = authProvider.appUser?.uid ?? 'unknown_user';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 1,
                color: AppColors.primaryStrong.withOpacity(0.3),
              ),
              const SizedBox(width: 12),
              Text(
                'EMERGENCY? ACT NOW',
                style: TextStyle(
                  color: AppColors.primaryStrong,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 20,
                height: 1,
                color: AppColors.primaryStrong.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onLongPress: sosProvider.isSending 
                ? null 
                : () async {
                    try {
                      await sosProvider.sendSOS(userId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🚨 SOS Alert Broadcasted Successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚠️ Failed to send SOS: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF544C),
                    Color(0xFFFF7A70),
                  ],
                ),
                borderRadius: BorderRadius.circular(44),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF544C).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF544C).withOpacity(0.15),
                    blurRadius: 60,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: sosProvider.isSending
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 6,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'S.O.S',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'HOLD 3 SEC',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ReportEmergencyScreen()),
                );
              },
              icon: const Icon(Icons.report_problem_outlined, size: 20),
              label: const Text(
                'REPORT SPECIFIC INCIDENT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceLow,
                foregroundColor: AppColors.textSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.textSecondary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
