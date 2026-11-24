import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'widgets.dart';

/// "Messaggi": requests received through the website's contact form.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final List<ContactMessage> _items = [];
  final _search = TextEditingController();
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
      final res = await context.read<AdminRepository>().messages(
        page: _page + 1,
        search: _search.text.trim(),
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

  Future<void> _delete(ContactMessage m) async {
    final repo = context.read<AdminRepository>();
    final ok = await confirm(
      context,
      'Eliminare il messaggio?',
      'Da ${m.name}',
    );
    if (!ok) return;
    try {
      await repo.deleteMessage(m.id);
      if (mounted) _load(reset: true);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        children: [
          PageHeader(eyebrow: '$_total ricevuti', title: 'Messaggi'),
          const SizedBox(height: 20),
          TextField(
            key: const Key('messages-search'),
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Cerca per nome, email o testo',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _load(reset: true),
          ),
          const SizedBox(height: 16),
          Container(height: 2, color: Palette.ink),
          if (_items.isEmpty && !_loading && _error == null)
            const EmptyView('Nessun messaggio.'),
          for (final m in _items)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Palette.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatDate(m.createdAt)} · ${m.email}'
                              .toUpperCase(),
                          style: eyebrowStyle(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(m.message, style: const TextStyle(height: 1.4)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Elimina messaggio di ${m.name}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(m),
                  ),
                ],
              ),
            ),
          if (_error != null) ErrorView(error: _error!, onRetry: _load),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasMore && _error == null && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Carica altri'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
