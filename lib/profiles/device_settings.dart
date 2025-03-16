import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/materials/app_colors.dart';
import 'package:project/materials/theme_notifier.dart';
import 'package:project/materials/custom_list_tile.dart';

class DeviceSettings extends StatefulWidget {
  final String userId;

  const DeviceSettings({super.key, required this.userId});

  @override
  State<DeviceSettings> createState() => _DeviceSettingsState();
}

class _DeviceSettingsState extends State<DeviceSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Appearance'),
            CustomListTile(
              title: 'Theme',
              leadingIcon: Icons.brightness_6,
              onTap: () {
                _showThemeSelectionDialog(context);
              },
            ),
            // Add other settings here if needed
          ],
        ),
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: themeNotifier.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeNotifier.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeNotifier.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeNotifier.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                value: ThemeMode.system,
                groupValue: themeNotifier.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeNotifier.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
