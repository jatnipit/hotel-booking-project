import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added Firestore import
import 'package:project/materials/app_colors.dart';
import 'package:project/screens/home_screen.dart';
import 'package:project/screens/reserve_history.dart';
import 'package:project/screens/user_profile_screen.dart';
import 'package:project/materials/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.system,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int screenIndex = 0;
  String? formattedName; // State variable to hold the formatted name
  final screens = [HomeScreen(), ReserveHistory(), UserProfileScreen()];

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // Fetch the name when the widget initializes
  }

  // Method to fetch and format the user's name from Firestore
  Future<void> _fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          String fullName =
              doc.get('name'); // Assumes 'name' field in Firestore
          List<String> nameParts = fullName.split(' ');
          if (nameParts.length >= 2) {
            String firstName = nameParts[0];
            String lastInitial = nameParts[1][0];
            setState(() {
              formattedName = '$firstName$lastInitial'; // e.g., "JohnD"
            });
          } else {
            setState(() {
              formattedName = fullName; // Fallback if no last name
            });
          }
        }
      } catch (e) {
        print('Error fetching user name: $e');
        setState(() {
          formattedName = FirebaseAuth.instance.currentUser?.email ?? 'Guest';
        });
      }
    }
  }

  // Updated titles getter to use the formatted name
  List<String> get titles {
    String profileTitle = formattedName != null
        ? 'Hello, $formattedName'
        : 'Hello, ${FirebaseAuth.instance.currentUser?.email ?? 'Guest'}';
    return [
      'Agado',
      'Trip',
      profileTitle, // Use formatted name for UserProfileScreen
    ];
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
                          ? const Icon(Icons.person)
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
                      )
                    : const TextStyle(fontSize: 20),
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
              borderRadius: BorderRadius.zero,
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
