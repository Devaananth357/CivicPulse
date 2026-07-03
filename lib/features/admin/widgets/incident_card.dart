import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/incident.dart';
import 'incident_details_dialog.dart';

class IncidentCard extends StatefulWidget {
  final Incident incident;
  final VoidCallback? onTap;

  const IncidentCard({super.key, required this.incident, this.onTap});

  @override
  State<IncidentCard> createState() => _IncidentCardState();
}

class _IncidentCardState extends State<IncidentCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 70),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSos = widget.incident.isSos;
    final Color accentColor = isSos ? Colors.redAccent : _getSeverityColor(widget.incident.severity);
    final String timeAgo = _formatTimeAgo(widget.incident.createdAt);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, animatedChild) {
            return GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.05 + (_glowAnimation.value * 0.1)),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSos 
                          ? Colors.red.withOpacity(0.1 + (_glowAnimation.value * 0.05))
                          : const Color(0xFF132D3E).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSos
                            ? Colors.redAccent.withOpacity(0.5 + (_glowAnimation.value * 0.5))
                            : accentColor.withOpacity(0.2 + (_glowAnimation.value * 0.3)),
                        width: isSos ? 2.5 : 1.5,
                      ),
                      boxShadow: isSos ? [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.2 * _glowAnimation.value),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ] : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _buildBadge(isSos ? "EMERGENCY SOS" : widget.incident.type, accentColor),
                                const SizedBox(width: 8),
                                _buildStatusBadge(widget.incident.status),
                                if (widget.incident.backupRequests.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  ...widget.incident.backupRequests.map((type) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: _buildBadge("NEEDS ${type.toUpperCase()}", Colors.orangeAccent),
                                  )),
                                ],
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  timeAgo.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) => IncidentDetailsDialog(incident: widget.incident),
                                  ),
                                  icon: const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blueAccent),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isSos 
                                  ? "🚨 SOS SIGNAL DETECTED @ ${widget.incident.location}"
                                  : "${widget.incident.type.toUpperCase()} @ ${widget.incident.location}",
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (widget.incident.status == 'completed') ...[
                              const SizedBox(width: 8),
                              _buildBadge("COMPLETED", Colors.greenAccent),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.incident.description.isEmpty ? "No description provided." : widget.incident.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        if (widget.incident.status == 'completed' && widget.incident.remarks != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.greenAccent.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "ADMIN COMPLETION REMARKS",
                                  style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.incident.remarks!,
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildVerificationStat(Icons.check_circle_rounded, "CONFIRMED", widget.incident.confirmCount.toString(), Colors.greenAccent),
                            const SizedBox(width: 16),
                            _buildVerificationStat(Icons.cancel_rounded, "DENIED", widget.incident.denyCount.toString(), Colors.redAccent),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "AI CONFIDENCE: ",
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  "${widget.incident.aiConfidence}%",
                                  style: TextStyle(
                                    color: _getConfidenceColor(widget.incident.aiConfidence),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "Analyzed in 0.8s",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.1),
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    bool isPulse = false;

    switch (status.toLowerCase()) {
      case 'assigned':
        color = Colors.blueAccent;
        text = "ASSIGNED";
        isPulse = true;
        break;
      case 'in_progress':
        color = Colors.greenAccent;
        text = "IN PROGRESS";
        break;
      case 'completion_pending':
        color = Colors.orangeAccent;
        text = "PENDING SIGN-OFF";
        break;
      case 'completed':
        color = Colors.white24;
        text = "COMPLETED";
        break;
      default:
        color = Colors.white10;
        text = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPulse) ...[
            _StatusPulse(color: color),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStat(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          "$value $label",
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.greenAccent;
      default:
        return Colors.blueAccent;
    }
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 80) return Colors.greenAccent;
    if (confidence >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return DateFormat('HH:mm').format(dateTime);
  }
}

class _StatusPulse extends StatefulWidget {
  final Color color;
  const _StatusPulse({required this.color});

  @override
  State<_StatusPulse> createState() => _StatusPulseState();
}

class _StatusPulseState extends State<_StatusPulse> with SingleTickerProviderStateMixin {
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
