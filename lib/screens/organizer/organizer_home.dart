import 'package:flutter/material.dart';

import 'organizer_my_events_screen.dart';
import 'organizer_create_event_screen.dart';
import 'organizer_dashboard_screen.dart';
import 'organizer_profile_screen.dart';

class OrganizerHomeScreen extends StatefulWidget {
  const OrganizerHomeScreen({super.key});

  @override
  State<OrganizerHomeScreen> createState() => _OrganizerHomeScreenState();
}

class _OrganizerHomeScreenState extends State<OrganizerHomeScreen> {
  static const Color primaryColor = Color(0xFFFF6A00);

  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const OrganizerMyEventsScreen(),

      // ✅ remove const to allow callback
      OrganizerCreateEventScreen(
        mode: OrganizerCreateMode.create,
        onCreated: () {
          setState(() => index = 0); // go back to My Events
        },
      ),

      const OrganizerDashboardScreen(),
      const OrganizerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "My Events",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Create"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
