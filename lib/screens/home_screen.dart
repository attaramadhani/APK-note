import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/note_model.dart';
import '../models/note_sort_option.dart';
import '../providers/notes_controller.dart';
import '../widgets/note_card.dart';
import '../widgets/category_chips.dart';
import '../widgets/pin_dialog.dart';
import 'note_editor_screen.dart';
import 'trash_screen.dart';
import 'settings_screen.dart';

enum HomeViewSection { notes, archive }

class HomeScreen extends StatefulWidget {
  final NotesController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeViewSection _currentSection = HomeViewSection.notes;
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      widget.controller.setSearchQuery(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openNoteEditor({NoteModel? note, bool startAsChecklist = false}) async {
    if (note != null && note.isLocked) {
      // Periksa PIN terlebih dahulu
      final unlocked = await PinDialog.showUnlockDialog(
        context,
        onVerify: widget.controller.verifyPin,
      );
      if (!unlocked) return;
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => NoteEditorScreen(
          initialNote: note,
          startAsChecklist: startAsChecklist,
          availableCategories: widget.controller.categories,
          hasMasterPin: widget.controller.hasMasterPin,
          onVerifyPin: widget.controller.verifyPin,
          onSetMasterPin: (pin) => widget.controller.setMasterPin(pin),
          onSave: (savedNote) => widget.controller.saveNote(savedNote),
          onDelete: (id) => widget.controller.moveToTrash(id),
        ),
      ),
    );
  }

  void _showSortModal(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.swap_vert_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Urutkan Catatan 🔀',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...NoteSortOption.values.map((option) {
                final isSelected = controller.sortOption == option;
                return ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: Icon(
                    option.icon,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 20)
                      : null,
                  onTap: () {
                    controller.setSortOption(option);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;

    final isArchive = _currentSection == HomeViewSection.archive;
    final pinnedNotes = isArchive ? <NoteModel>[] : controller.pinnedNotes;
    final otherNotes = isArchive ? controller.archivedNotes : controller.unpinnedNotes;
    final hasNotes = pinnedNotes.isNotEmpty || otherNotes.isNotEmpty;

    return Scaffold(
      drawer: _buildDrawer(context, controller),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari catatan atau tugas...',
                  border: InputBorder.none,
                  filled: false,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        _isSearching = false;
                      });
                    },
                  ),
                ),
              )
            : Row(
                children: [
                  Text(
                    isArchive ? 'Arsip Catatan' : 'NoteCraft',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  if (!isArchive) const SizedBox(width: 6),
                  if (!isArchive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${controller.totalActiveCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Cari',
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          // Tombol Urutkan Catatan
          IconButton(
            icon: Icon(
              Icons.swap_vert_rounded,
              color: controller.sortOption != NoteSortOption.dateModifiedDesc
                  ? theme.colorScheme.primary
                  : null,
            ),
            tooltip: 'Urutkan Catatan (${controller.sortOption.shortLabel})',
            onPressed: () => _showSortModal(context),
          ),
          IconButton(
            icon: Icon(
              controller.isGridView
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_rounded,
            ),
            tooltip: controller.isGridView ? 'Tampilan Baris' : 'Tampilan Grid',
            onPressed: () => controller.toggleViewMode(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Kategori Chips (Hanya di layar utama, bukan di Arsip)
          if (!isArchive) ...[
            const SizedBox(height: 6),
            CategoryChips(
              categories: [
                'Semua',
                '⏰ Pengingat',
                '🔴 Prioritas',
                ...controller.categories.where((c) => c != 'Semua' && c != '⏰ Pengingat' && c != '🔴 Prioritas'),
              ],
              selectedCategory: controller.selectedCategory,
              onSelected: (cat) => controller.setSelectedCategory(cat),
              onAddCategory: (cat) => controller.addCategory(cat),
              onDeleteCategory: (cat) => controller.deleteCategory(cat),
            ),
            const SizedBox(height: 10),
          ],

          // Indikator Urutan Aktif (jika bukan default)
          if (!isArchive && controller.sortOption != NoteSortOption.dateModifiedDesc) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(70),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(controller.sortOption.icon, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Urutan: ${controller.sortOption.label}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => controller.setSortOption(NoteSortOption.dateModifiedDesc),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Daftar Catatan
          Expanded(
            child: !hasNotes
                ? _buildEmptyState(theme, isArchive)
                : RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      children: [
                        // Bagian Pinned Notes
                        if (pinnedNotes.isNotEmpty) ...[
                          _buildSectionTitle(theme, '📌 DISEMATKAN (${pinnedNotes.length})'),
                          const SizedBox(height: 8),
                          _buildNotesContainer(pinnedNotes, controller),
                          const SizedBox(height: 20),
                        ],

                        // Bagian Catatan Lainnya
                        if (otherNotes.isNotEmpty) ...[
                          if (pinnedNotes.isNotEmpty)
                            _buildSectionTitle(theme, 'CATATAN LAINNYA (${otherNotes.length})'),
                          if (pinnedNotes.isNotEmpty) const SizedBox(height: 8),
                          _buildNotesContainer(otherNotes, controller),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: isArchive
          ? null
          : _buildFloatingActionButtons(theme),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
      ),
    );
  }

  Widget _buildNotesContainer(List<NoteModel> notes, NotesController controller) {
    if (controller.isGridView) {
      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteCard(
            note: note,
            onTap: () => _openNoteEditor(note: note),
            onTogglePin: () => controller.togglePin(note.id),
            onArchive: () => controller.toggleArchive(note.id),
            onDelete: () => controller.moveToTrash(note.id),
            onColorChange: (colorIdx) => controller.saveNote(note.copyWith(colorIndex: colorIdx)),
            onToggleChecklist: (itemId) => controller.toggleChecklistItem(note.id, itemId),
          );
        },
      );
    } else {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = notes[index];
          return NoteCard(
            note: note,
            onTap: () => _openNoteEditor(note: note),
            onTogglePin: () => controller.togglePin(note.id),
            onArchive: () => controller.toggleArchive(note.id),
            onDelete: () => controller.moveToTrash(note.id),
            onColorChange: (colorIdx) => controller.saveNote(note.copyWith(colorIndex: colorIdx)),
            onToggleChecklist: (itemId) => controller.toggleChecklistItem(note.id, itemId),
          );
        },
      );
    }
  }

  Widget _buildEmptyState(ThemeData theme, bool isArchive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(90),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isArchive
                    ? Icons.archive_outlined
                    : (widget.controller.searchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.note_add_outlined),
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isArchive
                  ? 'Belum Ada Catatan yang Diarsipkan'
                  : (widget.controller.searchQuery.isNotEmpty
                      ? 'Tidak Ditemukan Catatan'
                      : 'Belum Ada Catatan'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isArchive
                  ? 'Catatan yang Anda arsipkan akan muncul dengan rapi di sini.'
                  : (widget.controller.searchQuery.isNotEmpty
                      ? 'Coba gunakan kata kunci pencarian yang lain.'
                      : 'Buat catatan baru atau daftar tugas pertama Anda sekarang!'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Tombol Buat To-Do Checklist Cepat
        FloatingActionButton.small(
          heroTag: 'fab_checklist',
          tooltip: 'Buat Daftar To-Do',
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          onPressed: () => _openNoteEditor(startAsChecklist: true),
          child: const Icon(Icons.checklist_rounded),
        ),
        const SizedBox(width: 12),
        // Tombol Buat Catatan Teks Standar
        FloatingActionButton.extended(
          heroTag: 'fab_note',
          tooltip: 'Buat Catatan Baru',
          onPressed: () => _openNoteEditor(startAsChecklist: false),
          icon: const Icon(Icons.edit_note_rounded, size: 22),
          label: const Text('Catatan Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, NotesController controller) {
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NoteCraft',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Catatan Ringkas, Cepat & Aman',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sticky_note_2_rounded),
            title: const Text('Semua Catatan'),
            selected: _currentSection == HomeViewSection.notes,
            trailing: Text(
              '${controller.totalActiveCount}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            onTap: () {
              setState(() {
                _currentSection = HomeViewSection.notes;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Arsip'),
            selected: _currentSection == HomeViewSection.archive,
            trailing: Text(
              '${controller.totalArchivedCount}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            onTap: () {
              setState(() {
                _currentSection = HomeViewSection.archive;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Tempat Sampah'),
            trailing: Text(
              '${controller.totalTrashCount}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: controller.totalTrashCount > 0 ? Colors.red : theme.colorScheme.outline,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => TrashScreen(controller: controller),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Pengaturan'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => SettingsScreen(controller: controller),
                ),
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'NoteCraft v1.0.0\nOffline Local Storage',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
