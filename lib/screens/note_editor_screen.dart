import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../models/checklist_item.dart';
import '../themes/app_theme.dart';
import '../utils/date_formatter.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/pin_dialog.dart';
import '../services/notification_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? initialNote;
  final bool startAsChecklist;
  final List<String> availableCategories;
  final bool hasMasterPin;
  final bool Function(String pin) onVerifyPin;
  final Future<void> Function(String newPin) onSetMasterPin;
  final Function(NoteModel note) onSave;
  final Function(String noteId)? onDelete;

  const NoteEditorScreen({
    super.key,
    this.initialNote,
    this.startAsChecklist = false,
    required this.availableCategories,
    required this.hasMasterPin,
    required this.onVerifyPin,
    required this.onSetMasterPin,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late String _id;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _isChecklist;
  late List<ChecklistItem> _checklist;
  late int _colorIndex;
  late String _category;
  late bool _isPinned;
  late bool _isArchived;
  late bool _isLocked;
  late int _priority;
  late DateTime? _reminderDateTime;
  late bool _isDailyReminder;
  late DateTime _createdAt;
  late DateTime _updatedAt;

  final List<TextEditingController> _checklistControllers = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final note = widget.initialNote;
    if (note != null) {
      _id = note.id;
      _titleController = TextEditingController(text: note.title);
      _contentController = TextEditingController(text: note.content);
      _isChecklist = note.isChecklist;
      _checklist = List.from(note.checklist);
      _colorIndex = note.colorIndex;
      _category = note.category;
      _isPinned = note.isPinned;
      _isArchived = note.isArchived;
      _isLocked = note.isLocked;
      _priority = note.priority;
      _reminderDateTime = note.reminderDateTime;
      _isDailyReminder = note.isDailyReminder;
      _createdAt = note.createdAt;
      _updatedAt = note.updatedAt;
    } else {
      _id = const Uuid().v4();
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _isChecklist = widget.startAsChecklist;
      _checklist = widget.startAsChecklist
          ? [ChecklistItem(id: const Uuid().v4(), text: '', isDone: false)]
          : [];
      _colorIndex = 0;
      _category = 'Umum';
      _isPinned = false;
      _isArchived = false;
      _isLocked = false;
      _priority = 0;
      _reminderDateTime = null;
      _isDailyReminder = false;
      _createdAt = DateTime.now();
      _updatedAt = DateTime.now();
    }

    _initChecklistControllers();

    _titleController.addListener(_markChanged);
    _contentController.addListener(_markChanged);
  }

  void _initChecklistControllers() {
    _checklistControllers.clear();
    for (var item in _checklist) {
      final ctrl = TextEditingController(text: item.text);
      ctrl.addListener(() {
        item.text = ctrl.text;
        _markChanged();
      });
      _checklistControllers.add(ctrl);
    }
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    for (var c in _checklistControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isSaved = false;

  void _saveNote() {
    if (_isSaved) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Jika catatan checklist, bersihkan item yang benar-benar kosong kecuali jika hanya ada 1 item
    final validChecklist = _checklist
        .where((e) => e.text.trim().isNotEmpty)
        .toList();

    // Jangan simpan jika semuanya benar-benar kosong
    if (title.isEmpty && content.isEmpty && validChecklist.isEmpty) {
      return;
    }

    _isSaved = true;

    final note = NoteModel(
      id: _id,
      title: title,
      content: content,
      isChecklist: _isChecklist,
      checklist: _isChecklist ? validChecklist : [],
      colorIndex: _colorIndex,
      category: _category,
      isPinned: _isPinned,
      isArchived: _isArchived,
      isDeleted: false,
      isLocked: _isLocked,
      priority: _priority,
      reminderDateTime: _reminderDateTime,
      isDailyReminder: _isDailyReminder,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onSave(note);
  }

  void _saveAndPop() {
    _saveNote();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _toggleLock() async {
    if (!_isLocked) {
      // Ingin mengunci: cek apakah sudah punya master PIN
      if (!widget.hasMasterPin) {
        final newPin = await PinDialog.showSetPinDialog(context);
        if (newPin != null && newPin.isNotEmpty) {
          await widget.onSetMasterPin(newPin);
          setState(() {
            _isLocked = true;
            _hasChanges = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN berhasil dibuat. Catatan dikunci! 🔒')),
            );
          }
        }
      } else {
        setState(() {
          _isLocked = true;
          _hasChanges = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Catatan telah dikunci! 🔒')),
          );
        }
      }
    } else {
      // Ingin membuka kunci
      final unlocked = await PinDialog.showUnlockDialog(
        context,
        onVerify: widget.onVerifyPin,
      );
      if (unlocked) {
        setState(() {
          _isLocked = false;
          _hasChanges = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kunci catatan dilepas. 🔓')),
          );
        }
      }
    }
  }

  void _shareNote() {
    final title = _titleController.text.trim();
    String body = '';

    if (_isChecklist) {
      body = _checklist.map((e) {
        final timeStr = e.hasTime ? ' [${e.time}]' : '';
        return '${e.isDone ? "[x]" : "[ ]"} ${e.text}$timeStr';
      }).join('\n');
    } else {
      body = _contentController.text.trim();
    }

    final shareText = '${title.isNotEmpty ? "$title\n\n" : ""}$body\n\n— Dibuat dengan NoteCraft';
    Clipboard.setData(ClipboardData(text: shareText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan disalin ke papan klip! 📋 Siap ditempel ke WhatsApp, dsb.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addChecklistItem({String? time}) {
    final newItem = ChecklistItem(id: const Uuid().v4(), text: '', isDone: false, time: time);
    final ctrl = TextEditingController();
    ctrl.addListener(() {
      newItem.text = ctrl.text;
      _markChanged();
    });

    setState(() {
      _checklist.add(newItem);
      _checklistControllers.add(ctrl);
      _hasChanges = true;
    });
  }

  void _setScheduleForItem(int index, String schedule) {
    setState(() {
      _checklist[index].time = schedule;
      _hasChanges = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Jadwal diatur: $schedule 📅'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearTimeForItem(int index) {
    setState(() {
      _checklist[index].time = null;
      _hasChanges = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jadwal aktivitas dihapus.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showItemScheduleSheet(int index) async {
    final item = _checklist[index];
    final theme = Theme.of(context);
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atur Jadwal & Waktu Aktivitas 📅',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (item.text.trim().isNotEmpty)
                            Text(
                              item.text,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withAlpha(160),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (item.hasTime) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(90),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_available_rounded, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Jadwal Aktif: ${item.time}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                          tooltip: 'Hapus Jadwal',
                          onPressed: () {
                            _clearTimeForItem(index);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 1. Pilihan Cepat (Hari / Minggu / Bulan)
                Text(
                  'PILIHAN CEPAT (HARI / MINGGU / BULAN)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.today_rounded, size: 16),
                      label: Text('Hari Ini (${AppDateFormatter.formatDate(now)})'),
                      onPressed: () {
                        _setScheduleForItem(index, 'Hari Ini, ${AppDateFormatter.formatDate(now)}');
                        Navigator.pop(ctx);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wb_sunny_rounded, size: 16),
                      label: Text('Besok (${AppDateFormatter.formatDate(now.add(const Duration(days: 1)))})'),
                      onPressed: () {
                        final tomorrow = now.add(const Duration(days: 1));
                        _setScheduleForItem(index, 'Besok, ${AppDateFormatter.formatDate(tomorrow)}');
                        Navigator.pop(ctx);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.date_range_rounded, size: 16),
                      label: const Text('Minggu Depan'),
                      onPressed: () {
                        final nextWeek = now.add(const Duration(days: 7));
                        _setScheduleForItem(index, 'Minggu Depan (${AppDateFormatter.formatDayAndDate(nextWeek)})');
                        Navigator.pop(ctx);
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.calendar_view_month_rounded, size: 16),
                      label: const Text('Bulan Depan'),
                      onPressed: () {
                        final nextMonth = DateTime(now.year, now.month + 1, now.day);
                        _setScheduleForItem(index, 'Bulan Depan (${AppDateFormatter.formatDate(nextMonth)})');
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),

                // 2. Pilih Tanggal Kalender
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
                  ),
                  title: const Text('Pilih Tanggal & Hari dari Kalender...'),
                  subtitle: const Text('Tentukan tanggal, bulan, tahun & jam secara spesifik'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickDateAndOptionalTime(index);
                  },
                ),
                const SizedBox(height: 8),

                // 3. Periode / Ketik Bebas
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_note_rounded, color: theme.colorScheme.secondary),
                  ),
                  title: const Text('Ketik Jadwal Bebas / Periode Kustom...'),
                  subtitle: const Text('Contoh: "Minggu ke-2", "Akhir Bulan", "Setiap Senin"'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCustomScheduleDialog(index);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDateAndOptionalTime(int index) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: DateTime(now.year + 5),
      helpText: 'Pilih Tanggal & Hari Aktivitas',
    );
    if (pickedDate == null || !mounted) return;

    final addTime = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tambahkan Jam? ⏰'),
        content: Text(
          'Tanggal dipilih: ${AppDateFormatter.formatDayAndDate(pickedDate)}.\n'
          'Apakah Anda ingin menambahkan jam spesifik untuk aktivitas ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hanya Tanggal & Hari'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tambah Jam'),
          ),
        ],
      ),
    );

    if (addTime == true && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        helpText: 'Pilih Jam Aktivitas',
      );
      if (pickedTime != null) {
        final formatted = AppDateFormatter.formatDayDateAndTime(
          pickedDate,
          pickedTime.hour,
          pickedTime.minute,
        );
        _setScheduleForItem(index, formatted);
        return;
      }
    }

    final formattedDate = AppDateFormatter.formatDayAndDate(pickedDate);
    _setScheduleForItem(index, formattedDate);
  }

  void _showCustomScheduleDialog(int index) {
    final item = _checklist[index];
    final ctrl = TextEditingController(text: item.time ?? '');
    final presets = [
      'Setiap Hari',
      'Setiap Minggu',
      'Setiap Bulan',
      'Minggu ke-1',
      'Minggu ke-2',
      'Akhir Pekan',
      'Akhir Bulan',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Jadwal & Periode Kustom 🗓️'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Minggu ke-2, Setiap Senin',
                  prefixIcon: Icon(Icons.schedule_rounded),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Saran Cepat:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presets.map((p) {
                  return ActionChip(
                    label: Text(p, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      ctrl.text = p;
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                _setScheduleForItem(index, text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _addChecklistItemWithSchedule() async {
    _addChecklistItem();
    final newIndex = _checklist.length - 1;
    await _showItemScheduleSheet(newIndex);
  }

  Future<void> _insertTimestampToContent() async {
    final now = DateTime.now();
    final options = [
      'Tanggal & Hari (${AppDateFormatter.formatDayAndDate(now)})',
      'Tanggal & Jam (${AppDateFormatter.formatWithTime(now)})',
      'Jam Saja (${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})',
      'Pilih dari Kalender...',
    ];

    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sisipkan Waktu ke Teks 📅'),
        children: options.asMap().entries.map((e) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, e.key),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(e.value),
            ),
          );
        }).toList(),
      ),
    );

    if (choice == null || !mounted) return;

    String stamp = '';
    if (choice == 0) {
      stamp = '[${AppDateFormatter.formatDayAndDate(now)}] ';
    } else if (choice == 1) {
      stamp = '[${AppDateFormatter.formatWithTime(now)}] ';
    } else if (choice == 2) {
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      stamp = '[$hh:$mm] ';
    } else if (choice == 3) {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: DateTime(now.year + 5),
      );
      if (pickedDate != null) {
        stamp = '[${AppDateFormatter.formatDayAndDate(pickedDate)}] ';
      }
    }

    if (stamp.isNotEmpty) {
      final text = _contentController.text;
      final selection = _contentController.selection;
      if (selection.start >= 0 && selection.end >= 0) {
        final newText = text.replaceRange(selection.start, selection.end, stamp);
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start + stamp.length),
        );
      } else {
        _contentController.text = text.isEmpty ? stamp : '$text\n$stamp';
        _contentController.selection = TextSelection.collapsed(offset: _contentController.text.length);
      }
      _markChanged();
    }
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklist.removeAt(index);
      _checklistControllers[index].dispose();
      _checklistControllers.removeAt(index);
      _hasChanges = true;
    });
  }

  void _toggleChecklistMode() {
    setState(() {
      _isChecklist = !_isChecklist;
      _hasChanges = true;
      if (_isChecklist && _checklist.isEmpty) {
        // Konversi baris teks menjadi checklist
        final lines = _contentController.text.split('\n');
        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            final regexBracket = RegExp(r'^\[(\d{1,2}:\d{2})\]\s*(.*)');
            final regexDash = RegExp(r'^(\d{1,2}:\d{2})\s*[-–:]\s*(.*)');
            final matchBracket = regexBracket.firstMatch(trimmed);
            final matchDash = regexDash.firstMatch(trimmed);

            if (matchBracket != null) {
              _checklist.add(ChecklistItem(
                id: const Uuid().v4(),
                time: matchBracket.group(1),
                text: matchBracket.group(2) ?? '',
              ));
            } else if (matchDash != null) {
              _checklist.add(ChecklistItem(
                id: const Uuid().v4(),
                time: matchDash.group(1),
                text: matchDash.group(2) ?? '',
              ));
            } else {
              _checklist.add(ChecklistItem(id: const Uuid().v4(), text: trimmed));
            }
          }
        }
        if (_checklist.isEmpty) {
          _checklist.add(ChecklistItem(id: const Uuid().v4(), text: ''));
        }
        _initChecklistControllers();
      } else if (!_isChecklist) {
        // Konversi checklist kembali ke teks
        final text = _checklist
            .map((e) => e.hasTime ? '[${e.time}] ${e.text}' : e.text)
            .join('\n');
        _contentController.text = text;
      }
    });
  }

  void _showStatsDialog() {
    final titleText = _titleController.text.trim();
    final contentText = _isChecklist
        ? _checklist.map((e) => e.text).join(' ')
        : _contentController.text.trim();
    final combined = '$titleText $contentText'.trim();
    final words = combined.isEmpty ? 0 : RegExp(r'\S+').allMatches(combined).length;
    final chars = _titleController.text.length +
        (_isChecklist
            ? _checklist.fold(0, (sum, item) => sum + item.text.length)
            : _contentController.text.length);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Statistik Catatan 📊'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Jumlah Kata: $words'),
            const SizedBox(height: 6),
            Text('• Jumlah Karakter: $chars'),
            const SizedBox(height: 6),
            Text('• Dibuat: ${AppDateFormatter.formatDetail(_createdAt)}'),
            const SizedBox(height: 6),
            Text('• Diperbarui: ${AppDateFormatter.formatDetail(_updatedAt)}'),
            if (_isChecklist) ...[
              const SizedBox(height: 6),
              Text(
                '• Tugas Selesai: ${_checklist.where((e) => e.isDone).length} dari ${_checklist.length}',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showReminderSheet() {
    final theme = Theme.of(context);
    final now = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  Icon(Icons.alarm_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Atur Pengingat Catatan ⏰',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_reminderDateTime != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDailyReminder ? Icons.repeat_rounded : Icons.check_circle_outline_rounded,
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isDailyReminder
                              ? 'Pengingat Harian Aktif:\nSetiap Hari pukul ${AppDateFormatter.formatTimeOnly(_reminderDateTime!)} 🔁'
                              : 'Pengingat Aktif:\n${AppDateFormatter.formatDetail(_reminderDateTime!)} ⏰',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        tooltip: 'Hapus Pengingat',
                        onPressed: () {
                          setState(() {
                            _reminderDateTime = null;
                            _isDailyReminder = false;
                            _hasChanges = true;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pengingat dihapus.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 1. PENGINGAT HARIAN (SETIAP HARI)
              Text(
                'PENGINGAT HARIAN (SETIAP HARI) 🔁',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.wb_sunny_rounded, color: Colors.amber),
                ),
                title: const Text('Setiap Pagi (08:00)'),
                subtitle: const Text('Berulang setiap hari pukul 08:00 pagi'),
                onTap: () {
                  final dt = DateTime(now.year, now.month, now.day, 8, 0);
                  _setReminder(dt, isDaily: true);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.nightlight_round, color: Colors.indigo),
                ),
                title: const Text('Setiap Malam (19:00)'),
                subtitle: const Text('Berulang setiap hari pukul 19:00 malam'),
                onTap: () {
                  final dt = DateTime(now.year, now.month, now.day, 19, 0);
                  _setReminder(dt, isDaily: true);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.schedule_rounded, color: theme.colorScheme.primary),
                ),
                title: const Text('Atur Jam Harian Kustom...'),
                subtitle: const Text('Pilih jam berapa pun untuk diingatkan setiap hari'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickDailyTime();
                },
              ),
              const Divider(height: 24),

              // 2. PENGINGAT SATU KALI (TANGGAL TERTENTU)
              Text(
                'PENGINGAT 1 KALI (TANGGAL TERTENTU) 🗓️',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.today_rounded, color: theme.colorScheme.secondary),
                ),
                title: const Text('Besok Pagi (09:00)'),
                subtitle: const Text('Satu kali pada pagi hari esok'),
                onTap: () {
                  final tomorrow = now.add(const Duration(days: 1));
                  final target = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
                  _setReminder(target, isDaily: false);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.tertiary),
                ),
                title: const Text('Pilih Tanggal & Waktu dari Kalender...'),
                subtitle: const Text('Tentukan tanggal dan jam spesifik'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickCustomDateTime();
                },
              ),
              const Divider(height: 24),

              // 3. TES NOTIFIKASI LANGSUNG
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.green),
                ),
                title: const Text('Kirim Tes Notifikasi Sekarang 🔔'),
                subtitle: const Text('Uji coba alarm & suara notifikasi langsung di HP Anda'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await NotificationService().showInstantTestNotification();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifikasi uji coba dikirim! Periksa bilah status HP Anda. 🔔✨'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setReminder(DateTime dt, {bool isDaily = false}) {
    setState(() {
      _reminderDateTime = dt;
      _isDailyReminder = isDaily;
      _hasChanges = true;
    });
    final timeStr = AppDateFormatter.formatTimeOnly(dt);
    final msg = isDaily
        ? 'Pengingat harian aktif: Setiap hari pukul $timeStr 🔁'
        : 'Pengingat diatur untuk: ${AppDateFormatter.formatDetail(dt)} ⏰';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDailyTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderDateTime != null
          ? TimeOfDay(hour: _reminderDateTime!.hour, minute: _reminderDateTime!.minute)
          : TimeOfDay.now(),
      helpText: 'Pilih Jam untuk Pengingat Setiap Hari ⏰',
    );
    if (pickedTime == null || !mounted) return;

    final now = DateTime.now();
    final result = DateTime(
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    _setReminder(result, isDaily: true);
  }

  Future<void> _pickCustomDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderDateTime != null
          ? TimeOfDay(hour: _reminderDateTime!.hour, minute: _reminderDateTime!.minute)
          : TimeOfDay.now(),
    );
    if (pickedTime == null || !mounted) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    _setReminder(result, isDaily: false);
  }

  Widget _buildPrioritySelector(ThemeData theme) {
    final priorities = [
      {'val': 0, 'label': 'Biasa', 'emoji': '⚪'},
      {'val': 1, 'label': 'Rendah', 'emoji': '🟢'},
      {'val': 2, 'label': 'Sedang', 'emoji': '🟡'},
      {'val': 3, 'label': 'Tinggi', 'emoji': '🔴'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: priorities.map((p) {
          final val = p['val'] as int;
          final isSelected = _priority == val;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              label: Text(
                '${p['emoji']} ${p['label']}',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _priority = val;
                  _hasChanges = true;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = AppTheme.getNoteBackgroundColor(_colorIndex, isDark);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _saveNote();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _saveAndPop,
            tooltip: 'Simpan & Kembali',
          ),
          actions: [
            // Tombol Pengingat (Alarm)
            IconButton(
              icon: Icon(
                _reminderDateTime != null
                    ? Icons.alarm_on_rounded
                    : Icons.alarm_add_rounded,
                color: _reminderDateTime != null ? theme.colorScheme.primary : null,
              ),
              onPressed: _showReminderSheet,
              tooltip: _reminderDateTime != null
                  ? 'Pengingat: ${AppDateFormatter.formatDetail(_reminderDateTime!)}'
                  : 'Atur Pengingat',
            ),
            // Tombol Pin
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _isPinned ? theme.colorScheme.primary : null,
              ),
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                  _hasChanges = true;
                });
              },
              tooltip: _isPinned ? 'Lepas Sematan' : 'Sematkan ke Atas',
            ),
            // Tombol Kunci Catatan
            IconButton(
              icon: Icon(
                _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: _isLocked ? Colors.amber.shade700 : null,
              ),
              onPressed: _toggleLock,
              tooltip: _isLocked ? 'Catatan Terkunci' : 'Kunci Catatan',
            ),
            // Tombol Share
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareNote,
              tooltip: 'Bagikan Catatan',
            ),
            // Menu Lainnya
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'stats') {
                  _showStatsDialog();
                } else if (val == 'archive') {
                  setState(() {
                    _isArchived = !_isArchived;
                    _hasChanges = true;
                  });
                } else if (val == 'delete') {
                  if (widget.initialNote != null && widget.onDelete != null) {
                    widget.onDelete!(widget.initialNote!.id);
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pop();
                  }
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'stats',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 10),
                      Text('Info & Statistik'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(_isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text(_isArchived ? 'Batal Arsipkan' : 'Arsipkan'),
                    ],
                  ),
                ),
                if (widget.initialNote != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Area Tulis Catatan
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    // Field Judul
                    TextField(
                      controller: _titleController,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Judul Catatan...',
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 12),

                    // Info Kategori & Waktu Edit
                    Row(
                      children: [
                        // Pilihan Kategori Dropdown / Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: widget.availableCategories.contains(_category)
                                  ? _category
                                  : 'Umum',
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down, size: 18),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              items: widget.availableCategories
                                  .where((c) => c != 'Semua' && c != '⏰ Pengingat' && c != '🔴 Prioritas')
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ))
                                  .toList(),
                              onChanged: (newCat) {
                                if (newCat != null) {
                                  setState(() {
                                    _category = newCat;
                                    _hasChanges = true;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppDateFormatter.formatWithTime(_updatedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.textTheme.labelSmall?.color?.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Selector Prioritas
                    Row(
                      children: [
                        Text(
                          'Prioritas: ',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.labelMedium?.color?.withAlpha(160),
                          ),
                        ),
                        Expanded(child: _buildPrioritySelector(theme)),
                      ],
                    ),

                    // Banner Pengingat Aktif (jika ada)
                    if (_reminderDateTime != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _showReminderSheet,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withAlpha(90),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isDailyReminder ? Icons.repeat_rounded : Icons.alarm_on_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isDailyReminder
                                      ? 'Pengingat Harian: Setiap Hari, ${AppDateFormatter.formatTimeOnly(_reminderDateTime!)} 🔁'
                                      : 'Pengingat: ${AppDateFormatter.formatDetail(_reminderDateTime!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              Icon(Icons.edit_calendar_rounded, size: 16, color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const Divider(height: 28),

                    // Konten: Text Editor atau Checklist
                    if (_isChecklist)
                      _buildChecklistEditor(theme)
                    else
                      TextField(
                        controller: _contentController,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Mulai menulis catatan di sini...',
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                      ),
                  ],
                ),
              ),

              // Bottom Action Bar
              _buildBottomBar(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistEditor(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _checklist.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _checklist.removeAt(oldIndex);
              _checklist.insert(newIndex, item);

              final ctrl = _checklistControllers.removeAt(oldIndex);
              _checklistControllers.insert(newIndex, ctrl);
              _hasChanges = true;
            });
          },
          itemBuilder: (context, index) {
            final item = _checklist[index];
            final ctrl = _checklistControllers[index];

            return Padding(
              key: ValueKey(item.id),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: item.isDone,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        item.isDone = val ?? false;
                        _hasChanges = true;
                      });
                    },
                  ),
                  // Teks Item + Waktu Chip
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: ctrl,
                          style: TextStyle(
                            fontSize: 16,
                            decoration: item.isDone ? TextDecoration.lineThrough : null,
                            color: item.isDone
                                ? theme.textTheme.bodyLarge?.color?.withAlpha(120)
                                : theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Item tugas...',
                            filled: false,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                        if (item.hasTime)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: InkWell(
                              onTap: () => _showItemScheduleSheet(index),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withAlpha(isDark ? 90 : 120),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withAlpha(90),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.event_note_rounded,
                                      size: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.time!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _clearTimeForItem(index),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 13,
                                        color: theme.colorScheme.primary.withAlpha(180),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Tombol Atur Waktu Item
                  IconButton(
                    icon: Icon(
                      item.hasTime ? Icons.event_available_rounded : Icons.calendar_month_outlined,
                      size: 20,
                      color: item.hasTime
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withAlpha(150),
                    ),
                    tooltip: item.hasTime ? 'Ubah Jadwal (${item.time})' : 'Atur Jadwal / Waktu',
                    onPressed: () => _showItemScheduleSheet(index),
                  ),
                  // Hapus Item
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => _removeChecklistItem(index),
                    color: theme.colorScheme.outline,
                  ),
                  // Drag Handle
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 20,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Tombol Tambah Item Checklist & Tambah dengan Waktu
        Row(
          children: [
            TextButton.icon(
              onPressed: _addChecklistItem,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Item'),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: _addChecklistItemWithSchedule,
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('+ Item & Jadwal'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withAlpha(220),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withAlpha(60),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Ganti Warna
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Ubah Warna',
            onPressed: () {
              ColorPickerSheet.show(
                context,
                currentColorIndex: _colorIndex,
                onSelected: (idx) {
                  setState(() {
                    _colorIndex = idx;
                    _hasChanges = true;
                  });
                },
              );
            },
          ),
          // Toggle Checklist vs Plain Text
          IconButton(
            icon: Icon(
              _isChecklist ? Icons.notes_rounded : Icons.checklist_rounded,
              color: _isChecklist ? theme.colorScheme.primary : null,
            ),
            tooltip: _isChecklist ? 'Ubah ke Catatan Teks' : 'Ubah ke Mode To-Do',
            onPressed: _toggleChecklistMode,
          ),
          // Pengingat Tanggal / Waktu
          IconButton(
            icon: Icon(
              _reminderDateTime != null
                  ? Icons.alarm_on_rounded
                  : Icons.alarm_add_outlined,
              color: _reminderDateTime != null ? theme.colorScheme.primary : null,
            ),
            tooltip: 'Atur Pengingat',
            onPressed: _showReminderSheet,
          ),
          // Tambah / Sisipkan Waktu & Jadwal
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: _isChecklist ? 'Tambah Item & Jadwal' : 'Sisipkan Waktu ke Teks',
            onPressed: () {
              if (_isChecklist) {
                _addChecklistItemWithSchedule();
              } else {
                _insertTimestampToContent();
              }
            },
          ),
          const Spacer(),
          // Word / Item Counter
          Text(
            _isChecklist
                ? '${_checklist.length} item'
                : '${_contentController.text.trim().isEmpty ? 0 : RegExp(r'\S+').allMatches(_contentController.text).length} kata',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.labelSmall?.color?.withAlpha(160),
            ),
          ),
          const SizedBox(width: 8),
          // Selesai Button
          FilledButton.tonal(
            onPressed: _saveAndPop,
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}
