import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatCameraScreen extends ConsumerStatefulWidget {
  const ChatCameraScreen({super.key});

  @override
  ConsumerState<ChatCameraScreen> createState() => _ChatCameraScreenState();
}

class _ChatCameraScreenState extends ConsumerState<ChatCameraScreen> {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _capturedImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  Future<void> _loadSavedImages() async {
    // Load previously saved images from app directory
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
      print('Error loading saved images: $e');
    }
  }

  Future<void> _captureFromCamera() async {
    // Request camera permission
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
      }
    } catch (e) {
      _showErrorSnackbar('Failed to capture image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFromGallery() async {
    // Request storage permission
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
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _captureMultipleImages() async {
    final storageStatus = await Permission.photos.request();
    if (!storageStatus.isGranted) {
      _showPermissionDialog('Photos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      for (final image in images) {
        await _saveImage(image);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick images: $e');
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Failed to save image: $e');
    }
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content:
            Text('This app needs $permission permission to function properly.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Camera',
              subtitle: 'Take a photo',
              onTap: () {
                Navigator.pop(context);
                _captureFromCamera();
              },
            ),
            _buildOptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Gallery',
              subtitle: 'Choose from gallery',
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            _buildOptionTile(
              icon: Icons.photo_library_outlined,
              title: 'Multiple Photos',
              subtitle: 'Select multiple images',
              onTap: () {
                Navigator.pop(context);
                _captureMultipleImages();
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
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
      onTap: onTap,
    );
  }

  Widget _buildCameraView(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Header with navigation
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 0),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedIndex == 0
                                ? Colors.blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Camera',
                            style: TextStyle(
                              color: _selectedIndex == 0
                                  ? Colors.white
                                  : Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 1),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedIndex == 1
                                ? Colors.blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Gallery',
                            style: TextStyle(
                              color: _selectedIndex == 1
                                  ? Colors.white
                                  : Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_capturedImages.isNotEmpty)
                    Text(
                      '${_capturedImages.length} photos',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                ],
              ),
            ),

            // Camera placeholder/recent image
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[700]!, width: 2),
                ),
                child: _capturedImages.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          File(_capturedImages.first.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No photos yet',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
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
              padding: EdgeInsets.all(20),
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
                    onPressed: _showImageOptions,
                    size: 50,
                  ),
                ],
              ),
            ),
          ],
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
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            : Icon(
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

  Widget _buildGalleryView(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Header with navigation
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 0),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedIndex == 0
                                ? Colors.blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Camera',
                            style: TextStyle(
                              color: _selectedIndex == 0
                                  ? Colors.white
                                  : Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 1),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedIndex == 1
                                ? Colors.blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Gallery',
                            style: TextStyle(
                              color: _selectedIndex == 1
                                  ? Colors.white
                                  : Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_capturedImages.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        // Clear all images
                        setState(() => _capturedImages.clear());
                      },
                      child: Text(
                        'Clear All',
                        style: TextStyle(color: Colors.red),
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
                          SizedBox(height: 16),
                          Text(
                            'No photos yet',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Photos you take will appear here',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _capturedImages.length,
                      itemBuilder: (context, index) {
                        final image = _capturedImages[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(image.path),
                            fit: BoxFit.cover,
                          ),
                        );
                      },
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
      body: _selectedIndex == 0
          ? _buildCameraView(context)
          : _buildGalleryView(context),
      backgroundColor: Colors.black,
    );
  }
}
