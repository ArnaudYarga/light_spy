import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class BatteryNotification {
  static final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'spy',
    'spy',
    'spy channel',
    importance: Importance.Max,
    priority: Priority.High,
    ticker: 'ticker',
  );
  static final iOSPlatformChannelSpecifics = IOSNotificationDetails();
  final platformChannelSpecifics = NotificationDetails(
    androidPlatformChannelSpecifics,
    iOSPlatformChannelSpecifics,
  );
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  static final initializationSettingsIOS = IOSInitializationSettings();
  static final initializationSettings = InitializationSettings(
    initializationSettingsAndroid,
    initializationSettingsIOS,
  );
  int id;

  BatteryNotification() {
    id = 0;
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  show() async {
    flutterLocalNotificationsPlugin.show(
      id++,
      'ALERT',
      'Device state has changed',
      platformChannelSpecifics,
    );
    await FlutterRingtonePlayer.play(
      android: AndroidSounds.alarm,
      ios: IosSounds.glass,
      asAlarm: true, // Android only - all APIs
    );
    await Future.delayed(Duration(seconds: 3));
    FlutterRingtonePlayer.stop();
  }
}