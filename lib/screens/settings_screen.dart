import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/notes_controller.dart';
import '../widgets/pin_dialog.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  final NotesController controller;

  const SettingsScreen({super.key, required this.controller});

  void _showBackupDialog(BuildContext context) {
    final jsonStr = controller.exportBackup();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ekspor Data Cadangan (Backup) 📦'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data catatan Anda telah diekspor dalam format JSON. Anda dapat menyalinnya untuk disimpan:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonStr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cadangan disalin ke clipboard! 📋')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Salin JSON'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pulihkan Data Cadangan 📥'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tempel teks cadangan JSON yang sebelumnya Anda simpan:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 5,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Tempel JSON di sini...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final json = textController.text.trim();
              if (json.isNotEmpty) {
                final success = await controller.importBackup(json);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Data berhasil dipulihkan! 🎉'
                            : 'Gagal memulihkan data. Format JSON tidak sesuai.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section Tampilan
          _buildSectionHeader(context, 'Tampilan & Tema'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Tema Aplikasi'),
                  subtitle: Text(
                    controller.themeMode == ThemeMode.system
                        ? 'Ikuti Sistem HP'
                        : (controller.themeMode == ThemeMode.light ? 'Mode Terang' : 'Mode Gelap'),
                  ),
                  trailing: DropdownButton<ThemeMode>(
                    value: controller.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('Sistem'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Terang ☀️'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Gelap 🌙'),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) controller.setThemeMode(mode);
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.grid_view_rounded),
                  title: const Text('Tampilan Grid 2 Kolom'),
                  subtitle: const Text('Beralih antara tata letak Masonry Grid atau List'),
                  value: controller.isGridView,
                  onChanged: (_) => controller.toggleViewMode(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Notifikasi & Pengingat
          _buildSectionHeader(context, 'Notifikasi & Pengingat Harian 🔔'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.alarm_on_rounded),
                  title: const Text('Pengingat Harian (Setiap Hari)'),
                  subtitle: Text(
                    controller.dailyReminderEnabled
                        ? 'Aktif: Mengingatkan setiap hari pukul ${controller.dailyReminderTime}'
                        : 'Mengingatkan setiap hari untuk mengecek catatan & agenda',
                  ),
                  value: controller.dailyReminderEnabled,
                  onChanged: (val) async {
                    await controller.setDailyReminderEnabled(val);
                  },
                ),
                if (controller.dailyReminderEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.access_time_rounded),
                    title: const Text('Jam Pengingat Harian'),
                    subtitle: const Text('Ketuk untuk mengubah jam notifikasi harian'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        controller.dailyReminderTime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    onTap: () async {
                      final parts = controller.dailyReminderTime.split(':');
                      final currentHour = int.tryParse(parts[0]) ?? 9;
                      final currentMinute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
                        helpText: 'Pilih Jam Pengingat Harian',
                      );
                      if (picked != null) {
                        final hh = picked.hour.toString().padLeft(2, '0');
                        final mm = picked.minute.toString().padLeft(2, '0');
                        await controller.setDailyReminderTime('$hh:$mm');
                      }
                    },
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_rounded, color: Colors.green),
                  title: const Text('Tes Notifikasi Sekarang 🔔'),
                  subtitle: const Text('Kirim notifikasi langsung ke bilah status HP untuk uji coba'),
                  onTap: () async {
                    await NotificationService().showInstantTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifikasi uji coba dikirim! Periksa bilah status HP Anda. 🔔✨'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Keamanan
          _buildSectionHeader(context, 'Keamanan & Privasi'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('PIN Kunci Catatan'),
                  subtitle: Text(
                    controller.hasMasterPin
                        ? 'PIN Aktif (Catatan Anda aman terlindungi)'
                        : 'Belum diatur (Ketuk untuk membuat)',
                  ),
                  trailing: controller.hasMasterPin
                      ? TextButton(
                          onPressed: () async {
                            final verified = await PinDialog.showUnlockDialog(
                              context,
                              onVerify: controller.verifyPin,
                            );
                            if (verified && context.mounted) {
                              final newPin = await PinDialog.showSetPinDialog(context);
                              if (newPin != null) {
                                await controller.setMasterPin(newPin);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('PIN berhasil diperbarui! 🔑')),
                                  );
                                }
                              }
                            }
                          },
                          child: const Text('Ubah'),
                        )
                      : TextButton(
                          onPressed: () async {
                            final newPin = await PinDialog.showSetPinDialog(context);
                            if (newPin != null) {
                              await controller.setMasterPin(newPin);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('PIN berhasil dipasang! 🔒')),
                                );
                              }
                            }
                          },
                          child: const Text('Buat PIN'),
                        ),
                ),
                if (controller.hasMasterPin) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: Colors.red),
                    title: const Text('Hapus PIN Keamanan', style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      final verified = await PinDialog.showUnlockDialog(
                        context,
                        onVerify: controller.verifyPin,
                      );
                      if (verified) {
                        await controller.setMasterPin(null);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN keamanan dinonaktifkan.')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Data & Penyimpanan
          _buildSectionHeader(context, 'Cadangan Data (Backup)'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: const Text('Ekspor Cadangan Catatan'),
                  subtitle: const Text('Salin semua catatan Anda dalam format teks JSON'),
                  onTap: () => _showBackupDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Pulihkan Data Catatan'),
                  subtitle: const Text('Masukkan kode JSON untuk memulihkan catatan'),
                  onTap: () => _showRestoreDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Tentang
          _buildSectionHeader(context, 'Tentang Aplikasi'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: const Text('NoteCraft Mobile'),
                  subtitle: const Text('Versi 1.0.0 • Offline & Privacy-First'),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'NoteCraft dibuat untuk memberikan pengalaman mencatat terbaik di smartphone: cepat, bebas iklan, tanpa login akun yang rumit, dan data 100% tersimpan aman di perangkat Anda.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withAlpha(160),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
