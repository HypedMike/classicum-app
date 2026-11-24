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
