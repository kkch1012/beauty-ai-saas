import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/ai_service.dart';
import 'widgets/face_guide_overlay.dart';
import 'widgets/analysis_result_card.dart';

final camerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  File? _capturedImage;
  AnalysisResult? _analysisResult;
  bool _isAnalyzing = false;

  // Face detection
  final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  List<Face> _faces = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use front camera
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });

      // Start face detection stream
      _startFaceDetection();
    }
  }

  void _startFaceDetection() {
    _controller?.startImageStream((image) async {
      if (_isCapturing) return;

      // Convert camera image to InputImage
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return;

      try {
        final faces = await _faceDetector.processImage(inputImage);
        if (mounted) {
          setState(() {
            _faces = faces;
          });
        }
      } catch (e) {
        // Ignore face detection errors
      }
    });
  }

  InputImage? _convertCameraImage(CameraImage image) {
    // Simplified conversion - in production, implement proper conversion
    // based on platform (iOS/Android) and image format
    return null; // Placeholder
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Stop image stream before capture
      await _controller!.stopImageStream();

      // Capture
      final xFile = await _controller!.takePicture();

      setState(() {
        _capturedImage = File(xFile.path);
        _isCapturing = false;
      });

      // Analyze face
      await _analyzeFace();
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      _showError('촬영에 실패했습니다: $e');
    }
  }

  Future<void> _analyzeFace() async {
    if (_capturedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.analyzeFace(_capturedImage!);

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showError('분석에 실패했습니다: $e');
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _analysisResult = null;
    });

    // Restart camera
    _startFaceDetection();
  }

  void _proceedToSimulation() {
    if (_capturedImage == null) return;

    context.push(
      '/simulation',
      extra: {
        'targetImagePath': _capturedImage!.path,
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스마트 촬영'),
        actions: [
          if (_capturedImage != null)
            TextButton(
              onPressed: _retake,
              child: const Text('다시 촬영'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show captured image with analysis
    if (_capturedImage != null) {
      return _buildCapturedView();
    }

    // Show camera preview
    return _buildCameraView();
  }

  Widget _buildCameraView() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: CameraPreview(_controller!),
        ),

        // Face Guide Overlay
        Positioned.fill(
          child: FaceGuideOverlay(
            faces: _faces,
            previewSize: _controller!.value.previewSize!,
          ),
        ),

        // Bottom Controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              children: [
                // Face detection status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _faces.isNotEmpty
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _faces.isNotEmpty
                            ? FeatherIcons.check
                            : FeatherIcons.alertCircle,
                        size: 16,
                        color: _faces.isNotEmpty
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _faces.isNotEmpty
                            ? '얼굴이 인식되었습니다'
                            : '얼굴을 가이드에 맞춰주세요',
                        style: TextStyle(
                          color: _faces.isNotEmpty
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Capture Button
                GestureDetector(
                  onTap: _faces.isNotEmpty ? _capturePhoto : null,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _faces.isNotEmpty
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedView() {
    return Row(
      children: [
        // Captured Image
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _capturedImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Analysis Results
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '분석 결과',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                if (_isAnalyzing)
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('얼굴을 분석하고 있습니다...'),
                        ],
                      ),
                    ),
                  )
                else if (_analysisResult != null)
                  Expanded(
                    child: SingleChildScrollView(
                      child: AnalysisResultCard(result: _analysisResult!),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Text('분석 결과가 없습니다'),
                    ),
                  ),

                const SizedBox(height: 16),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: _analysisResult != null ? _proceedToSimulation : null,
                  icon: const Icon(FeatherIcons.arrowRight),
                  label: const Text('시뮬레이션 시작'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
