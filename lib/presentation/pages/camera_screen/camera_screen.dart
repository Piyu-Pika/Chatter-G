import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/datasources/remote/api_value.dart';
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
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  final ImagePicker _picker = ImagePicker();
  final ApiClient _apiClient = ApiClient();
  bool _isSending = false;

  // Camera feature state variables
  FlashMode _flashMode = FlashMode.off;
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  bool _showGrid = false;
  double _minExposure = 0.0;
  double _maxExposure = 0.0;
  double _currentExposure = 0.0;
  bool _showExposureSlider = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera({int cameraIndex = 0}) async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        _showPermissionDialog('Camera');
        return;
      }
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      _showErrorSnackbar('No cameras found.');
      return;
    }

    _controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize().then((_) async {
      if (!mounted) return;
      _minZoomLevel = await _controller!.getMinZoomLevel();
      _maxZoomLevel = await _controller!.getMaxZoomLevel();
      _minExposure = await _controller!.getMinExposureOffset();
      _maxExposure = await _controller!.getMaxExposureOffset();
      setState(() {
        _selectedCameraIndex = cameraIndex;
      });
    }).catchError((e) {
      if (mounted) _showErrorSnackbar("Failed to initialize camera: $e");
    });

    setState(() {});
  }

  void _switchCamera() {
    if (_cameras.length > 1) {
      final newIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _initializeCamera(cameraIndex: newIndex);
    }
  }

  void _toggleFlash() {
    if (_controller == null) return;
    setState(() {
      _flashMode = FlashMode.values[(_flashMode.index + 1) % FlashMode.values.length];
    });
    _controller!.setFlashMode(_flashMode);
  }

  void _toggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
  }

  Future<void> _handleTapToFocusAndExpose(TapUpDetails details) async {
    if (_controller == null) return;
    final screenSize = MediaQuery.of(context).size;
    final offset = Offset(details.localPosition.dx / screenSize.width, details.localPosition.dy / screenSize.height);
    await _controller!.setExposurePoint(offset);
    await _controller!.setFocusPoint(offset);
    setState(() {
      _showExposureSlider = true;
    });
  }

  Future<void> _captureFromCamera() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      await _initializeControllerFuture;
      final XFile image = await _controller!.takePicture();
      _showImagePreview(image);
    } catch (e) {
      _showErrorSnackbar('Failed to capture image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
      if (!status.isGranted) {
        _showPermissionDialog('Photos');
        return;
      }
    }
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) _showImagePreview(image);
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  Future<void> _sendImage(XFile imageFile) async {
    try {
      setState(() => _isSending = true);
      final authService = ref.read(authServiceProvider);
      final currentUserUuid = authService.currentUser?.uid ?? '';
      if (currentUserUuid.isEmpty) throw Exception('User not authenticated');

      final file = File(imageFile.path);
      final response = await _apiClient.sendImageMessage(userUuid: currentUserUuid, receiverId: widget.receiverUuid, imageFile: file);

      final message = ChatMessage(
        senderId: currentUserUuid,
        recipientId: widget.receiverUuid,
        content: response['data']['message_id'],
        timestamp: DateTime.now().toIso8601String(),
        messageType: 'image',
        fileType: file.path.split('.').last.toLowerCase(),
      );
      ref.read(chatMessagesProvider.notifier).addMessage(message);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image sent to ${widget.receiverName}'), backgroundColor: Colors.green));
        // Pop twice: once for the image preview dialog, and once for the camera screen itself.
        // This will return the user to the chat screen.
        Navigator.of(context)..pop()..pop();
      }
    } catch (e) {
      _showErrorSnackbar('Failed to send image: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_controller == null || !_controller!.value.isInitialized) {
              return Center(child: Text('Could not initialize camera.', style: TextStyle(color: Colors.white)));
            }
            return _buildCameraPreview();
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildCameraPreview() {
    var camera = _controller!.value;
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * camera.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return GestureDetector(
      onTapUp: _handleTapToFocusAndExpose,
      onScaleUpdate: (details) {
        double newZoom = _currentZoomLevel * details.scale;
        if (newZoom >= _minZoomLevel && newZoom <= _maxZoomLevel) {
          _controller!.setZoomLevel(newZoom);
        }
      },
      child: Stack(
        children: [
          Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Center(child: CameraPreview(_controller!)),
          ),
          if (_showGrid) CustomPaint(painter: GridPainter(), size: size),
          _buildOverlayControls(),
        ],
      ),
    );
  }

  Widget _buildOverlayControls() {
    return Stack(
      children: [
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                    IconButton(
                      icon: Icon(_flashMode == FlashMode.off ? Icons.flash_off : _flashMode == FlashMode.auto ? Icons.flash_auto : Icons.flash_on, color: Colors.white),
                      onPressed: _toggleFlash,
                    ),
                    IconButton(
                      icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off, color: Colors.white),
                      onPressed: _toggleGrid,
                    ),
                    IconButton(
                      icon: const Icon(Icons.exposure, color: Colors.white),
                      onPressed: () => setState(() => _showExposureSlider = !_showExposureSlider),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.photo_library, color: Colors.white, size: 30), onPressed: _pickFromGallery),
                    GestureDetector(
                      onTap: _captureFromCamera,
                      child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4))),
                    ),
                    IconButton(icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30), onPressed: _switchCamera),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showExposureSlider)
          Positioned(
            right: 10,
            top: 100,
            bottom: 150,
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: _currentExposure,
                min: _minExposure,
                max: _maxExposure,
                onChanged: (value) async {
                  setState(() => _currentExposure = value);
                  await _controller!.setExposureOffset(value);
                },
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
              ),
            ),
          ),
      ],
    );
  }

  void _showImagePreview(XFile image) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Column(
          children: [
            Expanded(child: InteractiveViewer(child: Image.file(File(image.path)))),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Retake')),
                  ElevatedButton(onPressed: _isSending ? null : () => _sendImage(image), child: _isSending ? const CircularProgressIndicator() : const Text('Send')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog(String permission) {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Permission Required'), content: Text('This app needs $permission permission.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () => openAppSettings(), child: const Text('Settings'))]));
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (int i = 1; i < 3; i++) {
      final dx = size.width * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 1; i < 3; i++) {
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}