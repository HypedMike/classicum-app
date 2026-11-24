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
