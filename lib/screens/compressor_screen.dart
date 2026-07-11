import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/compressor_service.dart';

class CompressorScreen extends StatefulWidget {
  const CompressorScreen({super.key});

  @override
  State<CompressorScreen> createState() => _CompressorScreenState();
}

class _CompressorScreenState extends State<CompressorScreen> {
  final _service = CompressorService();

  String? _selectedFilePath;
  VideoResolution _resolution = VideoResolution.p720;
  OutputFormat _format = OutputFormat.mp4;
  double _quality = 23; // CRF : 0 = qualité max, 51 = compression max

  bool _isCompressing = false;
  double _progress = 0;
  CompressionResult? _result;
  String? _error;

  Future<void> _pickVideo() async {
    await Permission.videos.request();
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _startCompression() async {
    if (_selectedFilePath == null) return;
    setState(() {
      _isCompressing = true;
      _progress = 0;
      _error = null;
      _result = null;
    });

    try {
      final result = await _service.compressVideo(
        inputPath: _selectedFilePath!,
        resolution: _resolution,
        format: _format,
        quality: _quality.round(),
        onProgress: (p) => setState(() => _progress = p),
      );
      setState(() {
        _result = result;
        _isCompressing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCompressing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _selectedFilePath?.split('/').last;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compresseur vidéo',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Sélection du fichier
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.video_file_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName ?? 'Aucune vidéo sélectionnée',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Choisir une vidéo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Résolution
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Résolution de sortie',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: VideoResolution.values.map((r) {
                    final selected = r == _resolution;
                    return ChoiceChip(
                      label: Text(r.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _resolution = r),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Format
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Format de sortie',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: OutputFormat.values.map((f) {
                    final selected = f == _format;
                    return ChoiceChip(
                      label: Text(f.extension.toUpperCase()),
                      selected: selected,
                      onSelected: (_) => setState(() => _format = f),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Qualité
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qualité (CRF : ${_quality.round()})',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Text(
                  'Plus bas = meilleure qualité, fichier plus lourd. Plus haut = plus compressé.',
                  style: TextStyle(fontSize: 12, color: Colors.white60),
                ),
                Slider(
                  value: _quality,
                  min: 0,
                  max: 51,
                  divisions: 51,
                  label: _quality.round().toString(),
                  onChanged: (v) => setState(() => _quality = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: (_selectedFilePath == null || _isCompressing)
                ? null
                : _startCompression,
            icon: const Icon(Icons.compress),
            label: Text(_isCompressing ? 'Compression en cours...' : 'Compresser'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),

          if (_isCompressing) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress / 100),
            const SizedBox(height: 6),
            Text('${_progress.toStringAsFixed(1)} %'),
          ],

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],

          if (_result != null) ...[
            const SizedBox(height: 20),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.greenAccent),
                      SizedBox(width: 8),
                      Text('Compression terminée !',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                      'Taille originale : ${_service.formatBytes(_result!.originalSizeBytes)}'),
                  Text(
                      'Taille compressée : ${_service.formatBytes(_result!.compressedSizeBytes)}'),
                  const SizedBox(height: 6),
                  Text(_result!.outputPath,
                      style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}
