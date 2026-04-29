import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotifService {
  static Future<void> init() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'borrow_ch',
        channelName: 'Pemesanan',
        channelDescription: 'Status pemesanan tempat',
        defaultColor: const Color(0xFF4F8EF7),
        importance: NotificationImportance.High,
      ),
    ]);
  }

  static Future<void> requestPermission() async {
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> showStatusNotif(String status, String assetName) async {
    final titles = {
      'approved': 'Pemesanan Disetujui',
      'rejected': 'Pemesanan Ditolak',
      'returned': 'Pemakaian Selesai',
    };
    final bodies = {
      'approved': 'Pemesanan "$assetName" telah disetujui!',
      'rejected': 'Pemesanan "$assetName" ditolak.',
      'returned': 'Selesai pemakaian "$assetName" dicatat.',
    };
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'borrow_ch',
        title: titles[status] ?? 'Update Pemesanan',
        body: bodies[status] ?? 'Status berubah: $status',
      ),
    );
  }

  static Future<void> scheduleReminder(String borrowId, String assetName, DateTime returnDate) async {
    final reminderDate = returnDate.subtract(const Duration(minutes: 15));
    if (reminderDate.isBefore(DateTime.now())) return;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: borrowId.hashCode.remainder(100000),
        channelKey: 'borrow_ch',
        title: 'Pengingat Waktu Selesai',
        body: '15 menit lagi batas waktu pemakaian "$assetName". Jangan lupa!',
      ),
      schedule: NotificationCalendar(
        year: reminderDate.year, month: reminderDate.month,
        day: reminderDate.day, hour: reminderDate.hour, minute: reminderDate.minute, second: 0,
        repeats: false, allowWhileIdle: true,
      ),
    );
  }

  static Future<void> cancelReminder(String borrowId) =>
      AwesomeNotifications().cancel(borrowId.hashCode.remainder(100000));
}
