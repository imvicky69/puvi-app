import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/couple_encryption_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/puvi_avatar.dart';
import '../data/chat_message.dart';
import '../data/chat_repository.dart';
import 'widgets/chat_audio_bubble.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_composer_bar.dart';
import 'widgets/chat_date_separator.dart';
import 'widgets/chat_emotion_bubble.dart';
import 'widgets/chat_emotion_effects.dart';
import 'widgets/quick_emotion_drawer.dart';

/// Private, intimate couple chat screen for Puja & Vicky.
///
/// Features:
/// - Strictly End-to-End Encrypted (AES-256-CBC).
/// - Opens directly at the most recent message with inverted reverse list layout.
/// - Edit and delete messages on long-press hold.
/// - Record, upload and listen to audio voice notes in Firebase Storage.
/// - 4 Dramatic interactive emotions: Kiss (💋), Hug (🤗), Angry (🔪), Flower (🌸).
/// - Fully responsive header with zero pixel overflow.
class CoupleChatScreen extends StatefulWidget {
  final String userName;

  const CoupleChatScreen({super.key, this.userName = 'Vicky'});

  @override
  State<CoupleChatScreen> createState() => _CoupleChatScreenState();
}

class _CoupleChatScreenState extends State<CoupleChatScreen> {
  final ChatRepository _repository = ChatRepository();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<List<ChatMessage>>? _messagesSub;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  String? _activeEmotionEffect;
  int _lastKnownMessageCount = 0;

  String get _myUid => widget.userName.toLowerCase() == 'puja'
      ? CoupleEncryptionService.pujaUid
      : CoupleEncryptionService.vickyUid;

  String get _partnerUid => widget.userName.toLowerCase() == 'puja'
      ? CoupleEncryptionService.vickyUid
      : CoupleEncryptionService.pujaUid;

  String get _partnerName =>
      widget.userName.toLowerCase() == 'puja' ? 'Vicky' : 'Puja';

  @override
  void initState() {
    super.initState();

    // 1. Initialize E2EE service
    CoupleEncryptionService.initialize();

    // 2. Mark unread messages as seen on entry
    _repository.markMessagesAsSeen(currentUserId: _myUid);

    // 3. Listen to real-time conversation stream
    _messagesSub = _repository.watchMessages().listen((messages) {
      if (!mounted) return;

      final bool isFirstLoad = _isLoading;
      final bool hasNewIncoming =
          !isFirstLoad &&
          messages.length > _lastKnownMessageCount &&
          messages.isNotEmpty &&
          messages.last.senderId != _myUid;

      setState(() {
        _messages = messages;
        _isLoading = false;
        _lastKnownMessageCount = messages.length;
      });

      // If a new emotion was just received live from the partner, trigger its dramatic effect!
      if (hasNewIncoming && messages.last.isEmotion) {
        _triggerEmotionEffect(messages.last.type);
      }

      // Mark seen on new incoming message while in view
      if (hasNewIncoming) {
        _repository.markMessagesAsSeen(currentUserId: _myUid);
      }
    });
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerEmotionEffect(String type) {
    setState(() {
      _activeEmotionEffect = type;
    });
  }

  Future<void> _handleSendText(String text) async {
    if (_isSending || text.trim().isEmpty) return;
    setState(() => _isSending = true);

    try {
      await _repository.sendMessage(
        senderId: _myUid,
        receiverId: _partnerUid,
        type: ChatMessageType.text,
        text: text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send note: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleSendVoiceNote(String path, int durationSeconds) async {
    if (_isSending) return;
    setState(() => _isSending = true);

    try {
      await _repository.sendVoiceNote(
        senderId: _myUid,
        receiverId: _partnerUid,
        localFilePath: path,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send voice memo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleSendEmotion(String type) async {
    // 1. Immediately play the dramatic effect locally
    _triggerEmotionEffect(type);

    // 2. Persist to Firestore with E2EE
    try {
      await _repository.sendMessage(
        senderId: _myUid,
        receiverId: _partnerUid,
        type: type,
        text: '',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send emotion: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    HapticFeedback.mediumImpact();
    final isMe = message.senderId == _myUid;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.borderPill,
                  ),
                ),
                AppSpacing.verticalMd,

                // Note info header with mascot avatar
                Row(
                  children: [
                    PuviAvatar(
                      nameOrUid: isMe ? widget.userName : _partnerName,
                      size: 38,
                      showBorder: true,
                      borderWidth: 1.2,
                      borderColor: AppColors.border,
                      backgroundColor: AppColors.ivory,
                    ),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMe ? 'Note by You' : 'Note from $_partnerName',
                            style: AppTypography.label.copyWith(
                              color: AppColors.espresso,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            message.isAudio
                                ? 'Voice note • ${message.durationSeconds}s'
                                : (message.isEmotion
                                      ? '${message.emotionTitle} emotion'
                                      : 'End-to-End Encrypted note'),
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.taupe,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSm,
                const Divider(),

                // Copy Action
                if (message.text.isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.copy_rounded,
                      color: AppColors.espresso,
                      size: 20,
                    ),
                    title: Text(
                      'Copy note',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.espresso,
                      ),
                    ),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.text));
                      Navigator.of(bottomSheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied note to clipboard 💕'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                // Edit Action (Sender only, Text notes only)
                if (isMe && message.type == ChatMessageType.text)
                  ListTile(
                    leading: const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.espresso,
                      size: 22,
                    ),
                    title: Text(
                      'Edit note',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.espresso,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      _showEditDialog(context, message);
                    },
                  ),

                // Replay Dramatic Effect (Emotions)
                if (message.isEmotion)
                  ListTile(
                    leading: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.burgundy,
                      size: 20,
                    ),
                    title: Text(
                      'Replay dramatic effect ✨',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.burgundy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      _triggerEmotionEffect(message.type);
                    },
                  ),

                // Delete Action (Sender or Partner)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  title: Text(
                    'Delete note',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _confirmDelete(context, message);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, ChatMessage message) {
    final editController = TextEditingController(text: message.text);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderCard),
          title: Text(
            'Edit Love Note',
            style: AppTypography.h3.copyWith(
              fontSize: 18,
              color: AppColors.espresso,
            ),
          ),
          content: TextField(
            controller: editController,
            maxLines: 4,
            autofocus: true,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.espresso),
            decoration: InputDecoration(
              hintText: 'Edit your note...',
              filled: true,
              fillColor: AppColors.ivory,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderButton,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderButton,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderButton,
                borderSide: const BorderSide(
                  color: AppColors.burgundy,
                  width: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: AppTypography.label.copyWith(color: AppColors.taupe),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.burgundy,
                foregroundColor: AppColors.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderButton,
                ),
              ),
              onPressed: () async {
                final newText = editController.text.trim();
                if (newText.isNotEmpty && newText != message.text) {
                  Navigator.of(dialogContext).pop();
                  await _repository.editMessage(
                    messageId: message.id,
                    newText: newText,
                  );
                } else {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ChatMessage message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.paper,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderCard),
          title: Text(
            'Delete Message?',
            style: AppTypography.h3.copyWith(
              fontSize: 18,
              color: AppColors.espresso,
            ),
          ),
          content: Text(
            'This message will be permanently removed from your couple conversation.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.taupe),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Keep',
                style: AppTypography.label.copyWith(color: AppColors.taupe),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderButton,
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _repository.deleteMessage(messageId: message.id);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showPartnerProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isVickyPartner = PuviAvatar.isVicky(_partnerName);
        final title = isVickyPartner
            ? 'Vicky • The Protector'
            : 'Puja • The Sunshine';
        final quote = isVickyPartner
            ? '“Loved by Puja, forever & always.”'
            : '“Cherished by Vicky, with every heartbeat.”';

        return AlertDialog(
          backgroundColor: AppColors.paper,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderLargeCard,
            side: BorderSide(color: AppColors.border, width: 1.2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpacing.verticalSm,
              PuviAvatar(
                nameOrUid: _partnerName,
                size: 110,
                showBorder: true,
                borderWidth: 2.5,
                borderColor: AppColors.dustyRose,
                showShadow: true,
                backgroundColor: AppColors.ivory,
              ),
              AppSpacing.verticalMd,
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.h3.copyWith(
                  fontSize: 18,
                  color: AppColors.espresso,
                ),
              ),
              AppSpacing.verticalXs,
              Text(
                quote,
                textAlign: TextAlign.center,
                style: AppTypography.handwrittenCaption.copyWith(
                  fontSize: 16,
                  color: AppColors.taupe,
                ),
              ),
              AppSpacing.verticalSm,
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
                    const Icon(
                      Icons.lock_rounded,
                      size: 11,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Private & End-to-End Encrypted',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Close',
                style: AppTypography.label.copyWith(color: AppColors.burgundy),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isDifferentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }

  @override
  Widget build(BuildContext context) {
    // Reversed list for natural WhatsApp/Telegram style reverse scroll
    final reversedMessages = _messages.reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. Stationery App Bar with Zero Pixel Overflow & Mascot Avatar
                _buildHeader(context),

                const Divider(height: 1, thickness: 1, color: AppColors.border),

                // 2. Message History Feed (opens instantly at most recent message)
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.burgundy,
                          ),
                        )
                      : _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          itemCount: reversedMessages.length,
                          itemBuilder: (context, index) {
                            final message = reversedMessages[index];
                            final isMe = message.senderId == _myUid;

                            // In reverse mode, check if next older message (index + 1) is a different day
                            final bool showDateSeparator =
                                index == reversedMessages.length - 1 ||
                                _isDifferentDay(
                                  reversedMessages[index + 1].createdAt,
                                  message.createdAt,
                                );

                            // Check if this message is at the bottom of its consecutive sender cluster
                            final bool isClusterBottom =
                                index == 0 ||
                                reversedMessages[index - 1].senderId !=
                                    message.senderId ||
                                _isDifferentDay(
                                  reversedMessages[index - 1].createdAt,
                                  message.createdAt,
                                );

                            Widget bubbleWidget;
                            if (message.isAudio) {
                              bubbleWidget = ChatAudioBubble(
                                message: message,
                                isMe: isMe,
                                onLongPress: () =>
                                    _showMessageOptions(context, message),
                              );
                            } else if (message.isEmotion) {
                              bubbleWidget = ChatEmotionBubble(
                                message: message,
                                isMe: isMe,
                                partnerName: _partnerName,
                                onReplay: () =>
                                    _triggerEmotionEffect(message.type),
                                onLongPress: () =>
                                    _showMessageOptions(context, message),
                              );
                            } else {
                              bubbleWidget = ChatBubble(
                                message: message,
                                isMe: isMe,
                                onLongPress: () =>
                                    _showMessageOptions(context, message),
                              );
                            }

                            // Wrap bubble with sender mascot avatar
                            Widget bubbleRow;
                            if (isMe) {
                              bubbleRow = Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(child: bubbleWidget),
                                  const SizedBox(width: 6),
                                  isClusterBottom
                                      ? PuviAvatar(
                                          nameOrUid: widget.userName,
                                          size: 28,
                                          showBorder: true,
                                          borderWidth: 1.0,
                                          borderColor: AppColors.border,
                                          backgroundColor: AppColors.ivory,
                                        )
                                      : const SizedBox(width: 28),
                                ],
                              );
                            } else {
                              bubbleRow = Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  isClusterBottom
                                      ? PuviAvatar(
                                          nameOrUid: _partnerName,
                                          size: 28,
                                          showBorder: true,
                                          borderWidth: 1.0,
                                          borderColor: AppColors.border,
                                          backgroundColor: AppColors.ivory,
                                        )
                                      : const SizedBox(width: 28),
                                  const SizedBox(width: 6),
                                  Expanded(child: bubbleWidget),
                                ],
                              );
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDateSeparator)
                                  ChatDateSeparator(date: message.createdAt),
                                bubbleRow,
                              ],
                            );
                          },
                        ),
                ),

                const Divider(height: 1, thickness: 1, color: AppColors.border),

                // 3. Quick Affection Bar (Kiss, Hug, Knife, Flower)
                QuickEmotionDrawer(onSelectEmotion: _handleSendEmotion),

                // 4. Message Composer Bar with Voice Note support
                ChatComposerBar(
                  onSend: _handleSendText,
                  onSendVoiceNote: _handleSendVoiceNote,
                  isSending: _isSending,
                ),
              ],
            ),

            // 5. Full-Screen Dramatic Particle Overlay
            if (_activeEmotionEffect != null)
              Positioned.fill(
                child: ChatEmotionEffects(
                  emotionType: _activeEmotionEffect!,
                  onDismiss: () {
                    if (mounted) {
                      setState(() => _activeEmotionEffect = null);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.ivory,
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.espresso,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // Partner Mascot Medallion with tap-to-view preview & sync dot
          GestureDetector(
            onTap: () => _showPartnerProfileDialog(context),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                PuviAvatar(
                  nameOrUid: _partnerName,
                  size: 40,
                  showBorder: true,
                  borderWidth: 1.5,
                  borderColor: AppColors.border,
                  backgroundColor: AppColors.ivory,
                  showShadow: true,
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.paper, width: 1.5),
                  ),
                ),
              ],
            ),
          ),

          AppSpacing.horizontalXs,

          // Partner Name & Security Badge (guarded against overflow)
          Expanded(
            child: GestureDetector(
              onTap: () => _showPartnerProfileDialog(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _partnerName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h3.copyWith(
                            fontSize: 17,
                            color: AppColors.espresso,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: AppColors.dustyRose,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 9,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          'End-to-End Encrypted',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.taupe,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Compact Intimate couple badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: AppRadius.borderPill,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 11,
                  color: AppColors.burgundy,
                ),
                const SizedBox(width: 3),
                Text(
                  'Our Sanctuary',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.espresso,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Overlapping couple mascots with heart medallion
            SizedBox(
              width: 96,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    child: PuviAvatar.vicky(
                      size: 52,
                      showBorder: true,
                      borderColor: AppColors.paper,
                      borderWidth: 2,
                      showShadow: true,
                      backgroundColor: AppColors.ivory,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: PuviAvatar.puja(
                      size: 52,
                      showBorder: true,
                      borderColor: AppColors.paper,
                      borderWidth: 2,
                      showShadow: true,
                      backgroundColor: AppColors.ivory,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.burgundy,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalMd,
            Text(
              'Your Private Love Letters',
              style: AppTypography.h3.copyWith(color: AppColors.espresso),
            ),
            AppSpacing.verticalXs,
            Text(
              'Send a note, record a voice memo, or tap an emotion below to shower $_partnerName with love 💕',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.taupe),
            ),
          ],
        ),
      ),
    );
  }
}
