// ignore_for_file: prefer_const_constructors, unused_import

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fr.innoyadev.mkgodev/SplashScreen/splashScreen.dart';
import 'package:fr.innoyadev.mkgodev/download/takephotoModel.dart';
import 'package:fr.innoyadev.mkgodev/homeScreen/AdminPlanning.dart';
import 'package:fr.innoyadev.mkgodev/homeScreen/DriverPlanning.dart';
import 'package:fr.innoyadev.mkgodev/login/login.dart';
import 'package:fr.innoyadev.mkgodev/profile/takephotoControlller.dart';
import 'package:fr.innoyadev.mkgodev/signup/registerModel.dart';
import 'login/loginModel.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:firebase_core/firebase_core.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  );
  await FirebaseMessaging.instance.getInitialMessage();

  tzdata.initializeTimeZones();
  await GetStorage.init();
  GetStorage storage = GetStorage();
  // GetStorage box = GetStorage();
  if (storage.hasData('imagePath2')) {
    storage.remove('imagePath2');
  }

  Get.put(AuthController());
  Get.put(UserController());
  Get.put(TakePhotoController());
  Get.put(TakePhotoController2());
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ImageController imageController = Get.put(ImageController());

  final SignupController signupController = Get.put(SignupController());

  final LoginController loginController = Get.put(LoginController());

  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        useMaterial3: false
      ),
      debugShowCheckedModeBanner: false,
      title: 'MKGO Mobile',
      home: AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  @override
  _AppEntryPointState createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: FutureBuilder(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (_isDisposed || _scaffoldKey.currentContext == null) {
            // Widget has been disposed, return an empty container or null
            return Container();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            // Always show the splash screen first
            return SplashScreen();
          } else {
            if (snapshot.hasError) {
              return Container(); // Handle error
            } else {
              final bool isLoggedIn = snapshot.data as bool;
              if (isLoggedIn) {
                final List<String> roles =
                    Get.find<UserController>().user.value.roles;

                if (roles.contains('ROLE_ADMIN')) {
                  return LandingScreen1();
                } else if (roles.contains('ROLE_CHAUFFEUR')) {
                  return LandingScreen2();
                } else {
                  return Container();
                }
              } else {
                // Redirect to login screen
                return loginScreen();
              }
            }
          }
        },
      ),
    );
  }

  Future<bool> checkLoginStatus() async {
    final String token = Get.find<AuthController>().token.value;
    if (token.isNotEmpty) {
      Get.find<UserController>().loadUserFromStorage();
      return true;
    } else {
      return false;
    }
  }
}

class ImageController extends GetxController {
  RxString galleryFilePath = ''.obs;
  RxString cameraFilePath = ''.obs;

  void setGalleryFilePath(String? path) {
    galleryFilePath.value = path ?? '';
  }

  void setCameraFilePath(String? path) {
    cameraFilePath.value = path ?? '';
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
