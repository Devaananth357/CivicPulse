import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/incident.dart';
import '../providers/dispatch_provider.dart';

class IncidentDetailsDialog extends StatelessWidget {
  final Incident incident;

  const IncidentDetailsDialog({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: 600,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1D2A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Image Area
                _buildImageSection(context),
                
                // Content Area
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildDetailRow(Icons.location_on_rounded, "LOCATION", incident.location),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.description_rounded, "DESCRIPTION", incident.description),
                      const SizedBox(height: 24),
                      if (incident.audioUrl != null && incident.audioUrl!.isNotEmpty) ...[
                        _buildAudioSection(context),
                        const SizedBox(height: 24),
                      ],
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 24),
                      _buildActionPanel(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: incident.imageUrl != null && incident.imageUrl!.isNotEmpty
              ? Image.network(
                  incident.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_rounded, color: Colors.white.withOpacity(0.1), size: 48),
          const SizedBox(height: 12),
          Text("NO VERIFICATION IMAGE", style: TextStyle(color: Colors.white.withOpacity(0.1), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getSeverityColor(incident.severity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _getSeverityColor(incident.severity).withOpacity(0.3)),
              ),
              child: Text(
                incident.severity.toUpperCase(),
                style: TextStyle(color: _getSeverityColor(incident.severity), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              incident.type.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          incident.title.isEmpty ? "Untitled Emergency" : incident.title,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blueAccent.withOpacity(0.5), size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionPanel(BuildContext context) {
    final dispatchProvider = Provider.of<DispatchProvider>(context);
    
    return Column(
      children: [
        // AI Insights Panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("AI ANALYSIS INSIGHTS", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  if (incident.aiAnalysisTime.isNotEmpty)
                    Text(incident.aiAnalysisTime, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildInsightItem("CONFIDENCE", "${incident.aiConfidence}%", _getConfidenceColor(incident.aiConfidence)),
                  const SizedBox(width: 24),
                  _buildInsightItem("PRIORITY", (incident.aiPriority ?? "PENDING").toUpperCase(), _getPriorityColor(incident.aiPriority)),
                  const SizedBox(width: 24),
                  _buildInsightItem("SEVERITY", (incident.severity).toUpperCase(), _getSeverityColor(incident.severity)),
                ],
              ),
              if (incident.aiReasoning != null) ...[
                const SizedBox(height: 20),
                const Text("REASONING", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  incident.aiReasoning!,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: dispatchProvider.isAnalyzing 
                ? null 
                : () => dispatchProvider.analyzeIncident(incident.id!),
              icon: dispatchProvider.isAnalyzing 
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
                : const Icon(Icons.psychology_rounded, size: 18),
              label: Text(dispatchProvider.isAnalyzing ? "RE-ANALYZING..." : "RE-ANALYZE WITH AI"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                foregroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.blueAccent)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await _showDeleteConfirm(context);
                if (confirm == true) {
                  await Provider.of<DispatchProvider>(context, listen: false).deleteIncidentById(context, incident.id!);
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text("REMOVE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudioSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("AUDIO EVIDENCE",
            style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.blueAccent, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Emergency Voice Recording",
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text("Audio Evidence from Scene", style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final url = Uri.parse(incident.audioUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.blueAccent),
                label: const Text("PLAY",
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.blueAccent.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1D2A),
        title: const Text("Confirm Deletion", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to remove this incident from the system? This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.orangeAccent;
      case 'low': return Colors.greenAccent;
      default: return Colors.blueAccent;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.orangeAccent;
      case 'low': return Colors.greenAccent;
      default: return Colors.white24;
    }
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 80) return Colors.greenAccent;
    if (confidence >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
