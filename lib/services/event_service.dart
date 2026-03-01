import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('events');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // --- Helpers
  Timestamp _combineToTimestamp(String date, String time) {
    final d = DateTime.parse(date); // YYYY-MM-DD
    final p = time.split(":");
    final hour = int.parse(p[0]);
    final minute = int.parse(p[1]);
    return Timestamp.fromDate(DateTime(d.year, d.month, d.day, hour, minute));
  }

  // ✅ CREATE (writes both "about" and "description" to avoid mismatch)
  Future<String> createEvent({
    required String title,
    required String about,
    required String category,
    required String location,
    required String date,
    required String time,
    required String imageUrl,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception("You are not logged in. Please login as organizer.");
    }

    final eventTs = _combineToTimestamp(date, time);

    final doc = await _events.add({
      // common names
      "title": title,
      "name": title, // ✅ if some UI uses name

      "about": about,
      "description": about, // ✅ if some UI uses description

      "category": category,
      "location": location,

      "date": date,
      "time": time,
      "eventDateTime": eventTs,

      "imageUrl": imageUrl,

      "organizerId": uid,
      "createdAt": FieldValue.serverTimestamp(),

      // ✅ make it visible immediately (for now)
      "approved": true,
      "status": "active",
    });

    return doc.id;
  }

  // ✅ UPDATE
  Future<void> updateEvent({
    required String eventId,
    required Map<String, dynamic> updates,
  }) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception("You are not logged in. Please login as organizer.");
    }

    // If date+time updated, keep eventDateTime always updated
    final updated = Map<String, dynamic>.from(updates);

    final String? newDate = updated["date"]?.toString();
    final String? newTime = updated["time"]?.toString();
    if (newDate != null &&
        newTime != null &&
        newDate.isNotEmpty &&
        newTime.isNotEmpty) {
      updated["eventDateTime"] = _combineToTimestamp(newDate, newTime);
    }

    // Keep duplicates for UI mismatch safety
    if (updated.containsKey("title")) updated["name"] = updated["title"];
    if (updated.containsKey("about")) updated["description"] = updated["about"];

    await _events.doc(eventId).update({
      ...updated,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // ✅ DELETE
  Future<void> deleteEvent(String eventId) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception("You are not logged in. Please login as organizer.");
    }
    await _events.doc(eventId).delete();
  }

  // ✅ STREAMS (IMPORTANT: NO orderBy to avoid composite index issues)
  // We'll sort in UI instead.
  Stream<QuerySnapshot<Map<String, dynamic>>> myEventsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _events.where("organizerId", isEqualTo: uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> dashboardStream() {
    // show all, filter/sort in UI (avoids index errors)
    return _events.snapshots();
  }
}
