import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/event_service.dart';

class OrganizerDashboardScreen extends StatelessWidget {
  const OrganizerDashboardScreen({super.key});

  static const primaryColor = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    final service = EventService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.dashboardStream(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text("Error: ${snap.error}"));
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          final totalEvents = docs.length;

          // Example metrics
          final totalViews = docs.fold<int>(
            0,
            (sum, d) => sum + ((d.data()["views"] ?? 0) as int),
          );
          final totalInterested = docs.fold<int>(
            0,
            (sum, d) => sum + ((d.data()["interestedCount"] ?? 0) as int),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _metricCard("Total Events", totalEvents.toString()),
                  const SizedBox(width: 12),
                  _metricCard("Total Views", totalViews.toString()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _metricCard("Interested Users", totalInterested.toString()),
                  const SizedBox(width: 12),
                  _metricCard("Active Events", totalEvents.toString()),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                "Recent Activity",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: docs.isEmpty
                    ? const Text("No activity yet")
                    : Column(
                        children: docs.take(6).map((d) {
                          final e = d.data();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text((e["title"] ?? "").toString()),
                                ),
                                Text(
                                  "+${(e["interestedCount"] ?? 0).toString()} interested",
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
