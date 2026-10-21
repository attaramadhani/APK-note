import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../themes/app_theme.dart';
import '../utils/date_formatter.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback? onTogglePin;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final void Function(int colorIndex)? onColorChange;
  final void Function(String itemId)? onToggleChecklist;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onTogglePin,
    this.onDelete,
    this.onArchive,
    this.onColorChange,
    this.onToggleChecklist,
  });

  String _formatDateTime(DateTime dt) {
    return AppDateFormatter.formatShort(dt);
  }

  void _showQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: Text(note.isPinned ? 'Lepas Sematan' : 'Sematkan ke Atas'),
                onTap: () {
                  Navigator.pop(ctx);
                  onTogglePin?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Ganti Warna'),
                onTap: () {
                  Navigator.pop(ctx);
                  // Buka sheet pemilih warna
                  _showColorPicker(context);
                },
              ),
              ListTile(
                leading: Icon(
                  note.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                ),
                title: Text(note.isArchived ? 'Batal Arsipkan' : 'Arsipkan Catatan'),
                onTap: () {
                  Navigator.pop(ctx);
                  onArchive?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('Pindahkan ke Tempat Sampah', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ganti Warna Catatan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppTheme.noteColors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (ctx2, i) {
                  final isSelected = note.colorIndex == i;
                  return GestureDetector(
                    onTap: () {
                      onColorChange?.call(i);
                      Navigator.pop(ctx2);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppTheme.noteColors[i].darkColor
                            : AppTheme.noteColors[i].lightColor,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : (isDark
                                  ? AppTheme.noteColors[i].darkBorder
                                  : AppTheme.noteColors[i].lightBorder),
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 20,
                              color: isDark ? Colors.white : Colors.black87,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = AppTheme.getNoteBackgroundColor(note.colorIndex, isDark);
    final borderColor = AppTheme.getNoteBorderColor(note.colorIndex, isDark);

    return InkWell(
      onTap: onTap,
      onLongPress: () => _showQuickActions(context),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Baris Judul & Indikator
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Tanpa Judul' : note.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (note.isLocked) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                  ),
                ],
                if (note.isPinned) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),

            // Badge Prioritas & Pengingat jika ada
            if (note.priority > 0 || note.hasReminder) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (note.priority > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: note.priority == 3
                            ? Colors.red.withAlpha(isDark ? 50 : 30)
                            : (note.priority == 2
                                ? Colors.amber.withAlpha(isDark ? 50 : 30)
                                : Colors.green.withAlpha(isDark ? 50 : 30)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: note.priority == 3
                              ? Colors.red.withAlpha(120)
                              : (note.priority == 2
                                  ? Colors.amber.withAlpha(120)
                                  : Colors.green.withAlpha(120)),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${note.priorityEmoji} ${note.priorityLabel}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: note.priority == 3
                              ? (isDark ? Colors.red.shade300 : Colors.red.shade800)
                              : (note.priority == 2
                                  ? (isDark ? Colors.amber.shade300 : Colors.amber.shade900)
                                  : (isDark ? Colors.green.shade300 : Colors.green.shade800)),
                        ),
                      ),
                    ),
                  if (note.hasReminder)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: note.isReminderOverdue
                            ? Colors.red.withAlpha(isDark ? 40 : 25)
                            : theme.colorScheme.primary.withAlpha(isDark ? 40 : 25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alarm_rounded,
                            size: 12,
                            color: note.isReminderOverdue
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            note.isDailyReminder
                                ? 'Setiap Hari (${AppDateFormatter.formatTimeOnly(note.reminderDateTime!)}) 🔁'
                                : (note.isReminderOverdue
                                    ? 'Terlewat (${AppDateFormatter.formatWithTime(note.reminderDateTime!)})'
                                    : AppDateFormatter.formatWithTime(note.reminderDateTime!)),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: note.isReminderOverdue
                                  ? Colors.red
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            // Konten
            if (note.isLocked)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Catatan terkunci',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (note.isChecklist)
              _buildChecklistPreview(theme)
            else if (note.content.isNotEmpty)
              Text(
                note.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(220),
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 14),

            // Baris Kategori & Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tag Kategori
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(25)
                        : Colors.black.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    note.category,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),

                // Waktu
                Text(
                  _formatDateTime(note.updatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.labelSmall?.color?.withAlpha(150),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistPreview(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (note.checklist.isEmpty) {
      return Text(
        'Daftar periksa kosong',
        style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      );
    }

    final displayItems = note.checklist.take(4).toList();
    final remaining = note.checklist.length - displayItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayItems.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => onToggleChecklist?.call(item.id),
                  borderRadius: BorderRadius.circular(4),
                  child: Icon(
                    item.isDone
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 18,
                    color: item.isDone
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.text.isEmpty ? 'Tugas...' : item.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      decoration: item.isDone ? TextDecoration.lineThrough : null,
                      color: item.isDone
                          ? theme.textTheme.bodyMedium?.color?.withAlpha(120)
                          : theme.textTheme.bodyMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.hasTime) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(isDark ? 80 : 120),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.time!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '+ $remaining tugas lainnya',
              style: theme.textTheme.labelSmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
