import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final ValueChanged<String>? onAddCategory;
  final ValueChanged<String>? onDeleteCategory;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    this.onAddCategory,
    this.onDeleteCategory,
  });

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama kategori (contoh: Kuliah, Hobi)',
            prefixIcon: Icon(Icons.label_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onAddCategory?.call(text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, String catName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Kategori "$catName"?'),
        content: const Text(
          'Catatan dengan kategori ini akan dipindahkan ke kategori "Umum".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              onDeleteCategory?.call(catName);
              Navigator.of(ctx).pop();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + (onAddCategory != null ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Kategori'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _showAddCategoryDialog(context),
            );
          }

          final category = categories[index];
          final isSelected = category == selectedCategory;
          final isDefault = category == 'Semua' ||
              category == 'Umum' ||
              category == '⏰ Pengingat' ||
              category == '🔴 Prioritas';

          return GestureDetector(
            onLongPress: (!isDefault && onDeleteCategory != null)
                ? () => _confirmDeleteCategory(context, category)
                : null,
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(category),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
              selectedColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withAlpha(90),
                ),
              ),
              onSelected: (_) => onSelected(category),
            ),
          );
        },
      ),
    );
  }
}
