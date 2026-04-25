import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  int get uniqueId =>
      DateTime.now().millisecondsSinceEpoch.remainder(100000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [

          // Default Notification
          OutlinedButton(
            onPressed: () async {
              await NotificationService.createNotification(
                id: uniqueId,
                title: 'Default Notification',
                body: 'This is the body',
              );
            },
            child: const Text('Default Notification'),
          ),

          OutlinedButton(
            onPressed: () async {
              await NotificationService.createNotification(
                id: uniqueId,
                title: 'Inbox Notification',
                body: 'This is the body',
                notificationLayout: NotificationLayout.Inbox,
              );
            },
            child: const Text('Inbox Notification'),
          ),

          OutlinedButton(
            onPressed: () async {
              await NotificationService.createNotification(
                id: uniqueId,
                title: 'Big Image',
                body: 'This is the body',
                notificationLayout: NotificationLayout.BigPicture,
                bigPicture: 'https://picsum.photos/300/200',
              );
            },
            child: const Text('Big Image Notification'),
          ),

          OutlinedButton(
            onPressed: () async {
              await NotificationService.createNotification(
                id: uniqueId,
                title: 'Action Button',
                body: 'Click button below',
                payload: {'navigate': 'true'},
                actionButtons: [
                  NotificationActionButton(
                    key: 'action_button',
                    label: 'Click me',
                  )
                ],
              );
            },
            child: const Text('Action Button Notification'),
          ),

          OutlinedButton(
            onPressed: () async {
              await NotificationService.createNotification(
                id: uniqueId,
                title: 'Scheduled Notification',
                body: 'Wait 5 seconds',
                scheduled: true,
                interval: const Duration(seconds: 5),
              );
            },
            child: const Text('Scheduled Notification'),
          ),
        ],
      ),
    );
  }
}