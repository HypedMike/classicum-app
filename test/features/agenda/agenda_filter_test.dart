import 'package:flutter_test/flutter_test.dart';
import 'package:classicum_admin/features/agenda/data/evento.dart';
import 'package:classicum_admin/features/agenda/presentation/agenda_screen.dart';

import '../../helpers/fake_backend.dart';

void main() {
  final now = DateTime(2026, 6, 15, 12);
  group('agenda filtering', () {
    final events = [
      Evento.fromJson(eventJson('1', 'Passato', DateTime(2026, 5, 1))),
      Evento.fromJson(eventJson('2', 'Tra due mesi', DateTime(2026, 8, 1))),
      Evento.fromJson(eventJson('3', 'Domani', DateTime(2026, 6, 16))),
    ];

    test('upcoming events come soonest first', () {
      final r = filterEvents(events, AgendaFilter.upcoming, now);
      expect(r.map((e) => e.titolo), ['Domani', 'Tra due mesi']);
    });

    test('past events come most recent first', () {
      final r = filterEvents(events, AgendaFilter.past, now);
      expect(r.map((e) => e.titolo), ['Passato']);
    });

    test('"all" lists upcoming before past', () {
      final r = filterEvents(events, AgendaFilter.all, now);
      expect(r.map((e) => e.titolo), ['Domani', 'Tra due mesi', 'Passato']);
    });
  });
}
