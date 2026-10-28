import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/puvi_avatar.dart';
import '../../../gallery/data/gallery_repository.dart';
import '../../data/timeline_item.dart';
import '../../data/timeline_media_service.dart';

/// Modal dialog / sheet to create a new milestone or edit an existing one.
class AddEditMilestoneDialog extends StatefulWidget {
  final TimelineItem? initialItem;
  final String currentUserName;
  final Future<void> Function(TimelineItem item) onSave;

  const AddEditMilestoneDialog({
    super.key,
    this.initialItem,
    this.currentUserName = 'Vicky',
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    TimelineItem? initialItem,
    String currentUserName = 'Vicky',
    required Future<void> Function(TimelineItem item) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditMilestoneDialog(
        initialItem: initialItem,
        currentUserName: currentUserName,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditMilestoneDialog> createState() => _AddEditMilestoneDialogState();
}

class _AddEditMilestoneDialogState extends State<AddEditMilestoneDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late TextEditingController _locationController;

  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _selectedAuthor;

  XFile? _pickedFile;
  String? _existingImageUrl;
  bool _isSaving = false;

  static const List<String> _categories = [
    'Milestones',
    'Anniversary',
    'Firsts',
    'Dates',
    'Love Notes',
    'Long Distance',
  ];

  static const List<String> _locationSuggestions = [
    'Assi Ghat, Varanasi',
    'IP Sigra, Varanasi',
    'VT, BHU, Varanasi',
    'Varanasi Junction',
    'Namo Ghat, Varanasi',
    'Varanasi',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;

    _titleController = TextEditingController(text: item?.title ?? '');
    _noteController = TextEditingController(text: item?.note ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');

    _selectedDate = item?.date ?? DateTime.now();
    _selectedCategory = item?.category ?? 'Milestones';
    _selectedAuthor = item?.authorName ?? widget.currentUserName;
    _existingImageUrl = item?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickFromDevice(ImageSource source) async {
    final file = await TimelineMediaService.pickImage(source);
    if (file != null) {
      setState(() {
        _pickedFile = file;
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _pickFromPuviGallery() async {
    try {
      final galleryRepo = GalleryRepository();
      final photos = await galleryRepo.getAllPhotos();
      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.paper,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: AppRadius.largeCard),
        ),
        builder: (sheetCtx) => SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSpacing.verticalSm,
                // Sheet drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.borderPill,
                  ),
                ),
                AppSpacing.verticalSm,
                Text(
                  'Choose from Puvi Gallery',
                  style: AppTypography.h3.copyWith(color: AppColors.espresso),
                ),
                AppSpacing.verticalXxs,
                Text(
                  '${photos.length} treasured photos (bundled & uploaded)',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
                AppSpacing.verticalSm,
                const Divider(height: 1, color: AppColors.border),
                Expanded(
                  child: photos.isEmpty
                      ? Center(
                          child: Text(
                            'No photos found in gallery yet',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.taupe,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: AppSpacing.screenPadding,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemCount: photos.length,
                          itemBuilder: (_, i) {
                            final item = photos[i];
                            final url = item.imageUrl.isNotEmpty
                                ? item.imageUrl
                                : item.mediaUrl;
                            final isLocal =
                                !url.startsWith('http://') &&
                                !url.startsWith('https://');

                            return InkWell(
                              borderRadius: AppRadius.borderSm,
                              onTap: () {
                                setState(() {
                                  _existingImageUrl = url;
                                  _pickedFile = null;
                                  if (_locationController.text.trim().isEmpty &&
                                      item.location != null &&
                                      item.location!.isNotEmpty) {
                                    _locationController.text = item.location!;
                                  }
                                });
                                Navigator.of(sheetCtx).pop();
                              },
                              child: ClipRRect(
                                borderRadius: AppRadius.borderSm,
                                child: Container(
                                  color: AppColors.ivory,
                                  child: isLocal
                                      ? (File(url).existsSync()
                                            ? Image.file(
                                                File(url),
                                                fit: BoxFit.cover,
                                              )
                                            : const Center(
                                                child: Icon(
                                                  Icons.photo_outlined,
                                                  color: AppColors.taupe,
                                                  size: 24,
                                                ),
                                              ))
                                      : CachedNetworkImage(
                                          imageUrl: url,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 300,
                                          placeholder: (context, url) =>
                                              Container(color: AppColors.ivory),
                                          errorWidget: (context, url, error) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: AppColors.dustyRose,
                                                  size: 24,
                                                ),
                                              ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? finalImageUrl = _existingImageUrl;

      // 1. If a new local photo was picked from device camera/storage, upload it
      if (_pickedFile != null) {
        final uploaded = await TimelineMediaService.uploadMilestonePhoto(
          _pickedFile!,
        );
        if (uploaded != null) {
          finalImageUrl = uploaded;
        }
      } else if (finalImageUrl != null &&
          !finalImageUrl.startsWith('http://') &&
          !finalImageUrl.startsWith('https://')) {
        // 2. If an uploaded gallery photo was selected and resides on local path, upload to Firebase Storage
        final uploaded = await TimelineMediaService.uploadMilestonePhoto(
          XFile(finalImageUrl),
        );
        if (uploaded != null) {
          finalImageUrl = uploaded;
        }
      }

      final existing = widget.initialItem;
      final uniqueId =
          existing?.id ?? 'milestone_${DateTime.now().millisecondsSinceEpoch}';

      final newItem = TimelineItem(
        id: uniqueId,
        title: _titleController.text.trim(),
        date: _selectedDate,
        note: _noteController.text.trim(),
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        imageUrl: finalImageUrl,
        category: _selectedCategory,
        authorName: _selectedAuthor,
        coupleId: 'puvi_couple',
        coordinates: existing?.coordinates,
        isFavorite: existing?.isFavorite ?? false,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      await widget.onSave(newItem);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Could not save milestone: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isEditing = widget.initialItem != null;

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.92),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: AppRadius.largeCard),
      ),
      child: Column(
        children: [
          // Drag handle
          AppSpacing.verticalSm,
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.borderPill,
              ),
            ),
          ),

          // Dialog Title & Close
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.burgundy,
                  size: 20,
                ),
                AppSpacing.horizontalXs,
                Text(
                  isEditing ? 'Edit Chapter' : 'New Milestone Chapter',
                  style: AppTypography.h3.copyWith(color: AppColors.espresso),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.espresso,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Scrollable Form Fields
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                mediaQuery.viewInsets.bottom + AppSpacing.xxl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Chapter Title *',
                      style: AppTypography.label.copyWith(
                        color: AppColors.espresso,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    TextFormField(
                      controller: _titleController,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.espresso,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Our First Walk at Assi Ghat',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.taupe,
                        ),
                        filled: true,
                        fillColor: AppColors.ivory,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderButton,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderButton,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderButton,
                          borderSide: const BorderSide(
                            color: AppColors.burgundy,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a romantic milestone title';
                        }
                        return null;
                      },
                    ),

                    AppSpacing.verticalMd,

                    // Date & Category Row
                    Row(
                      children: [
                        // Date picker button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Milestone Date',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.espresso,
                                ),
                              ),
                              AppSpacing.verticalXs,
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: AppRadius.borderButton,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.ivory,
                                    borderRadius: AppRadius.borderButton,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 16,
                                        color: AppColors.burgundy,
                                      ),
                                      AppSpacing.horizontalXs,
                                      Text(
                                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                              color: AppColors.espresso,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.horizontalMd,

                        // Author selector
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Penned By',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.espresso,
                                ),
                              ),
                              AppSpacing.verticalXs,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ivory,
                                  borderRadius: AppRadius.borderButton,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedAuthor,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: AppColors.taupe,
                                    ),
                                    items: ['Vicky', 'Puja', 'Puja & Vicky']
                                        .map((name) {
                                          return DropdownMenuItem(
                                            value: name,
                                            child: Row(
                                              children: [
                                                if (name == 'Vicky')
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 8,
                                                    ),
                                                    child: PuviAvatar.vicky(
                                                      size: 20,
                                                      showBorder: false,
                                                    ),
                                                  )
                                                else if (name == 'Puja')
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 8,
                                                    ),
                                                    child: PuviAvatar.puja(
                                                      size: 20,
                                                      showBorder: false,
                                                    ),
                                                  )
                                                else
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 8,
                                                    ),
                                                    child: Icon(
                                                      Icons.favorite_rounded,
                                                      size: 16,
                                                      color:
                                                          AppColors.dustyRose,
                                                    ),
                                                  ),
                                                Text(
                                                  name,
                                                  style: AppTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                        color:
                                                            AppColors.espresso,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedAuthor = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    AppSpacing.verticalMd,

                    // Category Pills
                    Text(
                      'Category',
                      style: AppTypography.label.copyWith(
                        color: AppColors.espresso,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppColors.burgundy,
                          backgroundColor: AppColors.ivory,
                          labelStyle: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.paper
                                : AppColors.espresso,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderPill,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.burgundy
                                  : AppColors.border,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),

                    AppSpacing.verticalMd,

                    // Location Input & Suggestion Chips
                    Text(
                      'Location (Spot)',
                      style: AppTypography.label.copyWith(
                        color: AppColors.espresso,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    TextFormField(
                      controller: _locationController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.espresso,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Assi Ghat, Varanasi',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.taupe,
                        ),
                        prefixIcon: const Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: AppColors.burgundy,
                        ),
                        filled: true,
                        fillColor: AppColors.ivory,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderButton,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderButton,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderButton,
                          borderSide: const BorderSide(
                            color: AppColors.burgundy,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    AppSpacing.verticalXs,
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _locationSuggestions.map((loc) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(loc),
                              labelStyle: AppTypography.captionSmall.copyWith(
                                color: AppColors.taupe,
                              ),
                              backgroundColor: AppColors.ivory,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderPill,
                                side: const BorderSide(
                                  color: AppColors.border,
                                  width: 0.8,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _locationController.text = loc;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    AppSpacing.verticalMd,

                    // Photo Attachment Area
                    Text(
                      'Milestone Photograph',
                      style: AppTypography.label.copyWith(
                        color: AppColors.espresso,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    _buildPhotoAttachmentArea(),

                    AppSpacing.verticalMd,

                    // Handwritten Love Note
                    Row(
                      children: [
                        Text(
                          'Handwritten Love Note',
                          style: AppTypography.label.copyWith(
                            color: AppColors.espresso,
                          ),
                        ),
                        AppSpacing.horizontalXs,
                        const Text(
                          '(Caveat script)',
                          style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 16,
                            color: AppColors.burgundy,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalXs,
                    TextFormField(
                      controller: _noteController,
                      maxLines: 4,
                      style: const TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 22,
                        height: 1.3,
                        color: AppColors.espresso,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Pour your heart out in handwritten words...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 20,
                          color: AppColors.taupe,
                        ),
                        filled: true,
                        fillColor: AppColors.ivory,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.borderButton,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderButton,
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderButton,
                          borderSide: const BorderSide(
                            color: AppColors.burgundy,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),

                    AppSpacing.verticalXl,

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.burgundy,
                          foregroundColor: AppColors.paper,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderButton,
                          ),
                        ),
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.paper,
                                ),
                              )
                            : const Icon(Icons.favorite_rounded, size: 18),
                        label: Text(
                          _isSaving
                              ? 'Treasuring Memory...'
                              : (isEditing
                                    ? 'Update Chapter'
                                    : 'Seal into Timeline'),
                          style: AppTypography.label.copyWith(
                            color: AppColors.paper,
                            fontSize: 15,
                          ),
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
    );
  }

  Widget _buildPhotoAttachmentArea() {
    final hasExisting =
        _existingImageUrl != null && _existingImageUrl!.isNotEmpty;
    final hasPicked = _pickedFile != null;

    if (hasPicked || hasExisting) {
      final isLocalExisting =
          hasExisting &&
          !_existingImageUrl!.startsWith('http://') &&
          !_existingImageUrl!.startsWith('https://');

      return Stack(
        children: [
          ClipRRect(
            borderRadius: AppRadius.borderButton,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.ivory,
                border: Border.all(color: AppColors.border),
              ),
              child: hasPicked
                  ? Image.file(
                      File(_pickedFile!.path),
                      width: double.infinity,
                      fit: BoxFit.contain,
                    )
                  : (isLocalExisting
                        ? (File(_existingImageUrl!).existsSync()
                              ? Image.file(
                                  File(_existingImageUrl!),
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                )
                              : Container(
                                  height: 160,
                                  color: AppColors.ivory,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.dustyRose,
                                      size: 32,
                                    ),
                                  ),
                                ))
                        : CachedNetworkImage(
                            imageUrl: _existingImageUrl!,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(28),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.burgundy,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 160,
                              color: AppColors.ivory,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.dustyRose,
                                  size: 32,
                                ),
                              ),
                            ),
                          )),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.espresso.withValues(alpha: 0.75),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.paper,
                ),
                onPressed: () {
                  setState(() {
                    _pickedFile = null;
                    _existingImageUrl = null;
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: AppRadius.borderButton,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPhotoSourceOption(
            icon: Icons.camera_alt_outlined,
            label: 'Camera',
            onTap: () => _pickFromDevice(ImageSource.camera),
          ),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildPhotoSourceOption(
            icon: Icons.photo_library_outlined,
            label: 'Device',
            onTap: () => _pickFromDevice(ImageSource.gallery),
          ),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildPhotoSourceOption(
            icon: Icons.auto_stories_outlined,
            label: 'Puvi Gallery',
            onTap: _pickFromPuviGallery,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.burgundy, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
