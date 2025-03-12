import 'package:flutter/material.dart';

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
  final VoidCallback? onTap;

  const CustomListTile(
      {super.key, required this.title, required this.leadingIcon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // let your container color show through
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300), // Light grey border
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
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
          ),
        ),
      ),
    );
  }
}
