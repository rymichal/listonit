class ListMember {
  final String id;
  final String name;
  final String? avatar;
  final String role;
  final DateTime createdAt;

  ListMember({
    required this.id,
    required this.name,
    this.avatar,
    required this.role,
    required this.createdAt,
  });

  ListMember copyWith({
    String? id,
    String? name,
    String? avatar,
    String? role,
    DateTime? createdAt,
  }) {
    return ListMember(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ListMember.fromJson(Map<String, dynamic> json) {
    return ListMember(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
