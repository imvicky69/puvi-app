import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/ledger_entry.dart';

/// Modal dialog to record an expense or split bill between the couple.
class AddExpenseDialog extends StatefulWidget {
  final String currentUserName;
  final String partnerName;
  final SplitMode initialSplitMode;

  const AddExpenseDialog({
    super.key,
    required this.currentUserName,
    required this.partnerName,
    this.initialSplitMode = SplitMode.equal,
  });

  static Future<LedgerEntry?> show(
    BuildContext context, {
    required String currentUserName,
    required String partnerName,
    SplitMode initialSplitMode = SplitMode.equal,
  }) {
    return showModalBottomSheet<LedgerEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseDialog(
        currentUserName: currentUserName,
        partnerName: partnerName,
        initialSplitMode: initialSplitMode,
      ),
    );
  }

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late String _paidBy;
  late SplitMode _splitMode;
  String _selectedCategory = LedgerCategory.dining;
  final double _customUserShare = 0.0;

  @override
  void initState() {
    super.initState();
    _paidBy = widget.currentUserName;
    _splitMode = widget.initialSplitMode;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _totalBill {
    final text = _amountController.text.trim().replaceAll(',', '');
    return double.tryParse(text) ?? 0.0;
  }

  double get _owedAmount {
    final total = _totalBill;
    if (total <= 0) return 0.0;

    switch (_splitMode) {
      case SplitMode.equal:
        return total / 2;
      case SplitMode.none:
        return total;
      case SplitMode.custom:
        if (_paidBy == widget.currentUserName) {
          final partnerShare = total - _customUserShare;
          return partnerShare > 0 ? partnerShare : 0.0;
        } else {
          return _customUserShare > 0 ? _customUserShare : 0.0;
        }
    }
  }

  String get _livePreviewText {
    final total = _totalBill;
    if (total <= 0) {
      return 'Enter an amount to preview split math';
    }

    final formattedTotal =
        '₹${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)}';
    final formattedOwed =
        '₹${_owedAmount.toStringAsFixed(_owedAmount.truncateToDouble() == _owedAmount ? 0 : 2)}';

    if (_splitMode == SplitMode.equal) {
      final isCurrentUserPayer = _paidBy == widget.currentUserName;
      if (isCurrentUserPayer) {
        return 'Total $formattedTotal • Equal 50/50 • ${widget.partnerName} owes you $formattedOwed';
      } else {
        return 'Total $formattedTotal • Equal 50/50 • You owe ${widget.partnerName} $formattedOwed';
      }
    } else if (_splitMode == SplitMode.none) {
      if (_paidBy == widget.currentUserName) {
        return 'You covered 100% of $formattedTotal • ${widget.partnerName} owes you $formattedTotal';
      } else {
        return '${widget.partnerName} covered 100% of $formattedTotal • You owe ${widget.partnerName} $formattedTotal';
      }
    } else {
      return 'Custom Split • Total $formattedTotal • Net impact $formattedOwed';
    }
  }

  void _saveEntry() {
    final total = _totalBill;
    final title = _titleController.text.trim();

    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid expense amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final entryTitle = title.isNotEmpty ? title : '$_selectedCategory Expense';
    final owedAmount = _owedAmount;
    final isCurrentUserPayer = _paidBy == widget.currentUserName;

    final entry = LedgerEntry(
      id: 'entry_${DateTime.now().millisecondsSinceEpoch}',
      title: entryTitle,
      totalBill: total,
      owedAmount: owedAmount,
      paidBy: _paidBy,
      owedBy: isCurrentUserPayer ? widget.partnerName : widget.currentUserName,
      date: DateTime.now(),
      category: _selectedCategory,
      note: _noteController.text.trim(),
      type: _splitMode == SplitMode.none
          ? (isCurrentUserPayer ? LedgerType.lent : LedgerType.borrowed)
          : LedgerType.split,
      splitMode: _splitMode,
      isSettled: false,
    );

    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Handle Pill
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                AppSpacing.verticalMd,

                // Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Record Couple Expense',
                      style: AppTypography.h2.copyWith(
                        fontSize: 22,
                        color: AppColors.espresso,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.taupe,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                AppSpacing.verticalSm,

                // Big Amount Field
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: AppRadius.borderButton,
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '₹',
                        style: GoogleFonts.dmSans(
                          fontSize: 30,
                          color: AppColors.burgundy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppSpacing.horizontalSm,
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          autofocus: !isKeyboardOpen,
                          style: GoogleFonts.dmSans(
                            fontSize: 30,
                            color: AppColors.espresso,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: GoogleFonts.dmSans(
                              fontSize: 30,
                              color: AppColors.taupe.withValues(alpha: 0.35),
                              fontWeight: FontWeight.w600,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.verticalMd,

                // Expense Title
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.espresso,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'What was this for?',
                    labelStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.taupe,
                    ),
                    hintText: 'e.g. Dinner, Movie, Groceries, Cab',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.taupe.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: AppColors.paper,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderButton,
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderButton,
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderButton,
                      borderSide: const BorderSide(
                        color: AppColors.burgundy,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),

                AppSpacing.verticalMd,

                // Who Paid?
                Text(
                  'Who paid the bill?',
                  style: AppTypography.label.copyWith(
                    fontSize: 13,
                    color: AppColors.taupe,
                  ),
                ),
                AppSpacing.verticalXs,
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectorTile(
                        label: 'You (${widget.currentUserName})',
                        isSelected: _paidBy == widget.currentUserName,
                        onTap: () =>
                            setState(() => _paidBy = widget.currentUserName),
                      ),
                    ),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: _buildSelectorTile(
                        label: widget.partnerName,
                        isSelected: _paidBy == widget.partnerName,
                        onTap: () =>
                            setState(() => _paidBy = widget.partnerName),
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalMd,

                // Split Mode Selection
                Text(
                  'How to split?',
                  style: AppTypography.label.copyWith(
                    fontSize: 13,
                    color: AppColors.taupe,
                  ),
                ),
                AppSpacing.verticalXs,
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectorTile(
                        label: '✂️ Split 50/50',
                        isSelected: _splitMode == SplitMode.equal,
                        onTap: () =>
                            setState(() => _splitMode = SplitMode.equal),
                      ),
                    ),
                    AppSpacing.horizontalXs,
                    Expanded(
                      child: _buildSelectorTile(
                        label: '100% Lent',
                        isSelected: _splitMode == SplitMode.none,
                        onTap: () =>
                            setState(() => _splitMode = SplitMode.none),
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalMd,

                // Live Preview Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blushSand,
                    borderRadius: AppRadius.borderButton,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: AppColors.burgundy,
                      ),
                      AppSpacing.horizontalSm,
                      Expanded(
                        child: Text(
                          _livePreviewText,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.espresso,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.verticalMd,

                // Category Chips
                Text(
                  'Category',
                  style: AppTypography.label.copyWith(
                    fontSize: 13,
                    color: AppColors.taupe,
                  ),
                ),
                AppSpacing.verticalXs,
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: LedgerCategory.all.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
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
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                AppSpacing.verticalMd,

                // Optional Note Field
                TextField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.espresso,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Add sweet memo or note (optional)',
                    labelStyle: AppTypography.caption.copyWith(
                      color: AppColors.taupe,
                    ),
                    hintText: 'e.g. delicious pasta at candlelight 🍷',
                    filled: true,
                    fillColor: AppColors.paper,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderButton,
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderButton,
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.borderButton,
                      borderSide: const BorderSide(
                        color: AppColors.burgundy,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),

                AppSpacing.verticalLg,

                // Save Action Button
                ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burgundy,
                    foregroundColor: AppColors.paper,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderButton,
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 20),
                      AppSpacing.horizontalXs,
                      Text(
                        'Save to Ledger',
                        style: AppTypography.label.copyWith(
                          color: AppColors.paper,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.verticalSm,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.burgundy : AppColors.ivory,
          borderRadius: AppRadius.borderButton,
          border: Border.all(
            color: isSelected ? AppColors.burgundy : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isSelected ? AppColors.paper : AppColors.espresso,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
