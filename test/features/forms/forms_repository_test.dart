import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:classicum_admin/features/forms/data/form_models.dart';

import '../../helpers/fake_backend.dart';

void main() {
  test('publishing a form PUTs the whole definition', () async {
    final b = FakeBackend();
    b.routes['PUT /api/form/f1'] = (req) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      return http.Response(jsonEncode({'id': 'f1', ...body}), 200);
    };
    final form = FormDefinition.fromJson({
      'id': 'f1',
      'name': 'Iscrizione',
      'description': 'd',
      'published': false,
      'fields': [
        {'key': 'nome', 'type': 'string', 'value': ''},
      ],
    });
    final updated = await b.deps.forms.setFormPublished(form, true);
    expect(updated.published, isTrue);
    expect(updated.fields.single.key, 'nome');
  });
}
