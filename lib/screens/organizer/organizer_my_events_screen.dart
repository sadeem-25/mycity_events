import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../services/event_service.dart';
import 'organizer_create_event_screen.dart';

class OrganizerMyEventsScreen extends StatefulWidget {
  const OrganizerMyEventsScreen({super.key});

  @override
  State<OrganizerMyEventsScreen> createState() =>
      _OrganizerMyEventsScreenState();
}

class _OrganizerMyEventsScreenState extends State<OrganizerMyEventsScreen> {
  static const Color primaryColor = Color(0xFFFF6A00);
  final _service = EventService();

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _openEdit(String id, Map<String, dynamic> data) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizerCreateEventScreen(
          mode: OrganizerCreateMode.edit,
          eventId: id,
          existingData: data,
        ),
      ),
    );

    if (changed == true && mounted) setState(() {});
  }

  Future<bool> _confirmDelete() async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete event?"),
            content: const Text("This will remove the event permanently."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
        )) ??
        false;
  }

  Future<void> _delete(String eventId) async {
    final ok = await _confirmDelete();
    if (!ok) return;

    try {
      await _service.deleteEvent(eventId);

      if (!mounted) return;
      _snack("Deleted ✅");
      setState(() {});
    } catch (e) {
      _snack("Delete failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ One StreamBuilder controls BOTH:
    // - the AppBar "events created" count
    // - the list
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.myEventsStream(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: primaryColor,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "My Events",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$count events created",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          body: Builder(
            builder: (_) {
              if (snap.hasError) {
                return Center(child: Text("Error: ${snap.error}"));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No events yet."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data();

                  final title = (data["title"] ?? "").toString();
                  final desc = (data["about"] ?? data["description"] ?? "")
                      .toString();
                  final category = (data["category"] ?? "").toString();
                  final location = (data["location"] ?? "").toString();
                  final date = (data["date"] ?? "").toString();
                  final time = (data["time"] ?? "").toString();

                  // ✅ Image field fallback (in case you saved a different key)
                  final imageUrl =
                      (data["imageUrl"] ??
                              data["imageURL"] ??
                              data["image"] ??
                              data["photoUrl"] ??
                              data["eventImage"] ??
                              "")
                          .toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _EventCard(
                      title: title,
                      description: desc,
                      category: category,
                      location: location,
                      date: date,
                      time: time,
                      imageUrl: imageUrl,
                      onEdit: () => _openEdit(doc.id, data),
                      onDelete: () => _delete(doc.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final String description;
  final String category;
  final String location;
  final String date;
  final String time;
  final String imageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    required this.time,
    required this.imageUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1.4,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 8,
              child: _EventImage(imageUrl: imageUrl),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? "Untitled" : title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == "edit") onEdit();
                        if (v == "delete") onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "edit", child: Text("Edit")),
                        PopupMenuItem(value: "delete", child: Text("Delete")),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (description.trim().isNotEmpty)
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time.trim().isEmpty ? date : "$date • $time",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (category.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEE0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Color(0xFFFF6A00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Fixes image issue:
/// - If your Firestore stores "gs://..." we convert it to a download URL.
/// - If it stores "https://..." we show it normally.
class _EventImage extends StatelessWidget {
  final String imageUrl;
  const _EventImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl.trim();

    if (raw.isEmpty) {
      return Container(
        color: Colors.black12,
        child: const Center(child: Icon(Icons.image, size: 40)),
      );
    }

    // ✅ If saved as Firebase Storage path (gs://...), convert to https URL
    if (raw.startsWith("gs://")) {
      return FutureBuilder<String>(
        future: FirebaseStorage.instance.refFromURL(raw).getDownloadURL(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return Image.network(
            snap.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.black12,
              child: const Center(child: Icon(Icons.broken_image, size: 40)),
            ),
          );
        },
      );
    }

    // ✅ Normal https image
    return Image.network(
      raw,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.black12,
        child: const Center(child: Icon(Icons.broken_image, size: 40)),
      ),
    );
  }
}
