import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../data/ledger_entry.dart';
import '../data/ledger_repository.dart';
import 'widgets/add_expense_dialog.dart';
import 'widgets/settle_up_dialog.dart';

/// Dedicated screen for the couple's shared khata / money ledger.
class CoupleLedgerScreen extends StatefulWidget {
  final String userName;

  const CoupleLedgerScreen({super.key, this.userName = 'Vicky'});

  @override
  State<CoupleLedgerScreen> createState() => _CoupleLedgerScreenState();
}

class _CoupleLedgerScreenState extends State<CoupleLedgerScreen> {
  final LedgerRepository _repository = LedgerRepository();
  List<LedgerEntry> _entries = [];
  bool _isLoading = true;
  String _activeFilter = 'All'; // 'All', 'Split', 'Lent', 'Borrowed', 'Settled'

  String get _currentUserName => widget.userName;
  String get _partnerName =>
      widget.userName.toLowerCase() == 'puja' ? 'Vicky' : 'Puja';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries({bool forceRefresh = false}) async {
    final list = await _repository.getEntries(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _entries = list;
        _isLoading = false;
      });
    }
  }

  double get _netBalance {
    return LedgerRepository.calculateNetBalance(_entries, _currentUserName);
  }

  double get _totalSharedSpent {
    double total = 0.0;
    for (final e in _entries) {
      total += e.totalBill;
    }
    return total;
  }

  int get _unsettledCount {
    return _entries.where((e) => !e.isSettled).length;
  }

  List<LedgerEntry> get _filteredEntries {
    final user = _currentUserName.toLowerCase();
    switch (_activeFilter) {
      case 'Lent':
        return _entries
            .where(
              (e) =>
                  !e.isSettled &&
                  e.paidBy.toLowerCase() == user &&
                  e.type != LedgerType.settlement,
            )
            .toList();
      case 'Borrowed':
        return _entries
            .where(
              (e) =>
                  !e.isSettled &&
                  e.owedBy.toLowerCase() == user &&
                  e.type != LedgerType.settlement,
            )
            .toList();
      case 'Split':
        return _entries
            .where((e) => e.splitMode == SplitMode.equal && !e.isSettled)
            .toList();
      case 'Settled':
        return _entries.where((e) => e.isSettled).toList();
      case 'All':
      default:
        return _entries;
    }
  }

  Future<void> _openAddExpenseModal({required SplitMode splitMode}) async {
    final newEntry = await AddExpenseDialog.show(
      context,
      currentUserName: _currentUserName,
      partnerName: _partnerName,
      initialSplitMode: splitMode,
    );

    if (newEntry != null) {
      await _repository.addEntry(newEntry);
      HapticFeedback.lightImpact();
      _loadEntries(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${newEntry.title}" to shared ledger 💕'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.espresso,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleSettleUp() async {
    final balance = _netBalance;
    if (balance == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All balances are already settled up! 💕'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await SettleUpDialog.show(
      context,
      currentUserName: _currentUserName,
      partnerName: _partnerName,
      netBalance: balance,
    );

    if (confirmed == true) {
      final isPartnerOwing = balance > 0;
      await _repository.settleUp(
        settledBy: isPartnerOwing ? _partnerName : _currentUserName,
        partnerName: isPartnerOwing ? _currentUserName : _partnerName,
        settledAmount: balance.abs(),
      );

      HapticFeedback.heavyImpact();
      _loadEntries(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Balance settled! All clear 💕'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteEntry(LedgerEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderCard,
          side: BorderSide.none,
        ),
        title: Text(
          'Delete Entry?',
          style: AppTypography.h3.copyWith(color: AppColors.espresso),
        ),
        content: Text(
          'Are you sure you want to remove "${entry.title}" from the ledger?',
          style: GoogleFonts.dmSans(color: AppColors.taupe, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppColors.taupe, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.paper,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderButton,
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _repository.deleteEntry(entry.id);
      _loadEntries(forceRefresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry removed from ledger'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case LedgerCategory.dining:
        return Icons.restaurant_rounded;
      case LedgerCategory.groceries:
        return Icons.shopping_basket_rounded;
      case LedgerCategory.travel:
        return Icons.local_taxi_rounded;
      case LedgerCategory.shopping:
        return Icons.shopping_bag_rounded;
      case LedgerCategory.bills:
        return Icons.receipt_long_rounded;
      case LedgerCategory.settlement:
        return Icons.handshake_rounded;
      case LedgerCategory.general:
      default:
        return Icons.receipt_rounded;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0 && date.day == now.day) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:$minute $period';
    } else if (difference.inDays <= 1 && now.day - date.day == 1) {
      return 'Yesterday';
    } else {
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
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(),

            const Divider(),

            // Main Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.burgundy,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadEntries(forceRefresh: true),
                      color: AppColors.burgundy,
                      backgroundColor: AppColors.paper,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. Net Balance Hero Card (Clean, Bold, Readable)
                                _buildNetBalanceCard(),

                                AppSpacing.verticalMd,

                                // 2. Quick Action Buttons Row
                                _buildActionButtons(),

                                AppSpacing.verticalLg,

                                // 3. Filter Chips
                                _buildFilterBar(),

                                AppSpacing.verticalMd,

                                // 4. History Timeline List
                                _buildHistoryList(),

                                AppSpacing.verticalXxl,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.ivory,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.espresso,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppSpacing.horizontalXs,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Couple Ledger',
                  style: AppTypography.h2.copyWith(
                    fontSize: 22,
                    color: AppColors.espresso,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Shared Khata • $_currentUserName & $_partnerName',
                  style: GoogleFonts.dmSans(
                    color: AppColors.taupe,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: AppColors.taupe,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.paper,
                  surfaceTintColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderCard,
                    side: BorderSide.none,
                  ),
                  title: Text(
                    'About Shared Khata',
                    style: AppTypography.h3.copyWith(color: AppColors.espresso),
                  ),
                  content: Text(
                    'A private, real-time shared ledger for Puja & Vicky to comfortably manage shared dining, bills, and mutual expenses.\n\n'
                    '• Long-press the home logo for 3s to open anytime\n'
                    '• Tap Split 50/50 for instant half-share tracking\n'
                    '• All entries are safely updated in Firestore and notify your partner 💕',
                    style: GoogleFonts.dmSans(
                      color: AppColors.espresso,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNetBalanceCard() {
    final balance = _netBalance;
    final isPositive = balance > 0;
    final isSettled = balance == 0;
    final absAmount = balance.abs();
    final formattedAmount =
        '₹${absAmount.toStringAsFixed(absAmount.truncateToDouble() == absAmount ? 0 : 2)}';

    Color headlineColor;
    String statusTitle;
    String subtext;
    IconData statusIcon;

    if (isSettled) {
      headlineColor = AppColors.dustyRose;
      statusTitle = 'All settled up! Zero dues 💕';
      subtext = 'Everything is balanced between both of you';
      statusIcon = Icons.favorite_rounded;
    } else if (isPositive) {
      headlineColor = AppColors.success;
      statusTitle = '$_partnerName owes you';
      subtext = 'You covered recent shared outings or bills';
      statusIcon = Icons.arrow_downward_rounded;
    } else {
      headlineColor = AppColors.burgundy;
      statusTitle = 'You owe $_partnerName';
      subtext = '$_partnerName paid for recent shared expenses';
      statusIcon = Icons.arrow_upward_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.borderLargeCard,
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.espresso.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Status Badge & Active Items Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blushSand,
                  borderRadius: AppRadius.borderPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: headlineColor),
                    AppSpacing.horizontalXxs,
                    Text(
                      isSettled
                          ? 'Settled'
                          : (isPositive ? 'You are owed' : 'You owe'),
                      style: GoogleFonts.dmSans(
                        color: headlineColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$_unsettledCount active ${_unsettledCount == 1 ? 'item' : 'items'}',
                style: GoogleFonts.dmSans(
                  color: AppColors.taupe,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          AppSpacing.verticalMd,

          // Large, Bold, Clear DM Sans Amount
          if (!isSettled) ...[
            Text(
              formattedAmount,
              style: GoogleFonts.dmSans(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: headlineColor,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              statusTitle,
              style: AppTypography.h2.copyWith(
                fontSize: 20,
                color: AppColors.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Text(
              statusTitle,
              style: AppTypography.h2.copyWith(
                fontSize: 24,
                color: AppColors.espresso,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 4),

          Text(
            subtext,
            style: GoogleFonts.dmSans(
              color: AppColors.taupe,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),

          AppSpacing.verticalMd,
          const Divider(),
          AppSpacing.verticalXs,

          // Total Shared Spent Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Shared Spent (All-Time)',
                style: GoogleFonts.dmSans(
                  color: AppColors.taupe,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${_totalSharedSpent.toStringAsFixed(0)}',
                style: GoogleFonts.dmSans(
                  color: AppColors.espresso,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // 1. Split 50/50 Button
        Expanded(
          child: ElevatedButton(
            onPressed: () => _openAddExpenseModal(splitMode: SplitMode.equal),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.burgundy,
              foregroundColor: AppColors.paper,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderButton,
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.call_split_rounded, size: 18),
                AppSpacing.horizontalXs,
                Text(
                  'Split 50/50',
                  style: GoogleFonts.dmSans(
                    color: AppColors.paper,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        AppSpacing.horizontalSm,

        // 2. 100% Lent / Borrowed
        Expanded(
          child: OutlinedButton(
            onPressed: () => _openAddExpenseModal(splitMode: SplitMode.none),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.paper,
              foregroundColor: AppColors.espresso,
              side: const BorderSide(color: AppColors.border, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.borderButton,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.espresso,
                ),
                AppSpacing.horizontalXs,
                Text(
                  'Direct Lent',
                  style: GoogleFonts.dmSans(
                    color: AppColors.espresso,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        AppSpacing.horizontalSm,

        // 3. Settle Up Action
        IconButton(
          tooltip: 'Settle Up Balance',
          onPressed: _handleSettleUp,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.blushSand,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.borderButton,
            ),
            padding: const EdgeInsets.all(12),
          ),
          icon: const Icon(
            Icons.handshake_rounded,
            color: AppColors.burgundy,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Split', 'Lent', 'Borrowed', 'Settled'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              selectedColor: AppColors.burgundy,
              backgroundColor: AppColors.paper,
              labelStyle: GoogleFonts.dmSans(
                color: isSelected ? AppColors.paper : AppColors.espresso,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderPill,
                side: BorderSide(
                  color: isSelected ? AppColors.burgundy : AppColors.border,
                  width: 1,
                ),
              ),
              onSelected: (val) {
                if (val) setState(() => _activeFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList() {
    final list = _filteredEntries;

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: AppRadius.borderCard,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppColors.dustyRose,
            ),
            AppSpacing.verticalSm,
            Text(
              _entries.isEmpty
                  ? 'No Shared Dues Yet 💕'
                  : 'No records in "$_activeFilter"',
              style: AppTypography.h3.copyWith(
                fontSize: 18,
                color: AppColors.espresso,
              ),
            ),
            AppSpacing.verticalXs,
            Text(
              _entries.isEmpty
                  ? 'Tap "Split 50/50" or "Direct Lent" above to log your first shared couple expense!'
                  : 'Try selecting a different filter above 💕',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColors.taupe,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: list.map((entry) => _buildTransactionCard(entry)).toList(),
    );
  }

  Widget _buildTransactionCard(LedgerEntry entry) {
    final user = _currentUserName.toLowerCase();
    final isPayer = entry.paidBy.toLowerCase() == user;
    final isSettlement = entry.type == LedgerType.settlement;
    final isSplit = entry.splitMode == SplitMode.equal;

    String amountDisplay;
    Color amountColor;

    if (entry.isSettled && isSettlement) {
      amountDisplay = '₹${entry.totalBill.toStringAsFixed(0)}';
      amountColor = AppColors.taupe;
    } else if (entry.isSettled) {
      amountDisplay = '₹${entry.owedAmount.toStringAsFixed(0)} (Settled)';
      amountColor = AppColors.taupe;
    } else if (isPayer) {
      amountDisplay = '+₹${entry.owedAmount.toStringAsFixed(0)}';
      amountColor = AppColors.success;
    } else {
      amountDisplay = '-₹${entry.owedAmount.toStringAsFixed(0)}';
      amountColor = AppColors.burgundy;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.borderCard,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: InkWell(
        borderRadius: AppRadius.borderCard,
        onLongPress: () => _confirmDeleteEntry(entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Icon
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isSettlement ? AppColors.blushSand : AppColors.ivory,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(entry.category),
                  color: isSettlement ? AppColors.success : AppColors.burgundy,
                  size: 20,
                ),
              ),

              AppSpacing.horizontalMd,

              // Details Column (Expanded to prevent overflow)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.espresso,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Responsive Wrap for badge and date (never overflows!)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (isSplit)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blushSand,
                              borderRadius: AppRadius.borderPill,
                            ),
                            child: Text(
                              '50/50 Split • ₹${entry.totalBill.toStringAsFixed(0)}',
                              style: GoogleFonts.dmSans(
                                color: AppColors.burgundy,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Text(
                          _formatDate(entry.date),
                          style: GoogleFonts.dmSans(
                            color: AppColors.taupe,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: AppColors.taupe,
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              AppSpacing.horizontalSm,

              // Amount Badge (Crisp Bold DM Sans)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountDisplay,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isSettlement ? 'Settled' : '${entry.paidBy} paid',
                    style: GoogleFonts.dmSans(
                      color: AppColors.taupe,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
