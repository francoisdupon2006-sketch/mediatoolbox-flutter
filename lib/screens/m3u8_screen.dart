import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/m3u8_service.dart';

class M3u8Screen extends StatefulWidget {
  const M3u8Screen({super.key});

  @override
  State<M3u8Screen> createState() => _M3u8ScreenState();
}

class _M3u8ScreenState extends State<M3u8Screen> {
  final _service = M3u8Service();

  bool _isScanning = false;
  bool _isConverting = false;
  List<M3u8File> _files = [];
  final Set<M3u8File> _selected = {};
  final Map<M3u8File, String> _logs = {};

  Future<void> _pickFolderAndScan() async {
    await Permission.manageExternalStorage.request();
    final folderPath = await FilePicker.platform.getDirectoryPath();
    if (folderPath == null) return;

    setState(() {
      _isScanning = true;
      _files = [];
      _selected.clear();
      _logs.clear();
    });

    final results = await _service.scanFolder(folderPath);

    setState(() {
      _files = results;
      _isScanning = false;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selected.length == _files.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_files);
      }
    });
  }

  Future<void> _convertSelected() async {
    if (_selected.isEmpty) return;
    setState(() => _isConverting = true);

    await _service.convertQueue(
      _selected.toList(),
      onStart: (file) => setState(() {
        file.status = M3u8ConversionStatus.running;
      }),
      onProgress: (file, log) => setState(() {
        _logs[file] = log;
      }),
      onSuccess: (file) => setState(() {
        file.status = M3u8ConversionStatus.success;
      }),
      onError: (file, error) => setState(() {
        file.status = M3u8ConversionStatus.failed;
        file.errorMessage = error;
      }),
    );

    setState(() => _isConverting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text('Convertisseur M3U8 → MP4',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isScanning ? null : _pickFolderAndScan,
                  icon: const Icon(Icons.search),
                  label: Text(_isScanning ? 'Scan en cours...' : 'Scanner un dossier'),
                ),
              ),
              const SizedBox(width: 8),
              if (_files.isNotEmpty)
                OutlinedButton(
                  onPressed: _toggleSelectAll,
                  child: Text(_selected.length == _files.length
                      ? 'Aucun'
                      : 'Tout sélectionner'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_files.isEmpty && !_isScanning)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Aucun fichier .m3u8 trouvé pour le moment. Choisis un dossier à scanner.',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _files.length,
            itemBuilder: (context, index) {
              final file = _files[index];
              final isSelected = _selected.contains(file);
              return Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: _isConverting
                      ? null
                      : (v) => setState(() {
                            if (v == true) {
                              _selected.add(file);
                            } else {
                              _selected.remove(file);
                            }
                          }),
                  title: Text(file.fileName, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    _logs[file] ?? file.path,
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondary: _statusIcon(file.status),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton.icon(
            onPressed: (_selected.isEmpty || _isConverting) ? null : _convertSelected,
            icon: const Icon(Icons.transform),
            label: Text(_isConverting
                ? 'Conversion en cours...'
                : 'Convertir la sélection (${_selected.length})'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
        ),
      ],
    );
  }

  Widget _statusIcon(M3u8ConversionStatus status) {
    switch (status) {
      case M3u8ConversionStatus.pending:
        return const Icon(Icons.schedule, color: Colors.white38);
      case M3u8ConversionStatus.running:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case M3u8ConversionStatus.success:
        return const Icon(Icons.check_circle, color: Colors.greenAccent);
      case M3u8ConversionStatus.failed:
        return const Icon(Icons.error, color: Colors.redAccent);
    }
  }
}
