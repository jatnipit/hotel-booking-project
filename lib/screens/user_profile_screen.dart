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
    return Center(
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => LoginPage()));
        },
        label: Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
