import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/item_form_provider.dart';
import '../../providers/items_provider.dart';

class AddItemForm extends ConsumerStatefulWidget {
  final String listId;
  final Color accentColor;

  const AddItemForm({
    super.key,
    required this.listId,
    required this.accentColor,
  });

  @override
  ConsumerState<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends ConsumerState<AddItemForm> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    final text = _quantityController.text;
    final quantity = int.tryParse(text);
    if (quantity != null && quantity >= 1) {
      ref.read(itemFormProvider.notifier).setQuantity(quantity);
    }
  }

  void _syncQuantityController(int quantity) {
    final currentText = _quantityController.text;
    final currentValue = int.tryParse(currentText);
    if (currentValue != quantity) {
      _quantityController.text = quantity.toString();
      _quantityController.selection = TextSelection.fromPosition(
        TextPosition(offset: _quantityController.text.length),
      );
    }
  }

  Future<void> _submitItem() async {
    final formState = ref.read(itemFormProvider);
    final name = _nameController.text.trim();

    if (name.isEmpty) return;

    // Clear form immediately for better UX
    _nameController.clear();
    _noteController.clear();
    _quantityController.text = '1';
    ref.read(itemFormProvider.notifier).resetKeepExpanded();
    _nameFocusNode.requestFocus();

    // Submit to backend
    if (formState.isExpanded) {
      // Add with details
      await ref.read(itemsProvider(widget.listId).notifier).addItem(
            name: name,
            quantity: formState.quantity,
            unit: formState.unit,
            note: formState.note?.trim().isEmpty == true
                ? null
                : formState.note?.trim(),
          );
    } else {
      // Quick add - support comma separation
      await ref.read(itemsProvider(widget.listId).notifier).addItemsBatch(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(itemFormProvider);

    // Sync quantity controller when state changes (from +/- buttons)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQuantityController(formState.quantity);
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick add row with expand button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    decoration: InputDecoration(
                      hintText: formState.isExpanded
                          ? 'Item name'
                          : 'Add an item... (use commas for multiple)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          formState.isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: widget.accentColor,
                        ),
                        onPressed: () {
                          ref.read(itemFormProvider.notifier).toggleExpanded();
                        },
                        tooltip: formState.isExpanded
                            ? 'Hide details'
                            : 'Add with details',
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitItem(),
                    onChanged: (value) {
                      ref.read(itemFormProvider.notifier).setName(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submitItem,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    padding: const EdgeInsets.all(12),
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // Expanded details form
          if (formState.isExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity and Unit row
                  Row(
                    children: [
                      // Quantity section
                      Text(
                        'Qty:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      _buildQuantityStepper(context, formState),

                      const SizedBox(width: 16),

                      // Unit dropdown
                      Expanded(
                        child: _buildUnitDropdown(context, formState),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Note field
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Note (optional) - brand, size, etc.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 2,
                    maxLength: 500,
                    onChanged: (value) {
                      ref.read(itemFormProvider.notifier).setNote(value);
                    },
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context, ItemFormState formState) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          InkWell(
            onTap: formState.quantity > 1
                ? () {
                    ref.read(itemFormProvider.notifier).decrementQuantity();
                  }
                : null,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(7),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.remove,
                size: 20,
                color: formState.quantity > 1
                    ? widget.accentColor
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),

          // Quantity input
          SizedBox(
            width: 50,
            child: TextField(
              controller: _quantityController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Increment button
          InkWell(
            onTap: () {
              ref.read(itemFormProvider.notifier).incrementQuantity();
            },
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(7),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.add,
                size: 20,
                color: widget.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown(BuildContext context, ItemFormState formState) {
    return DropdownButtonFormField<String>(
      initialValue: formState.unit,
      decoration: InputDecoration(
        hintText: 'Unit (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('No unit'),
        ),
        ...itemUnits.map(
          (unit) => DropdownMenuItem<String>(
            value: unit,
            child: Text(unit),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) {
          ref.read(itemFormProvider.notifier).clearUnit();
        } else {
          ref.read(itemFormProvider.notifier).setUnit(value);
        }
      },
    );
  }
}
