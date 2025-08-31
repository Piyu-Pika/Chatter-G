import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/datasources/remote/api_value.dart'; // Add this import
import '../../../data/models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';
import 'package:dev_log/dev_log.dart';

import '../chat_screen/chat_provider.dart';

class ChatCameraScreen extends ConsumerStatefulWidget {
  final String receiverUuid;
  final String receiverName;

  const ChatCameraScreen({
    super.key,
    required this.receiverUuid,
    required this.receiverName,
  });

  @override
  ConsumerState<ChatCameraScreen> createState() => _ChatCameraScreenState();
}

class _ChatCameraScreenState extends ConsumerState<ChatCameraScreen> {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  final ApiClient _apiClient = ApiClient(); // Add this
  List<XFile> _capturedImages = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${dir.path}/chat_images');
      if (await imageDir.exists()) {
        final files = await imageDir.list().toList();
        final imageFiles = files
            .where((file) =>
                file.path.toLowerCase().endsWith('.jpg') ||
                file.path.toLowerCase().endsWith('.png'))
            .map((file) => XFile(file.path))
            .toList();
        setState(() {
          _capturedImages = imageFiles;
        });
      }
    } catch (e) {
      L.e('Error loading saved images: $e');
    }
  }

  Future<void> _captureFromCamera() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      _showPermissionDialog('Camera');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _saveImage(image);
        // Auto-show preview with send option after capture
        _showImagePreview(image);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to capture image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final storageStatus = await Permission.photos.request();
    if (!storageStatus.isGranted) {
      _showPermissionDialog('Photos');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _saveImage(image);
        // Auto-show preview with send option after selection
        _showImagePreview(image);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveImage(XFile image) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${dir.path}/chat_images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'chat_image_$timestamp.jpg';
      final savedPath = p.join(imageDir.path, filename);
      await File(image.path).copy(savedPath);

      setState(() {
        _capturedImages.insert(0, XFile(savedPath));
      });

      L.i('Image saved successfully to: $savedPath');
    } catch (e) {
      _showErrorSnackbar('Failed to save image: $e');
    }
  }

  // UPDATED: Send image via HTTP form data instead of WebSocket base64
  // Updated _sendImage method in camera_screen.dart
Future<void> _sendImage(XFile imageFile) async {
  try {
    setState(() => _isSending = true);
    L.i('Starting image send process via HTTP...');

    // Get current user UUID from auth provider
    final authService = ref.read(authServiceProvider);
    final currentUserUuid = authService.currentUser?.uid ?? '';
    
    if (currentUserUuid.isEmpty) {
      throw Exception('User not authenticated');
    }

    // Create File object from XFile
    final file = File(imageFile.path);
    
    L.i('Sending image file - Size: ${await file.length()} bytes');
    L.i('Current user UUID: $currentUserUuid');
    L.i('Receiver UUID: ${widget.receiverUuid}');

    // Send via HTTP API using form data
    final response = await _apiClient.sendImageMessage(
      userUuid: currentUserUuid,
      receiverId: widget.receiverUuid,
      imageFile: file,
    );

    L.i('Image sent successfully via HTTP: $response');

    // IMPORTANT: Update the chat provider immediately
    try {
      final chatNotifier = ref.read(chatScreenProvider(widget.receiverUuid).notifier);
      
      // Create the message object
      final message = ChatMessage(
        senderId: currentUserUuid,
        recipientId: widget.receiverUuid,
        content: response['data']['message_id'], // Store the returned message ID
        timestamp: DateTime.now().toIso8601String(),
        messageType: 'image',
        fileType: file.path.split('.').last.toLowerCase(),
      );

      // Add to both WebSocket provider and local state
      ref.read(chatMessagesProvider.notifier).addMessage(message);
      
      // Force immediate local state update
      final currentMessages = List<ChatMessage>.from(chatNotifier.state.messages);
      currentMessages.add(message);
      currentMessages.sort((a, b) {
        try {
          final aTime = DateTime.parse(a.timestamp);
          final bTime = DateTime.parse(b.timestamp);
          return aTime.compareTo(bTime);
        } catch (e) {
          return 0;
        }
      });
      
      // Update the chat provider's state
      final newState = chatNotifier.state.copyWith(messages: currentMessages);
      chatNotifier.state = newState;
      
      L.i('Chat state updated from camera screen');
    } catch (e) {
      L.e('Error updating chat state: $e');
    }

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Image sent to ${widget.receiverName}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to chat after successful send
      Navigator.of(context).pop();
    }
  } catch (e) {
    L.e('Error sending image: $e');
    _showErrorSnackbar('Failed to send image: $e');
  } finally {
    if (mounted) {
      setState(() => _isSending = false);
    }
  }
}


  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text('This app needs $permission permission to function properly.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildImageTile(XFile image, int index) {
    return GestureDetector(
      onTap: () => _showImagePreview(image),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[600]!, width: 1),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                File(image.path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Send button overlay
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(178),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _isSending ? null : () => _sendImage(image),
                  tooltip: 'Send to ${widget.receiverName}',
                ),
              ),
            ),
            // Preview overlay
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(178),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Preview',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(XFile image) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(229),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with receiver info
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Send to ${widget.receiverName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            // Image preview
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(76)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.file(
                    File(image.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  // Send button
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : () {
                      Navigator.of(context).pop();
                      _sendImage(image);
                    },
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? 'Sending...' : 'Send Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Send to ${widget.receiverName}'),
        actions: [
          if (_capturedImages.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() => _capturedImages.clear());
              },
              icon: const Icon(Icons.clear_all, color: Colors.red),
              label: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildCameraView(context)
          : _buildGalleryView(context),
    );
  }

  Widget _buildCameraView(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Tab navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTabButton('Camera', 0),
                const SizedBox(width: 12),
                _buildTabButton('Gallery', 1),
                const Spacer(),
                if (_capturedImages.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_capturedImages.length} photos',
                      style: TextStyle(color: Colors.blue[300]),
                    ),
                  ),
              ],
            ),
          ),
          // Camera preview area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[700]!, width: 2),
              ),
              child: _capturedImages.isNotEmpty
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(_capturedImages.first.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        // Send button overlay for recent image
                        Positioned(
                          top: 16,
                          right: 16,
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : () => _sendImage(_capturedImages.first),
                            icon: _isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send, size: 18),
                            label: Text(_isSending ? 'Sending...' : 'Send'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No photos yet',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the camera button to start',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.photo_library_rounded,
                  onPressed: _pickFromGallery,
                  size: 50,
                ),
                _buildMainCameraButton(),
                _buildControlButton(
                  icon: Icons.more_horiz_rounded,
                  onPressed: _showCameraOptions,
                  size: 50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMainCameraButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _captureFromCamera,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 4),
        ),
        child: _isLoading
            ? Container(
                padding: const EdgeInsets.all(20),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                ),
              )
            : const Icon(
                Icons.camera_alt_rounded,
                size: 35,
                color: Colors.blue,
              ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[800],
          border: Border.all(color: Colors.grey[600]!, width: 2),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Capture with camera',
              onTap: () {
                Navigator.pop(context);
                _captureFromCamera();
              },
            ),
            _buildOptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose Photo',
              subtitle: 'Select from gallery',
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
      onTap: onTap,
    );
  }

  Widget _buildGalleryView(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Tab navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTabButton('Camera', 0),
                const SizedBox(width: 12),
                _buildTabButton('Gallery', 1),
                const Spacer(),
                if (_capturedImages.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(51),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_capturedImages.length} photos',
                      style: TextStyle(color: Colors.blue[300]),
                    ),
                  ),
              ],
            ),
          ),
          // Gallery grid
          Expanded(
            child: _capturedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No photos yet',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Photos you take will appear here',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _captureFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _capturedImages.length,
                    itemBuilder: (context, index) {
                      return _buildImageTile(_capturedImages[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
