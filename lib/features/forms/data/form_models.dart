class FormFieldDef {
  const FormFieldDef({
    required this.key,
    required this.type,
    required this.raw,
    this.required = false,
  });

  factory FormFieldDef.fromJson(Map<String, dynamic> json) => FormFieldDef(
    key: json['key'] as String,
    type: json['type'] as String,
    required: json['required'] as bool? ?? false,
    raw: json,
  );

  final String key;

  /// `string`, `number`, `boolean` or `multiple_choice`.
  final String type;
  final bool required;

  /// Original JSON, sent back untouched when the form is updated.
  final Map<String, dynamic> raw;

  /// Human readable label of a choice value (multiple choice fields).
  String choiceLabel(String value) {
    final choices = (raw['options']?['choices'] as List?) ?? const [];
    for (final c in choices) {
      if (c is Map && c['value'] == value) return c['label'] as String;
    }
    return value;
  }
}

class FormDefinition {
  const FormDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.published,
    required this.fields,
  });

  factory FormDefinition.fromJson(Map<String, dynamic> json) => FormDefinition(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    published: json['published'] as bool? ?? false,
    fields: ((json['fields'] as List?) ?? const [])
        .map((e) => FormFieldDef.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final String id;
  final String name;
  final String description;
  final bool published;
  final List<FormFieldDef> fields;

  /// Body for `PUT /api/form/:id`.
  Map<String, dynamic> toUpdateJson({bool? published}) => {
    'name': name,
    'description': description,
    'published': published ?? this.published,
    'fields': fields.map((f) => f.raw).toList(),
  };
}

class FormSubmission {
  const FormSubmission({
    required this.id,
    required this.createdAt,
    required this.answers,
  });

  factory FormSubmission.fromJson(Map<String, dynamic> json) => FormSubmission(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    answers: {
      for (final a in (json['answers'] as List?) ?? const [])
        (a as Map<String, dynamic>)['key'] as String: a['value'],
    },
  );

  final String id;
  final DateTime createdAt;
  final Map<String, dynamic> answers;
}
