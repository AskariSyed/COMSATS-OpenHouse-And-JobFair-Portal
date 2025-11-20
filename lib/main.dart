import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/firebase_options.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'screens/sigin.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    print("🔔 Background message: ${message.notification?.title}");
    print("📦 Background data: ${message.data}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check if we are NOT on the web AND if the platform is Android
  if (!kIsWeb && Platform.isAndroid) {
    FirebaseMessaging.instance.requestPermission();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: initSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (kDebugMode) {
        print("📩 Notification clicked: ${response.payload}");
      }
      // You can handle notification taps here, e.g., navigate
      // if (response.payload != null) { ... }
    },
  );

  FirebaseMessaging.instance.getToken().then((token) {
    if (kDebugMode) print("🔑 FCM token: $token");
  });

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => StudentProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("🔔 Foreground message: ${message.notification?.title}");
        print("📦 Foreground data: ${message.data}");
      }

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      String formattedData;
      try {
        formattedData = const JsonEncoder.withIndent(
          '   ',
        ).convert(message.data.isNotEmpty ? message.data : {});
      } catch (_) {
        formattedData = message.data.toString();
      }

      if (notification != null && android != null) {
        // ✅ Show local notification
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title ?? "Notification",
          formattedData,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_channel',
              'FCM Notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              styleInformation: const BigTextStyleInformation(''),
            ),
          ),
          payload: formattedData,
        );

        // --- FIX 2: Use the navigatorKey to get the correct context ---
        final context = navigatorKey.currentContext;
        if (context != null) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(notification.title ?? "Notification"),
              content: SingleChildScrollView(
                child: Text(
                  formattedData,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && kDebugMode) {
        print("📱 Opened from terminated: ${message.notification?.title}");
        print("📦 Data: ${message.data}");
        // Handle navigation based on data here
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        print("📱 Opened from background: ${message.notification?.title}");
        print("📦 Data: ${message.data}");
        // Handle navigation based on data here
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Job Fair Portal',
      navigatorKey: navigatorKey,
      home: const StudentLoginScreen(),
    );
  }
}
