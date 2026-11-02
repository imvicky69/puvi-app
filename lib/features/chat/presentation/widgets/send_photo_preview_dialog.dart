import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/chat_media_service.dart';

class SendPhotoResult {
  final File file;
  final bool isHd;
  final String caption;

  const SendPhotoResult({
    required this.file,
    required this.isHd,
    required this.caption,
  });
}

/// Themed preview dialog for couple chat photo sending.
/// Allows selecting between Standard (compressed) and HD (raw original)
/// and adding an optional love note caption.
class SendPhotoPreviewDialog extends StatefulWidget {
  final File imageFile;

  const SendPhotoPreviewDialog({super.key, required this.imageFile});

  static Future<SendPhotoResult?> show(
    BuildContext context, {
    required File imageFile,
  }) {
    return showDialog<SendPhotoResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SendPhotoPreviewDialog(imageFile: imageFile),
    );
  }

  @override
  State<SendPhotoPreviewDialog> createState() => _SendPhotoPreviewDialogState();
}

class _SendPhotoPreviewDialogState extends State<SendPhotoPreviewDialog> {
  final TextEditingController _captionController = TextEditingController();
  bool _isHd = false;
  late final int _fileSizeBytes;

  @override
  void initState() {
    super.initState();
    try {
      _fileSizeBytes = widget.imageFile.lengthSync();
    } catch (_) {
      _fileSizeBytes = 0;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _handleSend() {
    Navigator.of(context).pop(
      SendPhotoResult(
        file: widget.imageFile,
        isHd: _isHd,
        caption: _captionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawSize = ChatMediaService.formatFileSize(_fileSizeBytes);

    return Dialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.borderLargeCard,
        side: BorderSide(color: AppColors.border, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: const BoxDecoration(
                      color: AppColors.blushSand,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.burgundy,
                      size: 18,
                    ),
                  ),
                  AppSpacing.horizontalSm,
                  Expanded(
                    child: Text(
                      'Send Photo',
                      style: AppTypography.h3.copyWith(
                        fontSize: 18,
                        color: AppColors.espresso,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.taupe,
                    ),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),

              AppSpacing.verticalSm,

              // Image Preview
              ClipRRect(
                borderRadius: AppRadius.borderCard,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),

              AppSpacing.verticalMd,

              // Quality Selector (Standard vs HD)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    // Standard Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isHd = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isHd
                                ? AppColors.burgundy
                                : Colors.transparent,
                            borderRadius: AppRadius.borderPill,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 15,
                                  color: !_isHd
                                      ? AppColors.paper
                                      : AppColors.taupe,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Standard (Fast)',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: !_isHd
                                        ? AppColors.paper
                                        : AppColors.taupe,
                                    fontWeight: !_isHd
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // HD Raw Option
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isHd = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isHd
                                ? AppColors.burgundy
                                : Colors.transparent,
                            borderRadius: AppRadius.borderPill,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.hd_rounded,
                                  size: 15,
                                  color: _isHd
                                      ? AppColors.paper
                                      : AppColors.taupe,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'HD ($rawSize)',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: _isHd
                                        ? AppColors.paper
                                        : AppColors.taupe,
                                    fontWeight: _isHd
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              AppSpacing.verticalSm,

              // Caption TextField
              Container(
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: AppRadius.borderButton,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: TextField(
                  controller: _captionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  minLines: 1,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.espresso,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a sweet love caption... 💕',
                    hintStyle: AppTypography.caption.copyWith(
                      color: AppColors.taupe.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                  ),
                ),
              ),

              AppSpacing.verticalMd,

              // Send Button
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _handleSend,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isHd ? 'Send in HD Quality' : 'Send Photo',
                    style: AppTypography.label.copyWith(
                      color: AppColors.paper,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.burgundy,
                    foregroundColor: AppColors.paper,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.borderButton,
                    ),
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
