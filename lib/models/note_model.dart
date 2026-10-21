import 'checklist_item.dart';

class NoteModel {
  final String id;
  final String title;
  final String content;
  final bool isChecklist;
  final List<ChecklistItem> checklist;
  final int colorIndex;
  final String category;
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isLocked;
  final int priority; // 0: Biasa, 1: Rendah, 2: Sedang, 3: Tinggi
  final DateTime? reminderDateTime;
  final bool isDailyReminder; // true jika notifikasi berulang setiap hari pada jam ini
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.isChecklist = false,
    this.checklist = const [],
    this.colorIndex = 0,
    this.category = 'Umum',
    this.isPinned = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.deletedAt,
    this.isLocked = false,
    this.priority = 0,
    this.reminderDateTime,
    this.isDailyReminder = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasReminder => reminderDateTime != null;

  bool get isReminderOverdue =>
      !isDailyReminder && reminderDateTime != null && reminderDateTime!.isBefore(DateTime.now());

  String get priorityLabel {
    switch (priority) {
      case 3:
        return 'Tinggi';
      case 2:
        return 'Sedang';
      case 1:
        return 'Rendah';
      default:
        return 'Biasa';
    }
  }

  String get priorityEmoji {
    switch (priority) {
      case 3:
        return '🔴';
      case 2:
        return '🟡';
      case 1:
        return '🟢';
      default:
        return '⚪';
    }
  }

  int get wordCount {
    if (isChecklist) {
      final combined = checklist.map((e) => e.text).join(' ');
      if (combined.trim().isEmpty) return 0;
      return RegExp(r'\S+').allMatches(combined).length;
    }
    if (content.trim().isEmpty) return 0;
    return RegExp(r'\S+').allMatches(content).length;
  }

  int get charCount {
    if (isChecklist) {
      return checklist.fold(0, (sum, item) => sum + item.text.length);
    }
    return content.length;
  }

  int get completedChecklistCount =>
      checklist.where((item) => item.isDone).length;

  int get totalChecklistCount => checklist.length;

  String get previewText {
    if (isChecklist) {
      if (checklist.isEmpty) return 'Daftar periksa kosong';
      final active = checklist.where((e) => !e.isDone).map((e) => '• ${e.text}').take(3).join('\n');
      return active.isEmpty ? 'Semua tugas telah selesai 🎉' : active;
    }
    return content.trim().isEmpty ? 'Catatan kosong' : content;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isChecklist': isChecklist,
      'checklist': checklist.map((x) => x.toJson()).toList(),
      'colorIndex': colorIndex,
      'category': category,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'isLocked': isLocked,
      'priority': priority,
      'reminderDateTime': reminderDateTime?.toIso8601String(),
      'isDailyReminder': isDailyReminder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isChecklist: json['isChecklist'] as bool? ?? false,
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      colorIndex: json['colorIndex'] as int? ?? 0,
      category: json['category'] as String? ?? 'Umum',
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
      isLocked: json['isLocked'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      reminderDateTime: json['reminderDateTime'] != null
          ? DateTime.tryParse(json['reminderDateTime'] as String)
          : null,
      isDailyReminder: json['isDailyReminder'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    bool? isChecklist,
    List<ChecklistItem>? checklist,
    int? colorIndex,
    String? category,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    DateTime? deletedAt,
    bool? isLocked,
    int? priority,
    DateTime? reminderDateTime,
    bool? isDailyReminder,
    bool clearReminder = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isChecklist: isChecklist ?? this.isChecklist,
      checklist: checklist ?? this.checklist,
      colorIndex: colorIndex ?? this.colorIndex,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      isLocked: isLocked ?? this.isLocked,
      priority: priority ?? this.priority,
      reminderDateTime: clearReminder ? null : (reminderDateTime ?? this.reminderDateTime),
      isDailyReminder: clearReminder ? false : (isDailyReminder ?? this.isDailyReminder),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
