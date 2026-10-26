import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:path_provider/path_provider.dart';
import 'ledger_entry.dart';

/// Repository managing real Firestore synchronization with offline local caching
/// for the couple's shared khata / money ledger.
class LedgerRepository {
  static const _fileName = 'couple_ledger.json';

  List<LedgerEntry>? _memoryCache;

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

  /// Loads all real ledger entries from Firestore with local caching fallback.
  /// No dummy data: returns an empty list if no expenses have been recorded yet.
  Future<List<LedgerEntry>> getEntries({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryCache != null) {
      return List<LedgerEntry>.from(_memoryCache!);
    }

    // 1. In non-test environments with Firebase initialized, fetch directly from Firestore
    if (!_isTestEnvironment() && Firebase.apps.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('ledger')
            .orderBy('date', descending: true)
            .get();

        final firestoreEntries = snapshot.docs
            .map((doc) => LedgerEntry.fromJson(doc.data()))
            .where((entry) => !entry.id.startsWith('sample_'))
            .toList();

        // Also sync up any real local entries that were saved while rules were updating
        final localFile = await _getLocalFile();
        if (localFile != null && await localFile.exists()) {
          try {
            final raw = json.decode(await localFile.readAsString());
            if (raw is List) {
              final localEntries = raw
                  .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
                  .where((e) => !e.id.startsWith('sample_'));
              final firestoreIds = firestoreEntries.map((e) => e.id).toSet();
              for (final localItem in localEntries) {
                if (!firestoreIds.contains(localItem.id)) {
                  firestoreEntries.add(localItem);
                  await _syncEntryToFirestore(localItem);
                }
              }
            }
          } catch (_) {}
        }

        firestoreEntries.sort((a, b) => b.date.compareTo(a.date));
        _memoryCache = firestoreEntries;
        await _saveToLocal(firestoreEntries);
        return List<LedgerEntry>.from(firestoreEntries);
      } catch (e) {
        debugPrint('[LedgerRepository] Firestore fetch notice: $e');
      }
    }

    // 2. Fallback to local cached file
    final file = await _getLocalFile();
    if (file != null && await file.exists()) {
      try {
        final content = await file.readAsString();
        final dynamic raw = json.decode(content);
        if (raw is List) {
          final entries = raw
              .map((item) => LedgerEntry.fromJson(item as Map<String, dynamic>))
              .where((entry) => !entry.id.startsWith('sample_'))
              .toList();
          entries.sort((a, b) => b.date.compareTo(a.date));
          _memoryCache = entries;
          return List<LedgerEntry>.from(entries);
        }
      } catch (e) {
        debugPrint('[LedgerRepository] Local read notice: $e');
      }
    }

    // 3. Return clean empty list if no real entries exist
    _memoryCache = [];
    return [];
  }

  Future<void> _saveToLocal(List<LedgerEntry> entries) async {
    final file = await _getLocalFile();
    if (file == null) return;
    try {
      // Filter out any stale dummy entries before persisting
      final cleanList = entries
          .where((e) => !e.id.startsWith('sample_'))
          .toList();
      final jsonList = cleanList.map((e) => e.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('[LedgerRepository] Error writing local ledger: $e');
    }
  }

  /// Adds a new expense or split bill entry to Firestore and local cache
  Future<void> addEntry(LedgerEntry entry) async {
    final current = await getEntries();
    current.removeWhere((item) => item.id == entry.id);
    current.insert(0, entry);
    current.sort((a, b) => b.date.compareTo(a.date));
    _memoryCache = current;

    await _saveToLocal(current);
    await _syncEntryToFirestore(entry);
  }

  /// Deletes an entry by ID from Firestore and local cache
  Future<void> deleteEntry(String id) async {
    final current = await getEntries();
    current.removeWhere((item) => item.id == id);
    _memoryCache = current;

    await _saveToLocal(current);
    await _deleteEntryFromFirestore(id);
  }

  /// Settles all unsettled dues between the couple in Firestore and local cache
  Future<LedgerEntry?> settleUp({
    required String settledBy,
    required String partnerName,
    required double settledAmount,
  }) async {
    if (settledAmount <= 0) return null;

    final current = await getEntries();
    final now = DateTime.now();

    // Mark current active dues as settled
    final updatedList = current.map((item) {
      if (!item.isSettled) {
        return item.copyWith(isSettled: true, settledAt: now);
      }
      return item;
    }).toList();

    // Add a settlement milestone entry
    final settlementEntry = LedgerEntry(
      id: 'settle_${now.millisecondsSinceEpoch}',
      title: 'Settled Up Dues',
      totalBill: settledAmount,
      owedAmount: settledAmount,
      paidBy: settledBy,
      owedBy: partnerName,
      date: now,
      category: LedgerCategory.settlement,
      note: 'All pending balances settled via UPI / Cash 💕',
      type: LedgerType.settlement,
      splitMode: SplitMode.none,
      isSettled: true,
      settledAt: now,
    );

    updatedList.insert(0, settlementEntry);
    updatedList.sort((a, b) => b.date.compareTo(a.date));
    _memoryCache = updatedList;

    await _saveToLocal(updatedList);

    // Update unsettled documents and write settlement in Firestore
    if (!_isTestEnvironment() && Firebase.apps.isNotEmpty) {
      try {
        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();

        for (final item in current.where((e) => !e.isSettled)) {
          final docRef = firestore.collection('ledger').doc(item.id);
          batch.update(docRef, {
            'isSettled': true,
            'settledAt': now.toIso8601String(),
          });
        }

        final settleRef = firestore
            .collection('ledger')
            .doc(settlementEntry.id);
        batch.set(settleRef, settlementEntry.toJson());
        await batch.commit();

        // Also mirror settlement to couples collection
        await firestore
            .collection('couples')
            .doc('puvi_couple')
            .collection('ledger')
            .doc(settlementEntry.id)
            .set(settlementEntry.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('[LedgerRepository] SettleUp Firestore batch notice: $e');
      }
    }

    return settlementEntry;
  }

  Future<void> _syncEntryToFirestore(LedgerEntry entry) async {
    if (_isTestEnvironment() || Firebase.apps.isEmpty) return;
    try {
      final firestore = FirebaseFirestore.instance;
      // Write to top-level ledger collection (triggers Cloud Function notification)
      await firestore
          .collection('ledger')
          .doc(entry.id)
          .set(entry.toJson(), SetOptions(merge: true));

      // Also mirror to couples collection
      await firestore
          .collection('couples')
          .doc('puvi_couple')
          .collection('ledger')
          .doc(entry.id)
          .set(entry.toJson(), SetOptions(merge: true));

      debugPrint(
        '[LedgerRepository] ✓ Synced entry "${entry.title}" to Firestore',
      );
    } catch (e) {
      debugPrint('[LedgerRepository] Cloud sync notice: $e');
    }
  }

  Future<void> _deleteEntryFromFirestore(String id) async {
    if (_isTestEnvironment() || Firebase.apps.isEmpty) return;
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('ledger').doc(id).delete();
      await firestore
          .collection('couples')
          .doc('puvi_couple')
          .collection('ledger')
          .doc(id)
          .delete();
    } catch (_) {}
  }

  /// Calculates net balance for [currentUserName].
  ///
  /// Positive value (+): Partner owes [currentUserName] money.
  /// Negative value (-): [currentUserName] owes partner money.
  /// Zero (0.0): All settled!
  static double calculateNetBalance(
    List<LedgerEntry> entries,
    String currentUserName,
  ) {
    double balance = 0.0;
    final normalizedUser = currentUserName.trim().toLowerCase();

    for (final entry in entries) {
      if (entry.isSettled) continue;

      final normalizedPaidBy = entry.paidBy.trim().toLowerCase();
      final normalizedOwedBy = entry.owedBy.trim().toLowerCase();

      if (normalizedPaidBy == normalizedUser) {
        // Current user paid, partner owes this amount
        balance += entry.owedAmount;
      } else if (normalizedOwedBy == normalizedUser) {
        // Partner paid, current user owes this amount
        balance -= entry.owedAmount;
      }
    }

    return balance;
  }
}
