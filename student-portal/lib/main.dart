import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/firebase_options.dart';
import 'package:student_job_fair_portal/provider/company_provider.dart';
import 'package:student_job_fair_portal/provider/job_provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:student_job_fair_portal/provider/theme_provider.dart';
import 'package:student_job_fair_portal/provider/notification_provider.dart';
import 'package:student_job_fair_portal/provider/notice_provider.dart';
import 'package:student_job_fair_portal/model/notification_model.dart';
import 'package:student_job_fair_portal/config/backend_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_job_fair_portal/utils/page_transitions.dart';
import 'screens/sigin.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/company_profile_screen.dart';
import 'screens/requestScreen.dart';
import 'services/update_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _pushWhenReady(WidgetBuilder builder) {
  final nav = navigatorKey.currentState;
  if (nav != null) {
    nav.push(MaterialPageRoute(builder: builder));
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.push(MaterialPageRoute(builder: builder));
  });
}

void _openNotificationTargetByData(Map<String, dynamic> data) {
  final type = (data['Type'] ?? data['type'] ?? '').toString().toLowerCase();
  final screen = (data['screen'] ?? data['Screen'] ?? '')
      .toString()
      .toLowerCase();
  final tab = (data['tab'] ?? data['Tab'] ?? '').toString().toLowerCase();
  final requestIdRaw = (data['requestId'] ?? data['RequestId'] ?? '')
      .toString();
  final requestId = int.tryParse(requestIdRaw);
  final companyIdRaw = (data['CompanyId'] ?? data['companyId'] ?? '')
      .toString();
  final companyName = (data['CompanyName'] ?? data['companyName'] ?? 'Company')
      .toString();
  final companyId = int.tryParse(companyIdRaw);

  if (type == 'interviewrequest' || screen == 'requests' || tab == 'received') {
    _pushWhenReady(
      (_) =>
          RequestsScreen(initialTabIndex: 1, highlightedRequestId: requestId),
    );
    return;
  }

  if ((type == 'interviewscheduled' || type == 'interviewreminder') &&
      companyId != null &&
      companyId > 0) {
    _pushWhenReady(
      (_) =>
          CompanyProfileScreen(companyId: companyId, companyName: companyName),
    );
  }
}

void _openCompanyProfileByData([Map<String, dynamic>? data]) {
  if (data != null && data.isNotEmpty) {
    _openNotificationTargetByData(data);
  }
}

void _openCompanyProfileFromPayload(String? payload) {
  _openNotificationTargetFromPayload(payload);
}

void _openNotificationTargetFromPayload(String? payload) {
  if (payload == null || payload.isEmpty) return;
  try {
    final decoded = json.decode(payload);
    if (decoded is Map<String, dynamic>) {
      _openNotificationTargetByData(decoded);
    }
  } catch (_) {
    // Ignore malformed payload.
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    print("🔔 Background message: ${message.notification?.title}");
    print("📦 Background data: ${message.data}");
  }

  // Android already displays FCM notifications with `notification` payload
  // in background/terminated states. Showing them again locally causes duplicates.
  final notification = message.notification;
  final payload = jsonEncode(message.data.isNotEmpty ? message.data : {});

  if (notification != null) {
    await NotificationProvider.saveNotificationStatic(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: notification.title ?? "Notification",
        body: notification.body ?? "",
        timestamp: DateTime.now(),
        data: message.data,
      ),
    );
    return;
  }

  // For data-only background messages, show a local notification manually.
  final title =
      (message.data['title'] ?? message.data['Title'] ?? 'Notification')
          .toString();
  final body = (message.data['body'] ?? message.data['Body'] ?? '').toString();

  await flutterLocalNotificationsPlugin.show(
    message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'fcm_channel',
        'FCM Notifications',
        channelDescription: 'This channel is used for important notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: payload,
  );

  await NotificationProvider.saveNotificationStatic(
    NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      data: message.data,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BackendConfig.logResolvedConfig();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Request FCM permission and setup on native platforms
  if (!kIsWeb && Platform.isAndroid) {
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Initialize notifications on Android
  if (!kIsWeb && Platform.isAndroid) {
    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fcm_channel',
      'FCM Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

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
        _openCompanyProfileFromPayload(response.payload);
      },
    );

    FirebaseMessaging.instance.getToken().then((token) {
      if (kDebugMode) print("🔑 FCM token: $token");
    });
  }

  // Initialize web notifications (stub init only)
  // Permission request and token retrieval are deferred to sign-in (sigin.dart)
  // so they run after user interaction and on a secure context (HTTPS/localhost).
  if (kIsWeb) {
    const InitializationSettings initSettings = InitializationSettings();
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    if (kDebugMode) {
      print('🌐 Web: FCM permission will be requested at login');
      print('⚠️  Web push notifications require HTTPS or localhost');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
      ],
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
  static String get _studentApiBase => BackendConfig.apiBaseUrl;
  Timer? _interviewReminderTimer;

  @override
  void initState() {
    super.initState();

    // Reload notifications when app starts (to get background saved notifications)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        final notificationProvider = Provider.of<NotificationProvider>(
          ctx,
          listen: false,
        );
        notificationProvider.loadNotifications();
      }
    });

    // Setup Firebase messaging on all platforms
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("🔔 Foreground message: ${message.notification?.title}");
        print("📦 Foreground data: ${message.data}");
      }

      RemoteNotification? notification = message.notification;

      String formattedData;
      try {
        formattedData = const JsonEncoder.withIndent(
          '   ',
        ).convert(message.data.isNotEmpty ? message.data : {});
      } catch (_) {
        formattedData = message.data.toString();
      }

      if (notification != null) {
        // Store notification
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          final notificationProvider = Provider.of<NotificationProvider>(
            ctx,
            listen: false,
          );
          notificationProvider.addNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: notification.title ?? "Notification",
              body: notification.body ?? "",
              timestamp: DateTime.now(),
              data: message.data,
            ),
          );
        }

        if (kIsWeb) {
          // 🌐 Show web notification using browser API
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title ?? "Notification",
            notification.body,
            const NotificationDetails(),
          );
        } else {
          // 📱 Show Android notification
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title ?? "Notification",
            notification.body ?? "",
            NotificationDetails(
              android: AndroidNotificationDetails(
                'fcm_channel',
                'FCM Notifications',
                channelDescription:
                    'This channel is used for important notifications',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                styleInformation: BigTextStyleInformation(
                  notification.body ?? "",
                ),
              ),
            ),
            payload: formattedData,
          );
        }

        // Show dialog on all platforms
        final context = navigatorKey.currentContext;
        if (context != null) {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: MaterialLocalizations.of(
              context,
            ).modalBarrierDismissLabel,
            barrierColor: Colors.black54,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, animation, secondaryAnimation) {
              return Container();
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              );

              return ScaleTransition(
                scale: Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).animate(curvedAnimation),
                child: FadeTransition(
                  opacity: animation,
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : Colors.blue.shade50.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade600,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_active,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Title
                          Text(
                            notification.title ?? "Notification",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Body
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: SingleChildScrollView(
                              child: Text(
                                notification.body ?? "",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white70
                                          : Colors.black87,
                                      height: 1.5,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // OK Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Got it",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
      } else {
        // Foreground data-only push: surface it as a local notification.
        final title =
            (message.data['title'] ?? message.data['Title'] ?? 'Notification')
                .toString();
        final body = (message.data['body'] ?? message.data['Body'] ?? '')
            .toString();

        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          final notificationProvider = Provider.of<NotificationProvider>(
            ctx,
            listen: false,
          );
          notificationProvider.addNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: title,
              body: body,
              timestamp: DateTime.now(),
              data: message.data,
            ),
          );
        }

        flutterLocalNotificationsPlugin.show(
          message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_channel',
              'FCM Notifications',
              channelDescription:
                  'This channel is used for important notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: formattedData,
        );
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && kDebugMode) {
        print("📱 Opened from terminated: ${message.notification?.title}");
        print("📦 Data: ${message.data}");
      }
      if (message != null) {
        _openCompanyProfileByData(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        print("📱 Opened from background: ${message.notification?.title}");
        print("📦 Data: ${message.data}");
      }
      _openCompanyProfileByData(message.data);
    });

    _startInterviewReminderPolling();
  }

  @override
  void dispose() {
    _interviewReminderTimer?.cancel();
    super.dispose();
  }

  void _startInterviewReminderPolling() {
    if (kIsWeb) return;
    _checkUpcomingInterviewReminders();
    _interviewReminderTimer?.cancel();
    _interviewReminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkUpcomingInterviewReminders();
    });
  }

  Future<void> _checkUpcomingInterviewReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse('$_studentApiBase/Student/interviews/scheduled'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return;

      final payload = json.decode(response.body);
      if (payload is! List) return;

      final nowUtc = DateTime.now().toUtc();
      for (final row in payload) {
        if (row is! Map<String, dynamic>) continue;

        final status = (row['status'] ?? '').toString().toLowerCase();
        if (status != 'queued' &&
            status != 'accepted' &&
            status != 'inprogress')
          continue;

        final scheduledRaw = row['scheduledTime']?.toString();
        final scheduledUtc = scheduledRaw != null
            ? DateTime.tryParse(scheduledRaw)?.toUtc()
            : null;
        if (scheduledUtc == null) continue;

        final minutesLeft = scheduledUtc.difference(nowUtc).inMinutes;
        if (minutesLeft <= 0 || minutesLeft > 30) continue;

        int bucket;
        if (minutesLeft <= 5) {
          bucket = 5;
        } else if (minutesLeft <= 15) {
          bucket = 15;
        } else {
          bucket = 30;
        }

        final interviewId = row['interviewId']?.toString() ?? '';
        if (interviewId.isEmpty) continue;

        final reminderKey = 'interview_reminder_${interviewId}_$bucket';
        if (prefs.getBool(reminderKey) == true) continue;

        final companyName = (row['companyName'] ?? 'Company').toString();
        final room = (row['room'] ?? 'TBD').toString();
        final companyId = (row['companyId'] ?? '').toString();

        await flutterLocalNotificationsPlugin.show(
          interviewId.hashCode + bucket,
          'Interview in $minutesLeft min',
          '$companyName | Room: $room',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_channel',
              'FCM Notifications',
              channelDescription:
                  'This channel is used for important notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode({
            'type': 'InterviewReminder',
            'companyId': companyId,
            'companyName': companyName,
          }),
        );

        await prefs.setBool(reminderKey, true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Interview reminder polling failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Job Fair Portal',
          navigatorKey: navigatorKey,
          builder: (context, child) {
            final isIOSWeb =
                kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
            if (kIsWeb && !isIOSWeb && child != null) {
              return Overlay(
                initialEntries: [
                  OverlayEntry(builder: (_) => SelectionArea(child: child)),
                ],
              );
            }
            return child ?? const SizedBox.shrink();
          },
          themeMode: themeProvider.themeMode,
          theme: ThemeData.light(useMaterial3: false).copyWith(
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            primaryColor: Colors.blue.shade600,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CustomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              secondary: Colors.purple.shade400,
              surface: Colors.white,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
              bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
              bodySmall: TextStyle(color: Colors.black54, fontSize: 12),
              headlineMedium: TextStyle(
                color: Colors.black87,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              headlineSmall: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              titleLarge: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              titleMedium: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              titleSmall: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ).apply(fontFamily: 'Arial'),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 1,
            ),
            iconTheme: const IconThemeData(color: Colors.black87),
            dividerColor: Colors.black12,
          ),
          darkTheme: ThemeData.dark(useMaterial3: false).copyWith(
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            primaryColor: Colors.blue.shade400,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CustomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
            colorScheme: ColorScheme.dark(
              primary: Colors.blue.shade400,
              secondary: Colors.purple.shade400,
              surface: const Color(0xFF1E1E1E),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
              bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
              bodySmall: TextStyle(color: Colors.white70, fontSize: 12),
              headlineMedium: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              headlineSmall: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              titleLarge: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              titleMedium: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              titleSmall: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ).apply(fontFamily: 'Arial'),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            dividerColor: Colors.white24,
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

// Auth Wrapper to handle auto-login
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _checkAppUpdate();
  }

  void _checkAppUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context, navigatorKey: navigatorKey);
    });
  }

  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check onboarding first
      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
      if (!seenOnboarding && !kIsWeb) {
        if (mounted) {
          setState(() {
            _showOnboarding = true;
            _isChecking = false;
          });
        }
        return;
      }

      final token = prefs.getString('authToken');

      if (token != null && mounted) {
        // Token exists, try to fetch profile
        final studentProvider = Provider.of<StudentProvider>(
          context,
          listen: false,
        );

        // Set token first
        await studentProvider.setToken(token);

        // Try to fetch profile
        await studentProvider.fetchProfile();

        if (mounted && studentProvider.student != null) {
          // Profile loaded successfully, navigate to DashboardScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
          return;
        } else {
          // Token invalid or profile fetch failed, clear token
          await studentProvider.logout();
        }
      }
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Auto-login error: $e');
      }
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Show minimal loading while checking auth
      // Native splash screen from flutter_launcher_icons will show first
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showOnboarding) {
      return const OnboardingScreen();
    }

    // Show login screen
    return const StudentLoginScreen();
  }
}
