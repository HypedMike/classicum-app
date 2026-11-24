import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'widgets.dart';

/// "Moduli": the forms built on the website, with their submissions.
class FormsScreen extends StatefulWidget {
  const FormsScreen({super.key});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> {
  late Future<Paginated<FormDefinition>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminRepository>().forms();
  }

  void _reload() =>
      setState(() => _future = context.read<AdminRepository>().forms());

  Future<void> _open(FormDefinition f) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => SubmissionsScreen(form: f)));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        children: [
          const PageHeader(eyebrow: 'Iscrizioni e richieste', title: 'Moduli'),
          const SizedBox(height: 24),
          Container(height: 2, color: Palette.ink),
          FutureBuilder<Paginated<FormDefinition>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return ErrorView(error: snap.error!, onRetry: _reload);
              }
              final forms = snap.data!.items;
              if (forms.isEmpty) return const EmptyView('Nessun modulo.');
              return Column(
                children: [
                  for (final f in forms)
                    InkWell(
                      onTap: () => _open(f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Palette.line),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.name,
                                    style: const TextStyle(
                                      fontFamily: serif,
                                      fontSize: 26,
                                      height: 1.05,
                                    ),
                                  ),
                                  if (f.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        f.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Palette.muted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Pill(
                              f.published ? 'Pubblico' : 'Bozza',
                              dark: f.published,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key, required this.form});

  final FormDefinition form;

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  late FormDefinition _form = widget.form;
  final List<FormSubmission> _items = [];
  int _page = 0;
  int _total = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _items.clear();
      _page = 0;
      _hasMore = true;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<AdminRepository>().submissions(
        _form.id,
        page: _page + 1,
      );
      _items.addAll(res.items);
      _page = res.page;
      _total = res.total;
      _hasMore = res.hasMore;
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _togglePublished(bool value) async {
    try {
      final updated = await context.read<AdminRepository>().setFormPublished(
        _form,
        value,
      );
      if (mounted) setState(() => _form = updated);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    }
  }

  Future<void> _delete(FormSubmission s) async {
    final repo = context.read<AdminRepository>();
    if (!await confirm(
      context,
      'Eliminare la risposta?',
      'Inviata il ${formatDate(s.createdAt)}',
    )) {
      return;
    }
    try {
      await repo.deleteSubmission(_form.id, s.id);
      if (mounted) _load(reset: true);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    }
  }

  String _display(FormFieldDef field, dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Sì' : 'No';
    if (value is List) {
      return value.map((v) => field.choiceLabel('$v')).join(', ');
    }
    final text = '$value';
    return text.isEmpty ? '—' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_form.name)),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pubblicato sul sito'),
              value: _form.published,
              onChanged: _togglePublished,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('RISPOSTE ($_total)', style: eyebrowStyle()),
            ),
            if (_items.isEmpty && !_loading && _error == null)
              const EmptyView('Nessuna risposta.'),
            for (final s in _items)
              Card(
                color: Palette.paper,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Palette.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${formatDate(s.createdAt)} · ${formatTime(s.createdAt)}',
                              style: eyebrowStyle(),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Elimina risposta',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(s),
                          ),
                        ],
                      ),
                      for (final field in _form.fields)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.key,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Palette.muted,
                                ),
                              ),
                              Text(_display(field, s.answers[field.key])),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (_error != null) ErrorView(error: _error!, onRetry: _load),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_hasMore && _error == null && _items.isNotEmpty)
              Center(
                child: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Carica altre'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
