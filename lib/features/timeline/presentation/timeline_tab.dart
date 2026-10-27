import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/timeline_item.dart';
import '../data/timeline_repository.dart';
import 'widgets/add_edit_milestone_dialog.dart';
import 'widgets/milestone_detail_sheet.dart';
import 'widgets/timeline_milestone_card.dart';

/// Full-featured, romantic, and editable Love Letters Timeline tab for Puja & Vicky.
class TimelineTab extends StatefulWidget {
  final String userName;
  final TimelineRepository? repository;

  const TimelineTab({super.key, this.userName = 'Vicky', this.repository});

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  late final TimelineRepository _repository;

  List<TimelineItem> _milestones = [];
  bool _isLoading = true;
  String _activeCategory = 'All';
  bool _newestFirst = false; // Chronological storybook by default

  static const List<String> _filters = [
    'All',
    'Anniversary',
    'Firsts',
    'Dates',
    'Milestones',
    'Love Notes',
    'Long Distance',
    'Favorites',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? TimelineRepository();
    _loadMilestones();
  }

  Future<void> _loadMilestones({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);

    final items = await _repository.getMilestones(
      forceRefresh: forceRefresh,
      categoryFilter: _activeCategory,
      newestFirst: _newestFirst,
    );

    if (mounted) {
      setState(() {
        _milestones = items;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    if (_activeCategory == category) return;
    setState(() {
      _activeCategory = category;
    });
    _loadMilestones();
  }

  void _toggleSortOrder() {
    setState(() {
      _newestFirst = !_newestFirst;
    });
    _loadMilestones();
  }

  Future<void> _handleFavoriteToggle(TimelineItem item) async {
    await _repository.toggleFavorite(item.id);
    await _loadMilestones();
  }

  void _openAddMilestone() {
    AddEditMilestoneDialog.show(
      context: context,
      currentUserName: widget.userName,
      onSave: (newItem) async {
        await _repository.addMilestone(newItem);
        await _loadMilestones(forceRefresh: true);
        if (mounted) {
          _showToast('Chapter "${newItem.title}" sealed with love 💕');
        }
      },
    );
  }

  void _openEditMilestone(TimelineItem item) {
    AddEditMilestoneDialog.show(
      context: context,
      initialItem: item,
      currentUserName: widget.userName,
      onSave: (updated) async {
        await _repository.updateMilestone(updated);
        await _loadMilestones(forceRefresh: true);
        if (mounted) {
          _showToast('Chapter "${updated.title}" updated 🌹');
        }
      },
    );
  }

  void _openDeleteMilestone(TimelineItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderCard),
        title: Text(
          'Let Go of Memory?',
          style: AppTypography.h3.copyWith(color: AppColors.espresso),
        ),
        content: Text(
          'Are you sure you want to gently remove "${item.title}" from your couple timeline?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.taupe),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Keep Treasured',
              style: AppTypography.label.copyWith(color: AppColors.espresso),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.paper,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderButton,
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _repository.deleteMilestone(item.id);
              await _loadMilestones(forceRefresh: true);
              if (mounted) {
                _showToast('Milestone removed from timeline');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openDetailSheet(TimelineItem item) {
    MilestoneDetailSheet.show(
      context: context,
      item: item,
      onFavoriteToggle: () => _handleFavoriteToggle(item),
      onEdit: () => _openEditMilestone(item),
      onDelete: () => _openDeleteMilestone(item),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.paper),
        ),
        backgroundColor: AppColors.burgundy,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderButton,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // Editorial Header
            _buildEditorialHeader(),

            // Category Filter Bar & Sorting Row
            _buildFilterAndSortBar(),

            const Divider(height: 1, color: AppColors.border),

            // Timeline Milestones Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.burgundy,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.burgundy,
                      backgroundColor: AppColors.paper,
                      onRefresh: () => _loadMilestones(forceRefresh: true),
                      child: _milestones.isEmpty
                          ? _buildEmptyState()
                          : _buildMilestonesList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'timeline_add_chapter_fab',
        onPressed: _openAddMilestone,
        backgroundColor: AppColors.burgundy,
        foregroundColor: AppColors.paper,
        elevation: 4,
        tooltip: 'Add Chapter',
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.dustyRose, width: 1.5),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  /// Builds top editorial stationery header
  Widget _buildEditorialHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      color: AppColors.ivory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Our Story',
                style: AppTypography.h1.copyWith(
                  fontSize: 28,
                  color: AppColors.espresso,
                  letterSpacing: -0.5,
                ),
              ),

              // Total milestone counter badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blushSand,
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 13,
                      color: AppColors.burgundy,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_repository.totalCount} Chapters',
                      style: AppTypography.captionSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.espresso,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.verticalXxs,
          Text(
            'Puja & Vicky • Together since April 11, 2026',
            style: AppTypography.caption.copyWith(
              color: AppColors.taupe,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds horizontal scrollable category pills with sort button
  Widget _buildFilterAndSortBar() {
    return Container(
      color: AppColors.ivory,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: _filters.map((filter) {
                final isSelected =
                    _activeCategory.toLowerCase() == filter.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppColors.burgundy,
                    backgroundColor: AppColors.paper,
                    labelStyle: AppTypography.caption.copyWith(
                      color: isSelected ? AppColors.paper : AppColors.espresso,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderPill,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.burgundy
                            : AppColors.border,
                        width: 1,
                      ),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    onSelected: (_) => _onCategorySelected(filter),
                  ),
                );
              }).toList(),
            ),
          ),

          AppSpacing.verticalXxs,

          // Sort direction & active count row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  '${_milestones.length} ${_milestones.length == 1 ? 'memory' : 'memories'} found',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _toggleSortOrder,
                  borderRadius: AppRadius.borderSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _newestFirst
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 13,
                          color: AppColors.burgundy,
                        ),
                        AppSpacing.horizontalXxs,
                        Text(
                          _newestFirst ? 'Newest First' : 'Story Origin (1st)',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.burgundy,
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
        ],
      ),
    );
  }

  /// Builds the scrollable timeline milestones list
  Widget _buildMilestonesList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl + 20, // Bottom clearance for FAB
      ),
      itemCount: _milestones.length,
      itemBuilder: (context, index) {
        final item = _milestones[index];
        final isFirst = index == 0;
        final isLast = index == _milestones.length - 1;

        return TimelineMilestoneCard(
          item: item,
          isFirst: isFirst,
          isLast: isLast,
          onTap: () => _openDetailSheet(item),
          onFavoriteToggle: () => _handleFavoriteToggle(item),
          onEdit: () => _openEditMilestone(item),
          onDelete: () => _openDeleteMilestone(item),
        );
      },
    );
  }

  /// Builds romantic empty state when no items match the filter
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              size: 44,
              color: AppColors.dustyRose,
            ),
            AppSpacing.verticalSm,
            Text(
              'No Chapters in "$_activeCategory"',
              style: AppTypography.h3.copyWith(color: AppColors.espresso),
            ),
            AppSpacing.verticalXs,
            Text(
              'Every tender moment is worth remembering.\nTap "Add Chapter" below to record this memory.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.taupe),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
