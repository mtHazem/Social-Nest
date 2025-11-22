class UserModel {
  final String uid;
  final String email;
  final String username;
  final String fullName;
  final String bio;
  final String profileImageUrl;
  final List<String> followers;
  final List<String> following;
  final DateTime joinedDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.fullName,
    required this.bio,
    required this.profileImageUrl,
    required this.followers,
    required this.following,
    required this.joinedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'fullName': fullName,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'followers': followers,
      'following': following,
      'joinedDate': joinedDate.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      fullName: map['fullName'] ?? '',
      bio: map['bio'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      joinedDate: DateTime.fromMillisecondsSinceEpoch(map['joinedDate'] ?? 0),
    );
  }

  // Helper methods
  int get followersCount => followers.length;
  int get followingCount => following.length;
}