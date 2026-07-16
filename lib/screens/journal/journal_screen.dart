import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/journal_entry.dart';
import '../../services/journal_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'journal_entry_editor_screen.dart';

/// Diario de oracion: lista de intenciones/peticiones escritas por el
/// usuario, agrupadas por fecha, con opcion de marcar como "Respondida".
/// v11c: la ovejita acompana el diario — en el estado vacio mira el libro
/// abierto contigo, y con entradas te saluda desde el encabezado.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late Future<Map<String, List<JournalEntry>>> _future;
  final _newEntryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _newEntryController.dispose();
    super.dispose();
  }

  void _reload() {
    _future = context.read<JournalRepository>().groupedByDate();
  }

  Future<void> _openNewEntrySheet() async {
    _newEntryController.clear();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nueva intención de oración', style: AppTypography.title),
              const SizedBox(height: 12),
              TextField(
                controller: _newEntryController,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Por ejemplo: "Por la salud de mi mamá..."',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final text = _newEntryController.text.trim();
                    if (text.isEmpty) return;
                    await context.read<JournalRepository>().add(text);
                    if (context.mounted) Navigator.of(context).pop(true);
                  },
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (saved == true) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diario de oración')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewEntrySheet,
        icon: const Icon(Icons.add),
        label: const Text('Nueva intención'),
      ),
      body: FutureBuilder<Map<String, List<JournalEntry>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final grouped = snapshot.data!;
          if (grouped.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Libro abierto + la ovejita mirandolo contigo (v11c).
                  SizedBox(
                    width: 220,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        SvgPicture.asset(
                          'assets/illustrations/journal_empty.svg',
                          width: 168,
                        ),
                        Positioned(
                          right: -6,
                          bottom: -8,
                          child: Image.asset(
                            'assets/mascot/ovejita_esperando.png',
                            height: 86,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tu diario está en blanco, listo para tu primera intención',
                    textAlign: TextAlign.center,
                    style: AppTypography.title.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Todavía no has escrito ninguna intención de oración. '
                    'Toca "Nueva intención" para empezar tu diario.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(color: AppColors.inkSoft),
                  ),
                ],
              ),
            );
          }

          final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: dateKeys.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Encabezado con la ovejita (v11c): el diario tambien es
                // parte del caminar con el Pastor.
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/mascot/ovejita.png',
                        height: 34,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Él escucha cada una de tus intenciones 🌿',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.inkSoft),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final key = dateKeys[index - 1];
              final entries = grouped[key]!;
              final label =
                  DateFormat("d 'de' MMMM, y", 'es').format(entries.first.fecha);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      label,
                      style: AppTypography.caption.copyWith(color: AppColors.inkSoft),
                    ),
                  ),
                  ...entries.map((e) => _JournalTile(
                        entry: e,
                        onTap: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => JournalEntryEditorScreen(entry: e),
                            ),
                          );
                          if (changed == true) setState(_reload);
                        },
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _JournalTile extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;

  const _JournalTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        title: Text(
          entry.texto,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body,
        ),
        trailing: entry.respondida
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : const Icon(Icons.hourglass_bottom, color: AppColors.inkSoft),
      ),
    );
  }
}
