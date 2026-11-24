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
