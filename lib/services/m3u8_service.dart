import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

enum M3u8ConversionStatus { pending, running, success, failed }

class M3u8File {
  final String path;
  M3u8ConversionStatus status;
  String? errorMessage;

  M3u8File(this.path, {this.status = M3u8ConversionStatus.pending});

  String get fileName => path.split('/').last;
}

class M3u8Service {
  /// Scan récursif (BFS) d'un dossier à la recherche de fichiers .m3u8
  Future<List<M3u8File>> scanFolder(String rootPath) async {
    final found = <M3u8File>[];
    final queue = <Directory>[Directory(rootPath)];

    while (queue.isNotEmpty) {
      final dir = queue.removeAt(0);
      if (!await dir.exists()) continue;

      try {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is Directory) {
            queue.add(entity);
          } else if (entity is File &&
              entity.path.toLowerCase().endsWith('.m3u8')) {
            found.add(M3u8File(entity.path));
          }
        }
      } catch (_) {
        // Dossier inaccessible (permissions) : on l'ignore et on continue
        continue;
      }
    }

    return found;
  }

  Future<Directory> _getOutputDir() async {
    final dir = Directory('/storage/emulated/0/Download/m3u8');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Convertit un fichier m3u8 en mp4. Tente d'abord un simple "copy" (rapide,
  /// sans ré-encodage) puis retombe sur un ré-encodage complet si ça échoue
  /// (segments incompatibles entre eux, par exemple).
  Future<void> convertToMp4(
    M3u8File file, {
    required void Function(String message) onLog,
  }) async {
    final outputDir = await _getOutputDir();
    final baseName = file.fileName.replaceAll(RegExp(r'\.m3u8$', caseSensitive: false), '');
    final outputPath = '${outputDir.path}/$baseName.mp4';

    onLog('Tentative de copie directe (rapide)...');
    final copyCommand = '-y -allowed_extensions ALL -i "${file.path}" -c copy -bsf:a aac_adtstoasc "$outputPath"';
    var session = await FFmpegKit.execute(copyCommand);
    var returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      onLog('Copie directe impossible, ré-encodage complet en cours...');
      final reencodeCommand =
          '-y -allowed_extensions ALL -i "${file.path}" -c:v libx264 -preset veryfast -c:a aac "$outputPath"';
      session = await FFmpegKit.execute(reencodeCommand);
      returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        throw Exception('Échec de la conversion : $logs');
      }
    }

    onLog('Terminé : $outputPath');
  }

  /// Traite une liste de fichiers en file d'attente (un par un), en continuant
  /// même si l'un d'eux échoue (stream mort, fichier corrompu, etc.).
  Future<void> convertQueue(
    List<M3u8File> files, {
    required void Function(M3u8File file) onStart,
    required void Function(M3u8File file, String log) onProgress,
    required void Function(M3u8File file) onSuccess,
    required void Function(M3u8File file, String error) onError,
  }) async {
    for (final file in files) {
      onStart(file);
      try {
        await convertToMp4(file, onLog: (log) => onProgress(file, log));
        onSuccess(file);
      } catch (e) {
        onError(file, e.toString());
      }
    }
  }
}
