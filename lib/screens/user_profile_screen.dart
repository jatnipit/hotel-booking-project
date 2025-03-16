import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/profiles/personal_info.dart';
import 'package:project/profiles/device_settings.dart';
import 'package:project/authen/login_page.dart';
import 'package:project/materials/custom_list_tile.dart'; // Contains SectionHeader and CustomListTile

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: ListView(
          children: [
            // Conditionally show Account Management section if user is signed in
            if (user != null) ...[
              SectionHeader(title: 'Account Management'),
              CustomListTile(
                title: 'Personal information',
                leadingIcon: Icons.person_outlined,
                onTap: () {
                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PersonalInfo(userId: userId),
                      ),
                    );
                  }
                },
              ),
            ],

            // Preferences section (always visible)
            SectionHeader(title: 'Preferences'),
            CustomListTile(
              title: 'Personal preferences',
              leadingIcon: Icons.settings_outlined,
              onTap: () {
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeviceSettings(userId: userId),
                    ),
                  );
                }
              },
            ),

            // Spacing before login/logout button
            const SizedBox(height: 28),

            // Conditional Login/Logout Button
            user != null
                ? Container(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          // Show a confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text('Confirm Logout'),
                                content: const Text(
                                    'Are you sure you want to log out?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text(
                                      'Log out',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          // If confirmed, sign out
                          if (confirm == true) {
                            await FirebaseAuth.instance.signOut();
                            setState(() {}); // Update UI after sign out
                          }
                        },
                        child: const ListTile(
                          title: Center(
                            child: Text(
                              'Log out',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        child: const ListTile(
                          title: Center(
                            child: Text(
                              'Log in',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
