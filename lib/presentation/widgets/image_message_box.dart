import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/datasources/remote/api_value.dart';
import '../../util/image_encoding.dart';
import 'package:dev_log/dev_log.dart';

class ImageMessageBox extends StatefulWidget {
  final String imageIdOrBase64;
  final bool isUser;
  final String senderId;
  final String recipientId;
  final DateTime timestamp;
  final String? fileType;
  final String currentUserUuid;

  const ImageMessageBox({
    super.key,
    required this.imageIdOrBase64,
    required this.isUser,
    required this.senderId,
    required this.recipientId,
    required this.timestamp,
    required this.currentUserUuid,
    this.fileType,
  });

  @override
  State<ImageMessageBox> createState() => _ImageMessageBoxState();
}

class _ImageMessageBoxState extends State<ImageMessageBox> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final ApiClient _apiClient = ApiClient();
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    const maxRetries = 3;
    
    while (_retryCount < maxRetries) {
      try {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _errorMessage = '';
        });

        L.i('Loading image attempt ${_retryCount + 1} for: ${widget.imageIdOrBase64.substring(0, 20)}...');

        Uint8List imageBytes;

        // Check if this is base64 data or image ID
        if (_isBase64Data(widget.imageIdOrBase64)) {
          L.i('Loading image from base64 data');
          try {
            imageBytes = ImageEncoding.decodeImageForPreview(
              widget.imageIdOrBase64,
              maxSize: 300,
            );
          } catch (e) {
            L.e('Failed to decode base64: $e');
            throw Exception('Invalid base64 image data');
          }
        } else {
          L.i('Loading image from API with ID: ${widget.imageIdOrBase64}');
          try {
            final imageData = await _apiClient.getImageMessage(
              userUuid: widget.currentUserUuid,
              messageId: widget.imageIdOrBase64,
            );
            
            if (imageData.isEmpty) {
              throw Exception('Empty image data received from server');
            }
            
            imageBytes = Uint8List.fromList(imageData);
            L.i('Successfully loaded ${imageBytes.length} bytes from API');
          } catch (e) {
            L.e('API request failed: $e');
            throw Exception('Failed to load image from server: $e');
          }
        }

        // Validate image bytes
        if (imageBytes.isEmpty) {
          throw Exception('Image bytes are empty');
        }

        if (mounted) {
          setState(() {
            _imageBytes = imageBytes;
            _isLoading = false;
            _hasError = false;
            _retryCount = 0;
          });
          L.i('Image loaded successfully');
        }
        return; // Success, exit retry loop

      } catch (e) {
        _retryCount++;
        final errorMsg = 'Failed to load image: $e';
        L.e('$errorMsg (attempt $_retryCount)');
        
        if (_retryCount >= maxRetries) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
              _errorMessage = errorMsg;
            });
          }
          break;
        } else {
          // Wait before retrying
          await Future.delayed(Duration(seconds: _retryCount));
        }
      }
    }
  }

  void _retryLoad() {
    L.i('Manual retry triggered');
    _retryCount = 0;
    _loadImage();
  }

  bool _isBase64Data(String data) {
    // More sophisticated base64 detection
    if (data.length < 100) return false;
    
    // Check for data URL prefix
    if (data.startsWith('data:image/')) return true;
    
    // Check base64 pattern
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    return base64Pattern.hasMatch(data);
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Loading image...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (_retryCount > 0)
              Text(
                'Attempt $_retryCount/3',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      );
    }

    if (_hasError || _imageBytes == null) {
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
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _errorMessage.length > 50 
                    ? _errorMessage.substring(0, 50) + '...'
                    : _errorMessage,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _retryLoad,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
              ),
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
          _imageBytes!,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            L.e('Image.memory error: $error');
            return Container(
              height: 200,
              width: 200,
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Image display error',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _retryLoad,
                    child: const Text('Retry', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    if (_imageBytes == null) return;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => _FullScreenImageDialog(
        imageBytes: _imageBytes!,
        imageId: widget.imageIdOrBase64,
      ),
    );
  }
}

class _FullScreenImageDialog extends StatelessWidget {
  final Uint8List imageBytes;
  final String imageId;

  const _FullScreenImageDialog({
    required this.imageBytes,
    required this.imageId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to display image',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image ID: ${imageId.substring(0, 10)}...',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
