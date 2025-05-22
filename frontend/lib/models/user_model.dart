class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'];
    final fullName = json['fullName'];
    final email = json['email'];
    final role = json['role'];

    if (id == null || id is! String || id.isEmpty) {
      throw FormatException('Invalid or missing user ID');
    }
    if (email == null || email is! String || email.isEmpty) {
      throw FormatException('Invalid or missing email');
    }
    if (role == null || role is! String || !['listener', 'artist', 'admin'].contains(role)) {
      throw FormatException('Invalid or missing role');
    }

    return UserModel(
      id: id,
      fullName: fullName ?? '', // Allow empty fullName for flexibility
      email: email,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
    };
  }
}