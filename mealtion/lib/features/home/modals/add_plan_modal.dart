import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/colors.dart';
import '../../../app/app_state.dart';

class AddPlanModal extends StatefulWidget {
  const AddPlanModal({super.key});

  @override
  State<AddPlanModal> createState() => _AddPlanModalState();
}

class _AddPlanModalState extends State<AddPlanModal> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedMealTime = 'Lunch';
  String _selectedStatus = 'green';
  bool _loading = false;
  String? _error;

  final List<String> _mealTimes = ['Breakfast', 'Lunch', 'Dinner'];

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() => _selectedTime = picked);
    }
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

  Future<void> _savePlan() async {
    if (_titleController.text.isEmpty) {
      setState(() => _error = 'Please enter a meal name');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AppState>().addPlan(
        title: _titleController.text.trim(),
        date: _formatDate(_selectedDate),
        time: _formatTime(_selectedTime),
        mealTime: _selectedMealTime,
        status: _selectedStatus,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
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

              _Input(label: 'Meal name', hint: 'e.g., Oatmeal', controller: _titleController),
              const SizedBox(height: 12),

              // Date picker
              Text('When', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.textLight),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: AppColors.textLight),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Time picker
              Text('Time', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: AppColors.textLight),
                      const SizedBox(width: 10),
                      Text(
                        _formatTime(_selectedTime),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: AppColors.textLight),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Meal time selection (3 options: Breakfast, Lunch, Dinner)
              Text('Meal Time', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: _mealTimes.map((time) {
                  final isSelected = _selectedMealTime == time;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMealTime = time),
                      child: Container(
                        margin: EdgeInsets.only(right: time != _mealTimes.last ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            time,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textMain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Type selection (3 types: Healthy, Moderate, Cheat)
              Text('Type', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: 'Healthy',
                      dotColor: AppColors.green,
                      bgColor: AppColors.green.withOpacity(0.20),
                      selected: _selectedStatus == 'green',
                      onTap: () => setState(() => _selectedStatus = 'green'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeChip(
                      label: 'Moderate',
                      dotColor: AppColors.yellow,
                      bgColor: AppColors.yellow.withOpacity(0.25),
                      selected: _selectedStatus == 'yellow',
                      onTap: () => setState(() => _selectedStatus = 'yellow'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeChip(
                      label: 'Cheat',
                      dotColor: AppColors.red,
                      bgColor: AppColors.red.withOpacity(0.20),
                      selected: _selectedStatus == 'red',
                      onTap: () => setState(() => _selectedStatus = 'red'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _savePlan,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Plan', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? bgColor : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: dotColor, width: 2) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: selected ? dotColor : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({required this.label, required this.hint, this.controller});

  final String label;
  final String hint;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
