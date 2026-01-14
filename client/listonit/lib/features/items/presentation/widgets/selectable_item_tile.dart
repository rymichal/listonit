import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/item.dart';
import '../../providers/item_form_provider.dart';
import '../../providers/item_selection_provider.dart';
import '../../providers/items_provider.dart';

class SelectableItemTile extends ConsumerStatefulWidget {
  final Item item;
  final String listId;
  final Color accentColor;

  const SelectableItemTile({
    super.key,
    required this.item,
    required this.listId,
    required this.accentColor,
  });

  @override
  ConsumerState<SelectableItemTile> createState() => _SelectableItemTileState();
}

class _SelectableItemTileState extends ConsumerState<SelectableItemTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _showSaved = false;
  Timer? _debounceTimer;
  Timer? _savedTimer;

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _noteController;

  late AnimationController _checkAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
    _noteController = TextEditingController(text: widget.item.note ?? '');

    // Setup check animation
    _checkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _checkAnimationController,
      curve: Curves.easeInOut,
    ));

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Set initial animation state based on item
    if (widget.item.isChecked) {
      _checkAnimationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SelectableItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if item changed from server
    if (oldWidget.item.name != widget.item.name &&
        _nameController.text != widget.item.name) {
      _nameController.text = widget.item.name;
    }
    if (oldWidget.item.quantity != widget.item.quantity &&
        _quantityController.text != widget.item.quantity.toString()) {
      _quantityController.text = widget.item.quantity.toString();
    }
    if (oldWidget.item.note != widget.item.note &&
        _noteController.text != (widget.item.note ?? '')) {
      _noteController.text = widget.item.note ?? '';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _savedTimer?.cancel();
    _nameController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    _checkAnimationController.dispose();
    super.dispose();
  }

  void _debouncedSave({
    String? name,
    int? quantity,
    String? unit,
    String? note,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final success =
          await ref.read(itemsProvider(widget.listId).notifier).updateItem(
                itemId: widget.item.id,
                name: name,
                quantity: quantity,
                unit: unit,
                note: note,
              );

      if (success && mounted) {
        _showSavedIndicator();
      }
    });
  }

  void _showSavedIndicator() {
    setState(() => _showSaved = true);
    _savedTimer?.cancel();
    _savedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSaved = false);
      }
    });
  }

  Future<void> _toggleItem() async {
    // Play animation
    if (!widget.item.isChecked) {
      _checkAnimationController.forward();
    } else {
      _checkAnimationController.reverse();
    }

    await ref
        .read(itemsProvider(widget.listId).notifier)
        .toggleItem(widget.item.id);
  }

  Future<void> _deleteItem() async {
    final itemName = widget.item.name;
    final notifier = ref.read(itemsProvider(widget.listId).notifier);

    await notifier.deleteItem(widget.item.id);

    if (!mounted) return;

    // Show undo snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "$itemName"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            notifier.undoDeleteItem();
          },
        ),
      ),
    );
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    ref
        .read(itemSelectionProvider.notifier)
        .enterSelectionMode(widget.listId, widget.item.id);
  }

  void _onTapInSelectionMode() {
    ref.read(itemSelectionProvider.notifier).toggleItem(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(itemSelectionProvider);
    final isSelectionMode = selectionState.isSelectionMode &&
        selectionState.listId == widget.listId;
    final isSelected = selectionState.isSelected(widget.item.id);

    return GestureDetector(
      onLongPress: isSelectionMode ? null : _onLongPress,
      child: Dismissible(
        key: Key(widget.item.id),
        direction:
            isSelectionMode ? DismissDirection.none : DismissDirection.horizontal,
        background: _buildSwipeBackground(context, isLeft: true),
        secondaryBackground: _buildSwipeBackground(context, isLeft: false),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe right - toggle check
            await _toggleItem();
            return false; // Don't dismiss, just toggle
          } else {
            // Swipe left - delete
            return true;
          }
        },
        onDismissed: (_) => _deleteItem(),
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected
              ? widget.accentColor.withAlpha(30)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main tile
                ListTile(
                  leading: isSelectionMode
                      ? _buildSelectionCheckbox(isSelected)
                      : _buildAnimatedCheckbox(),
                  title: _isExpanded && !isSelectionMode
                      ? _buildNameField()
                      : GestureDetector(
                          onTap: isSelectionMode
                              ? _onTapInSelectionMode
                              : () => setState(() => _isExpanded = true),
                          child: Text(
                            widget.item.name,
                            style: TextStyle(
                              decoration: widget.item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: widget.item.isChecked
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                  subtitle: !_isExpanded ? _buildSubtitle() : null,
                  trailing: isSelectionMode
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_showSaved)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  'Saved',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                _isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  setState(() => _isExpanded = !_isExpanded),
                            ),
                          ],
                        ),
                  onTap: isSelectionMode
                      ? _onTapInSelectionMode
                      : (widget.item.isChecked ? () => _toggleItem() : null),
                ),

                // Expanded edit form
                if (_isExpanded && !isSelectionMode)
                  _buildExpandedForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCheckbox(bool isSelected) {
    return Checkbox(
      value: isSelected,
      onChanged: (_) => _onTapInSelectionMode(),
      activeColor: widget.accentColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildAnimatedCheckbox() {
    return GestureDetector(
      onTap: _toggleItem,
      child: AnimatedBuilder(
        animation: _checkAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.item.isChecked
                      ? widget.accentColor
                      : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
                color: widget.item.isChecked
                    ? widget.accentColor
                    : Colors.transparent,
              ),
              child: widget.item.isChecked
                  ? CustomPaint(
                      painter: _CheckPainter(
                        progress: _checkAnimation.value,
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeBackground(BuildContext context, {required bool isLeft}) {
    return Container(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(left: isLeft ? 16 : 0, right: isLeft ? 0 : 16),
      color: isLeft
          ? widget.accentColor
          : Theme.of(context).colorScheme.error,
      child: Icon(
        isLeft ? Icons.check : Icons.delete,
        color: Colors.white,
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      style: TextStyle(
        decoration: widget.item.isChecked ? TextDecoration.lineThrough : null,
        color: widget.item.isChecked
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : null,
      ),
      onChanged: (value) {
        if (value.trim().isNotEmpty) {
          _debouncedSave(name: value.trim());
        }
      },
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          _debounceTimer?.cancel();
          ref.read(itemsProvider(widget.listId).notifier).updateItem(
                itemId: widget.item.id,
                name: value.trim(),
              );
          _showSavedIndicator();
        }
      },
    );
  }

  Widget? _buildSubtitle() {
    final parts = <String>[];

    if (widget.item.quantity > 1 || widget.item.unit != null) {
      final qtyStr = widget.item.quantity > 1 ? '${widget.item.quantity}' : '';
      final unitStr = widget.item.unit ?? '';
      if (qtyStr.isNotEmpty && unitStr.isNotEmpty) {
        parts.add('$qtyStr $unitStr');
      } else if (qtyStr.isNotEmpty) {
        parts.add('Qty: $qtyStr');
      } else if (unitStr.isNotEmpty) {
        parts.add(unitStr);
      }
    }

    if (widget.item.note != null && widget.item.note!.isNotEmpty) {
      parts.add(widget.item.note!);
    }

    if (parts.isEmpty) return null;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Text(
        parts.join(' · '),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildExpandedForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // Quantity row
          Row(
            children: [
              Text(
                'Qty:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
              _buildQuantityStepper(),
              const SizedBox(width: 16),
              Expanded(
                child: _buildUnitDropdown(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Note field
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Note (optional)',
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
              _debouncedSave(note: value.isEmpty ? null : value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper() {
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
            onTap: () {
              final current = int.tryParse(_quantityController.text) ?? 1;
              if (current > 1) {
                final newQty = current - 1;
                _quantityController.text = newQty.toString();
                _debouncedSave(quantity: newQty);
              }
            },
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(7),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.remove,
                size: 20,
                color: (int.tryParse(_quantityController.text) ?? 1) > 1
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
              onChanged: (value) {
                final qty = int.tryParse(value);
                if (qty != null && qty >= 1) {
                  _debouncedSave(quantity: qty);
                }
              },
            ),
          ),

          // Increment button
          InkWell(
            onTap: () {
              final current = int.tryParse(_quantityController.text) ?? 1;
              final newQty = current + 1;
              _quantityController.text = newQty.toString();
              _debouncedSave(quantity: newQty);
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

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: widget.item.unit,
      decoration: InputDecoration(
        hintText: 'Unit',
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
        _debouncedSave(unit: value);
      },
    );
  }
}

/// Custom painter for animated checkmark
class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Checkmark path points (relative to size)
    final start = Offset(size.width * 0.2, size.height * 0.5);
    final middle = Offset(size.width * 0.4, size.height * 0.7);
    final end = Offset(size.width * 0.8, size.height * 0.3);

    final path = Path();

    if (progress <= 0.5) {
      // Draw first segment (start to middle)
      final segmentProgress = progress * 2;
      final currentPoint = Offset.lerp(start, middle, segmentProgress)!;
      path.moveTo(start.dx, start.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      // Draw first segment complete
      path.moveTo(start.dx, start.dy);
      path.lineTo(middle.dx, middle.dy);

      // Draw second segment (middle to end)
      final segmentProgress = (progress - 0.5) * 2;
      final currentPoint = Offset.lerp(middle, end, segmentProgress)!;
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
