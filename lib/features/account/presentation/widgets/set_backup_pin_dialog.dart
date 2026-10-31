import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Themed dialog for setting or changing the 4-digit backup PIN for App Lock.
class SetBackupPinDialog extends StatefulWidget {
  const SetBackupPinDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SetBackupPinDialog(),
    );
  }

  @override
  State<SetBackupPinDialog> createState() => _SetBackupPinDialogState();
}

class _SetBackupPinDialogState extends State<SetBackupPinDialog> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _onDigitPressed(String digit) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (!_isConfirming) {
      if (_pin.length < 4) {
        setState(() => _pin += digit);
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                _isConfirming = true;
              });
            }
          });
        }
      }
    } else {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin += digit);
        if (_confirmPin.length == 4) {
          if (_pin == _confirmPin) {
            Navigator.of(context).pop(_pin);
          } else {
            setState(() {
              _errorMessage = 'PINs do not match. Please try again.';
              _pin = '';
              _confirmPin = '';
              _isConfirming = false;
            });
          }
        }
      }
    }
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCode = _isConfirming ? _confirmPin : _pin;

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
              _isConfirming ? 'Confirm Backup PIN' : 'Set 4-Digit Backup PIN',
              style: AppTypography.h3.copyWith(
                fontSize: 18,
                color: AppColors.espresso,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _isConfirming
                  ? 'Re-enter your PIN to confirm'
                  : 'Used if fingerprint / face ID is unavailable',
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
                final filled = index < activeCode.length;
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
          onPressed: () => Navigator.of(context).pop(null),
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
