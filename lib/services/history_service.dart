import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class ReformulationEntry {
  final int? id;
  final String original;
  final String reformulated;
  final String tone;
  final DateTime createdAt;

  ReformulationEntry({
    this.id,
    required this.original,
    required this.reformulated,
    required this.tone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'original': original,
        'reformulated': reformulated,
        'tone': tone,
        'created_at': createdAt.toIso8601String(),
      };

  factory ReformulationEntry.fromMap(Map<String, dynamic> map) => ReformulationEntry(
        id: map['id'] as int?,
        original: map['original'] as String,
        reformulated: map['reformulated'] as String,
        tone: map['tone'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class HistoryService {
  static Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'mediatoolbox_history.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE reformulations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          original TEXT NOT NULL,
          reformulated TEXT NOT NULL,
          tone TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      '''),
    );
    return _db!;
  }

  Future<void> add(ReformulationEntry entry) async {
    final db = await _database;
    await db.insert('reformulations', entry.toMap());
  }

  Future<List<ReformulationEntry>> getRecent({int limit = 20}) async {
    final db = await _database;
    final rows = await db.query(
      'reformulations',
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map(ReformulationEntry.fromMap).toList();
  }
}
