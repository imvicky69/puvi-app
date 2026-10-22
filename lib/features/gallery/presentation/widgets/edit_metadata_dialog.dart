import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/gallery_item.dart';

/// Modal dialog for editing a memory's metadata (Title, Location, Date Taken).
class EditMetadataDialog extends StatefulWidget {
  final GalleryItem item;
  final ValueChanged<GalleryItem> onSave;

  const EditMetadataDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<EditMetadataDialog> createState() => _EditMetadataDialogState();
}

class _EditMetadataDialogState extends State<EditMetadataDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _locationController = TextEditingController(
      text: widget.item.location ?? '',
    );
    _selectedDate = widget.item.takenAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.burgundy,
              onPrimary: AppColors.paper,
              surface: AppColors.paper,
              onSurface: AppColors.espresso,
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

  void _handleSave() {
    final newTitle = _titleController.text.trim();
    final newLocation = _locationController.text.trim();

    final updated = widget.item.copyWith(
      title: newTitle.isNotEmpty ? newTitle : 'Our memory',
      location: newLocation.isNotEmpty ? newLocation : null,
      takenAt: _selectedDate,
    );

    widget.onSave(updated);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memory details updated 💕'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.espresso,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateString =
        '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.burgundy,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Memory',
                            style: AppTypography.h3.copyWith(
                              fontSize: 18,
                              color: AppColors.espresso,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  // Title Field
                  Text(
                    'Memory Title / Note',
                    style: AppTypography.captionSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.espresso,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. When we held hands by the ghats',
                      prefixIcon: Icon(Icons.title_rounded, size: 18),
                    ),
                  ),

                  AppSpacing.verticalMd,

                  // Location Field
                  Text(
                    'Location / Tag',
                    style: AppTypography.captionSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.espresso,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Varanasi, Jaipur, Rooftop',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                    ),
                  ),

                  AppSpacing.verticalMd,

                  // Date Taken Selector
                  Text(
                    'Date Taken',
                    style: AppTypography.captionSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.espresso,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: AppRadius.borderButton,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: AppRadius.borderButton,
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AppColors.burgundy,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dateString,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.espresso,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.taupe,
                          ),
                        ],
                      ),
                    ),
                  ),

                  AppSpacing.verticalLg,

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          child: const Text('Save Details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
