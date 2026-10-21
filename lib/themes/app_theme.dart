import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoteColor {
  final String name;
  final Color lightColor;
  final Color darkColor;
  final Color lightBorder;
  final Color darkBorder;

  const NoteColor({
    required this.name,
    required this.lightColor,
    required this.darkColor,
    required this.lightBorder,
    required this.darkBorder,
  });
}

class AppTheme {
  // 12 Palet Warna Kartu Catatan Elegan & Pastel
  static const List<NoteColor> noteColors = [
    NoteColor(
      name: 'Bawaan',
      lightColor: Color(0xFFFFFFFF),
      darkColor: Color(0xFF1E222B),
      lightBorder: Color(0xFFE2E8F0),
      darkBorder: Color(0xFF2D3748),
    ),
    NoteColor(
      name: 'Kuning Madu',
      lightColor: Color(0xFFFFF9DB),
      darkColor: Color(0xFF332F1A),
      lightBorder: Color(0xFFFFEE99),
      darkBorder: Color(0xFF524B27),
    ),
    NoteColor(
      name: 'Hijau Daun Mint',
      lightColor: Color(0xFFE6FCF5),
      darkColor: Color(0xFF163329),
      lightBorder: Color(0xFFB2F2BB),
      darkBorder: Color(0xFF225242),
    ),
    NoteColor(
      name: 'Biru Awan',
      lightColor: Color(0xFFE7F5FF),
      darkColor: Color(0xFF182D42),
      lightBorder: Color(0xFFA5D8FF),
      darkBorder: Color(0xFF234466),
    ),
    NoteColor(
      name: 'Lavender Ungu',
      lightColor: Color(0xFFF3F0FF),
      darkColor: Color(0xFF2A2045),
      lightBorder: Color(0xFFD0BFFF),
      darkBorder: Color(0xFF453470),
    ),
    NoteColor(
      name: 'Merah Muda Mawar',
      lightColor: Color(0xFFFFF0F6),
      darkColor: Color(0xFF3D1D2C),
      lightBorder: Color(0xFFFFC9DB),
      darkBorder: Color(0xFF5E2D43),
    ),
    NoteColor(
      name: 'Oranye Persik',
      lightColor: Color(0xFFFFF4E6),
      darkColor: Color(0xFF3D2719),
      lightBorder: Color(0xFFFFD8A8),
      darkBorder: Color(0xFF5E3C27),
    ),
    NoteColor(
      name: 'Teal Samudra',
      lightColor: Color(0xFFE6FFFA),
      darkColor: Color(0xFF143635),
      lightBorder: Color(0xFF96F2D7),
      darkBorder: Color(0xFF205453),
    ),
    NoteColor(
      name: 'Karang Senja',
      lightColor: Color(0xFFFFEBE8),
      darkColor: Color(0xFF381F1E),
      lightBorder: Color(0xFFFFBCB5),
      darkBorder: Color(0xFF5E3533),
    ),
    NoteColor(
      name: 'Krem Pasir',
      lightColor: Color(0xFFFDF6EC),
      darkColor: Color(0xFF332C22),
      lightBorder: Color(0xFFF3DEC3),
      darkBorder: Color(0xFF524737),
    ),
    NoteColor(
      name: 'Abu Minimalis',
      lightColor: Color(0xFFF8F9FA),
      darkColor: Color(0xFF252A34),
      lightBorder: Color(0xFFDEE2E6),
      darkBorder: Color(0xFF383F4D),
    ),
    NoteColor(
      name: 'Indigo Malam',
      lightColor: Color(0xFFEDF2FF),
      darkColor: Color(0xFF1E2640),
      lightBorder: Color(0xFFBAC8FF),
      darkBorder: Color(0xFF313E69),
    ),
  ];

  static Color getNoteBackgroundColor(int index, bool isDark) {
    if (index < 0 || index >= noteColors.length) index = 0;
    return isDark ? noteColors[index].darkColor : noteColors[index].lightColor;
  }

  static Color getNoteBorderColor(int index, bool isDark) {
    if (index < 0 || index >= noteColors.length) index = 0;
    return isDark ? noteColors[index].darkBorder : noteColors[index].lightBorder;
  }

  // Preset Kategori Bawaan
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Semua', 'icon': Icons.apps_rounded, 'color': Colors.blueGrey},
    {'name': 'Umum', 'icon': Icons.note_alt_outlined, 'color': Colors.teal},
    {'name': 'Pekerjaan', 'icon': Icons.work_outline_rounded, 'color': Colors.indigo},
    {'name': 'Pribadi', 'icon': Icons.person_outline_rounded, 'color': Colors.pink},
    {'name': 'Ide & Rencana', 'icon': Icons.lightbulb_outline_rounded, 'color': Colors.amber},
    {'name': 'Belanja', 'icon': Icons.shopping_bag_outlined, 'color': Colors.deepOrange},
    {'name': 'Belajar / Kuliah', 'icon': Icons.school_outlined, 'color': Colors.deepPurple},
  ];

  // Tema Terang
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF5B67CA),
    scaffoldBackgroundColor: const Color(0xFFF7F8FC),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF7F8FC),
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF1E293B),
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEDF2F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF5B67CA),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
    ),
  );

  // Tema Gelap
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFF7B88FF),
    scaffoldBackgroundColor: const Color(0xFF121418),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF121418),
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFFF1F5F9),
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF282F3E), width: 1),
      ),
      color: const Color(0xFF1C202A),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1F2430),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF6875F5),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
    ),
  );
}
