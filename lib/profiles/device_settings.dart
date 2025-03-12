import 'package:flutter/material.dart';
import 'package:project/materials/app_colors.dart';
import 'package:project/materials/custom_list_tile.dart';

class DeviceSettings extends StatefulWidget {
  const DeviceSettings({super.key});

  @override
  State<DeviceSettings> createState() => _DeviceSettingsState();
}

class _DeviceSettingsState extends State<DeviceSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView(
          children: [
            SectionHeader(title: 'Device setting'),
            CustomListTile(title: 'Theme', leadingIcon: Icons.invert_colors)
          ],
        ),
      ),
    );
  }
}
