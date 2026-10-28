import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/couple_encryption_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/puvi_avatar.dart';
import '../../../chat/data/chat_repository.dart';
import '../../../chat/presentation/couple_chat_screen.dart';
import 'secret_ledger_logo_trigger.dart';

/// Top header component for the Puvi home screen.
///
/// Features:
/// - Clean brand logo medallion.
/// - Dynamic time-of-day greeting ("Good morning / afternoon / evening").
/// - User's name in editorial typography.
/// - Interactive chat icon with live unread badge and navigation to CoupleChatScreen.
class HomeHeader extends StatefulWidget {
  final String userName;
  final VoidCallback? onChatPressed;

  const HomeHeader({super.key, this.userName = 'Vicky', this.onChatPressed});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final ChatRepository _chatRepository = ChatRepository();
  StreamSubscription<int>? _unreadSub;
  int _unreadCount = 0;

  String get _myUid => widget.userName.toLowerCase() == 'puja'
      ? CoupleEncryptionService.pujaUid
      : CoupleEncryptionService.vickyUid;

  @override
  void initState() {
    super.initState();
    _unreadSub = _chatRepository.watchUnreadCount(currentUserId: _myUid).listen(
      (count) {
        if (mounted && count != _unreadCount) {
          setState(() => _unreadCount = count);
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userName != widget.userName) {
      _unreadSub?.cancel();
      _unreadSub = _chatRepository
          .watchUnreadCount(currentUserId: _myUid)
          .listen((count) {
            if (mounted && count != _unreadCount) {
              setState(() => _unreadCount = count);
            }
          });
    }
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _unreadCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      color: AppColors.ivory,
      child: Row(
        children: [
          // Clean Brand Logo with secret 3s hold trigger for Couple Ledger
          SecretLedgerLogoTrigger(userName: widget.userName),

          AppSpacing.horizontalMd,

          // Greeting & User Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.taupe,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    PuviAvatar(
                      nameOrUid: widget.userName,
                      size: 26,
                      showBorder: true,
                      borderWidth: 1.2,
                      borderColor: AppColors.dustyRose,
                      backgroundColor: AppColors.ivory,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.userName,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h2.copyWith(
                          fontSize: 22,
                          color: AppColors.espresso,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    AppSpacing.horizontalXs,
                    const Icon(
                      Icons.favorite_rounded,
                      size: 14,
                      color: AppColors.dustyRose,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Top-right interactive chat icon with real-time unread stream
          GestureDetector(
            onTap:
                widget.onChatPressed ??
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CoupleChatScreen(userName: widget.userName),
                    ),
                  );
                },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: AppRadius.borderButton,
                border: Border.all(
                  color: hasUnread ? AppColors.dustyRose : AppColors.border,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espresso.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.espresso,
                    size: 20,
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.burgundy,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
