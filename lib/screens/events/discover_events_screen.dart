import 'package:flutter/material.dart';
import 'event_details_screen.dart';

class DiscoverEventsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> interestedEvents;
  final VoidCallback onOpenInterests;

  const DiscoverEventsScreen({
    super.key,
    required this.interestedEvents,
    required this.onOpenInterests,
  });

  @override
  State<DiscoverEventsScreen> createState() => _DiscoverEventsScreenState();
}

class _DiscoverEventsScreenState extends State<DiscoverEventsScreen> {
  // Main orange color used in the app
  final Color primaryColor = const Color(0xFFFF6A00);

  // ---------------- FILTER STATE (Front-end only) ----------------
  bool showFilters = false;

  String? selectedCategory; // null = All
  String? selectedLocation; // null = All
  DateTime? selectedDate; // null = All (day match)

  // Temporary event list (later will come from Firebase)
  final List<Map<String, dynamic>> eventList = [
    {
      "title": "City Marathon",
      "date": "2026-11-15",
      "time": "06:00",
      "location": "King Abdullah Financial District, Riyadh",
      "category": "Sports",
      "image": "assets/halapartners_SFA_RM_23.jpg",
      "about":
          "Join the annual City Marathon in Riyadh. Choose between 5K, 10K, or full marathon. Open for all fitness levels.",
      "organizer": "Riyadh Sports Committee",
      "isFavorite": false,
    },
    {
      "title": "Art Exhibition",
      "date": "2026-10-02",
      "time": "18:00",
      "location": "Diriyah, Riyadh",
      "category": "Art",
      "image": "assets/event_placeholder.jpg.jpg",
      "about":
          "Explore modern and traditional artworks by local artists. Enjoy live painting sessions and creative workshops.",
      "organizer": "Diriyah Art Society",
      "isFavorite": false,
    },
  ];

  // ---------------- Helpers for dropdown options ----------------
  List<String> get categories {
    final set = <String>{};
    for (final e in eventList) {
      final c = (e["category"] ?? "").toString().trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get locations {
    // Full location is long; we still filter by exact string.
    // (If you want city-only later, we can extract "Riyadh" from the end.)
    final set = <String>{};
    for (final e in eventList) {
      final l = (e["location"] ?? "").toString().trim();
      if (l.isNotEmpty) set.add(l);
    }
    final list = set.toList()..sort();
    return list;
  }

  // Parse "YYYY-MM-DD" safely
  DateTime? _parseEventDate(String? date) {
    if (date == null) return null;
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  // ---------------- FRONT-END FILTERING ----------------
  List<Map<String, dynamic>> get filteredEvents {
    return eventList.where((event) {
      // Category filter
      final matchCategory = selectedCategory == null
          ? true
          : (event["category"] == selectedCategory);

      // Location filter
      final matchLocation = selectedLocation == null
          ? true
          : (event["location"] == selectedLocation);

      // Date filter (same day)
      bool matchDate = true;
      if (selectedDate != null) {
        final eventDate = _parseEventDate(event["date"]?.toString());
        if (eventDate == null) {
          matchDate = false;
        } else {
          matchDate =
              eventDate.year == selectedDate!.year &&
              eventDate.month == selectedDate!.month &&
              eventDate.day == selectedDate!.day;
        }
      }

      return matchCategory && matchLocation && matchDate;
    }).toList();
  }

  // Toggle favorite icon
  void toggleFavorite(int indexInFiltered) {
    // IMPORTANT: your list is filtered now, so index is for filteredEvents.
    // We must find the same event in the original eventList.
    final filtered = filteredEvents;
    final event = filtered[indexInFiltered];

    final originalIndex = eventList.indexOf(event);

    if (originalIndex == -1) return;

    setState(() {
      eventList[originalIndex]["isFavorite"] =
          !(eventList[originalIndex]["isFavorite"] as bool);

      if (eventList[originalIndex]["isFavorite"]) {
        widget.interestedEvents.add(eventList[originalIndex]);
        widget.onOpenInterests();
      } else {
        widget.interestedEvents.remove(eventList[originalIndex]);
      }
    });
  }

  // Open details page
  void openDetails(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
    );
  }

  // Clear filters
  void clearFilters() {
    setState(() {
      selectedCategory = null;
      selectedLocation = null;
      selectedDate = null;
    });
  }

  // UI input style (matches your soft gray fields)
  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF2F2F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = filteredEvents;

    return Scaffold(
      backgroundColor: Colors.white,

      // Top bar
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Discover Events"),
      ),

      body: Column(
        children: [
          // -------- Filters button + panel --------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => setState(() => showFilters = !showFilters),
                  icon: Icon(Icons.tune, color: primaryColor),
                  label: Text("Filters", style: TextStyle(color: primaryColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "${listToShow.length} events",
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),

          if (showFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  const Text("Category", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: _fieldDecoration(),
                    hint: const Text("All Categories"),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategory = v),
                  ),

                  const SizedBox(height: 14),

                  // Location
                  const Text("Location", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedLocation,
                    decoration: _fieldDecoration(),
                    hint: const Text("All Locations"),
                    items: locations
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedLocation = v),
                  ),

                  const SizedBox(height: 14),

                  // Date
                  const Text("Date", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDate: selectedDate ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: _fieldDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null
                                ? "All Dates"
                                : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                          ),
                          const Icon(Icons.keyboard_arrow_down),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: clearFilters,
                      child: const Text("Clear filters"),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),

          // -------- Events list --------
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listToShow.length,
              itemBuilder: (context, index) {
                final event = listToShow[index];

                return InkWell(
                  onTap: () => openDetails(event), // open details
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Image.asset(
                                event["image"],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),

                              // Favorite icon
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () {
                                    // prevent opening details when tapping heart
                                    toggleFavorite(index);
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      event["isFavorite"]
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: event["isFavorite"]
                                          ? primaryColor
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Event details
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event["title"],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 6),
                                  Text("${event["date"]} at ${event["time"]}"),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(event["location"])),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Category label
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  event["category"],
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
