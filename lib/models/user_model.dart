class User {
  final int? id;
  final String fullName;
  final String phone;
  final String passwordHash;

  User({
    this.id,
    required this.fullName,
    required this.phone,
    required this.passwordHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'passwordHash': passwordHash,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      fullName: map['fullName'],
      phone: map['phone'],
      passwordHash: map['passwordHash'],
    );
  }
}
