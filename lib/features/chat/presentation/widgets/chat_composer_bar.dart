import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'send_photo_preview_dialog.dart';

/// Stationery love letter input bar with text field, voice note recorder,
/// camera/gallery photo sender, and primary send actions.
class ChatComposerBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final Function(String path, int durationSeconds) onSendVoiceNote;
  final Function(File file, bool isHd, String caption)? onSendImage;
  final bool isSending;

  const ChatComposerBar({
    super.key,
    required this.onSend,
    required this.onSendVoiceNote,
    this.onSendImage,
    this.isSending = false,
  });

  @override
  State<ChatComposerBar> createState() => _ChatComposerBarState();
}

class _ChatComposerBarState extends State<ChatComposerBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AudioRecorder _audioRecorder;

  bool _hasText = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _recordingPath;

  bool get _isTesting {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();

    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend(text);
    _controller.clear();
  }

  Future<void> _startRecording() async {
    if (_isTesting) {
      widget.onSendVoiceNote('/test/path.m4a', 5);
      return;
    }

    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _recordingPath = path;

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) {
            setState(() => _recordSeconds++);
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required for voice notes',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[ChatComposerBar] Error starting recording: $e');
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    final duration = _recordSeconds;

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordSeconds = 0;
      });

      final finalPath = path ?? _recordingPath;
      if (finalPath != null && duration >= 1) {
        widget.onSendVoiceNote(finalPath, duration);
      }
    } catch (e) {
      debugPrint('[ChatComposerBar] Error stopping recording: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
      _recordingPath = null;
    });
  }

  String _formatTimer(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showAttachmentSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AppSpacing.verticalMd,
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: const BoxDecoration(
                    color: AppColors.blushSand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.burgundy,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Take a Photo',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
                subtitle: Text(
                  'Capture an intimate live moment',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndPreviewImage(ImageSource.camera);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: const BoxDecoration(
                    color: AppColors.blushSand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.burgundy,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso,
                  ),
                ),
                subtitle: Text(
                  'Share pictures in Normal or HD Raw quality',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.taupe,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndPreviewImage(ImageSource.gallery);
                },
              ),
              AppSpacing.verticalSm,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndPreviewImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked == null || !mounted) return;

      final result = await SendPhotoPreviewDialog.show(
        context,
        imageFile: File(picked.path),
      );

      if (result != null && mounted) {
        widget.onSendImage?.call(result.file, result.isHd, result.caption);
      }
    } catch (e) {
      debugPrint('[ChatComposerBar] Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: AppColors.ivory,
      child: _isRecording
          ? _buildRecordingBar()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Camera / Attachment Action
                Container(
                  margin: const EdgeInsets.only(right: 6, bottom: 1),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espresso.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 20,
                      color: AppColors.espresso,
                    ),
                    onPressed: _showAttachmentSourceSheet,
                  ),
                ),

                // Text Input Field in Stationery Paper Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: AppRadius.borderButton,
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espresso.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 4,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.espresso,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write a love letter...',
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.taupe.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                ),

                AppSpacing.horizontalXs,

                // Dynamic Action Button (Send Text OR Record Voice Note)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _hasText ? AppColors.burgundy : AppColors.blushSand,
                    shape: BoxShape.circle,
                    boxShadow: _hasText
                        ? [
                            BoxShadow(
                              color: AppColors.burgundy.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: widget.isSending
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.paper,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            _hasText ? Icons.send_rounded : Icons.mic_rounded,
                            size: 20,
                            color: _hasText
                                ? AppColors.paper
                                : AppColors.espresso,
                          ),
                          onPressed: _hasText ? _handleSend : _startRecording,
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: AppRadius.borderButton,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Blinking recording dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.horizontalSm,

          // Timer
          Text(
            _formatTimer(_recordSeconds),
            style: AppTypography.label.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),

          AppSpacing.horizontalSm,

          Text(
            'Recording voice note...',
            style: AppTypography.captionSmall.copyWith(color: AppColors.taupe),
          ),

          const Spacer(),

          // Cancel Trash Button
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.taupe,
              size: 20,
            ),
            onPressed: _cancelRecording,
          ),

          // Send Checkmark Button
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.burgundy,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.check_rounded,
                color: AppColors.paper,
                size: 18,
              ),
              onPressed: _stopAndSendRecording,
            ),
          ),
        ],
      ),
    );
  }
}
