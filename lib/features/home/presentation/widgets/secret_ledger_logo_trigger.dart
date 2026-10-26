import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ledger/presentation/couple_ledger_screen.dart';

/// Secret easter-egg trigger widget for the Puvi logo.
///
/// Holding the logo continuously for 3.0 seconds animates a subtle
/// progress ring, fires a heavy haptic vibration, and opens the
/// private couple money ledger screen.
class SecretLedgerLogoTrigger extends StatefulWidget {
  final String userName;

  const SecretLedgerLogoTrigger({super.key, this.userName = 'Vicky'});

  @override
  State<SecretLedgerLogoTrigger> createState() =>
      _SecretLedgerLogoTriggerState();
}

class _SecretLedgerLogoTriggerState extends State<SecretLedgerLogoTrigger>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onHoldCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoldCompleted() {
    HapticFeedback.heavyImpact();
    _controller.reset();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CoupleLedgerScreen(userName: widget.userName),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward(from: 0.0);
  }

  void _onTapCancel() {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          final scale = 1.0 + (progress * 0.1);

          return SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle Radial Progress Indicator visible only during hold
                if (progress > 0)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.4,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.burgundy,
                      ),
                      backgroundColor: AppColors.blushSand.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),

                // Scaled Brand Logo
                Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: Image.asset(
                      'assets/logo_transparent.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
