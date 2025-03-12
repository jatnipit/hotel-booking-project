import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project/app_colors.dart';
import 'package:project/authen/login_page.dart';
import 'package:project/screens/home_screen.dart';
import 'package:project/screens/reserve_history.dart';
import 'package:project/screens/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int screenIndex = 0;
  final screens = [HomeScreen(), ReserveHistory(), UserProfileScreen()];

  List<String> get titles => [
        'ชื่อโปรเจคเจ๋งๆ',
        'Trip',
        'Hello, ${FirebaseAuth.instance.currentUser?.email ?? 'Guest'}'
      ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Rebuilds whenever the auth state changes
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
                          ? const Icon(Icons.person)
                          : null,
                    ),
                  )
                : const SizedBox(width: 15),
            title: Center(
              child: Text(
                titles[screenIndex],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            actions: const [
              Icon(Icons.notifications_outlined, color: Colors.white),
              SizedBox(width: 15),
            ],
            backgroundColor: AppColors.primary,
          ),
          body: screens[screenIndex],
          backgroundColor: Colors.white,
          bottomNavigationBar: Container(
            height: 70,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              color: AppColors.primary,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      screenIndex = 0;
                    });
                  },
                  child: const Icon(Icons.home_outlined, color: Colors.white),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      screenIndex = 1;
                    });
                  },
                  child: Image.asset(
                    'assets/logo/trip.png',
                    color: Colors.white,
                    height: 25,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      screenIndex = 2;
                    });
                  },
                  child: const Icon(Icons.person_outline, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
