import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart' as app_auth; // Use alias for AuthProvider
import 'screens/entry_screen.dart';
import 'screens/app_introduction_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/user_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC08sYKX6X9pafJPuXLmBiJjhtW6dC9RiA",
      appId: "1:85406590796:android:877f1d936c7fa2091511e9",
      messagingSenderId: "85406590796",
      projectId: "rahmath-b7dea",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Removed 'const' keyword

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => app_auth.AuthProvider(), // Use the alias here
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AdaptX',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          primaryColor: const Color(0xFF4A80F0),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A80F0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF3A3A3A),
            elevation: 0,
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return snapshot.hasData ? const HomeScreen() : const EntryScreen();
          },
        ),
        routes: {
          '/intro': (context) => const AppIntroductionScreen(),
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/profile_setup': (context) => const ProfileSetupScreen(),
          '/home': (context) => const HomeScreen(),
          '/accountSettings': (context) => const AccountSettingsScreen(),
          '/changePassword': (context) => const ChangePasswordScreen(),
          '/userDetails': (context) => const UserDetailsScreen(),
        },
      ),
    );
  }
}
