import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talent_foot_connect/models/feed_post.dart';
import 'package:talent_foot_connect/services/feed_service.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';
import 'package:talent_foot_connect/widgets/register_widgets.dart';
import 'package:video_player/video_player.dart';

class CreateFeedPostScreen extends StatefulWidget {
  const CreateFeedPostScreen({super.key});

  @override
  State<CreateFeedPostScreen> createState() => _CreateFeedPostScreenState();
}

class _CreateFeedPostScreenState extends State<CreateFeedPostScreen> {
  final _feed = FeedService();
  final _caption = TextEditingController();

  File? _file;
  FeedMediaType? _mediaType;
  bool _publishing = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _file = File(picked.path);
      _mediaType = FeedMediaType.image;
    });
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(type: FileType.video);
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() {
      _file = File(path);
      _mediaType = FeedMediaType.video;
    });
  }

  void _clearMedia() {
    setState(() {
      _file = null;
      _mediaType = null;
    });
  }

  Future<void> _publish() async {
    if (_file == null || _mediaType == null) {
      await showAppError(context, 'Choisis une photo ou une vidéo.');
      return;
    }

    setState(() => _publishing = true);
    try {
      await _feed.createPost(
        file: _file!,
        mediaType: _mediaType!,
        caption: _caption.text,
      );
      if (!mounted) return;
      await showAppSuccess(
        context,
        title: 'Publié',
        message: 'Ton post est visible sur l\'accueil pour tous les profils.',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      await showAppError(context, mapAuthError(e));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          SizedBox(height: topPad),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_file != null && _mediaType != null)
                            _HeroMediaBackground(
                              file: _file!,
                              mediaType: _mediaType!,
                            )
                          else
                            const ColoredBox(color: AppColors.surface),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xE60A0A0A),
                                  Color(0x990A0A0A),
                                  Color(0x660A0A0A),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(0xCC1A1C1C),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0x33FFFFFF),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.upload_file_outlined,
                                    color: AppColors.textSecondary,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Ajouter un\nhighlight',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_file != null)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Material(
                                color: const Color(0x99000000),
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: IconButton(
                                  onPressed: _clearMedia,
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  tooltip: 'Retirer',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _SourceButton(
                          icon: Icons.videocam_outlined,
                          label: 'Vidéo',
                          selected: _mediaType == FeedMediaType.video,
                          onTap: _pickVideo,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SourceButton(
                          icon: Icons.photo_outlined,
                          label: 'Photo',
                          selected: _mediaType == FeedMediaType.image,
                          onTap: _pickImage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _caption,
                    maxLines: 4,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Ajoute une légende... (ex: Mon dernier but en lucarne !)',
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.mint),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 12 + bottomPad),
            child: PrimaryCta(
              label: 'PUBLIER',
              onPressed: _publish,
              loading: _publishing,
              icon: Icons.send,
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0x66A1D494)
                  : const Color(0x33FFFFFF),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? AppColors.mint : AppColors.textSecondary,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.mint : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMediaBackground extends StatelessWidget {
  const _HeroMediaBackground({
    required this.file,
    required this.mediaType,
  });

  final File file;
  final FeedMediaType mediaType;

  @override
  Widget build(BuildContext context) {
    if (mediaType == FeedMediaType.image) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return _LocalVideoPreview(file: file);
  }
}

class _LocalVideoPreview extends StatefulWidget {
  const _LocalVideoPreview({required this.file});

  final File file;

  @override
  State<_LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<_LocalVideoPreview> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _LocalVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _disposeController();
      _init();
    }
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.file(widget.file);
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) return;
      setState(() {
        _ready = true;
        _failed = false;
      });
    } catch (_) {
      await controller.dispose();
      if (_controller == controller) _controller = null;
      if (!mounted) return;
      setState(() {
        _ready = false;
        _failed = true;
      });
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _ready = false;
    _failed = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.videocam_outlined,
                  color: AppColors.mint,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.file.path.split(RegExp(r'[\\/]')).last,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = _controller;
    if (!_ready || controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.mint,
            ),
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}
