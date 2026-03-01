import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main_nav_screen.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  static const Color primaryColor = Color(0xFFFF6A00);

  final List<String> allInterests = [
    "Music",
    "Sports",
    "Food & Dining",
    "Art & Culture",
    "Technology",
    "Business",
    "Fashion",
    "Photography",
    "Fitness",
    "Gaming",
    "Literature",
    "Film & Theater",
    "Science",
    "Nature & Outdoors",
  ];

  final Set<String> selected = {};

  bool isSaving = false;

  void toggleInterest(String interest) {
    setState(() {
      if (selected.contains(interest)) {
        selected.remove(interest);
      } else {
        selected.add(interest);
      }
    });
  }

  Future<void> saveAndContinue() async {
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one interest")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // نحفظ الاهتمامات في Firestore داخل user doc
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set(
        {
          "interests": selected.toList(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      // بعد ما يحفظ -> يروح للـ Main Navigation (Home/Discover + Profile..)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saving failed: $e")),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Welcome!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Let’s personalize your experience",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.favorite_border, color: primaryColor),
                        SizedBox(width: 8),
                        Text(
                          "Select Your Interests",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Choose at least one interest to help us recommend events you'll love",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 14),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: allInterests.map((interest) {
                            final bool isSelected = selected.contains(interest);

                            return ChoiceChip(
                              label: Text(interest),
                              selected: isSelected,
                              onSelected: (_) => toggleInterest(interest),
                              selectedColor: const Color(0xFFFFF3E6),
                              labelStyle: TextStyle(
                                color: isSelected ? primaryColor : Colors.black87,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                              backgroundColor: Colors.white,
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "${selected.length} interests selected",
                      style: const TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              selected.isEmpty ? Colors.grey : primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: (selected.isEmpty || isSaving)
                            ? null
                            : saveAndContinue,
                        child: isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Continue",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}