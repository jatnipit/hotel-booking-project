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
    debugShowCheckedModeBanner: false, // Remove this line when debugging
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Center(
              child: Text(
            'ชื่อโปรเจคเจ๋งๆ',
            style: TextStyle(
              color: Colors.white,
            ),
          )),
          leading: const SizedBox(
            width: 15,
          ),
          actions: const [
            Icon(
              Icons.notifications_outlined,
              color: Colors.white,
            ),
            SizedBox(
              width: 15,
            )
          ],
          backgroundColor: AppColors.primary,
        ),
        // Body
        body: screens[screenIndex],
        // Bottom Navigation Bar
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
                  child: Icon(Icons.home_outlined, color: Colors.white)),
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
                  )),
              GestureDetector(
                  onTap: () {
                    setState(() {
                      screenIndex = 2;
                    });
                  },
                  child: Icon(Icons.person_outline, color: Colors.white)),
            ],
          ),
        ));
  }
}
