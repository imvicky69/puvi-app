import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espresso.withValues(alpha: 0.12),
                  blurRadius: 28,
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
                  // 1. Header
                  Row(
                    children: [
                      Text(
                        'Edit Memory',
                        style: AppTypography.h3.copyWith(
                          fontSize: 18,
                          color: AppColors.espresso,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppColors.taupe,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 18,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Date Taken Pill Tile (Interactive)
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ivory.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.burgundy,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dateString,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.espresso,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          Text(
                            'Change',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.burgundy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Title / Note Field
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.ivory.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: TextFormField(
                      controller: _titleController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.espresso,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Memory title / note',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.taupe.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: AppColors.taupe,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Location Field
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.ivory.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: TextFormField(
                      controller: _locationController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.espresso,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Location (optional)',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.taupe.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.taupe,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 5. Actions (Cancel / Save)
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: AppTypography.label.copyWith(
                            color: AppColors.taupe,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.burgundy,
                          foregroundColor: AppColors.paper,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 11,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderButton,
                          ),
                        ),
                        child: Text(
                          'Save Details',
                          style: AppTypography.label.copyWith(
                            color: AppColors.paper,
                            fontWeight: FontWeight.w600,
                          ),
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
