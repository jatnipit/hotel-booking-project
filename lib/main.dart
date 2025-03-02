import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project/authen/login_page.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Firebase Authentication Example')),
      ),
      body: Center(child: Text('Welcome')),
    );
  }
}
