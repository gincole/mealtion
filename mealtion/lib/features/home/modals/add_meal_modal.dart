import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class AddMealModal extends StatefulWidget {
  const AddMealModal({
    super.key,
    required this.date,
    required this.onPickDate,
    required this.moodColor,
  });

  final DateTime date;
  final VoidCallback onPickDate;
  final Color Function(String) moodColor;

  @override
  State<AddMealModal> createState() => _AddMealModalState();
}

class _AddMealModalState extends State<AddMealModal> {
  String _selectedType = "healthy"; // healthy | moderate | cheat

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
                  const Text(
                    'Add Meal',
                    style: TextStyle(
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

              // Photo attachment placeholder (UI-only)
              _PhotoPickerCard(
                onTap: () {
                  // TODO: Implement real image picking (camera/gallery) later
                },
              ),
              const SizedBox(height: 16),

              // Meal name
              const _SectionLabel('MEAL NAME'),
              const SizedBox(height: 8),
              const _TextInput(
                hint: 'What did you eat?',
                prefixIcon: null,
              ),
              const SizedBox(height: 14),

              // Date + Time row
              Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      label: 'DATE',
                      value: _formatDate(widget.date),
                      icon: Icons.calendar_today,
                      onTap: widget.onPickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerField(
                      label: 'TIME',
                      value: '12:30 PM',
                      icon: Icons.access_time,
                      onTap: () {
                        // TODO: Implement time picker later
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Location
              const _SectionLabel('LOCATION'),
              const SizedBox(height: 8),
              const _TextInput(
                hint: 'Add location',
                prefixIcon: Icons.location_on,
              ),
              const SizedBox(height: 14),

              // Type selection
              const _SectionLabel('TYPE'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: 'Healthy',
                      dotColor: AppColors.green,
                      bgColor: AppColors.green.withOpacity(0.20),
                      selected: _selectedType == "healthy",
                      onTap: () => setState(() => _selectedType = "healthy"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeChip(
                      label: 'Moderate',
                      dotColor: AppColors.yellow,
                      bgColor: AppColors.yellow.withOpacity(0.25),
                      selected: _selectedType == "moderate",
                      onTap: () => setState(() => _selectedType = "moderate"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeChip(
                      label: 'Cheat',
                      dotColor: AppColors.red,
                      bgColor: AppColors.red.withOpacity(0.20),
                      selected: _selectedType == "cheat",
                      onTap: () => setState(() => _selectedType = "cheat"),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Save Meal',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

class _PhotoPickerCard extends StatelessWidget {
  const _PhotoPickerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              'Tap to take photo',
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
        fontSize: 11,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w700,
        color: AppColors.textLight,
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({required this.hint, this.prefixIcon});

  final String hint;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
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
