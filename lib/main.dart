import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/screens/home_screen.dart';
import 'package:project/screens/reserve_history.dart';
import 'package:project/screens/user_profile_screen.dart';
import 'package:project/materials/app_theme.dart';
import 'package:project/materials/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeNotifier.themeMode,
            home: const MyApp(),
          );
        },
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int screenIndex = 0;
  String? formattedName;
  final screens = [HomeScreen(), ReserveHistory(), UserProfileScreen()];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          String fullName = doc.get('name');
          List<String> nameParts = fullName.split(' ');
          setState(() {
            formattedName = nameParts.length >= 2
                ? '${nameParts[0]}${nameParts[1][0]}'
                : fullName;
          });
        }
      } catch (e) {
        print('Error fetching user name: $e');
        setState(() {
          formattedName = user.email ?? 'Guest';
        });
      }
    }
  }

  List<String> get titles {
    String profileTitle = formattedName != null
        ? 'Hello, $formattedName'
        : 'Hello, ${FirebaseAuth.instance.currentUser?.email ?? 'Guest'}';
    return ['Agado', 'Trip', profileTitle];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            leading: screenIndex == 2
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundImage:
                          FirebaseAuth.instance.currentUser?.photoURL != null
                              ? NetworkImage(
                                  FirebaseAuth.instance.currentUser!.photoURL!)
                              : null,
                      child: FirebaseAuth.instance.currentUser?.photoURL == null
                          ? Icon(Icons.person,
                              color: Theme.of(context).iconTheme.color)
                          : null,
                    ),
                  )
                : const SizedBox(width: 15),
            title: Center(
              child: Text(
                titles[screenIndex],
                style: screenIndex == 0
                    ? GoogleFonts.lobster(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).appBarTheme.titleTextStyle?.color,
                      )
                    : Theme.of(context).appBarTheme.titleTextStyle,
              ),
            ),
            actions: [
              Icon(Icons.notifications_outlined, color: Colors.white),
              const SizedBox(width: 15),
            ],
            backgroundColor: Theme.of(context).primaryColor,
          ),
          body: screens[screenIndex],
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          bottomNavigationBar: Container(
            height: 70,
            color: Theme.of(context).primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => setState(() => screenIndex = 0),
                  child: Icon(Icons.home_outlined, color: Colors.white),
                ),
                GestureDetector(
                  onTap: () => setState(() => screenIndex = 1),
                  child: Image.asset(
                    'assets/logo/trip.png',
                    color: Colors.white,
                    height: 25,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => screenIndex = 2),
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
