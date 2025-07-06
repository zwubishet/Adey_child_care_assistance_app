import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  NotificationService() {
    // Initialization will be done with locale-specific strings when called
  }

  Future<void> _initNotification({
    required String channelName,
    required String channelDescription,
  }) async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(tz.local.name));

      const AndroidInitializationSettings initSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(
        android: initSettingsAndroid,
      );

      await notificationPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (
          NotificationResponse response,
        ) async {
          if (response.payload != null) {
            final parts = response.payload!.split('|');
            if (parts.length >= 4) {
              final userId = parts[0];
              final day = int.parse(parts[1]);
              final title = parts[2];
              final scheduledDate = DateTime.parse(parts[3]);
              final locale = parts.length > 4 ? parts[4] : 'en';
              await Future.wait([
                _saveDeliveredNotification(
                  userId,
                  day,
                  title,
                  scheduledDate,
                  locale,
                ),
                markNotificationAsSeen(userId, day),
              ]);
            }
          }
        },
      );

      final androidPlugin =
          notificationPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted != true) return;

        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          'daily_channel_id',
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
      _isInitialized = false;
    }
  }

  NotificationDetails _notificationDetails({
    required String channelName,
    required String channelDescription,
  }) => NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_channel_id',
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    ),
  );

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required String channelName,
    required String channelDescription,
  }) async {
    try {
      await _initNotification(
        channelName: channelName,
        channelDescription: channelDescription,
      );
      await notificationPlugin.show(
        id,
        title,
        body,
        _notificationDetails(
          channelName: channelName,
          channelDescription: channelDescription,
        ),
        payload: payload,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> scheduleDailyHealthTips(
    DateTime startDate,
    String userId,
    String locale,
    String channelName,
    String channelDescription,
  ) async {
    await _initNotification(
      channelName: channelName,
      channelDescription: channelDescription,
    );
    if (!_isInitialized) return;

    final tips = await _fetchHealthTips(locale);
    if (tips.isEmpty) return;

    await notificationPlugin.cancelAll();
    final now = DateTime.now();
    const interval = 4; // 4-day interval
    final maxTips = (280 / interval).ceil(); // 280 days / 4 = 70 tips max

    await Future.wait(
      List.generate(maxTips, (index) {
        final day = index * interval; // Day 0, 4, 8, ..., 276
        if (day >= 280 || day >= tips.length * interval) return Future.value();

        final scheduledDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day + day,
          8,
          0,
        );
        final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

        if (tzScheduledDate.isAfter(now)) {
          final tipIndex = (day / interval).floor(); // Map to tip index
          final tip = tips[tipIndex];
          final title = tip['title'];
          final body = tip['body'];

          return notificationPlugin.zonedSchedule(
            tip['id'],
            title,
            body,
            tzScheduledDate,
            _notificationDetails(
              channelName: channelName,
              channelDescription: channelDescription,
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload:
                '$userId|$day|$title|${scheduledDate.toIso8601String()}|$locale',
          );
        }
        return Future.value();
      }),
    );
  }

  Future<void> checkAndShowTodaysTip(
    String userId,
    DateTime startDate,
    String locale,
    String channelName,
    String channelDescription, {
    bool showPopup = true,
  }) async {
    await _initNotification(
      channelName: channelName,
      channelDescription: channelDescription,
    );
    if (!_isInitialized) return;

    final now = DateTime.now();
    final daysSinceStart = now.difference(startDate).inDays;
    if (daysSinceStart < 0 || daysSinceStart >= 280) return;

    final todayIntervalDay =
        (daysSinceStart ~/ 4) * 4; // Nearest lower 4-day mark
    final history = await getNotificationHistory(userId, locale);
    final todayNotification = history.firstWhere(
      (n) => n['day'] == todayIntervalDay,
      orElse: () => {},
    );

    if (todayNotification.isEmpty || todayNotification['seen'] == false) {
      final tips = await _fetchHealthTips(locale);
      final tipIndex = todayIntervalDay ~/ 4;
      if (tipIndex >= tips.length) return;

      final tip = tips[tipIndex];
      final title = tip['title'];
      final body = tip['body'];

      // Always save to history
      await _saveDeliveredNotification(
        userId,
        todayIntervalDay,
        title,
        now,
        locale,
      );

      // Show pop-up only if enabled
      if (showPopup) {
        await showNotification(
          id: tip['id'],
          title: title,
          body: body,
          payload:
              '$userId|$todayIntervalDay|$title|${now.toIso8601String()}|$locale',
          channelName: channelName,
          channelDescription: channelDescription,
        );
      }
    }
  }

  Future<void> _saveDeliveredNotification(
    String userId,
    int day,
    String title,
    DateTime scheduledDate,
    String locale,
  ) async {
    try {
      // Fetch the tip in both languages
      final tipsEn = await _fetchHealthTips('en');
      final tipsAm = await _fetchHealthTips('am');
      final tipIndex = day ~/ 4;
      if (tipIndex >= tipsEn.length || tipIndex >= tipsAm.length) return;

      final tipEn = tipsEn[tipIndex];
      final tipAm = tipsAm[tipIndex];

      await Supabase.instance.client.from('notification_history').upsert({
        'user_id': userId,
        'day': day,
        'title_en': tipEn['title'],
        'title_am': tipAm['title'],
        'body_en': tipEn['body'],
        'body_am': tipAm['body'],
        if (tipEn['relevance'] != null) 'relevance': tipEn['relevance'],
        'scheduled_date': scheduledDate.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'seen': false,
        'delivered_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,day');
    } catch (e) {
      print('Error saving delivered notification: $e');
    }
  }

  Future<void> markNotificationAsSeen(String userId, int day) async {
    try {
      await Supabase.instance.client
          .from('notification_history')
          .update({'seen': true})
          .eq('user_id', userId)
          .eq('day', day);
    } catch (e) {
      print('Error marking notification as seen: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationHistory(
    String userId,
    String locale,
  ) async {
    try {
      final titleColumn = locale == 'am' ? 'title_am' : 'title_en';
      final bodyColumn = locale == 'am' ? 'body_am' : 'body_en';

      final response = await Supabase.instance.client
          .from('notification_history')
          .select(
            'id, user_id, day, $titleColumn, $bodyColumn, relevance, seen, delivered_at',
          )
          .eq('user_id', userId)
          .order('delivered_at', ascending: false);

      return response.map<Map<String, dynamic>>((notification) {
        return {
          'day': notification['day'],
          'title': notification[titleColumn] ?? '',
          'body': notification[bodyColumn] ?? '',
          'relevance': notification['relevance'],
          'seen': notification['seen'],
          'delivered_at': notification['delivered_at'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching notification history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHealthTips(String locale) async {
    try {
      final titleColumn = locale == 'am' ? 'title_am' : 'title_en';
      final bodyColumn = locale == 'am' ? 'body_am' : 'body_en';

      final response = await Supabase.instance.client
          .from('health_tips')
          .select('id, day, $titleColumn, $bodyColumn, relevance')
          .order('day', ascending: true);

      return response.map<Map<String, dynamic>>((tip) {
        return {
          'id': tip['id'],
          'day': tip['day'],
          'title': tip[titleColumn] ?? 'Fallback Tip',
          'body': tip[bodyColumn] ?? 'Consult your doctor.',
          'relevance': tip['relevance'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching health tips: $e');
      return List.generate(
        70,
        (index) => {
          'id': index,
          'day': index * 4,
          'title': locale == 'am' ? 'ምክር ${index + 1}' : 'Tip ${index + 1}',
          'body': locale == 'am' ? 'ለመከረው ሐኪምዎን ያማክሩ።' : 'Consult your doctor.',
        },
      );
    }
  }
}
