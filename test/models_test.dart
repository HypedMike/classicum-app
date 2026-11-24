import 'package:classicum_admin/data/models.dart';
import 'package:classicum_admin/ui/agenda_screen.dart';
import 'package:classicum_admin/ui/news_screens.dart';
import 'package:classicum_admin/ui/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_backend.dart';

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

  group('models', () {
    test('news images are sorted and the main one is picked', () {
      final n = NewsItem.fromJson({
        'id': '1',
        'title': 't',
        'content': 'c',
        'createdAt': '2026-01-01T00:00:00Z',
        'newsImages': [
          {'fileId': 'b', 'isMain': true, 'order': 1},
          {'fileId': 'a', 'isMain': false, 'order': 0},
        ],
      });
      expect(n.images.map((i) => i.fileId), ['a', 'b']);
      expect(n.mainImageId, 'b');
    });

    test('news without images has no main image', () {
      final n = NewsItem.fromJson({
        'id': '1',
        'title': 't',
        'content': 'c',
        'createdAt': '2026-01-01T00:00:00Z',
      });
      expect(n.mainImageId, isNull);
    });

    test('form update body keeps fields untouched and flips published', () {
      final f = FormDefinition.fromJson({
        'id': 'f',
        'name': 'Iscrizione',
        'description': '',
        'published': false,
        'fields': [
          {'key': 'nome', 'type': 'string', 'value': '', 'required': true},
        ],
      });
      final body = f.toUpdateJson(published: true);
      expect(body['published'], true);
      expect(body['fields'], [
        {'key': 'nome', 'type': 'string', 'value': '', 'required': true},
      ]);
    });

    test('choice labels resolve from the field options', () {
      final f = FormFieldDef.fromJson({
        'key': 'sala',
        'type': 'multiple_choice',
        'value': [],
        'options': {
          'maxNumberOfChoices': 1,
          'choices': [
            {'label': 'Sala Grande', 'value': 'grande'},
          ],
        },
      });
      expect(f.choiceLabel('grande'), 'Sala Grande');
      expect(f.choiceLabel('altro'), 'altro');
    });

    test('submissions map answers by key', () {
      final s = FormSubmission.fromJson({
        'id': 's',
        'createdAt': '2026-01-01T00:00:00Z',
        'answers': [
          {'key': 'nome', 'value': 'Anna'},
        ],
      });
      expect(s.answers['nome'], 'Anna');
    });
  });

  group('html helpers', () {
    test('stripHtml turns paragraphs into text', () {
      expect(stripHtml('<p>Uno &amp; due</p><p>Tre</p>'), 'Uno & due\nTre');
    });

    test('toHtml wraps paragraphs and escapes markup', () {
      expect(
        NewsHtml.toHtml('Uno <b>\nsegue\n\nDue'),
        '<p>Uno &lt;b&gt;<br>segue</p><p>Due</p>',
      );
    });
  });
}
