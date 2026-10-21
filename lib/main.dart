import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/notes_controller.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kunci orientasi ke Portrait (ideal untuk aplikasi HP)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}

  // Inisialisasi Service Notifikasi & Izin Alarm Android
  try {
    await NotificationService().init();
  } catch (_) {}

  // Inisialisasi Service Penyimpanan Lokal (Offline)
  final storageService = await StorageService.init();
  final notesController = NotesController(storageService);

  runApp(NoteCraftApp(controller: notesController));
}

class NoteCraftApp extends StatelessWidget {
  final NotesController controller;

  const NoteCraftApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'NoteCraft',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: controller.themeMode,
          home: HomeScreen(controller: controller),
        );
      },
    );
  }
}
