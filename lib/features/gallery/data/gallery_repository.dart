import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'gallery_item.dart';

enum GalleryFilter { all, photos, videos, favorites }

/// Repository responsible for paginated, on-demand loading of gallery memories.
class GalleryRepository {
  List<GalleryItem> _allItems = [];
  bool _isInitialized = false;

  /// Loads and caches all items into memory once, then serves paginated queries.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final jsonString = await rootBundle.loadString('assets/gallery.json');
      final dynamic raw = json.decode(jsonString);
      if (raw is List) {
        _allItems = raw
            .map((item) => GalleryItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Graceful fallback: return empty or sample items if asset is unavailable
      _allItems = [];
    }

    // Sort chronologically newest first
    _allItems.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    _isInitialized = true;
  }

  int get totalCount => _allItems.length;
  int get photosCount => _allItems.where((i) => !i.isVideo).length;
  int get videosCount => _allItems.where((i) => i.isVideo).length;
  int get favoritesCount => _allItems.where((i) => i.isFavorite).length;

  /// Retrieves a paginated slice of memories according to the active filter.
  Future<List<GalleryItem>> fetchPage({
    required int page,
    int pageSize = 14,
    GalleryFilter filter = GalleryFilter.all,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Filter items
    List<GalleryItem> filtered;
    switch (filter) {
      case GalleryFilter.all:
        filtered = _allItems;
        break;
      case GalleryFilter.photos:
        filtered = _allItems.where((i) => !i.isVideo).toList();
        break;
      case GalleryFilter.videos:
        filtered = _allItems.where((i) => i.isVideo).toList();
        break;
      case GalleryFilter.favorites:
        filtered = _allItems.where((i) => i.isFavorite).toList();
        break;
    }

    final startIndex = (page - 1) * pageSize;
    if (startIndex >= filtered.length) {
      return [];
    }

    final endIndex = (startIndex + pageSize).clamp(0, filtered.length);
    
    // Simulate slight natural async fetch for smooth dynamic loading (skipped during tests)
    final isTesting =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTesting) {
      await Future.delayed(const Duration(milliseconds: 120));
    }

    return filtered.sublist(startIndex, endIndex);
  }

  /// Toggles favorite state of an item
  void toggleFavorite(String id) {
    final index = _allItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final current = _allItems[index];
      _allItems[index] = current.copyWith(isFavorite: !current.isFavorite);
    }
  }
}
