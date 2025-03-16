import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final VoidCallback? onTap;
  final Color? titleColor; // New parameter for custom title color

  const CustomListTile({
    super.key,
    required this.title,
    required this.leadingIcon,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: ListTile(
            leading: Icon(
              leadingIcon,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: titleColor ??
                        Theme.of(context).textTheme.bodyLarge?.color,
                  ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
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
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
