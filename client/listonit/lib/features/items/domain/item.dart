import 'package:equatable/equatable.dart';

class Item extends Equatable {
  final String id;
  final String listId;
  final String name;
  final int quantity;
  final String? unit;
  final String? note;
  final bool isChecked;
  final DateTime? checkedAt;
  final String? checkedBy;
  final int sortIndex;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocal;

  const Item({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity = 1,
    this.unit,
    this.note,
    this.isChecked = false,
    this.checkedAt,
    this.checkedBy,
    this.sortIndex = 0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isLocal = false,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit'] as String?,
      note: json['note'] as String?,
      isChecked: json['is_checked'] as bool? ?? false,
      checkedAt: json['checked_at'] != null
          ? DateTime.parse(json['checked_at'] as String)
          : null,
      checkedBy: json['checked_by'] as String?,
      sortIndex: json['sort_index'] as int? ?? 0,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'note': note,
      'is_checked': isChecked,
      'checked_at': checkedAt?.toIso8601String(),
      'checked_by': checkedBy,
      'sort_index': sortIndex,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Item copyWith({
    String? id,
    String? listId,
    String? name,
    int? quantity,
    String? unit,
    String? note,
    bool? isChecked,
    DateTime? checkedAt,
    String? checkedBy,
    int? sortIndex,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLocal,
  }) {
    return Item(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      isChecked: isChecked ?? this.isChecked,
      checkedAt: checkedAt ?? this.checkedAt,
      checkedBy: checkedBy ?? this.checkedBy,
      sortIndex: sortIndex ?? this.sortIndex,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  List<Object?> get props => [
        id,
        listId,
        name,
        quantity,
        unit,
        note,
        isChecked,
        checkedAt,
        checkedBy,
        sortIndex,
        createdBy,
        createdAt,
        updatedAt,
        isLocal,
      ];
}
