class UserModel {
  final String id;
  final String? fullName;
  final String? email;   
  final String role;
  final String? profileImagePath;

  UserModel({
    required this.id,
    this.fullName,
    this.email,
    required this.role,
    this.profileImagePath,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'];
    final fullName = json['fullName'];
    final email = json['email'];
    final role = json['role'];
    final profileImagePath = json['profileImagePath'];

    if (id == null || id is! String || id.isEmpty) {
      throw FormatException('Invalid or missing user ID');
    }
    if (role == null || role is! String || !['listener', 'artist', 'admin'].contains(role)) {
      throw FormatException('Invalid or missing role');
    }

    return UserModel(
      id: id,
      fullName: fullName is String ? fullName : '', // Fallback to empty string
      email: email is String ? email : null,       // Allow null email
      role: role,
      profileImagePath: profileImagePath is String ? profileImagePath : null, // Allow null if not present
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'profileImagePath': profileImagePath,
    };
  }
}