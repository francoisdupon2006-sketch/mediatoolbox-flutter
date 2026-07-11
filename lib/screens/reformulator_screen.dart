import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/reformulator_service.dart';
import '../services/history_service.dart';

class ReformulatorScreen extends StatefulWidget {
  const ReformulatorScreen({super.key});

  @override
  State<ReformulatorScreen> createState() => _ReformulatorScreenState();
}

class _ReformulatorScreenState extends State<ReformulatorScreen> {
  final _service = ReformulatorService();
  final _historyService = HistoryService();
  final _controller = TextEditingController();

  ReformulationTone _tone = ReformulationTone.professionnel;
  String? _result;
  bool _isLoading = false;
  String? _error;
  List<ReformulationEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getRecent();
    setState(() => _history = history);
  }

  Future<void> _reformulate() async {
    final sentence = _controller.text.trim();
    if (sentence.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _service.reformulate(sentence, _tone);
      setState(() {
        _result = result;
        _isLoading = false;
      });

      await _historyService.add(ReformulationEntry(
        original: sentence,
        reformulated: result,
        tone: _tone.label,
        createdAt: DateTime.now(),
      ));
      _loadHistory();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyResult() {
    if (_result == null) return;
    Clipboard.setData(ClipboardData(text: _result!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copié dans le presse-papiers')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reformulateur de phrases',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Écris ta phrase ici...',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Catégorie de ton', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReformulationTone.values.map((t) {
              final selected = t == _tone;
              return ChoiceChip(
                label: Text(t.label),
                selected: selected,
                onSelected: (_) => setState(() => _tone = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _isLoading ? null : _reformulate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_isLoading ? 'Reformulation...' : 'Reformuler'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],

          if (_result != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_result!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _copyResult,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copier'),
                      ),
                      TextButton.icon(
                        onPressed: _isLoading ? null : _reformulate,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Régénérer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (_history.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text('Historique récent', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ..._history.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('[${entry.tone}]',
                          style: const TextStyle(fontSize: 11, color: Colors.white54)),
                      Text(entry.reformulated),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
