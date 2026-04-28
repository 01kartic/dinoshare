import 'dart:io';
import 'dart:typed_data';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:dinoshare/util/fomart_icon.dart';
import 'package:dinoshare/util/stored_file.dart';

final Map<String, Uint8List> _videoThumbnailCache = {};
final Map<String, Uint8List> _imageBytesCache = {};

class FileThumbnail extends StatefulWidget {
  const FileThumbnail({
    super.key,
    required this.path,
    required this.name,
    this.isDirectory = false,
    this.size = 48,
    this.borderRadius = 8,
    this.showThumbnail = true,
    this.iconColor,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final double size;
  final double borderRadius;
  final bool showThumbnail;
  final Color? iconColor;

  @override
  State<FileThumbnail> createState() => _FileThumbnailState();
}

class _FileThumbnailState extends State<FileThumbnail> {
  Uint8List? _videoThumbnailBytes;
  Uint8List? _imageBytes;
  bool _videoThumbnailLoading = false;
  bool _videoThumbnailFailed = false;
  bool _imageLoading = false;
  bool _imageFailed = false;

  bool get _isImage => fileTypeIconData(widget.name).fileType == 'Image';

  bool get _isVideo => fileTypeIconData(widget.name).fileType == 'Video';

  @override
  void initState() {
    super.initState();
    _maybeLoadThumbnail();
  }

  @override
  void didUpdateWidget(FileThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.name != widget.name ||
        oldWidget.showThumbnail != widget.showThumbnail) {
      _videoThumbnailBytes = null;
      _imageBytes = null;
      _videoThumbnailLoading = false;
      _videoThumbnailFailed = false;
      _imageLoading = false;
      _imageFailed = false;
      _maybeLoadThumbnail();
    }
  }

  void _maybeLoadThumbnail() {
    if (!widget.showThumbnail || widget.isDirectory || widget.path.isEmpty) {
      return;
    }
    if (_isVideo) {
      _maybeLoadVideoThumbnail();
    } else if (_isImage && Platform.isAndroid) {
      _maybeLoadImageBytes();
    }
  }

  void _maybeLoadImageBytes() {
    final cached = _imageBytesCache[widget.path];
    if (cached != null) {
      _imageBytes = cached;
      return;
    }

    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    if (_imageLoading || _imageFailed) return;
    setState(() => _imageLoading = true);

    try {
      final file = File(widget.path);
      if (!isContentUri(widget.path) && !await file.exists()) {
        if (!mounted) return;
        setState(() {
          _imageFailed = true;
          _imageLoading = false;
        });
        return;
      }

      final bytes = await readStoredFileBytes(widget.path);
      if (!mounted) return;

      if (bytes != null && bytes.isNotEmpty) {
        _imageBytesCache[widget.path] = bytes;
        setState(() {
          _imageBytes = bytes;
          _imageLoading = false;
        });
      } else {
        setState(() {
          _imageFailed = true;
          _imageLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _imageFailed = true;
        _imageLoading = false;
      });
    }
  }

  void _maybeLoadVideoThumbnail() {
    final isUri = isContentUri(widget.path);
    if (!isUri && !File(widget.path).existsSync()) return;

    final cached = _videoThumbnailCache[widget.path];
    if (cached != null) {
      _videoThumbnailBytes = cached;
      return;
    }

    _loadVideoThumbnail();
  }

  Future<void> _loadVideoThumbnail() async {
    if (_videoThumbnailLoading || _videoThumbnailFailed) return;
    setState(() => _videoThumbnailLoading = true);

    try {
      final isUri = isContentUri(widget.path);
      final bytes = await FcNativeVideoThumbnail().saveThumbnailToBytes(
        srcFile: widget.path,
        srcFileUri: isUri,
        width: 128,
        height: 128,
        format: 'jpeg',
        quality: 75,
      );

      if (!mounted) return;

      if (bytes != null && bytes.isNotEmpty) {
        _videoThumbnailCache[widget.path] = bytes;
        setState(() {
          _videoThumbnailBytes = bytes;
          _videoThumbnailLoading = false;
        });
      } else {
        setState(() {
          _videoThumbnailFailed = true;
          _videoThumbnailLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _videoThumbnailFailed = true;
        _videoThumbnailLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    if (widget.showThumbnail && _isImage && !widget.isDirectory) {
      if (_imageBytes != null) {
        return _buildImage(Image.memory(_imageBytes!, fit: BoxFit.cover));
      }

      if (!isContentUri(widget.path) && !Platform.isAndroid) {
        final file = File(widget.path);
        if (file.existsSync()) {
          return _buildImage(Image.file(file, fit: BoxFit.cover));
        }
      }
    }

    if (widget.showThumbnail &&
        _isVideo &&
        !widget.isDirectory &&
        _videoThumbnailBytes != null) {
      return _buildVideoThumbnail(theme);
    }

    return _buildIconFallback(theme);
  }

  Widget _buildImage(Image image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(width: widget.size, height: widget.size, child: image),
    );
  }

  Widget _buildVideoThumbnail(FThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_videoThumbnailBytes!, fit: BoxFit.cover),
            Center(
              child: Container(
                width: widget.size * 0.58,
                height: widget.size * 0.58,
                decoration: BoxDecoration(
                  color: theme.colors.background.withAlpha(190),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FIcons.play,
                  size: widget.size * 0.3,
                  color: theme.colors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconFallback(FThemeData theme) {
    final icon =
        widget.isDirectory
            ? HugeIcons.strokeRoundedFolder01
            : fileTypeIconData(widget.name).icon.icon;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: theme.colors.background,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          size: widget.size * 0.56,
          color: widget.iconColor ?? theme.colors.primary,
        ),
      ),
    );
  }
}
