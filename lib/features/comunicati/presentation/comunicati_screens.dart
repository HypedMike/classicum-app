import 'package:material_ui/material_ui.dart';
import 'package:classicum_admin/core/ui/admin_top_bar.dart';
import 'package:provider/provider.dart';
import 'package:classicum_admin/core/theme.dart';
import 'package:classicum_admin/core/ui/widgets.dart';
import 'package:classicum_admin/features/comunicati/data/comunicati_repository.dart';
import 'package:classicum_admin/features/comunicati/data/comunicato.dart';

class ComunicatiListScreen extends StatefulWidget {
  const ComunicatiListScreen({super.key});

  @override
  State<ComunicatiListScreen> createState() => _ComunicatiListScreenState();
}

class _ComunicatiListScreenState extends State<ComunicatiListScreen> {
  late Future<List<Comunicato>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ComunicatiRepository>().comunicati();
  }

  void _reload() => setState(() {
    _future = context.read<ComunicatiRepository>().comunicati();
  });

  Future<void> _open([Comunicato? c]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ComunicatoFormScreen(item: c)),
    );
    if (changed == true && mounted) _reload();
  }

  Future<void> _delete(Comunicato c) async {
    final repo = context.read<ComunicatiRepository>();
    if (!await confirm(context, 'Eliminare il comunicato?', c.title)) return;
    try {
      await repo.deleteComunicato(c.id);
      if (mounted) {
        showMessage(context, 'Comunicato eliminato');
        _reload();
      }
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminTopBar(title: 'Comunicati stampa'),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuovo comunicato',
        onPressed: () => _open(),
        backgroundColor: Palette.ink,
        foregroundColor: Palette.cream,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Comunicato>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorView(error: snap.error!, onRetry: _reload);
          }
          final items = [...snap.data!]
            ..sort((a, b) => b.date.compareTo(a.date));
          if (items.isEmpty) return const EmptyView('Nessun comunicato.');
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
              for (final c in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => _open(c),
                  title: Text(
                    c.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(formatDate(c.date)),
                  trailing: IconButton(
                    tooltip: 'Elimina ${c.title}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(c),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ComunicatoFormScreen extends StatefulWidget {
  const ComunicatoFormScreen({super.key, this.item});

  final Comunicato? item;

  @override
  State<ComunicatoFormScreen> createState() => _ComunicatoFormScreenState();
}

class _ComunicatoFormScreenState extends State<ComunicatoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item?.title);
  late final _description = TextEditingController(
    text: widget.item?.description,
  );
  late DateTime _date = widget.item?.date ?? DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = context.read<ComunicatiRepository>();
    try {
      if (widget.item == null) {
        await repo.createComunicato(
          title: _title.text.trim(),
          description: _description.text.trim(),
          date: _date,
        );
      } else {
        await repo.updateComunicato(
          widget.item!.id,
          title: _title.text.trim(),
          description: _description.text.trim(),
          date: _date,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminTopBar(
        title: widget.item == null ? 'Nuovo comunicato' : 'Modifica comunicato',
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const Key('comunicato-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titolo'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(formatDate(_date)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('comunicato-description'),
              controller: _description,
              minLines: 6,
              maxLines: 16,
              decoration: const InputDecoration(
                labelText: 'Testo',
                alignLabelWithHint: true,
              ),
              validator: _required,
            ),
            const SizedBox(height: 28),
            FilledButton(
              key: const Key('comunicato-save'),
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Salvataggio…' : 'Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
