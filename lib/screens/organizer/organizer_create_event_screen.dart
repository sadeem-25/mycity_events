import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../services/event_service.dart';

enum OrganizerCreateMode { create, edit }

class OrganizerCreateEventScreen extends StatefulWidget {
  final OrganizerCreateMode mode;
  final String? eventId;
  final Map<String, dynamic>? existingData;

  // optional for tab usage
  final VoidCallback? onCreated;

  const OrganizerCreateEventScreen({
    super.key,
    required this.mode,
    this.eventId,
    this.existingData,
    this.onCreated,
  });

  @override
  State<OrganizerCreateEventScreen> createState() =>
      _OrganizerCreateEventScreenState();
}

class _OrganizerCreateEventScreenState
    extends State<OrganizerCreateEventScreen> {
  static const Color primaryColor = Color(0xFFFF6A00);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color inputFill = Color(0xFFF2F2F2);
  static const Color darkButton = Color(0xFF0B0D2A);

  // ✅ when photo upload fails, we still save event with this image
  static const String placeholderImage =
      "https://via.placeholder.com/1200x600.png?text=MyCity+Event";

  // ✅ front-end timeout so it never hangs forever
  static const Duration uploadTimeout = Duration(seconds: 60);

  final _service = EventService();
  final _formKey = GlobalKey<FormState>();

  final title = TextEditingController();
  final about = TextEditingController();
  final location = TextEditingController();

  String? category;
  DateTime? date;
  TimeOfDay? time;

  Uint8List? pickedImageBytes;
  String? pickedImageName;
  String? existingImageUrl;

  bool saving = false;

  // upload UI
  UploadTask? _uploadTask;
  double _uploadProgress = 0;

  final categories = const [
    "Sports",
    "Art",
    "Music",
    "Tech",
    "Food",
    "Culture",
  ];

  @override
  void initState() {
    super.initState();

    final e = widget.existingData;
    if (widget.mode == OrganizerCreateMode.edit && e != null) {
      title.text = (e["title"] ?? "").toString();
      about.text = (e["about"] ?? e["description"] ?? "").toString();
      location.text = (e["location"] ?? "").toString();
      category = (e["category"] ?? "").toString();

      existingImageUrl =
          (e["imageUrl"] ??
                  e["imageURL"] ??
                  e["image"] ??
                  e["photoUrl"] ??
                  e["eventImage"] ??
                  "")
              .toString();
      if (existingImageUrl != null && existingImageUrl!.trim().isEmpty) {
        existingImageUrl = null;
      }

      try {
        final d = (e["date"] ?? "").toString();
        if (d.isNotEmpty) date = DateTime.parse(d);
      } catch (_) {}

      try {
        final t = (e["time"] ?? "").toString();
        final p = t.split(":");
        if (p.length == 2) {
          time = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    title.dispose();
    about.dispose();
    location.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _formatTime(TimeOfDay t) =>
      "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  Future<bool> _isValidImageBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image.width > 0 && frame.image.height > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ["jpg", "jpeg", "png", "webp"],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final f = result.files.first;
    if (f.bytes == null) {
      _snack("Could not read image");
      return;
    }

    final ok = await _isValidImageBytes(f.bytes!);
    if (!ok) {
      _snack("Please choose a real image (jpg/png/webp).");
      return;
    }

    setState(() {
      pickedImageBytes = f.bytes!;
      pickedImageName = f.name;
      existingImageUrl = null;
    });
  }

  bool _validate() {
    if (!_formKey.currentState!.validate()) return false;

    if (category == null || category!.trim().isEmpty) {
      _snack("Select category");
      return false;
    }
    if (date == null) {
      _snack("Select date");
      return false;
    }
    if (time == null) {
      _snack("Select time");
      return false;
    }

    // ✅ allow create even without image (per your request)
    return true;
  }

  void _cancelUploadSilently() {
    try {
      _uploadTask?.cancel();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _uploadTask = null;
        _uploadProgress = 0;
      });
    }
  }

  Future<String> _uploadToStorageOrThrow(
    Uint8List bytes,
    String fileName,
  ) async {
    final storage = FirebaseStorage.instance;

    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\.\-_]'), '_');
    final ext = safeName.contains(".")
        ? safeName.split(".").last.toLowerCase()
        : "jpg";

    final contentType = switch (ext) {
      "png" => "image/png",
      "webp" => "image/webp",
      _ => "image/jpeg",
    };

    final path =
        "event_images/${DateTime.now().millisecondsSinceEpoch}_$safeName";
    final ref = storage.ref().child(path);

    final task = ref.putData(bytes, SettableMetadata(contentType: contentType));
    _uploadTask = task;

    task.snapshotEvents.listen((snap) {
      final total = snap.totalBytes;
      if (total > 0 && mounted) {
        setState(() => _uploadProgress = snap.bytesTransferred / total);
      }
    });

    await task.whenComplete(() {}).timeout(uploadTimeout);

    final url = await ref.getDownloadURL();

    if (mounted) {
      setState(() {
        _uploadTask = null;
        _uploadProgress = 0;
      });
    }

    return url;
  }

  void _resetForm() {
    title.clear();
    about.clear();
    location.clear();
    category = null;
    date = null;
    time = null;
    pickedImageBytes = null;
    pickedImageName = null;
    existingImageUrl = null;
    setState(() {});
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final isEdit = widget.mode == OrganizerCreateMode.edit;

    setState(() => saving = true);

    try {
      // ✅ Default image (if upload fails or no image picked)
      String imageUrl = existingImageUrl ?? placeholderImage;

      // ✅ Try upload, but NEVER block creation forever
      if (pickedImageBytes != null && pickedImageName != null) {
        _snack("Uploading photo...");
        try {
          imageUrl = await _uploadToStorageOrThrow(
            pickedImageBytes!,
            pickedImageName!,
          );
        } on TimeoutException {
          _cancelUploadSilently();
          _snack(
            "Photo upload took too long. Event will be created without photo.",
          );
          imageUrl = placeholderImage; // keep placeholder
        } catch (_) {
          _cancelUploadSilently();
          _snack("Photo upload failed. Event will be created without photo.");
          imageUrl = placeholderImage; // keep placeholder
        }
      }

      _snack(isEdit ? "Saving changes..." : "Creating event...");

      if (isEdit) {
        if (widget.eventId == null) {
          _snack("Missing eventId for edit");
          return;
        }

        await _service.updateEvent(
          eventId: widget.eventId!,
          updates: {
            "title": title.text.trim(),
            "about": about.text.trim(),
            "description": about.text.trim(),
            "category": category,
            "location": location.text.trim(),
            "date": _formatDate(date!),
            "time": _formatTime(time!),
            "imageUrl": imageUrl,
          },
        );

        if (!mounted) return;
        _snack("Updated ✅");
        Navigator.pop(context, true);
        return;
      }

      await _service.createEvent(
        title: title.text.trim(),
        about: about.text.trim(),
        category: category!,
        location: location.text.trim(),
        date: _formatDate(date!),
        time: _formatTime(time!),
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      _snack("Created ✅");

      // tab mode: reset + go to My Events
      if (Navigator.canPop(context) && widget.onCreated == null) {
        Navigator.pop(context, true);
      } else {
        _resetForm();
        widget.onCreated?.call();
      }
    } catch (e) {
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mode == OrganizerCreateMode.edit;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: Navigator.canPop(context),
        title: Text(
          isEdit ? "Edit Event" : "Create Event",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _label("Event Name"),
                _field(title, "Enter event name"),
                const SizedBox(height: 14),

                _label("Description"),
                _field(about, "Describe your event", lines: 3),
                const SizedBox(height: 14),

                _label("Category"),
                _dropdown(),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: _dateBox(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _timeBox(context)),
                  ],
                ),
                const SizedBox(height: 14),

                _label("Location"),
                _field(location, "Enter location"),
                const SizedBox(height: 14),

                _label("Event Image"),
                const SizedBox(height: 8),
                _imageBox(),

                if (_uploadTask != null) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _uploadProgress == 0 ? null : _uploadProgress,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _uploadProgress == 0
                        ? "Uploading photo..."
                        : "Uploading photo... ${(100 * _uploadProgress).toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],

                const SizedBox(height: 18),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkButton,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: darkButton,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: saving ? null : _save,
                    child: saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(isEdit ? "Save Changes" : "Create Event"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) =>
      Text(t, style: const TextStyle(fontWeight: FontWeight.w600));

  Widget _field(TextEditingController c, String hint, {int lines = 1}) {
    return TextFormField(
      controller: c,
      maxLines: lines,
      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: category,
          hint: const Text("Select category"),
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => category = v),
        ),
      ),
    );
  }

  Widget _dateBox(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) setState(() => date = picked);
      },
      child: _pickerBox(
        "Date",
        date == null ? "mm/dd/yyyy" : _formatDate(date!),
        icon: Icons.calendar_today,
      ),
    );
  }

  Widget _timeBox(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (picked != null) setState(() => time = picked);
      },
      child: _pickerBox(
        "Time",
        time == null ? "--:--" : _formatTime(time!),
        icon: Icons.access_time,
      ),
    );
  }

  Widget _pickerBox(String label, String value, {required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(child: Text(value)),
              Icon(icon, size: 18, color: Colors.black54),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageBox() {
    final hasPicked = pickedImageBytes != null;
    final hasExisting = existingImageUrl != null;

    return InkWell(
      onTap: saving ? null : pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: hasPicked
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(pickedImageBytes!, fit: BoxFit.cover),
              )
            : hasExisting
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  existingImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Text("Image failed to load")),
                ),
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload, color: Colors.black54),
                    SizedBox(height: 6),
                    Text(
                      "Click to upload event image",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
