import 'package:flutter/material.dart';
import 'note_model.dart';

enum NoteSortOption {
  dateModifiedDesc,
  dateModifiedAsc,
  dateCreatedDesc,
  dateCreatedAsc,
  priorityDesc,
  titleAsc,
  titleDesc,
}

extension NoteSortOptionX on NoteSortOption {
  String get label {
    switch (this) {
      case NoteSortOption.dateModifiedDesc:
        return 'Terakhir Diedit (Terbaru)';
      case NoteSortOption.dateModifiedAsc:
        return 'Terakhir Diedit (Terlama)';
      case NoteSortOption.dateCreatedDesc:
        return 'Tanggal Dibuat (Terbaru)';
      case NoteSortOption.dateCreatedAsc:
        return 'Tanggal Dibuat (Terlama)';
      case NoteSortOption.priorityDesc:
        return 'Prioritas Tertinggi (🔴 ➔ 🟢)';
      case NoteSortOption.titleAsc:
        return 'Judul (A ke Z)';
      case NoteSortOption.titleDesc:
        return 'Judul (Z ke A)';
    }
  }

  String get shortLabel {
    switch (this) {
      case NoteSortOption.dateModifiedDesc:
        return 'Diedit Terbaru';
      case NoteSortOption.dateModifiedAsc:
        return 'Diedit Terlama';
      case NoteSortOption.dateCreatedDesc:
        return 'Dibuat Terbaru';
      case NoteSortOption.dateCreatedAsc:
        return 'Dibuat Terlama';
      case NoteSortOption.priorityDesc:
        return 'Prioritas Tertinggi';
      case NoteSortOption.titleAsc:
        return 'Judul A-Z';
      case NoteSortOption.titleDesc:
        return 'Judul Z-A';
    }
  }

  IconData get icon {
    switch (this) {
      case NoteSortOption.dateModifiedDesc:
        return Icons.update_rounded;
      case NoteSortOption.dateModifiedAsc:
        return Icons.history_rounded;
      case NoteSortOption.dateCreatedDesc:
        return Icons.add_circle_outline_rounded;
      case NoteSortOption.dateCreatedAsc:
        return Icons.schedule_rounded;
      case NoteSortOption.priorityDesc:
        return Icons.priority_high_rounded;
      case NoteSortOption.titleAsc:
        return Icons.sort_by_alpha_rounded;
      case NoteSortOption.titleDesc:
        return Icons.sort_by_alpha_rounded;
    }
  }

  int compare(NoteModel a, NoteModel b) {
    switch (this) {
      case NoteSortOption.dateModifiedDesc:
        return b.updatedAt.compareTo(a.updatedAt);
      case NoteSortOption.dateModifiedAsc:
        return a.updatedAt.compareTo(b.updatedAt);
      case NoteSortOption.dateCreatedDesc:
        return b.createdAt.compareTo(a.createdAt);
      case NoteSortOption.dateCreatedAsc:
        return a.createdAt.compareTo(b.createdAt);
      case NoteSortOption.priorityDesc:
        final pCompare = b.priority.compareTo(a.priority);
        if (pCompare != 0) return pCompare;
        return b.updatedAt.compareTo(a.updatedAt);
      case NoteSortOption.titleAsc:
        final titleA = a.title.trim().isEmpty ? a.previewText : a.title;
        final titleB = b.title.trim().isEmpty ? b.previewText : b.title;
        return titleA.toLowerCase().compareTo(titleB.toLowerCase());
      case NoteSortOption.titleDesc:
        final titleA = a.title.trim().isEmpty ? a.previewText : a.title;
        final titleB = b.title.trim().isEmpty ? b.previewText : b.title;
        return titleB.toLowerCase().compareTo(titleA.toLowerCase());
    }
  }
}
