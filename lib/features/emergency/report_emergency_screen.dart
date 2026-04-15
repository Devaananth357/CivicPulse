import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';
import 'package:civic_pulse/features/emergency/emergency_provider.dart';

class ReportEmergencyScreen extends StatelessWidget {
  const ReportEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch for state changes
    final emergencyProvider = context.watch<EmergencyProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    // Get current user ID
    final userId = authProvider.appUser?.uid ?? 'unknown_user';

    // Emergency types configuration
    final emergencyTypes = [
      {'label': 'Medical', 'icon': Icons.medical_services_rounded, 'color': Colors.redAccent},
      {'label': 'Fire', 'icon': Icons.fire_truck_rounded, 'color': Colors.orangeAccent},
      {'label': 'Crime', 'icon': Icons.security_rounded, 'color': Colors.blueAccent},
      {'label': 'Other', 'icon': Icons.more_horiz_rounded, 'color': Colors.blueGrey},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Emergency Report',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What type of emergency?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select one of the categories below to get help quickly.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.1,
                ),
                itemCount: emergencyTypes.length,
                itemBuilder: (context, index) {
                  final type = emergencyTypes[index];
                  final label = type['label'] as String;
                  final color = type['color'] as Color;
                  final icon = type['icon'] as IconData;
                  final isSelected = emergencyProvider.selectedType == label;

                  return GestureDetector(
                    onTap: () => emergencyProvider.setSelectedType(label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? color.withOpacity(0.15) 
                            : AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 0,
                          )
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 32,
                            color: isSelected ? color : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Description',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => emergencyProvider.setDescription(value),
                maxLines: 5,
                minLines: 3,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Describe what’s happening...',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                  fillColor: AppColors.surfaceLow,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: AppColors.primaryStrong,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Attach Evidence (Optional)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: emergencyProvider.isUploading ? null : () => emergencyProvider.pickImage(),
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: emergencyProvider.imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(emergencyProvider.imageFile!, fit: BoxFit.cover),
                              if (emergencyProvider.isUploading)
                                Container(
                                  color: Colors.black45,
                                  child: const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                                ),
                              if (!emergencyProvider.isUploading)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => emergencyProvider.resetImage(),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, color: AppColors.textSecondary, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to take a photo',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),
              
              const Text(
                'Audio Evidence (Optional)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              GestureDetector(
                onLongPressStart: (_) => emergencyProvider.startRecording(),
                onLongPressEnd: (_) => emergencyProvider.stopRecording(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: emergencyProvider.isRecording 
                        ? Colors.red.withOpacity(0.1) 
                        : AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: emergencyProvider.isRecording 
                          ? Colors.red 
                          : AppColors.textSecondary.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (emergencyProvider.isAudioUploading)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Uploading Audio...', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        )
                      else if (emergencyProvider.audioUrl != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            const Text('Audio Evidence Attached', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              onPressed: () => emergencyProvider.resetAudio(),
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            )
                          ],
                        )
                      else
                        Column(
                          children: [
                            Icon(
                              emergencyProvider.isRecording ? Icons.mic : Icons.mic_none_rounded, 
                              color: emergencyProvider.isRecording ? Colors.red : AppColors.textSecondary, 
                              size: 40
                            ),
                            const SizedBox(height: 12),
                            Text(
                              emergencyProvider.isRecording ? 'RECORDING... RELEASE TO STOP' : 'HOLD TO RECORD AUDIO',
                              style: TextStyle(
                                color: emergencyProvider.isRecording ? Colors.red : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              // Helpful Hint
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your location will be sent automatically with the report.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // AI Assessment Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI Assessment',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: emergencyProvider.currentAnalysis.severity == 'high' 
                                ? Colors.red.withOpacity(0.2)
                                : emergencyProvider.currentAnalysis.severity == 'medium'
                                    ? Colors.orange.withOpacity(0.2)
                                    : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            emergencyProvider.currentAnalysis.severity.toUpperCase(),
                            style: TextStyle(
                              color: emergencyProvider.currentAnalysis.severity == 'high' 
                                  ? Colors.redAccent
                                  : emergencyProvider.currentAnalysis.severity == 'medium'
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: emergencyProvider.currentAnalysis.confidence / 100,
                              minHeight: 12, // Slightly taller for better visual
                              backgroundColor: AppColors.surfaceHigh,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                emergencyProvider.currentAnalysis.severity == 'high' 
                                    ? Colors.redAccent
                                    : emergencyProvider.currentAnalysis.severity == 'medium'
                                        ? Colors.orangeAccent
                                        : Colors.greenAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...emergencyProvider.currentAnalysis.reasons.take(3).map((reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: (emergencyProvider.isSubmitting || emergencyProvider.isUploading || emergencyProvider.isAudioUploading)
                      ? null
                      : () async {
                          try {
                            final userName = authProvider.appUser?.displayName ?? 'Anonymous User';
                            await emergencyProvider.submitReport(userId, userName);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Text('${emergencyProvider.selectedType} Emergency Reported'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to submit: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryStrong,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primaryStrong.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primaryStrong.withOpacity(0.5),
                  ),
                  child: emergencyProvider.isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          emergencyProvider.isUploading 
                              ? 'UPLOADING PHOTO...' 
                              : emergencyProvider.isAudioUploading 
                                  ? 'UPLOADING AUDIO...' 
                                  : 'SUBMIT REPORT',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
