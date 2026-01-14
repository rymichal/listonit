import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemFormState {
  final String name;
  final int quantity;
  final String? unit;
  final String? note;
  final bool isExpanded;

  const ItemFormState({
    this.name = '',
    this.quantity = 1,
    this.unit,
    this.note,
    this.isExpanded = false,
  });

  bool get isValid => name.trim().isNotEmpty;

  ItemFormState copyWith({
    String? name,
    int? quantity,
    String? unit,
    String? note,
    bool? isExpanded,
  }) {
    return ItemFormState(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class ItemFormNotifier extends StateNotifier<ItemFormState> {
  ItemFormNotifier() : super(const ItemFormState());

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setQuantity(int quantity) {
    if (quantity >= 1) {
      state = state.copyWith(quantity: quantity);
    }
  }

  void incrementQuantity() {
    state = state.copyWith(quantity: state.quantity + 1);
  }

  void decrementQuantity() {
    if (state.quantity > 1) {
      state = state.copyWith(quantity: state.quantity - 1);
    }
  }

  void setUnit(String? unit) {
    state = state.copyWith(unit: unit);
  }

  void clearUnit() {
    state = ItemFormState(
      name: state.name,
      quantity: state.quantity,
      unit: null,
      note: state.note,
      isExpanded: state.isExpanded,
    );
  }

  void setNote(String? note) {
    state = state.copyWith(note: note);
  }

  void toggleExpanded() {
    state = state.copyWith(isExpanded: !state.isExpanded);
  }

  void setExpanded(bool expanded) {
    state = state.copyWith(isExpanded: expanded);
  }

  void reset() {
    state = const ItemFormState();
  }

  void resetKeepExpanded() {
    state = ItemFormState(isExpanded: state.isExpanded);
  }
}

final itemFormProvider =
    StateNotifierProvider.autoDispose<ItemFormNotifier, ItemFormState>(
  (ref) => ItemFormNotifier(),
);

// Common units for shopping items
const List<String> itemUnits = [
  'pcs',
  'kg',
  'g',
  'lb',
  'oz',
  'L',
  'ml',
  'gal',
  'dozen',
  'pack',
  'box',
  'can',
  'bottle',
  'bag',
];
