import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/colors.dart';
import '../../../app/app_state.dart';

class AddMealModal extends StatefulWidget {
  const AddMealModal({
    super.key,
    required this.date,
    required this.onPickDate,
    required this.moodColor,
    this.isPlan = false,
  });

  final DateTime date;
  final VoidCallback onPickDate;
  final Color Function(String) moodColor;
  final bool isPlan;

  @override
  State<AddMealModal> createState() => _AddMealModalState();
}

class _AddMealModalState extends State<AddMealModal> {
  String _selectedType = "green"; // green | yellow | red
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late DateTime _selectedDate;
  bool _loading = false;
  String? _error;

  // Image state
  Uint8List? _imageBytes;
  String? _imageContentType;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageContentType = image.mimeType ?? 'image/jpeg';
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMeal() async {
    if (_titleController.text.isEmpty) {
      setState(() => _error = widget.isPlan ? 'Please enter a plan name' : 'Please enter a meal name');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();

      if (widget.isPlan) {
        // Save as plan
        String mealTime = 'Lunch';
        final hour = _selectedTime.hour;
        if (hour < 10) {
          mealTime = 'Breakfast';
        } else if (hour < 14) {
          mealTime = 'Lunch';
        } else {
          mealTime = 'Dinner';
        }

        await appState.addPlan(
          title: _titleController.text.trim(),
          date: _formatDate(_selectedDate),
          time: _formatTime(_selectedTime),
          mealTime: mealTime,
          status: _selectedType,
        );
      } else {
        // Save as meal
        String? imageBase64;
        if (_imageBytes != null) {
          imageBase64 = base64Encode(_imageBytes!);
        }

        await appState.addMeal(
          title: _titleController.text.trim(),
          status: _selectedType,
          date: _formatDate(_selectedDate),
          time: _formatTime(_selectedTime),
          location: _locationController.text.trim(),
          imageBase64: imageBase64,
          imageContentType: _imageContentType,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row (title + close button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isPlan ? 'Add Plan' : 'Add Meal',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textLight),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),

              // Photo attachment (only show for meals, not plans)
              if (!widget.isPlan) ...[
                _PhotoPickerCardWithImage(
                  imageBytes: _imageBytes,
                  onTap: _showImageSourceDialog,
                  onRemove: () => setState(() {
                    _imageBytes = null;
                    _imageContentType = null;
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // Meal name
              _SectionLabel(widget.isPlan ? 'Plan Name' : 'Meal Name'),
              const SizedBox(height: 8),
              _TextInput(
                hint: widget.isPlan ? 'What will you eat?' : 'What did you eat?',
                prefixIcon: null,
                controller: _titleController,
              ),
              const SizedBox(height: 14),

              // Date + Time row
              Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      label: 'Date',
                      value: _formatDate(_selectedDate),
                      icon: Icons.calendar_today,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerField(
                      label: 'Time',
                      value: _formatTime(_selectedTime),
                      icon: Icons.access_time,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Location (only show for meals, not plans)
              if (!widget.isPlan) ...[
                const _SectionLabel('Location'),
                const SizedBox(height: 8),
                _TextInput(
                  hint: 'Add location',
                  prefixIcon: Icons.location_on,
                  controller: _locationController,
                ),
                const SizedBox(height: 14),
              ],

              // Type selection
              const _SectionLabel('Type'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: 'Healthy',
                      dotColor: AppColors.green,
                      bgColor: AppColors.green.withOpacity(0.20),
                      selected: _selectedType == "green",
                      onTap: () => setState(() => _selectedType = "green"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeChip(
                      label: 'Moderate',
                      dotColor: AppColors.yellow,
                      bgColor: AppColors.yellow.withOpacity(0.25),
                      selected: _selectedType == "yellow",
                      onTap: () => setState(() => _selectedType = "yellow"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeChip(
                      label: 'Cheat',
                      dotColor: AppColors.red,
                      bgColor: AppColors.red.withOpacity(0.20),
                      selected: _selectedType == "red",
                      onTap: () => setState(() => _selectedType = "red"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _saveMeal,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.isPlan ? 'Save Plan' : 'Save Meal',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPickerCardWithImage extends StatelessWidget {
  const _PhotoPickerCardWithImage({
    required this.imageBytes,
    required this.onTap,
    required this.onRemove,
  });

  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              imageBytes!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.photo_camera_outlined, color: AppColors.textLight, size: 26),
            SizedBox(height: 8),
            Text(
              'Tap to add photo',
              style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: child,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({required this.hint, this.prefixIcon, this.controller});

  final String hint;
  final IconData? prefixIcon;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB8BFC7), fontWeight: FontWeight.w600),
        filled: true,
        fillColor: AppColors.bg,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 18, color: AppColors.textLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.dotColor,
    required this.bgColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color dotColor;
  final Color bgColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? dotColor.withOpacity(0.9) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMain),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  // Keep it simple for UI mock (e.g. "13 Dec 2025")
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _formatTime(TimeOfDay t) {
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
