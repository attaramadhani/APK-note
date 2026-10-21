import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/note_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int globalDailyReminderId = 999990;

  Future<void> init() async {
    if (_isInitialized) return;

    _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notifications.initialize(
        settings: initSettings,
      );

      // Minta izin notifikasi & alarm tepat di Android 13+
      await requestPermissions();
    } catch (_) {}

    _isInitialized = true;
  }

  void _configureLocalTimezone() {
    try {
      tz.initializeTimeZones();
      final offset = DateTime.now().timeZoneOffset;
      String matchedLocation = 'Asia/Jakarta';
      for (final entry in tz.timeZoneDatabase.locations.entries) {
        try {
          final tzTime = tz.TZDateTime.from(DateTime.now(), entry.value);
          if (tzTime.timeZoneOffset == offset) {
            matchedLocation = entry.key;
            break;
          }
        } catch (_) {}
      }
      tz.setLocalLocation(tz.getLocation(matchedLocation));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImpl = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final notifGranted = await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();
        return notifGranted ?? false;
      }
    } catch (_) {}
    return true;
  }

  int _generateNotificationId(String noteId) {
    return noteId.hashCode.abs() % 2147483647;
  }

  Future<void> scheduleReminder(NoteModel note) async {
    if (note.reminderDateTime == null) return;
    await init();

    final scheduledDate = note.reminderDateTime!;
    final id = _generateNotificationId(note.id);

    const androidDetails = AndroidNotificationDetails(
      'notecraft_reminders_v2',
      'Pengingat Catatan NoteCraft',
      channelDescription:
          'Notifikasi pengingat catatan dan jadwal harian NoteCraft',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // KASUS 1: Pengingat Harian (Berulang Setiap Hari di jam yang sama)
    if (note.isDailyReminder) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        scheduledDate.hour,
        scheduledDate.minute,
      );
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final title = 'Pengingat Harian: ${note.title.isNotEmpty ? note.title : "Catatan NoteCraft"} ⏰';
      final body = note.previewText.isNotEmpty
          ? note.previewText
          : 'Saatnya mengecek catatan harian Anda di NoteCraft.';

      try {
        await _notifications.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        try {
          await _notifications.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: scheduledTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (_) {}
      }
      return;
    }

    // KASUS 2: Pengingat Satu Kali pada Tanggal & Jam Tertentu
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final title = note.title.isNotEmpty ? note.title : 'Pengingat Catatan ⏰';
    final body = note.previewText.isNotEmpty
        ? note.previewText
        : 'Buka NoteCraft untuk melihat catatan Anda.';

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await _notifications.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelReminder(String noteId) async {
    try {
      await init();
      final id = _generateNotificationId(noteId);
      await _notifications.cancel(id: id);
    } catch (_) {}
  }

  // Notifikasi Pengingat Rutin Harian Global (Seluruh Catatan / To-Do)
  Future<void> scheduleGlobalDailyReminder(int hour, int minute) async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'notecraft_reminders_v2',
      'Pengingat Catatan NoteCraft',
      channelDescription:
          'Notifikasi pengingat catatan dan jadwal harian NoteCraft',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.zonedSchedule(
        id: globalDailyReminderId,
        title: 'Cek Catatan & Agenda Hari Ini 📝✨',
        body: 'Buka NoteCraft untuk memeriksa catatan dan tugas prioritas Anda hari ini.',
        scheduledDate: scheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      try {
        await _notifications.zonedSchedule(
          id: globalDailyReminderId,
          title: 'Cek Catatan & Agenda Hari Ini 📝✨',
          body: 'Buka NoteCraft untuk memeriksa catatan dan tugas prioritas Anda hari ini.',
          scheduledDate: scheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelGlobalDailyReminder() async {
    try {
      await init();
      await _notifications.cancel(id: globalDailyReminderId);
    } catch (_) {}
  }

  // Kirim Notifikasi Tes Langsung (Untuk Uji Coba Cepat di HP Pengguna)
  Future<void> showInstantTestNotification() async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'notecraft_reminders_v2',
      'Pengingat Catatan NoteCraft',
      channelDescription:
          'Notifikasi pengingat catatan dan jadwal harian NoteCraft',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: 999999,
      title: 'Notifikasi NoteCraft Berfungsi! 🔔✨',
      body: 'Pengingat dan alarm di HP Anda sudah aktif dan siap berdering tepat waktu.',
      notificationDetails: notificationDetails,
    );
  }
}
