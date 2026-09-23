import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:skindisease/features/scan/data/disease_info.dart';

class PredictResult {
  final String label;
  final String displayName;
  final double confidence;
  final String description;
  final List<String> prevention;

  PredictResult({
    required this.label,
    required this.displayName,
    required this.confidence,
    required this.description,
    required this.prevention,
  });
}

class TFLitePredictService {
  late Interpreter _interpreter;
  bool _isLoaded = false;
  String _currentModelPath = '';

  final List<String> labels = [
    'BA- cellulitis',
    'BA-impetigo',
    'FU-athlete-foot',
    'FU-nail-fungus',
    'FU-ringworm',
    'Normal',
    'PA-cutaneous-larva-migrans',
    'VI-chickenpox',
    'VI-shingles',
  ];

  Future<void> loadModel({
    String modelPath =
        'assets/models/skin_disease_mobilenetv3large_float32.tflite',
  }) async {
    close();

    _interpreter = await Interpreter.fromAsset(modelPath);
    _currentModelPath = modelPath;
    _isLoaded = true;

    print('Model loaded: $modelPath');
    print('Input shape: ${_interpreter.getInputTensor(0).shape}');
    print('Output shape: ${_interpreter.getOutputTensor(0).shape}');
  }

  void close() {
    if (_isLoaded) {
      _interpreter.close();
      _isLoaded = false;
    }
  }

  /// Menentukan apakah model saat ini butuh normalisasi [0,1]
  /// EfficientNet-Lite (dari TF Hub KerasLayer) TIDAK punya preprocessing
  /// internal, sehingga butuh piksel dinormalisasi ke [0,1] secara manual.
  /// MobileNetV3Large (include_preprocessing=True) sudah punya preprocessing
  /// internal di dalam graf model, sehingga harus diberi piksel mentah 0-255.
  bool get _needsManualNormalization =>
      _currentModelPath.toLowerCase().contains('efficientnet');

  Future<PredictResult> predict(File imageFile) async {
    if (!_isLoaded) {
      throw Exception('Model belum dimuat');
    }

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Gambar tidak valid');
    }

    final resized = img.copyResize(
      image,
      width: 224,
      height: 224,
    );

    final normalize = _needsManualNormalization;

    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resized.getPixel(x, y);

            if (normalize) {
              // EfficientNet-Lite (TF Hub): butuh rentang [0, 1]
              return [
                pixel.r.toDouble() / 255.0,
                pixel.g.toDouble() / 255.0,
                pixel.b.toDouble() / 255.0,
              ];
            } else {
              // MobileNetV3Large (include_preprocessing=True): tetap 0-255
              return [
                pixel.r.toDouble(),
                pixel.g.toDouble(),
                pixel.b.toDouble(),
              ];
            }
          },
        ),
      ),
    );

    final outputShape = _interpreter.getOutputTensor(0).shape;

    final output = List.generate(
      outputShape[0],
      (_) => List.filled(outputShape[1], 0.0),
    );

    _interpreter.run(input, output);

    final scores = output[0];

    if (scores.length != labels.length) {
      throw Exception(
        'Model tidak cocok dengan label. Output model = ${scores.length}, jumlah label = ${labels.length}.',
      );
    }

    int maxIndex = 0;
    double maxScore = scores[0];

    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    final rawLabel = labels[maxIndex];
    final info = diseaseInfoMap[rawLabel];

    return PredictResult(
      label: rawLabel,
      displayName: info?.displayName ?? rawLabel,
      confidence: maxScore,
      description: info?.description ?? 'Belum ada penjelasan untuk label ini.',
      prevention: info?.prevention ?? const [],
    );
  }
}