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

    // return Center(
    //   child: Column(
    //     mainAxisAlignment: MainAxisAlignment.center, // Centers items vertically
    //     crossAxisAlignment:
    //         CrossAxisAlignment.center, // Centers items horizontally
    //     mainAxisSize: MainAxisSize.min, // Only take as much space as needed
    //     children: [
    //       Text(
    //         user != null ? 'Hello ${user.email}' : 'You are not logged in.',
    //         style: TextStyle(fontSize: 20),
    //       ),
    //       SizedBox(height: 20),
    //       FloatingActionButton.extended(
    //         onPressed: () async {
    //           if (user == null) {
    //             // If no user is signed in, navigate to the login page.
    //             Navigator.push(
    //               context,
    //               MaterialPageRoute(builder: (context) => LoginPage()),
    //             );
    //           } else {
    //             // If a user is signed in, sign them out.
    //             await FirebaseAuth.instance.signOut();
    //             // Update the UI by calling setState so that currentUser reflects the change.
    //             setState(() {});
    //           }
    //         },
    //         label: Text(
    //           user == null ? 'Login' : 'Logout',
    //           style: TextStyle(color: Colors.white),
    //         ),
    //         backgroundColor: AppColors.primary,
    //       ),
    //     ],
    //   ),
    // );

    return Padding(
      padding: EdgeInsets.all(15),
      // child: ListView(
      //   children: [
      //     const SectionHeader(title: 'ข้อมูลการชำระเงิน'),
      //     const CustomListTile(title: 'Rewards & Wallet'),
      //     const CustomListTile(title: 'วิธีชำระเงิน'),
      //     const SectionHeader(title: 'การจัดการแอคเคาท์'),
      //     const CustomListTile(title: 'ข้อมูลส่วนตัว'),
      //     const CustomListTile(title: 'การตั้งค่าความปลอดภัย'),
      //     const SectionHeader(title: 'การตั้งค่า'),
      //     const CustomListTile(title: 'การตั้งค่าอุปกรณ์'),
      //   ],
      // ),
      child: ListView(
        children: const [
          const SectionHeader(title: 'ข้อมูลการชำระเงิน'),
          CustomListTile(
            title: 'ข้อมูลส่วนตัว',
            leadingIcon: Icons.person_outline,
          ),
          const SectionHeader(title: 'การจัดการแอคเคาท์'),
          CustomListTile(
            title: 'การตั้งค่าความปลอดภัย',
            leadingIcon: Icons.lock_outline,
          ),
          const SectionHeader(title: 'การตั้งค่า'),
          CustomListTile(
            title: 'ผู้ร่วมเดินทางกับท่าน',
            leadingIcon: Icons.group_outlined,
          ),
          // ... more tiles
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// Simple tile for each item in a section
class CustomListTile extends StatelessWidget {
  final String title;
  final IconData leadingIcon;

  const CustomListTile({
    super.key,
    required this.title,
    required this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300), // Light grey border
        borderRadius: BorderRadius.circular(8), // Rounded corners
      ),
      child: ListTile(
        leading: Icon(
          leadingIcon,
          color: Colors.black,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {},
      ),
    );
  }
}

// class CustomListTile extends StatelessWidget {
//   final String title;

//   const CustomListTile({super.key, required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       // Example: single bottom border
//       decoration: const BoxDecoration(
//         border: Border(
//           bottom: BorderSide(color: Colors.grey, width: 1),
//         ),
//       ),
//       // Or for a full border, use:
//       // decoration: BoxDecoration(
//       //   border: Border.all(color: Colors.grey, width: 1),
//       //   borderRadius: BorderRadius.all(Radius.circular(8)),
//       // ),
//       child: ListTile(
//         title: Text(title),
//         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//         onTap: () {
//           // Handle tap
//         },
//       ),
//     );
//   }
// }
