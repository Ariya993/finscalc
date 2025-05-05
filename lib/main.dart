import 'package:finscalc/controllers/penerimaan_controller.dart';
import 'package:finscalc/controllers/pengeluaran_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'pages/category_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'controllers/login_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/fcm_controller.dart';
import 'pages/penerimaan_form.dart';
import 'pages/pengeluaran_form.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initializeNotifications();
  await GetStorage.init();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi controller sekali
  Get.put(LoginController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  Get.put(FCMController(), permanent: true);
 Get.put(PenerimaanController(), permanent: true);
  Get.put(PengeluaranController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final token = box.read('token');
    final expires = box.read('expires');
 
    // Refresh token jika mendekati kadaluarsa
    if (token != null && expires != null) {
      final expireDateTime = DateTime.fromMillisecondsSinceEpoch(expires);
      if (!DateTime.now().isBefore(expireDateTime.subtract(const Duration(seconds: 10)))) {
        final loginController = Get.find<LoginController>();
        loginController.refreshToken();
      }
    }

    final initialPage = token != null && expires != null ? DashboardPage() : LoginPage();

    // Hanya kirim welcome notification jika sudah login
    if (token != null) {
      _sendWelcomeNotification();
    }

    return GetMaterialApp(
      title: 'Login App',
      debugShowCheckedModeBanner: false,
      home: initialPage,
      getPages: [
        GetPage(name: '/dashboard', page: () => DashboardPage()),
        GetPage(name: '/login', page: () => LoginPage()),
         GetPage(name: '/kategori-form', page: () => KategoriPage()),
          // GetPage(name: '/penerimaan-form', page: () => PenerimaanForm()),
          //  GetPage(name: '/pengeluaran-form', page: () => PengeluaranForm()),
      ],
    );
  }

  Future<void> _sendWelcomeNotification() async {
    final box = GetStorage();
    final fcmtoken = box.read('fcmtoken');
    final username = box.read('username');
    final fcmController = Get.find<FCMController>();

    if (fcmtoken != null) {
      final title = 'Hello $username';
      const message = 'Welcome to Fins Tracking!';
      await fcmController.sendFCMNotification(fcmtoken, title, message);
    }
  }
}

Future<void> _initializeNotifications() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showNotification(message);
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _showNotification(message);
}

Future<void> _showNotification(RemoteMessage message) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const androidDetails = AndroidNotificationDetails(
    'FINS_TRACKING_CHANNEL_ID',
    'Fins Tracking',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title,
    message.notification?.body,
    notificationDetails,
  );
}
