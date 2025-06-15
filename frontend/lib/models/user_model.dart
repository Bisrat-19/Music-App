class UserModel {
  final String id;
  final String? fullName;
  final String? email;
  final String role;
  final String? profileImagePath;
  final List<String>? following;
  final int? followerCount;
  final int? followingCount;
  final List<String>? followers;

  UserModel({
    required this.id,
    this.fullName,
    this.email,
    required this.role,
    this.profileImagePath,
    this.following,
    this.followerCount,
    this.followingCount,
    this.followers,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'];
    final fullName = json['fullName'];
    final email = json['email'];
    final role = json['role'];
    final profileImagePath = json['profileImagePath'];
    final following = (json['following'] as List<dynamic>?)?.cast<String>() ?? [];
    final followerCount = json['followerCount'] as int? ?? 0;
    final followingCount = json['followingCount'] as int? ?? 0;
    final followers = (json['followers'] as List<dynamic>?)?.cast<String>() ?? [];

    if (id == null || id is! String || id.isEmpty) {
      throw FormatException('Invalid or missing user ID');
    }
    if (role == null || role is! String || !['listener', 'artist', 'admin'].contains(role)) {
      throw FormatException('Invalid or missing role');
    }

    return UserModel(
      id: id,
      fullName: fullName is String ? fullName : '',
      email: email is String ? email : null,
      role: role,
      profileImagePath: profileImagePath is String ? profileImagePath : null,
      following: following,
      followerCount: followerCount,
      followingCount: followingCount,
      followers: followers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'profileImagePath': profileImagePath,
      'following': following,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'followers': followers,
    };
  }
}