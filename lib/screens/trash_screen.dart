import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../providers/notes_controller.dart';
import '../themes/app_theme.dart';
import '../utils/date_formatter.dart';

class TrashScreen extends StatelessWidget {
  final NotesController controller;

  const TrashScreen({super.key, required this.controller});

  void _showTrashActionDialog(BuildContext context, NoteModel note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(note.title.isEmpty ? 'Catatan' : note.title),
        content: const Text('Pilih tindakan untuk catatan di tempat sampah:'),
        actions: [
          TextButton.icon(
            onPressed: () {
              controller.restoreFromTrash(note.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Catatan berhasil dipulihkan! ♻️')),
              );
            },
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Pulihkan'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              controller.deletePermanently(note.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Catatan dihapus permanen.')),
              );
            },
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kosongkan Tempat Sampah?'),
        content: const Text(
          'Semua catatan di tempat sampah akan dihapus secara permanen dan tidak dapat dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              controller.emptyTrash();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tempat sampah telah dikosongkan! 🗑️')),
              );
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trashNotes = controller.trashNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tempat Sampah'),
        actions: [
          if (trashNotes.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmEmptyTrash(context),
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              label: const Text('Kosongkan', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: trashNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tempat Sampah Kosong',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Catatan yang Anda hapus akan muncul di sini',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trashNotes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = trashNotes[index];
                final bgColor = AppTheme.getNoteBackgroundColor(note.colorIndex, isDark);
                final borderColor = AppTheme.getNoteBorderColor(note.colorIndex, isDark);

                return InkWell(
                  onTap: () => _showTrashActionDialog(context, note),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.title.isEmpty ? 'Tanpa Judul' : note.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.restore_rounded),
                              tooltip: 'Pulihkan',
                              onPressed: () {
                                controller.restoreFromTrash(note.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Catatan dipulihkan! ♻️')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                              tooltip: 'Hapus Permanen',
                              onPressed: () {
                                controller.deletePermanently(note.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Catatan dihapus permanen.')),
                                );
                              },
                            ),
                          ],
                        ),
                        if (note.previewText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            note.previewText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kategori: ${note.category}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            Text(
                              'Dihapus: ${note.deletedAt != null ? AppDateFormatter.formatWithTime(note.deletedAt!) : "-"}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
