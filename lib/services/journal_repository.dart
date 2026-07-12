import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/journal_entry.dart';

/// Repositorio del diario de oracion, respaldado por un archivo JSON local
/// (`journal_entries.json` en el directorio de documentos de la app).
///
/// Se implemento deliberadamente con una interfaz sencilla (metodos async
/// que devuelven `List<JournalEntry>` o `void`) para que en el futuro se
/// pueda sustituir por una implementacion con `sqflite` sin tener que
/// cambiar las pantallas que lo consumen.
class JournalRepository {
  static const _fileName = 'journal_entries.json';
  static final _uuid = Uuid();

  File? _fileCache;
  List<JournalEntry>? _memoryCache;

  Future<File> _file() async {
    if (_fileCache != null) return _fileCache!;
    final dir = await getApplicationDocumentsDirectory();
    _fileCache = File('${dir.path}/$_fileName');
    return _fileCache!;
  }

  Future<List<JournalEntry>> _readAll() async {
    if (_memoryCache != null) return _memoryCache!;
    final file = await _file();
    if (!await file.exists()) {
      _memoryCache = [];
      return _memoryCache!;
    }
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        _memoryCache = [];
        return _memoryCache!;
      }
      final list = jsonDecode(raw) as List;
      _memoryCache = list
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _memoryCache = [];
    }
    return _memoryCache!;
  }

  Future<void> _writeAll(List<JournalEntry> entries) async {
    final file = await _file();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await file.writeAsString(raw);
    _memoryCache = entries;
  }

  /// Todas las entradas, mas recientes primero.
  Future<List<JournalEntry>> all() async {
    final entries = List<JournalEntry>.from(await _readAll());
    entries.sort((a, b) => b.fecha.compareTo(a.fecha));
    return entries;
  }

  /// Entradas agrupadas por dia (clave "yyyy-MM-dd"), ordenadas del dia
  /// mas reciente al mas antiguo; dentro de cada dia, de la mas reciente
  /// a la mas antigua.
  Future<Map<String, List<JournalEntry>>> groupedByDate() async {
    final entries = await all();
    final Map<String, List<JournalEntry>> grouped = {};
    for (final e in entries) {
      final key =
          '${e.fecha.year.toString().padLeft(4, '0')}-${e.fecha.month.toString().padLeft(2, '0')}-${e.fecha.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return grouped;
  }

  Future<JournalEntry> add(String texto) async {
    final entries = await _readAll();
    final entry = JournalEntry(
      id: _uuid.v4(),
      fecha: DateTime.now(),
      texto: texto,
    );
    entries.add(entry);
    await _writeAll(entries);
    return entry;
  }

  Future<void> update(JournalEntry updated) async {
    final entries = await _readAll();
    final idx = entries.indexWhere((e) => e.id == updated.id);
    if (idx == -1) return;
    entries[idx] = updated;
    await _writeAll(entries);
  }

  Future<void> markRespondida(String id, {String? nota}) async {
    final entries = await _readAll();
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    entries[idx] = entries[idx].copyWith(
      respondida: true,
      fechaRespuesta: DateTime.now(),
      notaRespuesta: nota,
    );
    await _writeAll(entries);
  }

  Future<void> delete(String id) async {
    final entries = await _readAll();
    entries.removeWhere((e) => e.id == id);
    await _writeAll(entries);
  }
}
