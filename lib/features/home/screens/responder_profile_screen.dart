import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/responder_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ResponderProfileScreen extends StatelessWidget {
  const ResponderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ResponderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final responder = provider.currentResponder;

    if (responder == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF030D16),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            backgroundColor: const Color(0xFF0B1D2A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blueAccent.withOpacity(0.2), const Color(0xFF030D16)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: responder.imageUrl.isNotEmpty 
                            ? NetworkImage(responder.imageUrl) 
                            : null,
                          backgroundColor: Colors.white10,
                          child: responder.imageUrl.isEmpty 
                            ? const Icon(Icons.person, size: 50, color: Colors.white24) 
                            : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          responder.name,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                          ),
                          child: Text(
                            responder.specialization.toUpperCase(),
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text("CONTACT INFORMATION", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildInfoTile(Icons.email_outlined, "Email Address", responder.email),
                  _buildInfoTile(Icons.phone_outlined, "Mobile Number", responder.phone),
                  const SizedBox(height: 32),
                  const Text("MISSION STATISTICS", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatBox("COMPLETED", responder.missionsCompleted.toString(), Colors.greenAccent)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatBox("RATING", responder.rating.toStringAsFixed(1), Colors.orangeAccent)),
                    ],
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ).asButton(
                      onPressed: () => authProvider.signOut(),
                      child: const Text("SIGN OUT ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

extension on ButtonStyle {
  Widget asButton({required VoidCallback onPressed, required Widget child}) {
    return OutlinedButton(onPressed: onPressed, style: this, child: child);
  }
}
