import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/shopping_list.dart';
import '../../providers/lists_provider.dart';
import 'color_picker.dart';
import 'icon_picker.dart';

class EditListModal extends ConsumerStatefulWidget {
  final ShoppingList list;

  const EditListModal({
    super.key,
    required this.list,
  });

  @override
  ConsumerState<EditListModal> createState() => _EditListModalState();
}

class _EditListModalState extends ConsumerState<EditListModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedIcon;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list.name);
    _selectedColor = widget.list.color;
    _selectedIcon = widget.list.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final changed = _nameController.text.trim() != widget.list.name ||
        _selectedColor != widget.list.color ||
        _selectedIcon != widget.list.icon;
    setState(() => _hasChanges = changed);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim() != widget.list.name
        ? _nameController.text.trim()
        : null;
    final color = _selectedColor != widget.list.color ? _selectedColor : null;
    final icon = _selectedIcon != widget.list.icon ? _selectedIcon : null;

    final success = await ref.read(listsProvider.notifier).updateList(
          widget.list.id,
          name: name,
          color: color,
          icon: icon,
        );

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit List',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'List Name',
                  hintText: 'Enter list name',
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  if (value.trim().length > 100) {
                    return 'Name must be 100 characters or less';
                  }
                  return null;
                },
                onChanged: (_) => _checkForChanges(),
              ),
              const SizedBox(height: 16),
              ColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) {
                  setState(() {
                    _selectedColor = color;
                    _checkForChanges();
                  });
                },
              ),
              const SizedBox(height: 16),
              IconPicker(
                selectedIcon: _selectedIcon,
                onIconSelected: (icon) {
                  setState(() {
                    _selectedIcon = icon;
                    _checkForChanges();
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _hasChanges && !_isSaving ? _handleSave : null,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
