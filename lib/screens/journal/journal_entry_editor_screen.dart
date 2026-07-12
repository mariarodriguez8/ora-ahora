import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/journal_entry.dart';
import '../../services/journal_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Pantalla para ver/editar una entrada existente del diario de oracion,
/// marcarla como "Respondida" y opcionalmente añadir una nota.
class JournalEntryEditorScreen extends StatefulWidget {
  final JournalEntry entry;

  const JournalEntryEditorScreen({super.key, required this.entry});

  @override
  State<JournalEntryEditorScreen> createState() =>
      _JournalEntryEditorScreenState();
}

class _JournalEntryEditorScreenState extends State<JournalEntryEditorScreen> {
  late TextEditingController _textController;
  late TextEditingController _notaController;
  late bool _respondida;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.entry.texto);
    _notaController = TextEditingController(text: widget.entry.notaRespuesta ?? '');
    _respondida = widget.entry.respondida;
  }

  @override
  void dispose() {
    _textController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = context.read<JournalRepository>();
    final updated = widget.entry.copyWith(
      texto: _textController.text.trim(),
      respondida: _respondida,
      fechaRespuesta: _respondida ? (widget.entry.fechaRespuesta ?? DateTime.now()) : null,
      notaRespuesta: _respondida ? _notaController.text.trim() : null,
    );
    await repo.update(updated);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: const Text('¿Seguro que quieres eliminar esta intención de tu diario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final repo = context.read<JournalRepository>();
    await repo.delete(widget.entry.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final fecha = DateFormat("d 'de' MMMM, y", 'es').format(widget.entry.fecha);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intención de oración'),
        actions: [
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fecha, style: AppTypography.caption.copyWith(color: AppColors.inkSoft)),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                maxLines: 6,
                style: AppTypography.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu intención de oración...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _respondida,
                onChanged: (v) => setState(() => _respondida = v),
                title: const Text('Marcar como respondida'),
                subtitle: const Text('Dios contestó esta oración'),
              ),
              if (_respondida) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _notaController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '¿Cómo fue respondida? (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
