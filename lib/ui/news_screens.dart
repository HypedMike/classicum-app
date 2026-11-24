import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import 'image_picker_field.dart';
import 'widgets.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final List<NewsItem> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore({bool reset = false}) async {
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
      final res = await context.read<AdminRepository>().news(page: _page + 1);
      _items.addAll(res.items);
      _page = res.page;
      _hasMore = res.hasMore;
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _open([NewsItem? item]) async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => NewsFormScreen(item: item)));
    if (changed == true && mounted) _loadMore(reset: true);
  }

  Future<void> _delete(NewsItem n) async {
    final repo = context.read<AdminRepository>();
    if (!await confirm(context, 'Eliminare la news?', n.title)) return;
    try {
      await repo.deleteNews(n.id);
      if (mounted) {
        showMessage(context, 'News eliminata');
        _loadMore(reset: true);
      }
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('News')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuova news',
        onPressed: () => _open(),
        backgroundColor: Palette.ink,
        foregroundColor: Palette.cream,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMore(reset: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: [
            if (_items.isEmpty && !_loading && _error == null)
              const EmptyView('Nessuna news.'),
            for (final n in _items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _open(n),
                leading: RemoteImage(
                  size: 56,
                  url: n.mainImageId == null
                      ? null
                      : repo.imageUrl(n.mainImageId!),
                ),
                title: Text(
                  n.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(formatDate(n.createdAt)),
                trailing: IconButton(
                  tooltip: 'Elimina ${n.title}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(n),
                ),
              ),
            if (_error != null)
              ErrorView(error: _error!, onRetry: () => _loadMore()),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_hasMore && _error == null && _items.isNotEmpty)
              Center(
                child: OutlinedButton(
                  onPressed: _loadMore,
                  child: const Text('Carica altre'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Create (item == null) or edit a news item.
class NewsFormScreen extends StatefulWidget {
  const NewsFormScreen({super.key, this.item});

  final NewsItem? item;

  @override
  State<NewsFormScreen> createState() => _NewsFormScreenState();
}

class _NewsFormScreenState extends State<NewsFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item?.title);
  late final _content = TextEditingController(
    text: stripHtml(widget.item?.content ?? ''),
  );
  List<UploadImage> _images = [];
  bool _busy = false;

  bool get _editing => widget.item != null;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = context.read<AdminRepository>();
    try {
      final html = NewsHtml.toHtml(_content.text);
      if (_editing) {
        await repo.updateNews(
          widget.item!,
          title: _title.text.trim(),
          content: html,
        );
      } else {
        await repo.createNews(
          title: _title.text.trim(),
          content: html,
          images: _images,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Modifica news' : 'Nuova news')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const Key('news-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titolo'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('news-content'),
              controller: _content,
              minLines: 8,
              maxLines: 20,
              decoration: const InputDecoration(
                labelText: 'Testo',
                alignLabelWithHint: true,
                helperText: 'Una riga vuota separa i paragrafi.',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
            ),
            const SizedBox(height: 16),
            if (_editing)
              const Text(
                'Le immagini si modificano dal sito; qui restano invariate.',
                style: TextStyle(color: Palette.muted),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await pickImages(multiple: true);
                  if (picked.isNotEmpty) setState(() => _images = picked);
                },
                icon: const Icon(Icons.image_outlined),
                label: const Text('Immagini (la prima è la principale)'),
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 8),
                PickedImagesRow(
                  images: _images,
                  onRemove: (i) => setState(() => _images.removeAt(i)),
                ),
              ],
            ],
            const SizedBox(height: 28),
            FilledButton(
              key: const Key('news-save'),
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Salvataggio…' : 'Salva'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Converts the plain text typed in the app to the HTML the website stores.
class NewsHtml {
  static String toHtml(String text) => text
      .split(RegExp(r'\n{2,}'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .map((p) {
        final escaped = p
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('\n', '<br>');
        return '<p>$escaped</p>';
      })
      .join();
}
