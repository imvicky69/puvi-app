import 'package:flutter/material.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Themed dialog for verifying the 4-digit backup PIN.
class VerifyPinDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const VerifyPinDialog({
    super.key,
    this.title = 'Enter Backup PIN',
    this.subtitle = 'Enter your 4-digit PIN to continue',
  });

  static Future<bool> show(
    BuildContext context, {
    String title = 'Enter Backup PIN',
    String subtitle = 'Enter your 4-digit PIN to continue',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => VerifyPinDialog(title: title, subtitle: subtitle),
    );
    return result == true;
  }

  @override
  State<VerifyPinDialog> createState() => _VerifyPinDialogState();
}

class _VerifyPinDialogState extends State<VerifyPinDialog> {
  String _pin = '';
  String? _errorMessage;

  void _onDigitPressed(String digit) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        final isValid = AppLockService.verifyPin(_pin);
        if (isValid) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage = 'Incorrect PIN. Please try again.';
            _pin = '';
          });
        }
      }
    }
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = null;
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderCard,
        side: BorderSide(color: AppColors.border, width: 1.2),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.blushSand,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.burgundy,
                size: 22,
              ),
            ),
            AppSpacing.verticalSm,
            Text(
              widget.title,
              style: AppTypography.h3.copyWith(
                fontSize: 18,
                color: AppColors.espresso,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.taupe,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalMd,

            // 4 Pin Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: filled ? AppColors.burgundy : AppColors.ivory,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: filled ? AppColors.burgundy : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              AppSpacing.verticalSm,
              Text(
                _errorMessage!,
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            AppSpacing.verticalLg,

            // Numeric Keypad
            _NumericKeypad(
              onDigit: _onDigitPressed,
              onDelete: _onDeletePressed,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: AppTypography.label.copyWith(color: AppColors.taupe),
          ),
        ),
      ],
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  const _NumericKeypad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 8),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 8),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 54, height: 44),
            _buildKey('0'),
            SizedBox(
              width: 54,
              height: 44,
              child: IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.backspace_outlined,
                  size: 20,
                  color: AppColors.espresso,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildKey).toList(),
    );
  }

  Widget _buildKey(String digit) {
    return SizedBox(
      width: 54,
      height: 44,
      child: OutlinedButton(
        onPressed: () => onDigit(digit),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.espresso,
          backgroundColor: AppColors.paper,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderButton,
          ),
        ),
        child: Text(
          digit,
          style: AppTypography.h3.copyWith(
            fontSize: 18,
            color: AppColors.espresso,
          ),
        ),
      ),
    );
  }
}
