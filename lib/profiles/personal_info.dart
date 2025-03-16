import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PersonalInfo extends StatefulWidget {
  final String userId;
  const PersonalInfo({super.key, required this.userId});

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  String? name;
  String? gender;
  DateTime? birthday;
  String? email;
  String? phoneNumber;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late DocumentReference _userDoc;

  @override
  void initState() {
    super.initState();
    _userDoc = _firestore.collection('users').doc(widget.userId);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot doc = await _userDoc.get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          name = data['name'];
          gender = data['gender'];
          if (data['birthday'] != null)
            birthday = (data['birthday'] as Timestamp).toDate();
          email = data['email'];
          phoneNumber = data['phoneNumber'];
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _showTextEditDialog(
      String title, String? currentValue, Function(String) onSave) {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter $title'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGenderSelectionDialog() {
    String? selectedGender = gender;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Gender'),
        content: DropdownButton<String>(
          value: selectedGender,
          items: ['Male', 'Female', 'Other'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (value) => selectedGender = value,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => gender = selectedGender);
              _updateField('gender', selectedGender);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateField(String field, dynamic value) async {
    try {
      await _userDoc.set({field: value}, SetOptions(merge: true));
    } catch (e) {
      print('Error updating field: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InfoListTile(
            label: 'Name',
            data: name,
            placeholder: 'Enter your name',
            onTap: () => _showTextEditDialog('Edit Name', name, (newValue) {
              setState(() => name = newValue);
              _updateField('name', newValue);
            }),
          ),
          const SizedBox(height: 10),
          InfoListTile(
            label: 'Gender',
            data: gender,
            placeholder: 'Select your gender',
            onTap: _showGenderSelectionDialog,
          ),
          const SizedBox(height: 10),
          InfoListTile(
            label: 'Date of birth',
            data: birthday != null
                ? DateFormat('yyyy-MM-dd').format(birthday!)
                : null,
            placeholder: 'Enter your date of birth',
            onTap: () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: birthday ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                setState(() => birthday = selectedDate);
                _updateField('birthday', Timestamp.fromDate(selectedDate));
              }
            },
          ),
          const SizedBox(height: 10),
          InfoListTile(
            label: 'Email',
            data: email,
            placeholder: 'Enter your email',
            onTap: () => _showTextEditDialog('Edit Email', email, (newValue) {
              setState(() => email = newValue);
              _updateField('email', newValue);
            }),
          ),
          const SizedBox(height: 10),
          InfoListTile(
            label: 'Phone number',
            data: phoneNumber,
            placeholder: 'Add your phone number',
            onTap: () => _showTextEditDialog('Edit Phone Number', phoneNumber,
                (newValue) {
              setState(() => phoneNumber = newValue);
              _updateField('phoneNumber', newValue);
            }),
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

  const InfoListTile(
      {super.key,
      required this.label,
      required this.placeholder,
      this.data,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasData = data != null && data!.isNotEmpty;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: Theme.of(context).splashColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      hasData ? data! : placeholder,
                      style: TextStyle(
                        color: hasData
                            ? Theme.of(context).textTheme.bodyMedium?.color
                            : Colors.grey,
                        fontSize: 17,
                        fontWeight: hasData ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Theme.of(context).iconTheme.color),
            ],
          ),
        ),
      ),
    );
  }
}
