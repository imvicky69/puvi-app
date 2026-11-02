import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/chat_media_service.dart';
import '../../data/chat_message.dart';
import 'chat_fullscreen_image_viewer.dart';

/// Editorial stationery bubble for couple chat photos.
///
/// Features:
/// - Rounded paper card frame with intimate styling.
/// - Prominent HD badge if sent in raw HD quality.
/// - One-tap quick download icon to save directly to phone's gallery.
/// - Optional romantic caption.
/// - Interactive tap to open pinch-to-zoom fullscreen viewer.
class ChatImageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final String partnerName;
  final VoidCallback? onLongPress;

  const ChatImageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.partnerName,
    this.onLongPress,
  });

  @override
  State<ChatImageBubble> createState() => _ChatImageBubbleState();
}

class _ChatImageBubbleState extends State<ChatImageBubble> {
  bool _isDownloading = false;
  bool _isSaved = false;

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Future<void> _handleQuickDownload() async {
    final url = widget.message.mediaUrl;
    if (url == null || url.isEmpty || _isDownloading) return;

    setState(() => _isDownloading = true);
    HapticFeedback.lightImpact();

    final success = await ChatMediaService.downloadImageToGallery(url);

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _isSaved = success;
    });

    if (success) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.dustyRose,
                size: 18,
              ),
              SizedBox(width: 8),
              Text('Photo saved to your gallery 💕'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildImageWidget(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          color: AppColors.blushSand.withValues(alpha: 0.5),
          height: 200,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.dustyRose),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.blushSand,
          height: 180,
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: AppColors.taupe,
              size: 36,
            ),
          ),
        ),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: double.infinity);
      }
      return Container(
        color: AppColors.blushSand,
        height: 180,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: AppColors.taupe,
            size: 36,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = widget.isMe;
    final url = message.mediaUrl ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isMe ? AppColors.blushSand : AppColors.paper,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isMe
                  ? const Radius.circular(18)
                  : const Radius.circular(4),
              bottomRight: isMe
                  ? const Radius.circular(4)
                  : const Radius.circular(18),
            ),
            border: isMe
                ? null
                : Border.all(color: AppColors.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onLongPress: widget.onLongPress,
              onTap: () {
                ChatFullscreenImageViewer.show(
                  context,
                  message: message,
                  senderName: isMe ? 'You' : widget.partnerName,
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Photo Frame with Badges
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 280,
                              minHeight: 160,
                            ),
                            child: _buildImageWidget(url),
                          ),
                        ),

                        // HD Badge
                        if (message.isHd)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.espresso.withValues(
                                  alpha: 0.75,
                                ),
                                borderRadius: AppRadius.borderPill,
                              ),
                              child: Text(
                                'HD',
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.paper,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                        // Quick Download Button
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _handleQuickDownload,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.espresso.withValues(
                                  alpha: 0.7,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: _isDownloading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      _isSaved
                                          ? Icons.check_rounded
                                          : Icons.download_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Optional Caption
                    if (message.text.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                        child: Text(
                          message.text,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.espresso,
                            fontSize: 14.5,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],

                    // Timestamp & Status Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.createdAt),
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.taupe.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.isSeen
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 14,
                              color: message.isSeen
                                  ? AppColors.burgundy
                                  : AppColors.taupe.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
