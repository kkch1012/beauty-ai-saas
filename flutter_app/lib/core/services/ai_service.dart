import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as dio;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/env.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class SynthesisConfig {
  final double preserveHairStrength;
  final String blendMode;
  final bool toneCorrection;
  final double denoiseStrength;
  final double guidanceScale;
  final int numInferenceSteps;
  final int? seed;

  SynthesisConfig({
    this.preserveHairStrength = 0.7,
    this.blendMode = 'multiply',
    this.toneCorrection = true,
    this.denoiseStrength = 0.75,
    this.guidanceScale = 7.5,
    this.numInferenceSteps = 30,
    this.seed,
  });

  Map<String, dynamic> toJson() => {
    'preserve_hair_strength': preserveHairStrength,
    'blend_mode': blendMode,
    'tone_correction': toneCorrection,
    'denoise_strength': denoiseStrength,
    'guidance_scale': guidanceScale,
    'num_inference_steps': numInferenceSteps,
    if (seed != null) 'seed': seed,
  };
}

class SynthesisResult {
  final Uint8List imageBytes;
  final int processingTimeMs;
  final Map<String, dynamic>? metadata;

  SynthesisResult({
    required this.imageBytes,
    required this.processingTimeMs,
    this.metadata,
  });
}

class AnalysisResult {
  final Map<String, dynamic> skinTone;
  final Map<String, dynamic> goldenRatio;

  AnalysisResult({
    required this.skinTone,
    required this.goldenRatio,
  });

  String get skinToneType => skinTone['type'] ?? 'neutral';
  String get skinBrightness => skinTone['brightness'] ?? '21호';
  String get recommendation => skinTone['recommendation'] ?? '';
  bool get isSymmetric => goldenRatio['is_symmetric'] ?? true;
  List<String> get recommendations =>
      List<String>.from(goldenRatio['recommendations'] ?? []);
}

class AIService {
  final _client = dio.Dio(dio.BaseOptions(
    baseUrl: Env.aiServerUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5), // AI processing can take time
  ));

  final _supabase = Supabase.instance.client;

  /// Synthesize eyebrow on target face
  Future<SynthesisResult> synthesize({
    required File targetImage,
    required File sourceEyebrow,
    SynthesisConfig? config,
  }) async {
    config ??= SynthesisConfig();

    final formData = dio.FormData.fromMap({
      'target_image': await dio.MultipartFile.fromFile(
        targetImage.path,
        filename: 'target.png',
      ),
      'source_eyebrow': await dio.MultipartFile.fromFile(
        sourceEyebrow.path,
        filename: 'source.png',
      ),
      ...config.toJson(),
    });

    final response = await _client.post(
      '/api/v1/synthesize/stream',
      data: formData,
      options: dio.Options(responseType: dio.ResponseType.bytes),
    );

    final processingTime = int.tryParse(
      response.headers.value('X-Processing-Time-Ms') ?? '0',
    ) ?? 0;

    return SynthesisResult(
      imageBytes: Uint8List.fromList(response.data),
      processingTimeMs: processingTime,
    );
  }

  /// Analyze face for consultation
  Future<AnalysisResult> analyzeFace(File image) async {
    final formData = dio.FormData.fromMap({
      'image': await dio.MultipartFile.fromFile(
        image.path,
        filename: 'face.png',
      ),
    });

    final response = await _client.post(
      '/api/v1/analyze',
      data: formData,
    );

    final data = response.data;

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Analysis failed');
    }

    return AnalysisResult(
      skinTone: data['skin_tone'] ?? {},
      goldenRatio: data['golden_ratio'] ?? {},
    );
  }

  /// Extract eyebrow design from image
  Future<Uint8List> extractDesign(File image) async {
    final formData = dio.FormData.fromMap({
      'image': await dio.MultipartFile.fromFile(
        image.path,
        filename: 'source.png',
      ),
    });

    final response = await _client.post(
      '/api/v1/extract-design/stream',
      data: formData,
      options: dio.Options(responseType: dio.ResponseType.bytes),
    );

    return Uint8List.fromList(response.data);
  }

  /// Upload image to Supabase Storage
  Future<String> uploadImage({
    required Uint8List bytes,
    required String bucket,
    required String path,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fullPath = '${user.id}/$path';

    await _supabase.storage.from(bucket).uploadBinary(
      fullPath,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );

    return _supabase.storage.from(bucket).getPublicUrl(fullPath);
  }

  /// Save simulation result to database
  Future<String> saveSimulation({
    required String originalImageUrl,
    required String resultImageUrl,
    String? customerId,
    String? designId,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? analysisResult,
    int? processingTimeMs,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase.from('simulations').insert({
      'profile_id': user.id,
      'customer_id': customerId,
      'design_id': designId,
      'original_image_url': originalImageUrl,
      'result_image_url': resultImageUrl,
      'settings': settings,
      'analysis_result': analysisResult,
      'processing_time_ms': processingTimeMs,
      'status': 'completed',
    }).select('id').single();

    return response['id'];
  }

  /// Check server health
  Future<bool> checkHealth() async {
    try {
      final response = await _client.get('/health');
      return response.data['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }
}
