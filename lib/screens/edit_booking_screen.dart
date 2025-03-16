import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class EditBookingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  const EditBookingScreen({super.key, required this.booking});

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  DateTime? checkInDate;
  DateTime? checkOutDate;
  String remainingTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.booking['name']);
    _surnameController = TextEditingController(text: widget.booking['surname']);
    _phoneController = TextEditingController(text: widget.booking['phone']);
    _emailController = TextEditingController(text: widget.booking['email']);
    checkInDate = DateTime.parse(widget.booking['checkInDate']);
    checkOutDate = DateTime.parse(widget.booking['checkOutDate']);
    _updateRemainingTime();
    _timer =
        Timer.periodic(Duration(seconds: 1), (timer) => _updateRemainingTime());
  }

  void _updateRemainingTime() {
    Timestamp? bookingTimestamp = widget.booking['bookingTime'];
    if (bookingTimestamp != null) {
      DateTime bookingTime = bookingTimestamp.toDate();
      DateTime now = DateTime.now();
      int secondsRemaining = (15 * 60) - now.difference(bookingTime).inSeconds;
      if (secondsRemaining > 0) {
        int minutes = secondsRemaining ~/ 60;
        int seconds = secondsRemaining % 60;
        setState(() => remainingTime =
            'Time remaining: $minutes:${seconds.toString().padLeft(2, '0')}');
      } else {
        setState(() => remainingTime = 'Edit window closed');
        _timer?.cancel();
        Navigator.pop(context);
      }
    } else {
      setState(() => remainingTime = 'No booking time available');
    }
  }

  String _formatDate(DateTime? date) =>
      date == null ? 'Select date' : DateFormat('dd/MM/yyyy').format(date);

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    DateTime today = DateTime.now();
    DateTime initialDate = isCheckIn
        ? (checkInDate ?? today)
        : (checkOutDate ?? (checkInDate ?? today).add(const Duration(days: 1)));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          checkInDate = picked;
          if (checkOutDate != null && checkOutDate!.isBefore(picked))
            checkOutDate = null;
        } else if (!picked.isBefore(checkInDate ?? today)) {
          checkOutDate = picked;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Check-out date must be after check-in date.')),
          );
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select check-in and check-out dates.')));
      return;
    }
    String name = _nameController.text.trim();
    String surname = _surnameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();

    if (name.isEmpty || surname.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields.')));
      return;
    }

    Timestamp? bookingTimestamp = widget.booking['bookingTime'];
    if (bookingTimestamp != null &&
        DateTime.now().difference(bookingTimestamp.toDate()).inMinutes >= 15) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The 15-minute edit window has expired.')));
      Navigator.pop(context);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking['id'])
          .update({
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
        'checkInDate': checkInDate!.toString(),
        'checkOutDate': checkOutDate!.toString(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking updated successfully.')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating booking.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Booking'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can edit this booking within 15 minutes of booking. $remainingTime',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Room: ${widget.booking['roomName']}',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 10),
              Text('Price per night: ${widget.booking['pricePerNight']} ฿',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(context, true),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                  text: 'Check-in : ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: _formatDate(checkInDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(context, false),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                  text: 'Check-out : ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: _formatDate(checkOutDate)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: Theme.of(context).textTheme.bodyMedium),
              ),
              TextField(
                controller: _surnameController,
                decoration: InputDecoration(
                    labelText: 'Surname',
                    labelStyle: Theme.of(context).textTheme.bodyMedium),
              ),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: 'Tel',
                    labelStyle: Theme.of(context).textTheme.bodyMedium),
              ),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
