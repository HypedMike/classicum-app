class AdminUser {
  const AdminUser({required this.id, required this.email});

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      AdminUser(id: json['id'] as String, email: json['email'] as String);

  final String id;
  final String email;
}
