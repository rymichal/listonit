import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/lists_provider.dart';
import 'color_picker.dart';
import 'icon_picker.dart';

class CreateListModal extends ConsumerStatefulWidget {
  const CreateListModal({super.key});

  @override
  ConsumerState<CreateListModal> createState() => _CreateListModalState();
}

class _CreateListModalState extends ConsumerState<CreateListModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = '#4CAF50';
  String _selectedIcon = 'shopping_cart';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(listsProvider.notifier).createList(
          name: _nameController.text.trim(),
          color: _selectedColor,
          icon: _selectedIcon,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _nameController.text.trim().isNotEmpty;

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
                    'Create New List',
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
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              ColorPicker(
                selectedColor: _selectedColor,
                onColorSelected: (color) {
                  setState(() => _selectedColor = color);
                },
              ),
              const SizedBox(height: 16),
              IconPicker(
                selectedIcon: _selectedIcon,
                onIconSelected: (icon) {
                  setState(() => _selectedIcon = icon);
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isValid && !_isSubmitting ? _handleSubmit : null,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create List'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
