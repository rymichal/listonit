import 'package:equatable/equatable.dart';

class ShoppingList extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String color;
  final String icon;
  final bool isArchived;
  final String sortMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocal;

  const ShoppingList({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.color,
    required this.icon,
    required this.isArchived,
    this.sortMode = 'chronological',
    required this.createdAt,
    required this.updatedAt,
    this.isLocal = false,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      isArchived: json['is_archived'] as bool,
      sortMode: json['sort_mode'] as String? ?? 'chronological',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'color': color,
      'icon': icon,
      'is_archived': isArchived,
      'sort_mode': sortMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ShoppingList copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? color,
    String? icon,
    bool? isArchived,
    String? sortMode,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLocal,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isArchived: isArchived ?? this.isArchived,
      sortMode: sortMode ?? this.sortMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerId,
        name,
        color,
        icon,
        isArchived,
        sortMode,
        createdAt,
        updatedAt,
        isLocal,
      ];
}
