import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/gallery_item.dart';
import '../../data/image_upload_processor.dart';

enum UploadViewMode { cards, list }

/// Modal dialog for reviewing batch photos with auto-detected dates and optional notes.
///
/// Supports:
/// - Single photo big proportion preview.
/// - Multiple photos with dual view modes: Horizontal swipe cards (in natural proportion) and Compact List.
/// - Zero harsh outlines, smooth Love Letters stationery aesthetic.
class UploadPhotosDialog extends StatefulWidget {
  final List<UploadDraft> initialDrafts;
  final ValueChanged<List<GalleryItem>> onUploaded;

  const UploadPhotosDialog({
    super.key,
    required this.initialDrafts,
    required this.onUploaded,
  });

  @override
  State<UploadPhotosDialog> createState() => _UploadPhotosDialogState();
}

class _UploadPhotosDialogState extends State<UploadPhotosDialog> {
  late final List<UploadDraft> _drafts;
  final Map<String, TextEditingController> _noteControllers = {};
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  UploadViewMode _viewMode = UploadViewMode.cards;
  late final PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _drafts = List.from(widget.initialDrafts);
    for (final draft in _drafts) {
      _noteControllers[draft.id] = TextEditingController(text: draft.note);
    }
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateFor(int index) async {
    final draft = _drafts[index];
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.date,
      firstDate: DateTime(2000),
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
      setState(() {
        final old = draft.date;
        draft.date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          old.hour,
          old.minute,
          old.second,
        );
      });
    }
  }

  Future<void> _addMorePhotos() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isEmpty) return;

      for (final file in pickedFiles) {
        final draft = await ImageUploadProcessor.processPickedFile(file);
        _noteControllers[draft.id] = TextEditingController();
        _drafts.add(draft);
      }
      setState(() {});
    } catch (_) {}
  }

  void _removeDraft(int index) {
    setState(() {
      final removed = _drafts.removeAt(index);
      _noteControllers[removed.id]?.dispose();
      _noteControllers.remove(removed.id);

      if (_currentPageIndex >= _drafts.length && _drafts.isNotEmpty) {
        _currentPageIndex = _drafts.length - 1;
      }
    });

    if (_drafts.isEmpty) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSave() async {
    if (_drafts.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final List<GalleryItem> savedItems = [];
      for (final draft in _drafts) {
        draft.note = _noteControllers[draft.id]?.text.trim() ?? '';
        final item = await ImageUploadProcessor.saveDraftToPermanentStorage(
          draft,
        );
        savedItems.add(item);
      }

      widget.onUploaded(savedItems);

      if (!mounted) return;
      Navigator.pop(context, savedItems);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.paper,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${savedItems.length} memories added to your gallery 💕',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.paper,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.espresso,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save photos: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = _drafts.length == 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
        side: BorderSide.none,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 660),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espresso.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header with title & optional view toggle
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                  child: Row(
                    children: [
                      Text(
                        isSingle ? 'Upload Memory' : 'Upload Memories',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.espresso,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blushSand,
                          borderRadius: AppRadius.borderPill,
                        ),
                        child: Text(
                          '${_drafts.length}',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.burgundy,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Dual View Mode Toggle (Cards proportion scroll vs compact List)
                      if (!isSingle) ...[
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.ivory,
                            borderRadius: AppRadius.borderPill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => setState(
                                  () => _viewMode = UploadViewMode.cards,
                                ),
                                borderRadius: AppRadius.borderPill,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _viewMode == UploadViewMode.cards
                                        ? AppColors.paper
                                        : Colors.transparent,
                                    borderRadius: AppRadius.borderPill,
                                  ),
                                  child: Icon(
                                    Icons.view_carousel_rounded,
                                    size: 16,
                                    color: _viewMode == UploadViewMode.cards
                                        ? AppColors.burgundy
                                        : AppColors.taupe,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(
                                  () => _viewMode = UploadViewMode.list,
                                ),
                                borderRadius: AppRadius.borderPill,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _viewMode == UploadViewMode.list
                                        ? AppColors.paper
                                        : Colors.transparent,
                                    borderRadius: AppRadius.borderPill,
                                  ),
                                  child: Icon(
                                    Icons.view_agenda_rounded,
                                    size: 16,
                                    color: _viewMode == UploadViewMode.list
                                        ? AppColors.burgundy
                                        : AppColors.taupe,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],

                      IconButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppColors.taupe,
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: AppColors.ivory),

                // 2. Main Content: Cards Proportion View OR Compact List
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: (isSingle || _viewMode == UploadViewMode.cards)
                        ? _buildCardsProportionView(isSingle)
                        : _buildCompactListView(),
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: AppColors.ivory),

                // 3. Bottom Action Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _isSaving ? null : _addMorePhotos,
                        icon: const Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 18,
                          color: AppColors.taupe,
                        ),
                        label: Text(
                          'Add more',
                          style: AppTypography.label.copyWith(
                            color: AppColors.taupe,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
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
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.paper,
                                ),
                              )
                            : Text(
                                _drafts.length == 1
                                    ? 'Upload Memory'
                                    : 'Upload ${_drafts.length} Photos',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.paper,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Horizontal carousel/cards view showing each image in its natural proportions with date and note below.
  Widget _buildCardsProportionView(bool isSingle) {
    if (isSingle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: _buildLargeDraftCard(0, _drafts[0]),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 385,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _drafts.length,
            onPageChanged: (index) {
              setState(() => _currentPageIndex = index);
            },
            itemBuilder: (context, index) {
              return _buildLargeDraftCard(index, _drafts[index]);
            },
          ),
        ),

        // Page navigation dots & indicators
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentPageIndex > 0)
                InkWell(
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: AppColors.taupe,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: AppRadius.borderPill,
                ),
                child: Text(
                  '${_currentPageIndex + 1} of ${_drafts.length}',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.espresso,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              if (_currentPageIndex < _drafts.length - 1)
                InkWell(
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.taupe,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Big card displaying the photo in its true aspect ratio with date & caption below.
  Widget _buildLargeDraftCard(int index, UploadDraft draft) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Photo in natural proportion
          Stack(
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.ivory.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: draft.aspectRatio.clamp(0.55, 1.8),
                    child: Image.memory(
                      draft.processedBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.blushSand,
                        child: const Icon(
                          Icons.image,
                          color: AppColors.taupe,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Delete button on top-right of image
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => _removeDraft(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.espresso.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.paper,
                    ),
                  ),
                ),
              ),

              // HEIC to PNG badge on top-left of image
              if (draft.wasHeic)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.espresso.withValues(alpha: 0.65),
                      borderRadius: AppRadius.borderPill,
                    ),
                    child: Text(
                      'PNG',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.paper,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Date button pill below the image
          Row(
            children: [
              InkWell(
                onTap: () => _pickDateFor(index),
                borderRadius: AppRadius.borderPill,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: AppRadius.borderPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppColors.burgundy,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        draft.formattedDate,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.burgundy,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit_rounded,
                        size: 11,
                        color: AppColors.dustyRose,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3. Caption / Note field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.ivory.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _noteControllers[draft.id],
              maxLength: 80,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.espresso,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Add a sweet note (optional)...',
                hintStyle: AppTypography.captionSmall.copyWith(
                  color: AppColors.taupe.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
                counterText: '',
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact vertical list view showing all photos in the batch.
  Widget _buildCompactListView() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _drafts.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.ivory.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: Image.memory(
                    draft.processedBytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.blushSand,
                      child: const Icon(
                        Icons.image,
                        color: AppColors.taupe,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Metadata Inputs: Date Pill & Note Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top line: Date button & badges
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _pickDateFor(index),
                          borderRadius: AppRadius.borderPill,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: AppRadius.borderPill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11,
                                  color: AppColors.burgundy,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  draft.formattedDate,
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.burgundy,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.edit_rounded,
                                  size: 10,
                                  color: AppColors.dustyRose,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (draft.wasHeic) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blushSand,
                              borderRadius: AppRadius.borderPill,
                            ),
                            child: Text(
                              'PNG',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.espresso,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Note Field
                    TextField(
                      controller: _noteControllers[draft.id],
                      maxLength: 80,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.espresso,
                        fontSize: 12.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add note (optional)...',
                        hintStyle: AppTypography.captionSmall.copyWith(
                          color: AppColors.taupe.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Delete Photo Button
              InkWell(
                onTap: () => _removeDraft(index),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.taupe,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
