import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../util/image_encoding.dart';
import 'package:dev_log/dev_log.dart';


class ImageMessageBox extends StatefulWidget {
  final String base64Image;
  final bool isUser;
  final String senderId;
  final String recipientId;
  final DateTime timestamp;
  final String? fileType;

  const ImageMessageBox({
    super.key,
    required this.base64Image,
    required this.isUser,
    required this.senderId,
    required this.recipientId,
    required this.timestamp,
    this.fileType,
  });

  @override
  State<ImageMessageBox> createState() => _ImageMessageBoxState();
}

class _ImageMessageBoxState extends State<ImageMessageBox> {
  Uint8List? _previewImageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPreviewImage();
  }

  Future<void> _loadPreviewImage() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Use optimized preview decoding for faster loading
      final previewBytes = ImageEncoding.decodeImageForPreview(
        widget.base64Image,
        maxSize: 300, // Thumbnail size for chat preview
      );

      if (mounted) {
        setState(() {
          _previewImageBytes = previewBytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      L.e('Error loading preview image: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.assistant, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth * 0.75;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    maxHeight: 300,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isUser 
                        ? (isDarkMode ? Colors.blue[700] : Colors.blue[100])
                        : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(widget.isUser ? 16 : 0),
                        bottomRight: Radius.circular(widget.isUser ? 0 : 16),
                      ),
                    ),
                    child: _buildImageContent(),
                  ),
                );
              },
            ),
          ),
          if (widget.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (_isLoading) {
      return Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasError || _previewImageBytes == null) {
      return Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.grey[600],
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load image',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadPreviewImage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _previewImageBytes!,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => _FullScreenImageDialog(
        base64Image: widget.base64Image,
      ),
    );
  }
}

class _FullScreenImageDialog extends StatefulWidget {
  final String base64Image;

  const _FullScreenImageDialog({required this.base64Image});

  @override
  State<_FullScreenImageDialog> createState() => _FullScreenImageDialogState();
}

class _FullScreenImageDialogState extends State<_FullScreenImageDialog> {
  Uint8List? _fullImageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFullImage();
  }

  Future<void> _loadFullImage() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Use optimized full-screen decoding
      final fullBytes = ImageEncoding.decodeImageForFullScreen(widget.base64Image);

      if (mounted) {
        setState(() {
          _fullImageBytes = fullBytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      L.e('Error loading full image: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : _hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadFullImage,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : InteractiveViewer(
                        child: Image.memory(
                          _fullImageBytes!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
