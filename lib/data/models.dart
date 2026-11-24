class AdminUser {
  const AdminUser({required this.id, required this.email});

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      AdminUser(id: json['id'] as String, email: json['email'] as String);

  final String id;
  final String email;
}

class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  final List<T> items;
  final int page;
  final int total;
  final bool hasMore;
}

class Evento {
  const Evento({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.data,
    required this.luogo,
    this.imageId,
  });

  factory Evento.fromJson(Map<String, dynamic> json) => Evento(
    id: json['id'] as String,
    titolo: json['titolo'] as String,
    descrizione: json['descrizione'] as String? ?? '',
    data: DateTime.parse(json['data'] as String).toLocal(),
    luogo: json['luogo'] as String? ?? '',
    imageId: json['imageId'] as String?,
  );

  final String id;
  final String titolo;
  final String descrizione;
  final DateTime data;
  final String luogo;
  final String? imageId;

  bool isUpcoming(DateTime now) => !data.isBefore(now);
}

class NewsImage {
  const NewsImage({
    required this.fileId,
    required this.isMain,
    required this.order,
  });

  factory NewsImage.fromJson(Map<String, dynamic> json) => NewsImage(
    fileId: json['fileId'] as String,
    isMain: json['isMain'] as bool? ?? false,
    order: (json['order'] as num?)?.toInt() ?? 0,
  );

  final String fileId;
  final bool isMain;
  final int order;

  Map<String, dynamic> toKeepJson() => {
    'fileId': fileId,
    'isMain': isMain,
    'order': order,
  };
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.images = const [],
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final images =
        ((json['newsImages'] as List?) ?? const [])
            .map((e) => NewsImage.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return NewsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      images: images,
    );
  }

  final String id;
  final String title;

  /// HTML produced by the website's rich text editor.
  final String content;
  final DateTime createdAt;
  final List<NewsImage> images;

  String? get mainImageId {
    if (images.isEmpty) return null;
    return images
        .firstWhere((i) => i.isMain, orElse: () => images.first)
        .fileId;
  }
}

class Comunicato {
  const Comunicato({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  factory Comunicato.fromJson(Map<String, dynamic> json) => Comunicato(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    date: DateTime.parse(json['date'] as String).toLocal(),
  );

  final String id;
  final String title;
  final String description;
  final DateTime date;
}

class ContactMessage {
  const ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    required this.createdAt,
  });

  factory ContactMessage.fromJson(Map<String, dynamic> json) => ContactMessage(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    message: json['message'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
  );

  final String id;
  final String name;
  final String email;
  final String message;
  final DateTime createdAt;
}

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
