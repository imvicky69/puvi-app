import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/chat_media_service.dart';
import '../../data/chat_message.dart';

/// Fullscreen pinch-to-zoom viewer for couple chat photos with one-click
/// download to the phone's system photo gallery.
class ChatFullscreenImageViewer extends StatefulWidget {
  final ChatMessage message;
  final String senderName;

  const ChatFullscreenImageViewer({
    super.key,
    required this.message,
    required this.senderName,
  });

  static void show(
    BuildContext context, {
    required ChatMessage message,
    required String senderName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChatFullscreenImageViewer(message: message, senderName: senderName),
      ),
    );
  }

  @override
  State<ChatFullscreenImageViewer> createState() =>
      _ChatFullscreenImageViewerState();
}

class _ChatFullscreenImageViewerState extends State<ChatFullscreenImageViewer> {
  bool _isDownloading = false;
  bool _downloadSuccess = false;

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Future<void> _handleDownload() async {
    final url = widget.message.mediaUrl;
    if (url == null || url.isEmpty || _isDownloading) return;

    setState(() => _isDownloading = true);
    HapticFeedback.lightImpact();

    final success = await ChatMediaService.downloadImageToGallery(url);

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _downloadSuccess = success;
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save photo to gallery.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.dustyRose),
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: AppColors.taupe,
            size: 48,
          ),
        ),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
      return const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.taupe,
          size: 48,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final url = message.mediaUrl ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Pinch-to-zoom interactive viewer
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.5,
              child: _buildImage(url),
            ),
          ),

          // Top App Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  AppSpacing.horizontalXs,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.senderName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _formatTime(message.createdAt),
                          style: AppTypography.captionSmall.copyWith(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // HD Badge
                  if (message.isHd) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blushSand,
                        borderRadius: AppRadius.borderPill,
                      ),
                      child: Text(
                        'HD RAW',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.burgundy,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Download Button
                  _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            _downloadSuccess
                                ? Icons.check_rounded
                                : Icons.download_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _handleDownload,
                        ),
                ],
              ),
            ),
          ),

          // Bottom Caption Bar
          if (message.text.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
