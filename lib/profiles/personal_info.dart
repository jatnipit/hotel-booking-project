import 'package:flutter/material.dart';
import 'package:project/materials/app_colors.dart';

class PersonalInfo extends StatefulWidget {
  const PersonalInfo({super.key});

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Personal Information',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          SizedBox(
            height: 20,
          ),
          // 1) Name
          InfoListTile(
            label: 'ชื่อ',
            data: 'KONGGASAME Jatnipit',
            placeholder: 'กรอกชื่อของท่าน',
            onTap: () {},
          ),

          // 2) Gender
          InfoListTile(
            label: 'เพศ',
            placeholder: 'เลือกเพศของท่าน',
            onTap: () {},
          ),

          // 3) Birthday
          InfoListTile(
            label: 'วันเกิด',
            placeholder: 'ระบุวันเกิดของท่าน',
            onTap: () {},
          ),

          // 4) Contact Info
          InfoListTile(
            label: 'Email',
            data: 'jatnpit.k@ku.th',
            placeholder: 'Enter your email',
            onTap: () {},
          ),

          // 5) Phone Number
          InfoListTile(
            label: 'หมายเลขโทรศัพท์',
            placeholder: 'ระบุหมายเลขโทรศัพท์',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class InfoListTile extends StatelessWidget {
  final String label;
  final String? data;
  final String placeholder;
  final VoidCallback? onTap;

  const InfoListTile({
    super.key,
    required this.label,
    required this.placeholder,
    this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = data != null && data!.isNotEmpty;

    return Material(
      color: Colors.transparent, // Required for ripple effect
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // Ensure proper padding and sizing for the ripple effect to display
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Expanded for the text part
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Data or placeholder
                    Text(
                      hasData ? data! : placeholder,
                      style: TextStyle(
                        color: hasData ? Colors.black : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
