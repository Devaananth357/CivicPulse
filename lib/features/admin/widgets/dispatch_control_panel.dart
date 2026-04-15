import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dispatch_provider.dart';
import '../../../models/responder.dart';

class DispatchControlPanel extends StatelessWidget {
  const DispatchControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DispatchProvider>(
      builder: (context, provider, _) {
        final incident = provider.selectedIncident;
        if (incident == null) {
          return Container(
            width: 380,
            decoration: const BoxDecoration(
              color: Color(0xFF030D16),
              border: Border(left: BorderSide(color: Colors.white10)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_customize_rounded, color: Colors.white10, size: 48),
                  const SizedBox(height: 16),
                  const Text("NO INCIDENT SELECTED", style: TextStyle(color: Colors.white10, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  const Text("Select a feed item to initiate dispatch", style: TextStyle(color: Colors.white10, fontSize: 10)),
                ],
              ),
            ),
          );
        }

        return Container(
          width: 380,
          decoration: BoxDecoration(
            color: const Color(0xFF081521).withOpacity(0.95),
            border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 40, offset: const Offset(-20, 0)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, provider),
              _buildStatusSection(incident.status),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    if (incident.status == 'completed')
                      _buildCompletedHistoryView(context, incident)
                    else ...[
                      if (incident.assignedResponderIds.isNotEmpty)
                        _buildCurrentlyAssignedUnits(context, incident),
                      
                      const SizedBox(height: 24),
                      const Text(
                        "DISPATCH NEW UNIT",
                        style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                      const SizedBox(height: 16),
                      if (provider.suggestedResponders.isEmpty)
                        _buildNoRespondersView()
                      else
                        ...provider.suggestedResponders
                            .where((res) => !incident.assignedResponderIds.contains((res['responder'] as Responder).id))
                            .map((data) {
                          return _buildResponderCard(context, provider, data['responder'] as Responder, data['distance'] as double, false);
                        }),
                      
                      const SizedBox(height: 32),
                      if (incident.assignedResponderIds.isNotEmpty)
                        _buildMissionSummaryAction(context, provider),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoRespondersView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Icon(Icons.gps_off_rounded, color: Colors.white12, size: 32),
          SizedBox(height: 12),
          Text("No matching units available nearby. Checking backup sectors...", textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DispatchProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("UNIT DISPATCH", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  SizedBox(height: 4),
                  Text("ALLOCATION CONTROL CENTER", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
              IconButton(
                onPressed: () => provider.clearSelection(),
                icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white24, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(String status) {
    bool isActive = status == 'in_progress' || status == 'assigned' || status == 'completion_pending';
    bool isPending = status == 'completion_pending';
    
    final Color color = isPending ? Colors.orangeAccent : (isActive ? Colors.blueAccent : Colors.white24);
    
    String label;
    if (isPending) {
      label = "COMPLETION REQUESTED";
    } else if (status == 'assigned') {
      label = "RESPONDER NOTIFIED";
    } else if (status == 'in_progress') {
      label = "RESPONDER EN ROUTE";
    } else if (status == 'completed') {
      label = "MISSION COMPLETED";
    } else {
      label = "MANUAL OVERRIDE ACTIVE";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentlyAssignedUnits(BuildContext context, dynamic incident) {
    final responders = incident.responderDetails ?? {};
    final ids = incident.assignedResponderIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "UNITS ON MISSION",
          style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ids.length,
            itemBuilder: (context, index) {
              final rid = ids[index];
              final details = responders[rid] ?? {};
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: details['imageUrl'] != null ? NetworkImage(details['imageUrl']) : null,
                      backgroundColor: Colors.white10,
                      child: details['imageUrl'] == null ? const Icon(Icons.person, color: Colors.white24) : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details['name'] ?? 'Unit',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      details['specialization'] ?? 'Unit',
                      style: const TextStyle(color: Colors.white38, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMissionSummaryAction(BuildContext context, DispatchProvider provider) {
    final incident = provider.selectedIncident!;
    final isPending = incident.status == 'completion_pending';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPending ? Colors.orangeAccent.withOpacity(0.1) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPending ? Colors.orangeAccent.withOpacity(0.3) : Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(isPending ? Icons.notification_important_rounded : Icons.check_circle_outline, 
                color: isPending ? Colors.orangeAccent : Colors.white38, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isPending ? "COMPLETION REQUESTED BY FIELD AGENTS" : "MISSION OPERATIONAL",
                  style: TextStyle(color: isPending ? Colors.orangeAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCompletionDialog(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending ? Colors.orangeAccent : Colors.white.withOpacity(0.1),
                foregroundColor: isPending ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isPending ? "FINAL SIGN-OFF" : "CLOSE MISSION", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedHistoryView(BuildContext context, dynamic incident) {
    final responders = incident.responderDetails ?? {};
    final ids = incident.assignedResponderIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MISSION SUMMARY",
          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ASSIGNED TEAM", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...ids.map((rid) {
                final details = responders[rid] ?? {};
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: details['imageUrl'] != null ? NetworkImage(details['imageUrl']) : null,
                        backgroundColor: Colors.white10,
                      ),
                      const SizedBox(width: 12),
                      Text(details['name'] ?? 'Unit', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(details['specialization'] ?? 'Unit', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
              const Divider(color: Colors.white10, height: 32),
              const Text("CLOSURE REMARKS", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                incident.remarks ?? "No remarks provided.",
                style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCompletionDialog(BuildContext context, DispatchProvider provider) async {
    final TextEditingController remarkController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1D2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Complete Mission", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Provide a final remark for the incident log:", style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: remarkController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g., Fire extinguished, victim stabilized.",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              if (remarkController.text.trim().isEmpty) return;
              await provider.completeSelectedIncident(remarkController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
            child: const Text("SUBMIT & CLOSE"),
          ),
        ],
      ),
    );
  }

  Widget _buildResponderCard(BuildContext context, DispatchProvider provider, Responder responder, double distance, bool isRecommended) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        border: Border.all(
          color: isRecommended ? Colors.blueAccent.withOpacity(0.4) : Colors.white.withOpacity(0.05),
          width: isRecommended ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isRecommended ? Colors.blueAccent : Colors.transparent, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(responder.imageUrl),
                    backgroundColor: Colors.white10,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(responder.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (distance > 4000 || (responder.latitude == 0 && responder.longitude == 0))
                        const Text("GPS SIGNAL PENDING", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold))
                      else
                        Text("${distance.toStringAsFixed(1)} KM AWAY", style: TextStyle(color: isRecommended ? Colors.blueAccent : Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(responder.specialization.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () => provider.manualAssign(responder.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecommended ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(100, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("ASSIGN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
