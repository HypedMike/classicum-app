import 'package:flutter_test/flutter_test.dart';
import 'package:classicum_admin/features/forms/data/form_models.dart';

void main() {
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
}
