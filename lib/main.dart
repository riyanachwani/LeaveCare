import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:leavecare/pages/signup.dart';
import 'pages/login.dart';
import "utils/routes.dart";
import "widget/themes.dart";
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBA8Bxam2mYb44m0DeVuVl246l_AiwsYZg",
            appId: "1:273070570620:web:08476712dccefa61109df9",
            messagingSenderId: "273070570620",
            projectId: "leavecare-7a6b4"));
            
            }
  await Firebase.initializeApp().then((_) {
    print("Firebase initialized successfully!");
  }).catchError((error) {
    print("Error initializing Firebase: $error");
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.light,
      theme: MyTheme.lightTheme(context),
      darkTheme: MyTheme.darkTheme(context),
      debugShowCheckedModeBanner:
          false, //to remove the debug that is shown on app
      initialRoute: MyRoutes.homeRoute,
      routes: {
        "/": (context) => HomePage(), //object - can also use new keyword
        MyRoutes.homeRoute: (context) => const HomePage(),
        MyRoutes.signupRoute: (context) => const SignupPage(),
        MyRoutes.loginRoute: (context) => const LoginPage(),
      },
    );
  }
}
