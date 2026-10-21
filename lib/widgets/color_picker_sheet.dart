import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class ColorPickerSheet extends StatelessWidget {
  final int selectedColorIndex;
  final ValueChanged<int> onColorSelected;

  const ColorPickerSheet({
    super.key,
    required this.selectedColorIndex,
    required this.onColorSelected,
  });

  static void show(
    BuildContext context, {
    required int currentColorIndex,
    required ValueChanged<int> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ColorPickerSheet(
        selectedColorIndex: currentColorIndex,
        onColorSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.palette_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pilih Warna Catatan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppTheme.noteColors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final isSelected = selectedColorIndex == index;
                final color = isDark
                    ? AppTheme.noteColors[index].darkColor
                    : AppTheme.noteColors[index].lightColor;
                final borderColor = isDark
                    ? AppTheme.noteColors[index].darkBorder
                    : AppTheme.noteColors[index].lightBorder;

                return GestureDetector(
                  onTap: () {
                    onColorSelected(index);
                    Navigator.of(context).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : borderColor,
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withAlpha(80),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 24,
                            color: isDark ? Colors.white : Colors.black87,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tema saat ini: ${AppTheme.noteColors[selectedColorIndex].name}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withAlpha(160),
            ),
          ),
        ],
      ),
    );
  }
}
