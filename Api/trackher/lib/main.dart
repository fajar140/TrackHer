import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:trackher/password_reset.dart';
import 'package:trackher/request_password_reset.dart';
import 'package:trackher/verify_password_reset_code.dart';
import 'login.dart';
import 'signup.dart';
import 'home.dart';
import 'profile.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackHer',
      theme: ThemeData(
        fontFamily: 'Poppins',
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: const Color(0xFFeb858d), // Cursor color
          selectionColor: const Color(0xFFeb858d)
              .withOpacity(0.3), // Selection highlight color
          selectionHandleColor:
              const Color(0xFFeb858d), // Selection handle color
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFeb858d), width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
              fontFamily: 'Poppins'), // Use bodyLarge instead of bodyText1
          bodyMedium: TextStyle(
              fontFamily: 'Poppins'), // Use bodyMedium instead of bodyText2
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFeb858d); // Custom color when selected
            }
            return Colors.grey; // Default color when not selected
          }),
        ),
      ),
      initialRoute: '/', // Set initial route to welcome page
      routes: {
        '/': (context) => WelcomePage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
        '/profile': (context) => ProfilePage(),
        '/request_password_reset': (context) => PasswordResetRequestPage(),
        '/verify_password_reset_code': (context) =>
            VerifyPasswordResetCodePage(),
        '/password_reset': (context) => PasswordResetPage(),
      },
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Image.asset('assets/logo.png'),
              const Text(
                'Welcome to Track Her!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Trackher will help you to track your menstrual cycle with ease and accuracy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 260),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Get Started',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFeb858d),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              /*
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child:
                    const Text('LOGIN', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFeb858d),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: const Text('SIGN UP',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFeb858d),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ), */
            ],
          ),
        ),
      ),
    );
  }
}
