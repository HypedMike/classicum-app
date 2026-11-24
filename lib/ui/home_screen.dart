import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../state/auth_controller.dart';
import '../theme.dart';
import 'comunicati_screens.dart';
import 'event_form_screen.dart';
import 'news_screens.dart';
import 'widgets.dart';

class _Overview {
  const _Overview(this.next, this.news, this.newsTotal);

  final Evento? next;
  final List<NewsItem> news;
  final int newsTotal;
}

/// "Oggi": next event, quick actions and latest news.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_Overview> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Overview> _load() async {
    final repo = context.read<AdminRepository>();
    final results = await Future.wait([repo.events(), repo.news(limit: 3)]);
    final events = results[0] as List<Evento>;
    final news = results[1] as Paginated<NewsItem>;
    final now = DateTime.now();
    final upcoming = events.where((e) => e.isUpcoming(now)).toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    return _Overview(
      upcoming.isEmpty ? null : upcoming.first,
      news.items,
      news.total,
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthController>().user?.email ?? '';
    final repo = context.read<AdminRepository>();
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text(
            'CIAO ${email.split('@').first.toUpperCase()}',
            style: eyebrowStyle(color: Palette.ink),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: displayStyle(52),
              children: [
                const TextSpan(text: 'Cosa succede\n'),
                TextSpan(
                  text: 'a Lucca.',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Palette.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FutureBuilder<_Overview>(
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
              final data = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NextEventCard(
                    event: data.next,
                    onOpenAgenda: () => widget.onOpenTab(1),
                  ),
                  const SizedBox(height: 32),
                  const _SectionTitle('I.', 'Gestisci'),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _ServiceTile(
                        n: 'i',
                        label: 'Nuovo evento',
                        onTap: () => _push(const EventFormScreen()),
                      ),
                      _ServiceTile(
                        n: 'ii',
                        label: 'Nuova news',
                        onTap: () => _push(const NewsFormScreen()),
                      ),
                      _ServiceTile(
                        n: 'iii',
                        label: 'News',
                        onTap: () => _push(const NewsListScreen()),
                      ),
                      _ServiceTile(
                        n: 'iv',
                        label: 'Comunicati stampa',
                        onTap: () => _push(const ComunicatiListScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const _SectionTitle('II.', 'Dal Real Collegio'),
                  const SizedBox(height: 6),
                  if (data.news.isEmpty)
                    const EmptyView('Nessuna news ancora.'),
                  for (final n in data.news)
                    InkWell(
                      onTap: () => _push(NewsFormScreen(item: n)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Palette.line),
                          ),
                        ),
                        child: Row(
                          children: [
                            RemoteImage(
                              url: n.mainImageId == null
                                  ? null
                                  : repo.imageUrl(n.mainImageId!),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatDate(n.createdAt).toUpperCase(),
                                    style: eyebrowStyle(),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.numeral, this.title);

  final String numeral;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(
        numeral,
        style: const TextStyle(
          fontFamily: serif,
          fontSize: 18,
          color: Palette.muted,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
      ),
    ],
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.n,
    required this.label,
    required this.onTap,
  });

  final String n;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Palette.ink,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              n,
              style: const TextStyle(
                fontFamily: serif,
                fontSize: 22,
                color: Palette.gold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Palette.cream,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NextEventCard extends StatelessWidget {
  const _NextEventCard({required this.event, required this.onOpenAgenda});

  final Evento? event;
  final VoidCallback onOpenAgenda;

  @override
  Widget build(BuildContext context) {
    final e = event;
    return Container(
      key: const Key('next-event-card'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Palette.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Palette.cream,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Il prossimo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              if (e != null)
                Flexible(
                  child: Text(
                    '${formatDate(e.data)} · ${e.luogo}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFD9D2C3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            e?.titolo ?? 'Nessun evento in programma',
            style: displayStyle(32, color: Palette.cream).copyWith(height: 1),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onOpenAgenda,
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.cream,
              side: const BorderSide(color: Palette.cream),
            ),
            child: const Text('Apri agenda →'),
          ),
        ],
      ),
    );
  }
}
