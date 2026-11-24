import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:classicum_admin/core/theme.dart';
import 'package:classicum_admin/core/ui/widgets.dart';
import 'package:classicum_admin/features/agenda/data/evento.dart';
import 'package:classicum_admin/features/agenda/data/events_repository.dart';
import 'package:classicum_admin/features/agenda/presentation/event_form_screen.dart';

enum AgendaFilter { all, upcoming, past }

const _filterLabels = {
  AgendaFilter.all: 'Tutti',
  AgendaFilter.upcoming: 'Prossimi',
  AgendaFilter.past: 'Passati',
};

/// Filters and orders events for the agenda (upcoming first, soonest first).
List<Evento> filterEvents(List<Evento> all, AgendaFilter f, DateTime now) {
  final list = all.where((e) {
    switch (f) {
      case AgendaFilter.all:
        return true;
      case AgendaFilter.upcoming:
        return e.isUpcoming(now);
      case AgendaFilter.past:
        return !e.isUpcoming(now);
    }
  }).toList();
  list.sort((a, b) {
    final au = a.isUpcoming(now), bu = b.isUpcoming(now);
    if (au != bu) return au ? -1 : 1;
    return au ? a.data.compareTo(b.data) : b.data.compareTo(a.data);
  });
  return list;
}

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late Future<List<Evento>> _future;
  AgendaFilter _filter = AgendaFilter.upcoming;

  @override
  void initState() {
    super.initState();
    _future = context.read<EventsRepository>().events();
  }

  void _reload() =>
      setState(() => _future = context.read<EventsRepository>().events());

  Future<void> _add() async {
    final created = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const EventFormScreen()));
    if (created == true && mounted) _reload();
  }

  Future<void> _delete(Evento e) async {
    final repo = context.read<EventsRepository>();
    if (!await confirm(context, 'Eliminare l\'evento?', e.titolo)) return;
    try {
      await repo.deleteEvent(e.id);
      if (mounted) {
        showMessage(context, 'Evento eliminato');
        _reload();
      }
    } catch (err) {
      if (mounted) showMessage(context, errorText(err));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-event'),
        onPressed: _add,
        backgroundColor: Palette.ink,
        foregroundColor: Palette.cream,
        icon: const Icon(Icons.add),
        label: const Text('Evento'),
      ),
      body: FutureBuilder<List<Evento>>(
        future: _future,
        builder: (context, snap) {
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 96),
              children: [
                const PageHeader(eyebrow: 'Eventi del sito', title: 'Agenda'),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in AgendaFilter.values) ...[
                        FilterPill(
                          label: _filterLabels[f]!,
                          selected: f == _filter,
                          onTap: () => setState(() => _filter = f),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(height: 2, color: Palette.ink),
                if (snap.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snap.hasError)
                  ErrorView(error: snap.error!, onRetry: _reload)
                else
                  ..._items(snap.data!),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _items(List<Evento> all) {
    final events = filterEvents(all, _filter, DateTime.now());
    if (events.isEmpty) return const [EmptyView('Nessun evento.')];
    return [
      for (final e in events)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Palette.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatDay(e.data), style: displayStyle(44)),
                    const SizedBox(height: 4),
                    Text(
                      formatMonth(e.data),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.titolo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${e.luogo} · ${formatTime(e.data)}',
                      style: const TextStyle(
                        fontFamily: serif,
                        fontStyle: FontStyle.italic,
                        fontSize: 17,
                        color: Palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Elimina ${e.titolo}',
                onPressed: () => _delete(e),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
    ];
  }
}
