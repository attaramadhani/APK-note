import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../models/note_sort_option.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class NotesController extends ChangeNotifier {
  final StorageService _storage;

  List<NoteModel> _notes = [];
  List<String> _categories = [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  NoteSortOption _sortOption = NoteSortOption.dateModifiedDesc;
  bool _isGridView = true;
  ThemeMode _themeMode = ThemeMode.system;
  String? _masterPin;
  bool _dailyReminderEnabled = false;
  String _dailyReminderTime = '09:00';

  NotesController(this._storage) {
    _loadInitialData();
  }

  void _loadInitialData() {
    _notes = _storage.loadNotes();
    _categories = _storage.loadCategories();
    _sortOption = _storage.loadSortOption();
    _isGridView = _storage.loadIsGridView();
    _masterPin = _storage.loadMasterPin();
    _dailyReminderEnabled = _storage.loadDailyReminderEnabled();
    _dailyReminderTime = _storage.loadDailyReminderTime();

    final savedTheme = _storage.loadThemeMode();
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Jadwalkan notifikasi untuk catatan yang memiliki pengingat
    for (var note in _notes) {
      if (note.hasReminder && !note.isDeleted && !note.isArchived) {
        NotificationService().scheduleReminder(note);
      }
    }

    // Jadwalkan pengingat harian aplikasi jika aktif
    if (_dailyReminderEnabled) {
      final parts = _dailyReminderTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      NotificationService().scheduleGlobalDailyReminder(hour, minute);
    }

    notifyListeners();
  }

  // Getters
  List<NoteModel> get allNotes => _notes;
  List<String> get categories => _categories;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  NoteSortOption get sortOption => _sortOption;
  bool get isGridView => _isGridView;
  ThemeMode get themeMode => _themeMode;
  bool get hasMasterPin => _masterPin != null && _masterPin!.isNotEmpty;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  String get dailyReminderTime => _dailyReminderTime;

  // Filter Catatan Aktif
  List<NoteModel> _filterNotes(List<NoteModel> list) {
    return list.where((note) {
      // Filter Kategori Khusus
      if (_selectedCategory == '⏰ Pengingat') {
        if (!note.hasReminder) return false;
      } else if (_selectedCategory == '🔴 Prioritas') {
        if (note.priority == 0) return false;
      } else if (_selectedCategory != 'Semua' && note.category != _selectedCategory) {
        return false;
      }

      // Filter Pencarian
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = note.title.toLowerCase().contains(q);
        final matchContent = note.content.toLowerCase().contains(q);
        final matchChecklist = note.checklist.any((item) => item.text.toLowerCase().contains(q));
        if (!matchTitle && !matchContent && !matchChecklist) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<NoteModel> get pinnedNotes {
    final active = _notes.where((n) => !n.isDeleted && !n.isArchived && n.isPinned).toList();
    active.sort((a, b) => _sortOption.compare(a, b));
    return _filterNotes(active);
  }

  List<NoteModel> get unpinnedNotes {
    final active = _notes.where((n) => !n.isDeleted && !n.isArchived && !n.isPinned).toList();
    active.sort((a, b) => _sortOption.compare(a, b));
    return _filterNotes(active);
  }

  List<NoteModel> get archivedNotes {
    final archived = _notes.where((n) => !n.isDeleted && n.isArchived).toList();
    archived.sort((a, b) => _sortOption.compare(a, b));
    if (_searchQuery.trim().isEmpty) return archived;
    return archived.where((n) {
      final q = _searchQuery.toLowerCase();
      return n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q);
    }).toList();
  }

  List<NoteModel> get trashNotes {
    final trash = _notes.where((n) => n.isDeleted).toList();
    trash.sort((a, b) => (b.deletedAt ?? b.updatedAt).compareTo(a.deletedAt ?? a.updatedAt));
    if (_searchQuery.trim().isEmpty) return trash;
    return trash.where((n) {
      final q = _searchQuery.toLowerCase();
      return n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q);
    }).toList();
  }

  int get totalActiveCount => _notes.where((n) => !n.isDeleted && !n.isArchived).length;
  int get totalTrashCount => _notes.where((n) => n.isDeleted).length;
  int get totalArchivedCount => _notes.where((n) => !n.isDeleted && n.isArchived).length;

  // Search & Filter
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Pengurutan Catatan
  void setSortOption(NoteSortOption option) {
    _sortOption = option;
    _storage.saveSortOption(option);
    notifyListeners();
  }

  // Tampilan Grid / List
  void toggleViewMode() {
    _isGridView = !_isGridView;
    _storage.saveIsGridView(_isGridView);
    notifyListeners();
  }

  // Pengaturan Tema
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    final modeStr = mode == ThemeMode.light ? 'light' : (mode == ThemeMode.dark ? 'dark' : 'system');
    _storage.saveThemeMode(modeStr);
    notifyListeners();
  }

  // Security PIN
  bool verifyPin(String inputPin) {
    if (_masterPin == null || _masterPin!.isEmpty) return true;
    return _masterPin == inputPin;
  }

  Future<void> setMasterPin(String? newPin) async {
    _masterPin = newPin;
    await _storage.saveMasterPin(newPin);
    notifyListeners();
  }

  // CRUD Catatan
  Future<void> saveNote(NoteModel note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note.copyWith(updatedAt: DateTime.now());
    } else {
      _notes.insert(0, note);
    }
    await _persistNotes();

    // Jadwalkan atau batalkan pengingat
    if (note.hasReminder && !note.isDeleted && !note.isArchived) {
      await NotificationService().scheduleReminder(note);
    } else {
      await NotificationService().cancelReminder(note.id);
    }
  }

  Future<void> togglePin(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      final current = _notes[index];
      _notes[index] = current.copyWith(
        isPinned: !current.isPinned,
        updatedAt: DateTime.now(),
      );
      await _persistNotes();
    }
  }

  Future<void> toggleArchive(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      final current = _notes[index];
      _notes[index] = current.copyWith(
        isArchived: !current.isArchived,
        isPinned: false, // unpin when archiving
        updatedAt: DateTime.now(),
      );
      await _persistNotes();

      if (_notes[index].isArchived) {
        await NotificationService().cancelReminder(noteId);
      } else if (_notes[index].hasReminder) {
        await NotificationService().scheduleReminder(_notes[index]);
      }
    }
  }

  Future<void> moveToTrash(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      final current = _notes[index];
      _notes[index] = current.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      await _persistNotes();
      await NotificationService().cancelReminder(noteId);
    }
  }

  Future<void> restoreFromTrash(String noteId) async {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index >= 0) {
      final current = _notes[index];
      _notes[index] = current.copyWith(
        isDeleted: false,
        deletedAt: null,
        updatedAt: DateTime.now(),
      );
      await _persistNotes();

      if (_notes[index].hasReminder) {
        await NotificationService().scheduleReminder(_notes[index]);
      }
    }
  }

  Future<void> deletePermanently(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    await _persistNotes();
    await NotificationService().cancelReminder(noteId);
  }

  Future<void> emptyTrash() async {
    _notes.removeWhere((n) => n.isDeleted);
    await _persistNotes();
  }

  Future<void> toggleChecklistItem(String noteId, String itemId) async {
    final noteIndex = _notes.indexWhere((n) => n.id == noteId);
    if (noteIndex >= 0) {
      final current = _notes[noteIndex];
      final updatedList = current.checklist.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isDone: !item.isDone);
        }
        return item;
      }).toList();

      _notes[noteIndex] = current.copyWith(
        checklist: updatedList,
        updatedAt: DateTime.now(),
      );
      await _persistNotes();
    }
  }

  // Manajemen Kategori
  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && !_categories.contains(trimmed)) {
      _categories.add(trimmed);
      await _storage.saveCategories(_categories);
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String name) async {
    if (name == 'Semua' || name == 'Umum') return; // Lindungi kategori default
    _categories.remove(name);
    // Kembalikan catatan berkategori ini ke 'Umum'
    for (int i = 0; i < _notes.length; i++) {
      if (_notes[i].category == name) {
        _notes[i] = _notes[i].copyWith(category: 'Umum');
      }
    }
    if (_selectedCategory == name) {
      _selectedCategory = 'Semua';
    }
    await _storage.saveCategories(_categories);
    await _persistNotes();
  }

  // Backup & Import
  String exportBackup() => _storage.exportBackupJson();

  Future<bool> importBackup(String jsonStr) async {
    final success = await _storage.importBackupJson(jsonStr);
    if (success) {
      _loadInitialData();
    }
    return success;
  }

  Future<void> _persistNotes() async {
    await _storage.saveNotes(_notes);
    notifyListeners();
  }

  // Pengingat Harian Aplikasi
  Future<void> setDailyReminderEnabled(bool enabled) async {
    _dailyReminderEnabled = enabled;
    await _storage.saveDailyReminderEnabled(enabled);

    if (enabled) {
      final parts = _dailyReminderTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      await NotificationService().scheduleGlobalDailyReminder(hour, minute);
    } else {
      await NotificationService().cancelGlobalDailyReminder();
    }
    notifyListeners();
  }

  Future<void> setDailyReminderTime(String time) async {
    _dailyReminderTime = time;
    await _storage.saveDailyReminderTime(time);

    if (_dailyReminderEnabled) {
      final parts = time.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      await NotificationService().scheduleGlobalDailyReminder(hour, minute);
    }
    notifyListeners();
  }
}
