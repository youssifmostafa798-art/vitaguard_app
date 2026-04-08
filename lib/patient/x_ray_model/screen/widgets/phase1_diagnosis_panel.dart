import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vitaguard_app/core/utils/app_colors.dart';
import 'package:vitaguard_app/patient/x_ray_model/screen/doctor_two_phase_models.dart';

class Phase1DiagnosisPanel extends StatelessWidget {
  const Phase1DiagnosisPanel({
    super.key,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.notesController,
    required this.onContinue,
    required this.canContinue,
  });

  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final TextEditingController notesController;
  final VoidCallback onContinue;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Initial diagnosis (manual)',
          style: textTheme.titleMedium?.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Select findings or document in notes (at least one required).',
          style: textTheme.bodySmall?.copyWith(
            fontSize: 13.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 14.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: DiagnosisChecklistOption.standardOptions.map((opt) {
            final selected = selectedIds.contains(opt.id);
            return FilterChip(
              label: Text(opt.label),
              selected: selected,
              onSelected: (v) {
                final next = Set<String>.from(selectedIds);
                if (v) {
                  next.add(opt.id);
                } else {
                  next.remove(opt.id);
                }
                onSelectionChanged(next);
              },
            );
          }).toList(),
        ),
        SizedBox(height: 16.h),
        TextField(
          controller: notesController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Clinical notes',
            hintText: 'Required if no checklist item is selected',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
            alignLabelWithHint: true,
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canContinue ? onContinue : null,
            child: const Text('Continue to AI Review'),
          ),
        ),
      ],
    );
  }
}
