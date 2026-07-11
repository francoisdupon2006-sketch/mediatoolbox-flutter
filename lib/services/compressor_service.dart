import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// Résolutions disponibles, de la plus basse à la 2K
enum VideoResolution {
  p144('144p', 256, 144),
  p240('240p', 426, 240),
  p360('360p', 640, 360),
  p480('480p', 854, 480),
  p720('720p', 1280, 720),
  p1080('1080p', 1920, 1080),
  p1440('2K (1440p)', 2560, 1440);

  final String label;
  final int width;
  final int height;
  const VideoResolution(this.label, this.width, this.height);
}

enum OutputFormat {
  mp4('mp4', 'libx264'),
  mkv('mkv', 'libx264'),
  webm('webm', 'libvpx-vp9'),
  avi('avi', 'mpeg4');

  final String extension;
  final String codec;
  const OutputFormat(this.extension, this.codec);
}

class CompressionResult {
  final String outputPath;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  CompressionResult({
    required this.outputPath,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
  });
}

class CompressorService {
  /// [quality] va de 0 (qualité max, fichier plus gros) à 51 (compression max, qualité minimale).
  /// C'est directement le paramètre CRF de x264/x265.
  Future<CompressionResult> compressVideo({
    required String inputPath,
    required VideoResolution resolution,
    required OutputFormat format,
    required int quality,
    required void Function(double progressPercent) onProgress,
  }) async {
    final originalFile = File(inputPath);
    final originalSize = await originalFile.length();

    final downloadsDir = await _getCompressedOutputDir();
    final fileName =
        'compressed_${DateTime.now().millisecondsSinceEpoch}.${format.extension}';
    final outputPath = '${downloadsDir.path}/$fileName';

    // Récupère la durée totale de la vidéo pour calculer la progression en %
    final durationMs = await _probeDurationMs(inputPath);

    final scaleFilter =
        'scale=${resolution.width}:${resolution.height}:force_original_aspect_ratio=decrease,'
        'pad=${resolution.width}:${resolution.height}:(ow-iw)/2:(oh-ih)/2';

    final command =
        '-y -i "$inputPath" -vf "$scaleFilter" -c:v ${format.codec} -crf $quality -preset medium -c:a aac -b:a 128k "$outputPath"';

    FFmpegKitConfig.enableStatisticsCallback((stats) {
      if (durationMs > 0) {
        final currentMs = stats.getTime();
        final percent = (currentMs / durationMs * 100).clamp(0, 100).toDouble();
        onProgress(percent);
      }
    });

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw Exception('La compression a échoué : $logs');
    }

    final compressedSize = await File(outputPath).length();

    return CompressionResult(
      outputPath: outputPath,
      originalSizeBytes: originalSize,
      compressedSizeBytes: compressedSize,
    );
  }

  Future<int> _probeDurationMs(String inputPath) async {
    final session = await FFmpegKit.execute(
        '-i "$inputPath" -hide_banner -f null -');
    final output = await session.getAllLogsAsString() ?? '';
    final match = RegExp(r'Duration:\s*(\d+):(\d+):(\d+)\.(\d+)').firstMatch(output);
    if (match == null) return 0;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final s = int.parse(match.group(3)!);
    final ms = int.parse(match.group(4)!) * 10;
    return (h * 3600 + m * 60 + s) * 1000 + ms;
  }

  Future<Directory> _getCompressedOutputDir() async {
    // Android : dossier public Download/MediaToolbox/Compressed
    final base = Directory('/storage/emulated/0/Download/MediaToolbox/Compressed');
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    return base;
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (bytes.bitLength - 1) ~/ 10;
    if (i >= suffixes.length) i = suffixes.length - 1;
    final value = bytes / (1 << (i * 10));
    return '${value.toStringAsFixed(2)} ${suffixes[i]}';
  }
}
