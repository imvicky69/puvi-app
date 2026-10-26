import 'dart:convert';

/// Category identifiers for couple expenses
abstract final class LedgerCategory {
  static const String dining = 'Dining';
  static const String groceries = 'Groceries';
  static const String travel = 'Travel';
  static const String shopping = 'Shopping';
  static const String bills = 'Bills';
  static const String general = 'General';
  static const String settlement = 'Settlement';

  static const List<String> all = [
    dining,
    groceries,
    travel,
    shopping,
    bills,
    general,
  ];
}

/// The nature of the ledger record
enum LedgerType {
  /// Paid 100% on behalf of partner (Partner owes user)
  lent,

  /// Partner paid 100% on behalf of user (User owes partner)
  borrowed,

  /// Shared bill split 50/50 or custom
  split,

  /// Settle-up payment milestone
  settlement;

  String toJson() => name;
  static LedgerType fromJson(String value) {
    return LedgerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LedgerType.split,
    );
  }
}

/// How the bill was split
enum SplitMode {
  /// 100% covered by one partner
  none,

  /// Equal 50/50 split
  equal,

  /// Custom split amounts
  custom;

  String toJson() => name;
  static SplitMode fromJson(String value) {
    return SplitMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SplitMode.none,
    );
  }
}

/// Represents an individual expense, split bill, or settlement record
class LedgerEntry {
  final String id;
  final String title;
  final double totalBill;
  final double owedAmount;
  final String paidBy;
  final String owedBy;
  final DateTime date;
  final String category;
  final String note;
  final LedgerType type;
  final SplitMode splitMode;
  final bool isSettled;
  final DateTime? settledAt;

  const LedgerEntry({
    required this.id,
    required this.title,
    required this.totalBill,
    required this.owedAmount,
    required this.paidBy,
    required this.owedBy,
    required this.date,
    this.category = LedgerCategory.general,
    this.note = '',
    this.type = LedgerType.split,
    this.splitMode = SplitMode.equal,
    this.isSettled = false,
    this.settledAt,
  });

  LedgerEntry copyWith({
    String? id,
    String? title,
    double? totalBill,
    double? owedAmount,
    String? paidBy,
    String? owedBy,
    DateTime? date,
    String? category,
    String? note,
    LedgerType? type,
    SplitMode? splitMode,
    bool? isSettled,
    DateTime? settledAt,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      totalBill: totalBill ?? this.totalBill,
      owedAmount: owedAmount ?? this.owedAmount,
      paidBy: paidBy ?? this.paidBy,
      owedBy: owedBy ?? this.owedBy,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      type: type ?? this.type,
      splitMode: splitMode ?? this.splitMode,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'totalBill': totalBill,
      'owedAmount': owedAmount,
      'paidBy': paidBy,
      'owedBy': owedBy,
      'date': date.toIso8601String(),
      'category': category,
      'note': note,
      'type': type.toJson(),
      'splitMode': splitMode.toJson(),
      'isSettled': isSettled,
      'settledAt': settledAt?.toIso8601String(),
    };
  }

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Shared Expense',
      totalBill: (json['totalBill'] as num?)?.toDouble() ?? 0.0,
      owedAmount: (json['owedAmount'] as num?)?.toDouble() ?? 0.0,
      paidBy: json['paidBy'] as String? ?? 'Vicky',
      owedBy: json['owedBy'] as String? ?? 'Puja',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: json['category'] as String? ?? LedgerCategory.general,
      note: json['note'] as String? ?? '',
      type: json['type'] != null
          ? LedgerType.fromJson(json['type'] as String)
          : LedgerType.split,
      splitMode: json['splitMode'] != null
          ? SplitMode.fromJson(json['splitMode'] as String)
          : SplitMode.equal,
      isSettled: json['isSettled'] as bool? ?? false,
      settledAt: json['settledAt'] != null
          ? DateTime.tryParse(json['settledAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
