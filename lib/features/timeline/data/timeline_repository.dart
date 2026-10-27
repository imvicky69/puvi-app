import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:path_provider/path_provider.dart';
import 'timeline_item.dart';

/// Repository managing real Firestore synchronization with offline local caching
/// for Puja & Vicky's romantic relationship timeline milestones.
class TimelineRepository {
  static const _fileName = 'timeline_cache.json';

  List<TimelineItem>? _memoryCache;
  bool _isInitialized = false;

  bool _isTestEnvironment() {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  Future<File?> _getLocalFile() async {
    if (_isTestEnvironment()) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_fileName');
    } catch (_) {
      return null;
    }
  }

  /// Initializes the repository by loading bundled assets, local cached overrides,
  /// and attempting a real-time fetch from Firestore.
  Future<void> initialize() async {
    if (_isInitialized) return;

    List<TimelineItem> items = [];

    // Tier 1: Try local cache file
    final localFile = await _getLocalFile();
    if (localFile != null && await localFile.exists()) {
      try {
        final content = await localFile.readAsString();
        final dynamic raw = json.decode(content);
        if (raw is List) {
          items = raw
              .map((e) => TimelineItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('[TimelineRepository] Notice reading local cache: $e');
      }
    }

    // Tier 2: If local cache is empty, load bundled offline asset
    if (items.isEmpty) {
      try {
        final assetString = await rootBundle
            .loadString('assets/timeline.json')
            .timeout(const Duration(milliseconds: 500), onTimeout: () => '');
        if (assetString.isNotEmpty) {
          final dynamic raw = json.decode(assetString);
          if (raw is List) {
            items = raw
                .map((e) => TimelineItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (e) {
        debugPrint('[TimelineRepository] Notice loading bundled asset: $e');
      }
    }

    _memoryCache = items;
    _isInitialized = true;

    // Tier 3: Fetch fresh state from Firestore in background
    if (!_isTestEnvironment() && Firebase.apps.isNotEmpty) {
      unawaited(_fetchFromFirestore());
    }
  }

  Future<void> _fetchFromFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('timeline').get();

      if (snapshot.docs.isNotEmpty) {
        final firestoreItems = snapshot.docs.map((doc) {
          final data = doc.data();
          data['_id'] = doc.id;
          return TimelineItem.fromJson(data);
        }).toList();

        _memoryCache = firestoreItems;
        await _saveToLocal(firestoreItems);
        debugPrint(
          '[TimelineRepository] ✓ Synced ${firestoreItems.length} milestones from Firestore',
        );
      }
    } catch (e) {
      debugPrint('[TimelineRepository] Cloud Firestore sync notice: $e');
    }
  }

  Future<void> _saveToLocal(List<TimelineItem> items) async {
    final file = await _getLocalFile();
    if (file == null) return;
    try {
      final jsonList = items.map((e) => e.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('[TimelineRepository] Error saving local timeline: $e');
    }
  }

  /// Retrieves all milestones, filtered and sorted.
  /// [newestFirst]: When false, shows the romantic chronological story from the beginning.
  Future<List<TimelineItem>> getMilestones({
    bool forceRefresh = false,
    String? categoryFilter,
    bool newestFirst = false,
  }) async {
    if (!_isInitialized || forceRefresh) {
      await initialize();
      if (forceRefresh && !_isTestEnvironment() && Firebase.apps.isNotEmpty) {
        await _fetchFromFirestore();
      }
    }

    List<TimelineItem> list = List<TimelineItem>.from(_memoryCache ?? []);

    // Filter by category if specified and not 'All'
    if (categoryFilter != null &&
        categoryFilter.isNotEmpty &&
        categoryFilter.toLowerCase() != 'all') {
      if (categoryFilter.toLowerCase() == 'favorites') {
        list = list.where((item) => item.isFavorite).toList();
      } else {
        list = list
            .where(
              (item) =>
                  item.category.toLowerCase() == categoryFilter.toLowerCase(),
            )
            .toList();
      }
    }

    // Sort chronologically or reverse-chronologically
    list.sort((a, b) {
      return newestFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date);
    });

    return list;
  }

  /// Adds a new romantic milestone to Firestore and local cache.
  Future<void> addMilestone(TimelineItem item) async {
    if (_memoryCache == null) {
      await initialize();
    }

    _memoryCache!.removeWhere((i) => i.id == item.id);
    _memoryCache!.add(item);
    await _saveToLocal(_memoryCache!);

    // Sync to Firestore
    if (!_isTestEnvironment() && Firebase.apps.isNotEmpty) {
      try {
        final firestore = FirebaseFirestore.instance;
        final docRef = firestore.collection('timeline').doc(item.id);
        await docRef.set(item.toJson(), SetOptions(merge: true));

        // Mirror to couple collection
        await firestore
            .collection('couples')
            .doc('puvi_couple')
            .collection('timeline')
            .doc(item.id)
            .set(item.toJson(), SetOptions(merge: true));

        debugPrint(
          '[TimelineRepository] ✓ Added milestone "${item.title}" to Firestore',
        );
      } catch (e) {
        debugPrint('[TimelineRepository] Error adding milestone to cloud: $e');
      }
    }
  }

  /// Updates an existing milestone in Firestore and local cache.
  Future<void> updateMilestone(TimelineItem updated) async {
    if (_memoryCache == null) {
      await initialize();
    }

    final index = _memoryCache!.indexWhere((i) => i.id == updated.id);
    if (index != -1) {
      _memoryCache![index] = updated;
    } else {
      _memoryCache!.add(updated);
    }
    await _saveToLocal(_memoryCache!);

    // Sync to Firestore
    if (!_isTestEnvironment() && Firebase.apps.isNotEmpty) {
      try {
        final firestore = FirebaseFirestore.instance;
        final docRef = firestore.collection('timeline').doc(updated.id);
        await docRef.set(updated.toJson(), SetOptions(merge: true));

        await firestore
            .collection('couples')
            .doc('puvi_couple')
            .collection('timeline')
            .doc(updated.id)
            .set(updated.toJson(), SetOptions(merge: true));

        debugPrint(
          '[TimelineRepository] ✓ Updated milestone "${updated.title}" in Firestore',
        );
      } catch (e) {
        debugPrint(
          '[TimelineRepository] Error updating milestone in cloud: $e',
        );
      }
    }
  }

  /// Deletes a milestone from Firestore and local cache.
  Future<void> deleteMilestone(String id) async {
    if (_memoryCache == null) {
      await initialize();
    }

    _memoryCache!.removeWhere((i) => i.id == id);
    await _saveToLocal(_memoryCache!);

    // Delete in Firestore
    if (!_isTestEnvironment() && Firebase.apps.isNotEmpty) {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('timeline').doc(id).delete();
        await firestore
            .collection('couples')
            .doc('puvi_couple')
            .collection('timeline')
            .doc(id)
            .delete();

        debugPrint(
          '[TimelineRepository] ✓ Deleted milestone $id from Firestore',
        );
      } catch (e) {
        debugPrint(
          '[TimelineRepository] Error deleting milestone in cloud: $e',
        );
      }
    }
  }

  /// Toggles favorite status for a milestone.
  Future<void> toggleFavorite(String id) async {
    if (_memoryCache == null) {
      await initialize();
    }

    final index = _memoryCache!.indexWhere((i) => i.id == id);
    if (index != -1) {
      final current = _memoryCache![index];
      final updated = current.copyWith(isFavorite: !current.isFavorite);
      await updateMilestone(updated);
    }
  }

  int get totalCount => _memoryCache?.length ?? 0;
}
