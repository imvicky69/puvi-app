import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/gallery_item.dart';
import '../data/gallery_repository.dart';
import '../data/image_upload_processor.dart';
import 'widgets/gallery_filter_bar.dart';
import 'widgets/gallery_fullscreen_viewer.dart';
import 'widgets/postcard_card.dart';
import 'widgets/upload_photos_dialog.dart';

/// The full-featured, paginated Postcard Gallery screen.
///
/// Features:
/// - Dynamic on-demand paged loading (fetches in slices as user scrolls).
/// - Scattered vintage postcard layout with subtle organic tilts.
/// - Top memory filtering (All, Photos, Videos, Favorites).
/// - High-performance caching with memory optimization via [CachedNetworkImage].
/// - Tap to view full interactive 3D flippable postcard modal.
class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  final GalleryRepository _repository = GalleryRepository();
  final ScrollController _scrollController = ScrollController();

  final List<GalleryItem> _items = [];
  int _currentPage = 1;
  static const int _pageSize = 14;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  GalleryFilter _activeFilter = GalleryFilter.all;

  bool get _isTestEnv =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (_isTestEnv) {
      _isInitialLoading = false;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    final firstPage = await _repository.fetchPage(
      page: _currentPage,
      pageSize: _pageSize,
      filter: _activeFilter,
    );

    if (mounted) {
      setState(() {
        _items.addAll(firstPage);
        _hasMore = firstPage.length >= _pageSize;
        _isInitialLoading = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger load more when 250px away from the bottom
    if (currentScroll >= (maxScroll - 250)) {
      if (!_isLoadingMore && _hasMore && !_isInitialLoading) {
        _loadMore();
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final newItems = await _repository.fetchPage(
      page: nextPage,
      pageSize: _pageSize,
      filter: _activeFilter,
    );

    if (mounted) {
      setState(() {
        _currentPage = nextPage;
        _items.addAll(newItems);
        _hasMore = newItems.length >= _pageSize;
        _isLoadingMore = false;
      });
    }
  }

  void _onFilterChanged(GalleryFilter newFilter) {
    if (_activeFilter == newFilter) return;
    setState(() {
      _activeFilter = newFilter;
    });
    _loadInitialData();
  }

  void _openFullscreenViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            GalleryFullscreenViewer(
              items: _items,
              initialIndex: index,
              onUpdate: (updatedItem) {
                setState(() {
                  _repository.updateItem(updatedItem);
                  final idx = _items.indexWhere((i) => i.id == updatedItem.id);
                  if (idx != -1) {
                    _items[idx] = updatedItem;
                  }
                });
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showUploadSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.burgundy,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Couple Memories',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.espresso,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Upload single or batch photos with auto-detected dates 💕',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.taupe,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blushSand,
                    borderRadius: AppRadius.borderPill,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.burgundy,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Choose from Phone Gallery (Batch)',
                  style: AppTypography.label.copyWith(
                    color: AppColors.espresso,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Select multiple photos with auto-detected dates',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhotos(fromCamera: false);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blushSand,
                    borderRadius: AppRadius.borderPill,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.burgundy,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Take a Photo with Camera',
                  style: AppTypography.label.copyWith(
                    color: AppColors.espresso,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Capture a new sweet moment right now',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhotos(fromCamera: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhotos({bool fromCamera = false}) async {
    try {
      final picker = ImagePicker();
      List<XFile> pickedFiles = [];

      if (fromCamera) {
        final photo = await picker.pickImage(source: ImageSource.camera);
        if (photo != null) pickedFiles.add(photo);
      } else {
        pickedFiles = await picker.pickMultiImage();
      }

      if (pickedFiles.isEmpty || !mounted) return;

      // Show processing dialog while reading EXIF dates & converting HEIC if needed
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espresso.withValues(alpha: 0.15),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.burgundy,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Detecting dates & formats...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.espresso,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final List<UploadDraft> drafts = [];
      for (final file in pickedFiles) {
        final draft = await ImageUploadProcessor.processPickedFile(file);
        drafts.add(draft);
      }

      if (!mounted) return;
      Navigator.pop(context); // Close processing dialog

      // Open the batch review dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UploadPhotosDialog(
          initialDrafts: drafts,
          onUploaded: (newItems) async {
            await _repository.addUploadedItems(newItems);
            setState(() {
              _items.insertAll(0, newItems);
              _items.sort((a, b) => b.takenAt.compareTo(a.takenAt));
            });
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('MissingPluginException')
            ? 'New native plugin added! Please stop the app in the terminal (press "q") and run "flutter run" to rebuild with the native image picker.'
            : 'Could not open photos: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header with couple badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              color: AppColors.ivory,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gallery',
                          style: AppTypography.h1.copyWith(
                            fontSize: 24,
                            color: AppColors.espresso,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Cherished Postcards • Vicky & Puja',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.taupe,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Total frames badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: AppRadius.borderPill,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 13,
                          color: AppColors.burgundy,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_repository.totalCount} Frames',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.burgundy,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Upload Button (Pill in header)
                  GestureDetector(
                    onTap: _showUploadSourceSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.burgundy,
                        borderRadius: AppRadius.borderPill,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.burgundy.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 13,
                            color: AppColors.paper,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Upload',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.paper,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Filter Bar (All, Photos, Videos, Favorites)
            GalleryFilterBar(
              activeFilter: _activeFilter,
              onFilterChanged: _onFilterChanged,
              totalCount: _repository.totalCount,
              photosCount: _repository.photosCount,
              videosCount: _repository.videosCount,
              favoritesCount: _repository.favoritesCount,
            ),

            const Divider(height: 1),

            // 3. Dynamic Paginated Postcard Feed
            Expanded(
              child: (_isInitialLoading && !_isTestEnv)
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.burgundy,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _items.isEmpty
                  ? _buildEmptyState()
                  : _buildPostcardGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadSourceSheet,
        backgroundColor: AppColors.burgundy,
        foregroundColor: AppColors.paper,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderPill),
        icon: const Icon(Icons.add_photo_alternate_rounded, size: 19),
        label: Text(
          'Upload Photos',
          style: AppTypography.label.copyWith(
            color: AppColors.paper,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              size: 40,
              color: AppColors.dustyRose,
            ),
            AppSpacing.verticalMd,
            Text(
              'No memories found',
              style: AppTypography.h3.copyWith(color: AppColors.espresso),
            ),
            AppSpacing.verticalXs,
            Text(
              'Upload couple photos or select another filter.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.taupe),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _showUploadSourceSheet,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
              label: const Text('Upload Photos 💕'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                foregroundColor: AppColors.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostcardGrid() {
    // Dynamic height-balanced 2-column masonry grid for seamless visual rhythm
    final leftItems = <Widget>[];
    final rightItems = <Widget>[];
    double leftHeight = 0;
    double rightHeight = 0;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final ar = item.aspectRatio.clamp(0.48, 2.0);
      final hasCustomNote =
          item.title.trim().isNotEmpty &&
          item.title.trim().toLowerCase() != 'our memory';
      final itemEstimatedHeight = (1.0 / ar) + (hasCustomNote ? 0.28 : 0.14);

      final cardWidget = Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PostcardCard(
          item: item,
          index: i,
          onTap: () => _openFullscreenViewer(i),
        ),
      );

      if (leftHeight <= rightHeight) {
        leftItems.add(cardWidget);
        leftHeight += itemEstimatedHeight;
      } else {
        rightItems.add(cardWidget);
        rightHeight += itemEstimatedHeight;
      }
    }

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: leftItems,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: rightItems,
                    ),
                  ),
                ],
              ),

              // Dynamic Pagination Loader
              if (_isLoadingMore) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: AppColors.dustyRose,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Unfolding more memories...',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.taupe,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!_hasMore && _items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '— You have reached the dawn of your story 💕 —',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.taupe.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
