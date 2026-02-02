import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../design/presentation/design_selector_dialog.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  final String? targetImagePath;
  final String? customerId;

  const SimulationScreen({
    super.key,
    this.targetImagePath,
    this.customerId,
  });

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  File? _targetImage;
  File? _selectedDesign;
  Uint8List? _resultImage;
  bool _isProcessing = false;
  String? _errorMessage;

  // Synthesis config
  double _preserveHairStrength = 0.7;
  String _blendMode = 'multiply';

  @override
  void initState() {
    super.initState();
    if (widget.targetImagePath != null) {
      _targetImage = File(widget.targetImagePath!);
    }
  }

  Future<void> _selectDesign() async {
    final result = await showDialog<File>(
      context: context,
      builder: (context) => const DesignSelectorDialog(),
    );

    if (result != null) {
      setState(() {
        _selectedDesign = result;
        _resultImage = null; // Clear previous result
      });
    }
  }

  Future<void> _runSynthesis() async {
    if (_targetImage == null || _selectedDesign == null) return;

    // Check usage limit
    final canSynthesize = await ref.read(subscriptionServiceProvider).canSynthesize();
    if (!canSynthesize) {
      _showUpgradeDialog();
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);

      final result = await aiService.synthesize(
        targetImage: _targetImage!,
        sourceEyebrow: _selectedDesign!,
        config: SynthesisConfig(
          preserveHairStrength: _preserveHairStrength,
          blendMode: _blendMode,
        ),
      );

      setState(() {
        _resultImage = result.imageBytes;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용량 초과'),
        content: const Text(
          '이번 달 시뮬레이션 사용량을 모두 사용했습니다.\n'
          '더 많은 시뮬레이션을 위해 구독을 업그레이드하세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings'); // Navigate to subscription page
            },
            child: const Text('업그레이드'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResult() async {
    if (_resultImage == null) return;

    try {
      final aiService = ref.read(aiServiceProvider);

      // Upload images
      final resultId = const Uuid().v4();

      final originalUrl = await aiService.uploadImage(
        bytes: await _targetImage!.readAsBytes(),
        bucket: 'simulation-results',
        path: 'originals/$resultId.png',
      );

      final resultUrl = await aiService.uploadImage(
        bytes: _resultImage!,
        bucket: 'simulation-results',
        path: 'results/$resultId.png',
      );

      // Save to database
      await aiService.saveSimulation(
        originalImageUrl: originalUrl,
        resultImageUrl: resultUrl,
        customerId: widget.customerId,
        settings: {
          'preserve_hair_strength': _preserveHairStrength,
          'blend_mode': _blendMode,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('시뮬레이션 결과가 저장되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _proceedToContract() {
    if (_resultImage == null) return;

    // Save result first, then navigate
    _saveResult().then((_) {
      context.push('/contract', extra: {
        'customerId': widget.customerId,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(FeatherIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('시뮬레이션'),
        actions: [
          if (_resultImage != null)
            TextButton.icon(
              onPressed: _saveResult,
              icon: const Icon(FeatherIcons.save),
              label: const Text('저장'),
            ),
        ],
      ),
      body: Row(
        children: [
          // Left: Images
          Expanded(
            flex: 3,
            child: _buildImagePanel(),
          ),

          // Right: Controls
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                left: BorderSide(color: AppColors.border),
              ),
            ),
            child: _buildControlPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Original Image
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '원본',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _targetImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _targetImage!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Center(
                            child: Text('이미지 없음'),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Arrow
          Icon(
            FeatherIcons.arrowRight,
            size: 32,
            color: AppColors.textTertiary,
          ),

          const SizedBox(width: 24),

          // Result Image
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '시뮬레이션 결과',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('AI가 눈썹을 합성하고 있습니다...'),
                              ],
                            ),
                          )
                        : _resultImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  _resultImage!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : _errorMessage != null
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          FeatherIcons.alertCircle,
                                          color: AppColors.error,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _errorMessage!,
                                          style: TextStyle(color: AppColors.error),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          FeatherIcons.image,
                                          size: 64,
                                          color: AppColors.textTertiary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '디자인을 선택하고\n시뮬레이션을 실행하세요',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Design Selection
          Text(
            '눈썹 디자인',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          InkWell(
            onTap: _selectDesign,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDesign != null
                      ? AppColors.primary
                      : AppColors.border,
                  width: _selectedDesign != null ? 2 : 1,
                ),
              ),
              child: _selectedDesign != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedDesign!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FeatherIcons.plus,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '디자인 선택',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 32),

          // Settings
          Text(
            '합성 설정',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Preserve Hair Strength
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('기존 눈썹 보존'),
              Text(
                '${(_preserveHairStrength * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: _preserveHairStrength,
            onChanged: (value) {
              setState(() {
                _preserveHairStrength = value;
              });
            },
            min: 0.0,
            max: 1.0,
          ),

          const SizedBox(height: 16),

          // Blend Mode
          const Text('블렌딩 모드'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'multiply', label: Text('Multiply')),
              ButtonSegment(value: 'soft_light', label: Text('Soft')),
              ButtonSegment(value: 'overlay', label: Text('Overlay')),
            ],
            selected: {_blendMode},
            onSelectionChanged: (selection) {
              setState(() {
                _blendMode = selection.first;
              });
            },
          ),

          const SizedBox(height: 32),

          // Run Button
          ElevatedButton.icon(
            onPressed: _selectedDesign != null && !_isProcessing
                ? _runSynthesis
                : null,
            icon: const Icon(FeatherIcons.play),
            label: const Text('시뮬레이션 실행'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          if (_resultImage != null) ...[
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _proceedToContract,
              icon: const Icon(FeatherIcons.fileText),
              label: const Text('계약서 작성'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
