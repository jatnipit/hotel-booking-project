import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/app_colors.dart';
import 'package:project/authen/login_page.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // Check the current user dynamically during build
    final user = FirebaseAuth.instance.currentUser;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centers items vertically
        crossAxisAlignment:
            CrossAxisAlignment.center, // Centers items horizontally
        mainAxisSize: MainAxisSize.min, // Only take as much space as needed
        children: [
          Text(
            user != null ? 'Hello ${user.email}' : 'You are not logged in.',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 20),
          FloatingActionButton.extended(
            onPressed: () async {
              if (user == null) {
                // If no user is signed in, navigate to the login page.
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              } else {
                // If a user is signed in, sign them out.
                await FirebaseAuth.instance.signOut();
                // Update the UI by calling setState so that currentUser reflects the change.
                setState(() {});
              }
            },
            label: Text(
              user == null ? 'Login' : 'Logout',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
