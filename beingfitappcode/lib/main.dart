import 'dart:async';
import 'dart:io';
import 'package:amazone/animationsplash/animationsplash.dart';
import 'package:amazone/widget/nativehelper.dart';
import 'package:amazone/widget/webviewpage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

final InAppLocalhostServer localhostServer =
    InAppLocalhostServer(documentRoot: 'assets/images', port: 9234);

@pragma('vm:entry-point')
Future<String> _downloadAndSaveImage(String url, String fileName) async {
  var directory = await getApplicationDocumentsDirectory();
  var filePath = '${directory.path}/$fileName';
  var response = await http.get(Uri.parse(url));

  var file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

@pragma('vm:entry-point')
Future<void> generateImageNotication(
    String title, String msg, String image, String type, String id) async {
  var largeIconPath = await _downloadAndSaveImage(image, 'largeIcon');
  var bigPicturePath = await _downloadAndSaveImage(image, 'bigPicture');
  var bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath),
      hideExpandedLargeIcon: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: msg,
      htmlFormatSummaryText: true);
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'high_importance_channel',
    'Absher Notifications',
    channelDescription: 'description',
    largeIcon: FilePathAndroidBitmap(largeIconPath),
    styleInformation: bigPictureStyleInformation,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );
  var ios = const DarwinNotificationDetails(
    presentSound: true,
  );
  var platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics, iOS: ios);
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().minute + DateTime.now().second,
    title,
    msg,
    platformChannelSpecifics,
    payload: '$type,$id',
  );
}

@pragma('vm:entry-point')
Future<void> generateSimpleNotication(
    String title, String msg, String type, String id) async {
  var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
    'high_importance_channel',
    'Absher Notifications',
    channelDescription: 'description',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().minute + DateTime.now().second,
    title,
    msg,
    platformChannelSpecifics,
    payload: '$type,$id',
  );
}

@pragma('vm:entry-point')
Future<void> _showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel',
    'Notifications',
    channelDescription: "description",
    importance: Importance.max,
    playSound: true,
    priority: Priority.high,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().minute + DateTime.now().second,
    title,
    body,
    platformChannelSpecifics,
    payload: 'item x',
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  var data = message.notification!;

  var title = data.title.toString();
  var body = data.body.toString();
  var image = message.data['image'] ?? '';

  var type = message.data['type'] ?? '';
  var id = '';
  id = message.data['url'] ?? '';

  if (type == 'url') {
    if (image != null && image != 'null' && image != '') {
      await generateImageNotication(title, body, image, type, id);
    } else {
      await generateSimpleNotication(title, body, type, id);
    }
  } else if (image != null && image != 'null' && image != '') {
    await generateImageNotication(title, body, image, type, id);
  } else {
    await generateSimpleNotication(title, body, type, id);
  }
}

@pragma('vm:entry-point')
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
@pragma('vm:entry-point')
FirebaseMessaging messaging = FirebaseMessaging.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await localhostServer.start();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
      iOS: DarwinInitializationSettings()));

  if (Platform.isIOS) {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  } else {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .requestPermission();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({
    super.key,
  });
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: navigatorKey,
      title: "BeingFit",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        keys: navigatorKey,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final keys;
  const MyHomePage({
    super.key,
    this.keys,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        var data = message.notification!;

        var title = data.title.toString();
        var body = data.body.toString();
        var image = message.data['image'] ?? '';

        var type = message.data['type'] ?? '';
        var id = '';
        id = message.data['url'] ?? '';

        if (type == 'url') {
          if (image != null && image != 'null' && image != '') {
            await generateImageNotication(title, body, image, type, id);
          } else {
            await generateSimpleNotication(title, body, type, id);
          }
        } else if (image != null && image != 'null' && image != '') {
          await generateImageNotication(title, body, image, type, id);
        } else {
          await generateSimpleNotication(title, body, type, id);
        }
      },
    );
    FirebaseMessaging.onBackgroundMessage((message) {
      return _firebaseMessagingBackgroundHandler(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      var id = '';
      var type = message.data['type'] ?? '';

      id = message.data['url'] ?? '';

      if (type == 'url') {
        widget.keys.currentState!.pushReplacement(
          MaterialPageRoute<void>(
              builder: (BuildContext context) => WebViewMini(
                    url: id,
                  )),
        );
      } else {
        //
        widget.keys.currentState!.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return WebViewMini(
                url: "http://localhost:9234/index.html",
              );
            },
          ),
        );
      }
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) async {
      if (message != null) {
        var type = message.data['type'] ?? '';
        var id = '';
        id = message.data['url'] ?? '';

        if (type == 'url') {
          widget.keys.currentState!.pushReplacement(
            MaterialPageRoute<void>(
                builder: (BuildContext context) => WebViewMini(
                      url: "http://localhost:9234/index.html",
                    )),
          );
        }
        // Provider.of<SettingProvider>(context, listen: false)
        //     .setPrefrenceBool(ISFROMBACK, false);
      }
    });
    sub();
  }

  void sub() async {
    var pref = await SharedPreferences.getInstance();
    bool sb = pref.getBool('sub') ?? false;
    if (!sb) {
      await messaging.subscribeToTopic('noti');
      await pref.setBool('sub', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.scale(
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(seconds: 2),
      backgroundColor: HexColor('#121717'),
      onEnd: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) {
              return WebViewMini(
                url: "http://localhost:9234/index.html",
              );
            },
          ),
        );
      },
      defaultNextScreen: const WebViewMini(
        url: "https://yovotomejor.com/",
      ),
      childWidget: Image.asset(
        "assets/images/logo-nav.png",
        filterQuality: FilterQuality.high,
        height: 80,
        width: 80,
      ),
    );
  }
}
