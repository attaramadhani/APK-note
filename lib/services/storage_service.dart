import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import '../models/checklist_item.dart';
import '../models/note_sort_option.dart';

class StorageService {
  static const String _notesKey = 'notecraft_notes';
  static const String _categoriesKey = 'notecraft_categories';
  static const String _masterPinKey = 'notecraft_master_pin';
  static const String _isGridKey = 'notecraft_is_grid';
  static const String _themeModeKey = 'notecraft_theme_mode';
  static const String _firstRunKey = 'notecraft_first_run_completed';
  static const String _sortOptionKey = 'notecraft_sort_option';
  static const String _dailyReminderEnabledKey = 'notecraft_daily_reminder_enabled';
  static const String _dailyReminderTimeKey = 'notecraft_daily_reminder_time';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service._seedInitialDataIfNeeded();
    return service;
  }

  // Cek dan isi data awal jika aplikasi baru pertama dibuka
  Future<void> _seedInitialDataIfNeeded() async {
    final hasRun = _prefs.getBool(_firstRunKey) ?? false;
    if (!hasRun) {
      final now = DateTime.now();
      final sampleNotes = [
        NoteModel(
          id: 'welcome_note',
          title: 'Selamat Datang di NoteCraft! ✨',
          content: 'NoteCraft adalah aplikasi catatan modern yang dirancang untuk kenyamanan mencatat di smartphone Anda.\n\n'
              'Fitur yang bisa Anda coba:\n'
              '• 🎨 Pilih warna kartu pastel kesukaan Anda\n'
              '• 📌 Sematkan catatan penting agar selalu di atas\n'
              '• ⏰ Atur jadwal pengingat tanggal & jam notifikasi\n'
              '• 🔴 Berikan tingkat prioritas (Tinggi, Sedang, Rendah)\n'
              '• ☑️ Buat daftar tugas to-do list interaktif\n'
              '• 🔒 Kunci catatan pribadi Anda dengan PIN\n'
              '• 🔍 Cari catatan secara instan\n'
              '• 🗑️ Kembalikan catatan dari Tempat Sampah\n\n'
              'Tekan tombol + di bawah untuk membuat catatan baru!',
          colorIndex: 3, // Madu
          category: 'Umum',
          isPinned: true,
          priority: 0,
          createdAt: now.subtract(const Duration(hours: 3)),
          updatedAt: now.subtract(const Duration(hours: 3)),
        ),
        NoteModel(
          id: 'todo_demo',
          title: 'Daftar Belanja Mingguan 🛒',
          content: '',
          isChecklist: true,
          checklist: [
            ChecklistItem(id: 'c1', text: 'Kopi Arabika & Teh Hijau', isDone: true),
            ChecklistItem(id: 'c2', text: 'Susu UHT & Oatmeal', isDone: true),
            ChecklistItem(id: 'c3', text: 'Buah Pisang & Apel Fuji', isDone: false),
            ChecklistItem(id: 'c4', text: 'Roti Gandum', isDone: false),
            ChecklistItem(id: 'c5', text: 'Dada Ayam Fillet & Telur', isDone: false),
          ],
          colorIndex: 2, // Mint
          category: 'Belanja',
          isPinned: true,
          priority: 1, // Rendah
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now.subtract(const Duration(hours: 2)),
        ),
        NoteModel(
          id: 'idea_demo',
          title: 'Ide Desain & Konsep Aplikasi 💡',
          content: 'Fokus pada kesederhanaan dan keindahan:\n'
              '1. Micro-interactions pada tombol centang to-do\n'
              '2. Transisi mulus saat membuka detail catatan\n'
              '3. Tampilan responsif di semua ukuran layar smartphone',
          colorIndex: 4, // Lavender
          category: 'Ide & Rencana',
          isPinned: false,
          priority: 2, // Sedang
          createdAt: now.subtract(const Duration(hours: 1)),
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
        NoteModel(
          id: 'work_demo',
          title: 'Jadwal Rapat & Target Hari Ini 💼',
          content: '• 09:00 - Daily Standup bersama Tim\n'
              '• 11:30 - Review Mockup Desain\n'
              '• 14:00 - Uji Coba Aplikasi Versi 1.0\n'
              '• 16:30 - Evaluasi & Catatan Akhir Hari',
          colorIndex: 1, // Madu / Oranye
          category: 'Pekerjaan',
          isPinned: false,
          priority: 3, // Tinggi
          reminderDateTime: now.add(const Duration(hours: 3)),
          createdAt: now.subtract(const Duration(minutes: 30)),
          updatedAt: now.subtract(const Duration(minutes: 30)),
        ),
      ];

      await saveNotes(sampleNotes);
      await _prefs.setBool(_firstRunKey, true);
    }
  }

  // Simpan & Ambil Catatan
  List<NoteModel> loadNotes() {
    final jsonString = _prefs.getString(_notesKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => NoteModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveNotes(List<NoteModel> notes) async {
    final encoded = jsonEncode(notes.map((e) => e.toJson()).toList());
    return await _prefs.setString(_notesKey, encoded);
  }

  // Preferensi View Mode (Grid / List)
  bool loadIsGridView() {
    return _prefs.getBool(_isGridKey) ?? true;
  }

  Future<bool> saveIsGridView(bool isGrid) async {
    return await _prefs.setBool(_isGridKey, isGrid);
  }

  // Preferensi Urutan Catatan
  NoteSortOption loadSortOption() {
    final index = _prefs.getInt(_sortOptionKey);
    if (index != null && index >= 0 && index < NoteSortOption.values.length) {
      return NoteSortOption.values[index];
    }
    return NoteSortOption.dateModifiedDesc;
  }

  Future<bool> saveSortOption(NoteSortOption option) async {
    return await _prefs.setInt(_sortOptionKey, option.index);
  }

  // Preferensi Tema (system, light, dark)
  String loadThemeMode() {
    return _prefs.getString(_themeModeKey) ?? 'system';
  }

  Future<bool> saveThemeMode(String mode) async {
    return await _prefs.setString(_themeModeKey, mode);
  }

  // Master PIN Keamanan
  String? loadMasterPin() {
    return _prefs.getString(_masterPinKey);
  }

  Future<bool> saveMasterPin(String? pin) async {
    if (pin == null || pin.isEmpty) {
      return await _prefs.remove(_masterPinKey);
    }
    return await _prefs.setString(_masterPinKey, pin);
  }

  // Kategori Dinamis
  List<String> loadCategories() {
    final list = _prefs.getStringList(_categoriesKey);
    if (list == null || list.isEmpty) {
      return ['Semua', 'Umum', 'Pekerjaan', 'Pribadi', 'Ide & Rencana', 'Belanja', 'Belajar / Kuliah'];
    }
    return list;
  }

  Future<bool> saveCategories(List<String> categories) async {
    return await _prefs.setStringList(_categoriesKey, categories);
  }

  // Pengingat Harian Aplikasi
  bool loadDailyReminderEnabled() {
    return _prefs.getBool(_dailyReminderEnabledKey) ?? false;
  }

  Future<bool> saveDailyReminderEnabled(bool enabled) async {
    return await _prefs.setBool(_dailyReminderEnabledKey, enabled);
  }

  String loadDailyReminderTime() {
    return _prefs.getString(_dailyReminderTimeKey) ?? '09:00';
  }

  Future<bool> saveDailyReminderTime(String time) async {
    return await _prefs.setString(_dailyReminderTimeKey, time);
  }

  // Backup & Restore
  String exportBackupJson() {
    final notes = loadNotes();
    final categories = loadCategories();
    return jsonEncode({
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories,
      'notes': notes.map((n) => n.toJson()).toList(),
    });
  }

  Future<bool> importBackupJson(String rawJson) async {
    try {
      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      if (data.containsKey('notes')) {
        final List<dynamic> rawNotes = data['notes'];
        final notes = rawNotes.map((n) => NoteModel.fromJson(n as Map<String, dynamic>)).toList();
        await saveNotes(notes);

        if (data.containsKey('categories')) {
          final List<dynamic> rawCats = data['categories'];
          final cats = rawCats.map((c) => c.toString()).toList();
          await saveCategories(cats);
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
