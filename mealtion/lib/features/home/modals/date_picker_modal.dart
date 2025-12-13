import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class DatePickerModal extends StatelessWidget {
  const DatePickerModal({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final DateTime selected;
  final void Function(DateTime) onSelect;

  @override
  Widget build(BuildContext context) {
    DateTime temp = selected;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Select date', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain)),
      content: SizedBox(
        height: 280,
        width: 320,
        child: CalendarDatePicker(
          initialDate: selected,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          onDateChanged: (d) => temp = d,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            onSelect(temp);
            Navigator.pop(context);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
