import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/incident.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/chat_screen.dart';

class ResponderTrackerCard extends StatelessWidget {
  final Incident? incident;

  const ResponderTrackerCard({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    if (incident == null || incident!.status == 'completed') return const SizedBox.shrink();

    // The feature activates when assignedResponderId is present
    final isAssigned = incident!.assignedResponderIds.isNotEmpty;
    final responder = incident!.responderDetail;
    
    // Debug logging to help identify why a responder might not show
    print("🕵️ ResponderTracker: Status: ${incident!.status}, AssignedIDs: ${incident!.assignedResponderIds}, hasDetail: ${responder != null}");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: isAssigned && responder != null
            ? _buildResponderCard(context, responder)
            : _buildSearchingCard(context),
      ),
    );
  }

  Widget _buildSearchingCard(BuildContext context) {
    return Container(
      key: const ValueKey('searching'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 32,
            width: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Searching for responders...",
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponderCard(BuildContext context, Map<String, dynamic> responder) {
    return Container(
      key: const ValueKey('responder'),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceLow.withOpacity(0.8),
                  AppColors.surfaceLow.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "HELP IS ON THE WAY",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          incident!.status == 'assigned' ? "Unit Dispatched" : "Responder is on the way",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _buildAIConfidenceBadge(),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildProfileImage(responder['imageUrl']),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            responder['name'] ?? 'Responder Agent',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Certified Responder",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSpecializationBadge(responder['specialization'] ?? 'Emergency'),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildChatButton(context),
                        const SizedBox(width: 12),
                        _buildCallButton(responder['phone']),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildETATile(),
                    const Row(
                      children: [
                         _PulseDot(color: Colors.greenAccent),
                         SizedBox(width: 8),
                         Text(
                          "LIVE TRACKING ACTIVE",
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? url) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty 
            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildAvatarFallback(),) 
            : _buildAvatarFallback(),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: AppColors.surfaceHigh,
      child: const Icon(Icons.person, color: Colors.white24, size: 30),
    );
  }

  Widget _buildSpecializationBadge(String spec) {
    final isMedical = spec.toLowerCase().contains('medical');
    final isFire = spec.toLowerCase().contains('fire');
    final color = isMedical ? Colors.blueAccent : (isFire ? Colors.orangeAccent : Colors.tealAccent);
    final icon = isMedical ? Icons.medical_services : (isFire ? Icons.local_fire_department : Icons.security);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            spec.toUpperCase(),
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAIConfidenceBadge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
         Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.blueAccent, size: 10),
              SizedBox(width: 6),
              Text("AI VERIFIED", style: TextStyle(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${incident?.aiConfidence ?? 0}% CONFIDENCE",
          style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCallButton(String? phoneNumber) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10),
      ),
      child: IconButton(
        icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 22),
        onPressed: () => _handleCall(phoneNumber),
      ),
    );
  }

  Widget _buildChatButton(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 20),
        onPressed: () => _handleChat(context),
      ),
    );
  }

  void _handleCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri url = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      print("Error launching dialer: $e");
    }
  }

  void _handleChat(BuildContext context) {
    if (incident?.id == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          incidentId: incident!.id!,
          otherPartyName: incident!.responderDetails?['name'] ?? 'Responder',
        ),
      ),
    );
  }

  Widget _buildETATile() {
    return Row(
      children: [
        Icon(Icons.access_time_filled_rounded, color: Colors.white.withOpacity(0.4), size: 16),
        const SizedBox(width: 10),
        const Text(
          "ARRIVING IN ~4 MIN",
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
