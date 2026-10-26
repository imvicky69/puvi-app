import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Modal dialog to confirm and record settling all outstanding couple dues.
class SettleUpDialog extends StatelessWidget {
  final String currentUserName;
  final String partnerName;
  final double netBalance;

  const SettleUpDialog({
    super.key,
    required this.currentUserName,
    required this.partnerName,
    required this.netBalance,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String currentUserName,
    required String partnerName,
    required double netBalance,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettleUpDialog(
        currentUserName: currentUserName,
        partnerName: partnerName,
        netBalance: netBalance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final absAmount = netBalance.abs();
    final formattedAmount =
        '₹${absAmount.toStringAsFixed(absAmount.truncateToDouble() == absAmount ? 0 : 2)}';
    final isPartnerOwing = netBalance > 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
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

              AppSpacing.verticalSm,

              // Icon & Title
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.blushSand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
              ),

              AppSpacing.verticalSm,

              Center(
                child: Text(
                  'Settle Up Dues',
                  style: AppTypography.h2.copyWith(
                    fontSize: 22,
                    color: AppColors.espresso,
                  ),
                ),
              ),

              AppSpacing.verticalXs,

              Center(
                child: Text(
                  isPartnerOwing
                      ? '$partnerName pays you $formattedAmount'
                      : 'You pay $partnerName $formattedAmount',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                    fontSize: 14,
                  ),
                ),
              ),

              AppSpacing.verticalMd,

              // Settlement Highlight Box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: AppRadius.borderCard,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      formattedAmount,
                      style: GoogleFonts.dmSans(
                        fontSize: 34,
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    AppSpacing.verticalXs,
                    Text(
                      'This marks all current pending items as settled and clears the balance to zero 💕',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: AppColors.taupe,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.verticalMd,

              // Confirm Button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.paper,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderButton,
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 20),
                    AppSpacing.horizontalXs,
                    Text(
                      'Confirm Settlement',
                      style: GoogleFonts.dmSans(
                        color: AppColors.paper,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.verticalXs,

              // Cancel Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.dmSans(
                    color: AppColors.taupe,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
