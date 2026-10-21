import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notecraft/models/note_model.dart';
import 'package:notecraft/models/note_sort_option.dart';
import 'package:notecraft/models/checklist_item.dart';
import 'package:notecraft/services/storage_service.dart';
import 'package:notecraft/providers/notes_controller.dart';
import 'package:notecraft/screens/note_editor_screen.dart';
import 'package:notecraft/utils/date_formatter.dart';
import 'package:notecraft/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoteCraft Unit Tests', () {
    test('NoteModel and ChecklistItem JSON serialization', () {
      final item = ChecklistItem(id: 'c1', text: 'Beli susu', isDone: false, time: '08:30');
      expect(item.id, 'c1');
      expect(item.text, 'Beli susu');
      expect(item.isDone, false);
      expect(item.time, '08:30');
      expect(item.hasTime, true);

      final note = NoteModel(
        id: 'n1',
        title: 'Catatan Belanja',
        content: '',
        isChecklist: true,
        checklist: [item],
        colorIndex: 2,
        category: 'Belanja',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = note.toJson();
      final decoded = NoteModel.fromJson(json);

      expect(decoded.id, 'n1');
      expect(decoded.title, 'Catatan Belanja');
      expect(decoded.isChecklist, true);
      expect(decoded.checklist.length, 1);
      expect(decoded.checklist.first.text, 'Beli susu');
      expect(decoded.checklist.first.time, '08:30');
      expect(decoded.checklist.first.hasTime, true);
      expect(decoded.colorIndex, 2);
    });

    test('NotesController CRUD operations', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final controller = NotesController(storage);

      expect(controller.allNotes.isNotEmpty, true); // Seed notes should exist
      final initialCount = controller.allNotes.length;

      final newNote = NoteModel(
        id: 'test_123',
        title: 'Catatan Baru',
        content: 'Isi catatan uji coba',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await controller.saveNote(newNote);
      expect(controller.allNotes.length, initialCount + 1);

      // Pin
      await controller.togglePin('test_123');
      expect(controller.pinnedNotes.any((n) => n.id == 'test_123'), true);

      // Move to trash
      await controller.moveToTrash('test_123');
      expect(controller.trashNotes.any((n) => n.id == 'test_123'), true);

      // Restore
      await controller.restoreFromTrash('test_123');
      expect(controller.trashNotes.any((n) => n.id == 'test_123'), false);
    });
  });

  testWidgets('NoteCraftApp launches smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = NotesController(storage);

    await tester.pumpWidget(NoteCraftApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('NoteCraft'), findsOneWidget);
  });

  testWidgets('Creating a new note via UI test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = NotesController(storage);

    await tester.pumpWidget(NoteCraftApp(controller: controller));
    await tester.pumpAndSettle();

    final fab = find.byTooltip('Buat Catatan Baru');
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorScreen), findsOneWidget);

    // Enter title
    await tester.enterText(find.widgetWithText(TextField, 'Judul Catatan...'), 'Catatan Baru Saya');
    await tester.pumpAndSettle();

    // Tap Selesai button
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan Baru Saya'), findsOneWidget);
  });

  testWidgets('Creating a checklist to-do note via UI test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = NotesController(storage);

    await tester.pumpWidget(NoteCraftApp(controller: controller));
    await tester.pumpAndSettle();

    final fabChecklist = find.byTooltip('Buat Daftar To-Do');
    expect(fabChecklist, findsOneWidget);
    await tester.tap(fabChecklist);
    await tester.pumpAndSettle();

    expect(find.byType(NoteEditorScreen), findsOneWidget);

    // Enter title
    await tester.enterText(find.widgetWithText(TextField, 'Judul Catatan...'), 'Daftar Tugas Baru');
    // Enter first checklist item
    await tester.enterText(find.widgetWithText(TextField, 'Item tugas...').first, 'Tugas Pertama');
    await tester.pumpAndSettle();

    // Tap Selesai button
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(find.text('Daftar Tugas Baru'), findsOneWidget);
    expect(find.text('Tugas Pertama'), findsOneWidget);
  });

  testWidgets('Search notes via UI test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = NotesController(storage);

    await tester.pumpWidget(NoteCraftApp(controller: controller));
    await tester.pumpAndSettle();

    // Open search bar
    final searchBtn = find.byTooltip('Cari');
    expect(searchBtn, findsOneWidget);
    await tester.tap(searchBtn);
    await tester.pumpAndSettle();

    // Search for non-existing note
    final searchField = find.widgetWithText(TextField, 'Cari catatan atau tugas...');
    await tester.enterText(searchField, 'KataKunciYangPastiTidakAda123');
    await tester.pumpAndSettle();

    expect(find.text('Tidak Ditemukan Catatan'), findsOneWidget);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();

    // Notes should be visible again
    expect(find.text('Selamat Datang di NoteCraft! ✨'), findsOneWidget);
  });

  testWidgets('Toggle Grid and List view test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = NotesController(storage);

    await tester.pumpWidget(NoteCraftApp(controller: controller));
    await tester.pumpAndSettle();

    expect(controller.isGridView, true);

    // Tap toggle view
    final toggleBtn = find.byTooltip('Tampilan Baris');
    expect(toggleBtn, findsOneWidget);
    await tester.tap(toggleBtn);
    await tester.pumpAndSettle();

    expect(controller.isGridView, false);
  });

  test('NoteModel priority and reminder logic', () {
    final now = DateTime.now();
    final noteHigh = NoteModel(
      id: 'high_prio',
      title: 'Tugas Mendesak',
      content: 'Harus selesai hari ini',
      priority: 3,
      reminderDateTime: now.add(const Duration(hours: 2)),
      isDailyReminder: false,
      createdAt: now,
      updatedAt: now,
    );

    expect(noteHigh.priorityLabel, 'Tinggi');
    expect(noteHigh.priorityEmoji, '🔴');
    expect(noteHigh.hasReminder, true);
    expect(noteHigh.isReminderOverdue, false);

    final noteDaily = NoteModel(
      id: 'daily_prio',
      title: 'Olahraga Pagi',
      content: 'Jogging 30 menit',
      reminderDateTime: now.subtract(const Duration(hours: 5)),
      isDailyReminder: true,
      createdAt: now,
      updatedAt: now,
    );
    expect(noteDaily.isDailyReminder, true);
    expect(noteDaily.isReminderOverdue, false);

    final json = noteDaily.toJson();
    final restoredDaily = NoteModel.fromJson(json);
    expect(restoredDaily.isDailyReminder, true);
    expect(restoredDaily.reminderDateTime?.hour, noteDaily.reminderDateTime?.hour);
  });

  testWidgets('Filter by Reminder and Priority chips test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = NotesController(storage);

    await tester.pumpWidget(NoteCraftApp(controller: controller));
    await tester.pumpAndSettle();

    // Verify filter chips exist on screen
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('⏰ Pengingat'), findsOneWidget);
    expect(find.text('🔴 Prioritas'), findsOneWidget);

    // Tap '🔴 Prioritas' chip
    await tester.tap(find.text('🔴 Prioritas'));
    await tester.pumpAndSettle();

    expect(controller.selectedCategory, '🔴 Prioritas');
    // Work demo note has priority 3 (Tinggi), Idea demo has priority 2 (Sedang)
    expect(controller.unpinnedNotes.every((n) => n.priority > 0), true);

    // Tap '⏰ Pengingat' chip
    await tester.tap(find.text('⏰ Pengingat'));
    await tester.pumpAndSettle();

    expect(controller.selectedCategory, '⏰ Pengingat');
    // Only notes with reminder are shown
    expect(controller.unpinnedNotes.every((n) => n.hasReminder), true);

    // Tap 'Semua' to reset
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();

    expect(controller.selectedCategory, 'Semua');
  });

  test('NoteSortOption comparison unit test', () {
    final now = DateTime.now();
    final noteA = NoteModel(
      id: 'a',
      title: 'Ayam Goreng',
      content: 'Resep',
      priority: 1, // Rendah
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(hours: 1)),
    );
    final noteB = NoteModel(
      id: 'b',
      title: 'Bebek Bakar',
      content: 'Menu',
      priority: 3, // Tinggi
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(hours: 3)),
    );

    // Title Ascending (A before B)
    expect(NoteSortOption.titleAsc.compare(noteA, noteB) < 0, true);
    // Title Descending (B before A)
    expect(NoteSortOption.titleDesc.compare(noteA, noteB) > 0, true);

    // Priority Descending (B has higher priority than A)
    expect(NoteSortOption.priorityDesc.compare(noteB, noteA) < 0, true);

    // Date Modified Descending (A was updated more recently than B)
    expect(NoteSortOption.dateModifiedDesc.compare(noteA, noteB) < 0, true);

    // Date Created Descending (B was created more recently than A)
    expect(NoteSortOption.dateCreatedDesc.compare(noteB, noteA) < 0, true);
  });

  testWidgets('Flexible sorting via UI bottom sheet test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = NotesController(storage);

    await tester.pumpWidget(NoteCraftApp(controller: controller));
    await tester.pumpAndSettle();

    // Default sorting is dateModifiedDesc
    expect(controller.sortOption, NoteSortOption.dateModifiedDesc);

    // Tap sort icon button in AppBar
    final sortBtn = find.byTooltip('Urutkan Catatan (Diedit Terbaru)');
    expect(sortBtn, findsOneWidget);
    await tester.tap(sortBtn);
    await tester.pumpAndSettle();

    // Bottom sheet should open with sort options
    expect(find.text('Urutkan Catatan 🔀'), findsOneWidget);
    final titleAscItem = find.text('Judul (A ke Z)');
    expect(titleAscItem, findsOneWidget);
    await tester.ensureVisible(titleAscItem);
    await tester.pumpAndSettle();

    // Tap 'Judul (A ke Z)'
    await tester.tap(titleAscItem);
    await tester.pumpAndSettle();

    // Controller should now have titleAsc
    expect(controller.sortOption, NoteSortOption.titleAsc);

    // Active sort indicator banner should appear
    expect(find.text('Urutan: Judul (A ke Z)'), findsOneWidget);

    // Tap 'Reset' button
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(controller.sortOption, NoteSortOption.dateModifiedDesc);
  });

  testWidgets('Checklist items with time, day, week, and month preview test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = NotesController(storage);

    // Save a note with time, day, week, and month schedule strings
    final now = DateTime.now();
    final timedNote = NoteModel(
      id: 'timed_note_test',
      title: 'Aktivitas Lengkap & Jadwal',
      content: '',
      isChecklist: true,
      checklist: [
        ChecklistItem(id: 't1', text: 'UTS Teori', isDone: false, time: 'Senin, 14 Okt'),
        ChecklistItem(id: 't2', text: 'Praktikum Lab', isDone: false, time: '08:00'),
        ChecklistItem(id: 't3', text: 'Laporan Proyek', isDone: false, time: 'Minggu Depan'),
        ChecklistItem(id: 't4', text: 'Evaluasi Kinerja', isDone: true, time: 'Bulan Depan (Nov)'),
      ],
      createdAt: now,
      updatedAt: now,
    );
    await controller.saveNote(timedNote);

    await tester.pumpWidget(NoteCraftApp(controller: controller));
    await tester.pumpAndSettle();

    // Verify the title is displayed
    expect(find.text('Aktivitas Lengkap & Jadwal'), findsOneWidget);
    // Verify item texts are displayed
    expect(find.text('UTS Teori'), findsOneWidget);
    expect(find.text('Praktikum Lab'), findsOneWidget);
    expect(find.text('Laporan Proyek'), findsOneWidget);
    expect(find.text('Evaluasi Kinerja'), findsOneWidget);
    // Verify multi-schedule badges are displayed on the note card
    expect(find.text('Senin, 14 Okt'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('Minggu Depan'), findsOneWidget);
    expect(find.text('Bulan Depan (Nov)'), findsOneWidget);
  });

  test('AppDateFormatter schedule formatting methods test', () {
    final testDate = DateTime(2026, 10, 12, 14, 30); // 12 Oktober 2026 is Monday (Senin)
    expect(AppDateFormatter.getDayName(testDate), 'Senin');
    expect(AppDateFormatter.getMonthShort(testDate), 'Okt');
    expect(AppDateFormatter.formatDate(testDate), '12 Okt');
    expect(AppDateFormatter.formatDayAndDate(testDate), 'Senin, 12 Okt');
    expect(AppDateFormatter.formatDayDateAndTime(testDate, 14, 30), 'Senin, 12 Okt, 14:30');
    expect(AppDateFormatter.formatTimeOnly(testDate), '14:30');
  });

  test('NotesController daily reminder preferences test', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final controller = NotesController(storage);

    expect(controller.dailyReminderEnabled, false);
    expect(controller.dailyReminderTime, '09:00');

    await controller.setDailyReminderEnabled(true);
    expect(controller.dailyReminderEnabled, true);

    await controller.setDailyReminderTime('08:30');
    expect(controller.dailyReminderTime, '08:30');

    await controller.setDailyReminderEnabled(false);
    expect(controller.dailyReminderEnabled, false);
  });
}

