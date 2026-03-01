import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'interests_screen.dart';
import 'login_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String email;
  final String role; // "user" or "organizer"

  const CompleteProfileScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  static const primaryColor = Color(0xFFFF6A00);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // ✅ TEMP (no file_picker, no storage) just to keep UI working
  String? certificateName;

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void uploadCertificateTemp() {
    setState(() {
      certificateName = "certificate (temp)";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Upload disabled for web test الآن")),
    );
  }

  Future<void> createAccount() async {
    final isOrganizer = widget.role == "organizer";

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name")),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    if (isOrganizer && certificateName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload certificate")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
        "email": widget.email,
        "name": nameController.text.trim(),
        "role": widget.role,
        "certificateUploaded": isOrganizer,
        "certificateName": certificateName, // temp
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created ✅")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InterestsScreen()),
        );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget label(String t) =>
      Text(t, style: const TextStyle(fontWeight: FontWeight.w600));

  Widget grayField({
    required String hint,
    required TextEditingController c,
    bool obscure = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOrganizer = widget.role == "organizer";

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text("Back", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          "assets/logo.png.jpg",
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.location_city,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "myCity Event",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // White Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Complete Your Profile",
                        style:
                            TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isOrganizer
                            ? "Start creating and managing events"
                            : "Start discovering events in your city",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 18),

                      label("Email"),
                      const SizedBox(height: 8),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFD2AE)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.centerLeft,
                        child: Text(widget.email),
                      ),

                      const SizedBox(height: 14),

                      label("Full Name"),
                      const SizedBox(height: 8),
                      grayField(hint: "Enter your name", c: nameController),

                      const SizedBox(height: 14),

                      label("Password"),
                      const SizedBox(height: 8),
                      grayField(
                        hint: "Create a password",
                        c: passwordController,
                        obscure: true,
                      ),

                      const SizedBox(height: 14),

                      label("Confirm Password"),
                      const SizedBox(height: 8),
                      grayField(
                        hint: "Confirm your password",
                        c: confirmPasswordController,
                        obscure: true,
                      ),

                      if (isOrganizer) ...[
                        const SizedBox(height: 14),
                        const Text(
                          "Upload Certificates *",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: uploadCertificateTemp,
                          child: Container(
                            height: 110,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E6),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFFFD2AE)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.file_upload_outlined,
                                    color: primaryColor, size: 28),
                                const SizedBox(height: 8),
                                const Text(
                                  "Click to upload certificates",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  certificateName == null
                                      ? "PDF, JPG, PNG (Max 5MB)"
                                      : "Selected: $certificateName",
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isLoading ? null : createAccount,
                          child: Text(
                            isLoading ? "Creating..." : "Create Account",
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}