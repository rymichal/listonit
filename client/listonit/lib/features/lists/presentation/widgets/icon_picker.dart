import 'package:flutter/material.dart';

import '../../../../core/constants/icons.dart';

class IconPicker extends StatelessWidget {
  final String selectedIcon;
  final ValueChanged<String> onIconSelected;

  const IconPicker({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ListIcons.iconNames.map((iconName) {
            final isSelected = iconName == selectedIcon;
            final iconData = ListIcons.getIcon(iconName);

            return GestureDetector(
              onTap: () => onIconSelected(iconName),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Icon(
                  iconData,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
