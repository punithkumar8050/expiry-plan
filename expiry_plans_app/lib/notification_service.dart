import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Load Timezones
    tz.initializeTimeZones(); 

    // 2. Setup Settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings, 
      iOS: iosSettings
    );

    // 3. Initialize
    await _notifications.initialize(settings);
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required DateTime expiryDate,
  }) async {
    try {
      final scheduledDate = DateTime(
        expiryDate.year,
        expiryDate.month,
        expiryDate.day,
        9, 0, 0 
      );

      if (scheduledDate.isBefore(DateTime.now())) return;

      await _notifications.zonedSchedule(
        id,
        'Expiry Alert! ⚠️',
        '$title is expiring today!',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expiry_channel', 
            'Expiry Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }
}