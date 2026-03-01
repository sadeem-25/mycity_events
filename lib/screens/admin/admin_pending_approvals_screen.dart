import 'package:flutter/material.dart';

class AdminPendingApprovalsScreen extends StatefulWidget {
  const AdminPendingApprovalsScreen({super.key});

  @override
  State<AdminPendingApprovalsScreen> createState() =>
      _AdminPendingApprovalsScreenState();
}

class _AdminPendingApprovalsScreenState
    extends State<AdminPendingApprovalsScreen>
    with SingleTickerProviderStateMixin {
  // Colors like your design
  static const Color orange = Color(0xFFFF6A00);
  static const Color iosGreen = Color(0xFF34C759); // iOS system green
  static const Color iosRed = Color(0xFFFF3B30); // iOS system red

  late final TabController _tabController;

  final List<_OrganizerReq> _organizers = [
    _OrganizerReq("Sarah Ali", "sarah.ali@email.com", "11/10/2025"),
    _OrganizerReq("Mohammed Ahmed", "mohammed.ahmed@email.com", "11/12/2025"),
    _OrganizerReq("Saud Ibrahim", "saud.ibrahim@email.com", "11/13/2025"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  int get _pendingCount => _organizers.length; // front-end only demo

  void _approve(int index) => setState(() => _organizers.removeAt(index));
  void _reject(int index) => setState(() => _organizers.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: orange,
        unselectedItemColor: const Color(0xFF9E9E9E),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Analytics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_outlined),
            label: "Approvals",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            label: "Events",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ===== ORANGE HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              color: orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with icon (like screenshot)
                  Row(
                    children: const [
                      Icon(Icons.person_outline, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Pending Approvals",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$_pendingCount pending items",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ===== TABS (white background with orange underline) =====
            Material(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: orange,
                unselectedLabelColor: const Color(0xFF9E9E9E),
                indicatorColor: orange,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                tabs: const [
                  Tab(text: "Organizers (3)"),
                  Tab(text: "Events (3)"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ===== ORGANIZERS LIST =====
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: _organizers.length,
                    itemBuilder: (context, index) {
                      final r = _organizers[index];
                      return _ApprovalCard(
                        name: r.name,
                        email: r.email,
                        requested: r.requested,
                        onApprove: () => _approve(index),
                        onReject: () => _reject(index),
                        iosGreen: iosGreen,
                        iosRed: iosRed,
                      );
                    },
                  ),

                  // ===== EVENTS TAB (same style placeholder for now) =====
                  const Center(
                    child: Text(
                      "Events approvals screen",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizerReq {
  final String name;
  final String email;
  final String requested;
  _OrganizerReq(this.name, this.email, this.requested);
}

class _ApprovalCard extends StatelessWidget {
  final String name;
  final String email;
  final String requested;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final Color iosGreen;
  final Color iosRed;

  const _ApprovalCard({
    required this.name,
    required this.email,
    required this.requested,
    required this.onApprove,
    required this.onReject,
    required this.iosGreen,
    required this.iosRed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6F6F6F),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Requested: $requested",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iosGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Reject"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: iosRed,
                      side: BorderSide(
                        color: iosRed.withOpacity(0.35),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
