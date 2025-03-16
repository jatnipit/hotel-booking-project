import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project/main.dart';
import 'package:project/screens/edit_booking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> roomData;
  const DetailScreen({super.key, required this.roomData});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final PageController _pageController = PageController();
  DateTime? checkInDate;
  DateTime? checkOutDate;

  String _formatDate(DateTime? date) =>
      date == null ? 'Select date' : DateFormat('dd/MM/yyyy').format(date);

  int calculateTotalPrice(
      DateTime checkInDate, DateTime checkOutDate, int pricePerNight) {
    return checkOutDate.difference(checkInDate).inDays * pricePerNight;
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    DateTime today = DateTime.now();
    DateTime initialDate =
        isCheckIn ? today : (checkInDate ?? today).add(const Duration(days: 1));
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

  // Fetch user's personal info from Firestore and split the full name into first and last names.
  Future<Map<String, String>> _fetchUserPersonalInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String fullName = data['name'] ?? '';
        List<String> nameParts = fullName.split(' ');
        String firstName = nameParts.isNotEmpty ? nameParts.first : '';
        String lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        return {
          'firstName': firstName,
          'lastName': lastName,
          'phone': data['phoneNumber'] ?? '',
          'email': data['email'] ?? '',
        };
      }
    }
    return {'firstName': '', 'lastName': '', 'phone': '', 'email': ''};
  }

  // When booking, first fetch user info and prepopulate the form
  void _bookNow() async {
    if (checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select check-in and check-out dates.')),
      );
      return;
    }

    // Fetch user's personal info from Firestore and split the name
    Map<String, String> personalInfo = await _fetchUserPersonalInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Information for booking'),
        content: UserInfoForm(
          initialName: personalInfo['firstName']!,
          initialSurname: personalInfo['lastName']!,
          initialPhone: personalInfo['phone']!,
          initialEmail: personalInfo['email']!,
          onSubmit: (name, surname, phone, email, discountCode) {
            _saveToFirebase(name, surname, phone, email, discountCode);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _saveToFirebase(String name, String surname, String phone,
      String email, String discountCode) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String? userID = user?.uid;
      double discountPercentage = 0.0;

      if (discountCode.isNotEmpty) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('discount_codes')
            .where('code', isEqualTo: discountCode)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          var discountData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;
          discountPercentage = discountData['percentage']?.toDouble() ?? 0.0;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid discount code.')));
          return;
        }
      }

      int pricePerNight =
          int.tryParse(widget.roomData['pricePerNight'].toString()) ?? 0;
      int totalPrice =
          calculateTotalPrice(checkInDate!, checkOutDate!, pricePerNight);
      double discountAmount = totalPrice * discountPercentage;
      int finalPrice = (totalPrice - discountAmount).round();

      await FirebaseFirestore.instance.collection('bookings').add({
        'userID': userID,
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
        'checkInDate': checkInDate?.toString(),
        'checkOutDate': checkOutDate?.toString(),
        'roomName': widget.roomData['name'],
        'pricePerNight': pricePerNight,
        'totalPrice': finalPrice,
        'bookingTime': FieldValue.serverTimestamp(),
        'isCancelled': false,
        'discountPercentage': discountPercentage,
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Book success.')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrls =
        List<String>.from(widget.roomData['roomImages'] ?? []);
    int totalPrice = (checkInDate != null && checkOutDate != null)
        ? calculateTotalPrice(checkInDate!, checkOutDate!,
            int.tryParse(widget.roomData['pricePerNight'].toString()) ?? 0)
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomData['name'] ?? 'Room Details'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imageUrls.isEmpty
                  ? Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.surface,
                      child: Center(
                          child: Icon(Icons.image,
                              color: Theme.of(context).iconTheme.color,
                              size: 50)),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(imageUrls[index],
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back,
                                color: Theme.of(context).iconTheme.color),
                            onPressed: () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          child: IconButton(
                            icon: Icon(Icons.arrow_forward,
                                color: Theme.of(context).iconTheme.color),
                            onPressed: () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
              Text(
                '${widget.roomData['name'] ?? 'Unknown'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text('Location: ${widget.roomData['location'] ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              Text('Price/Night: ${widget.roomData['pricePerNight']} ฿',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.green)),
              const SizedBox(height: 10),
              Text('Facilities: ${widget.roomData['Facilities'] ?? 'Unknown'}',
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
              if (checkInDate != null && checkOutDate != null)
                Text(
                  'Estimated Total Price: $totalPrice ฿ (Discount will be applied upon booking)',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _bookNow,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_online_outlined,
                          color: Theme.of(context).colorScheme.onPrimary),
                      const SizedBox(width: 10),
                      Text('Book',
                          style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onPrimary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserInfoForm extends StatefulWidget {
  final Function(String name, String surname, String phone, String email,
      String discountCode) onSubmit;
  final String initialName;
  final String initialSurname;
  final String initialPhone;
  final String initialEmail;
  const UserInfoForm({
    super.key,
    required this.onSubmit,
    this.initialName = '',
    this.initialSurname = '',
    this.initialPhone = '',
    this.initialEmail = '',
  });

  @override
  State<UserInfoForm> createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  final _discountCodeController = TextEditingController();
  String _discountMessage = '';
  bool _isDiscountValid = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _surnameController = TextEditingController(text: widget.initialSurname);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _emailController = TextEditingController(text: widget.initialEmail);
    _discountCodeController.addListener(_validateDiscountCode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _discountCodeController.removeListener(_validateDiscountCode);
    _discountCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateDiscountCode() async {
    String discountCode = _discountCodeController.text.trim();
    if (discountCode.isEmpty) {
      setState(() {
        _discountMessage = '';
        _isDiscountValid = false;
      });
      return;
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('discount_codes')
          .where('code', isEqualTo: discountCode)
          .get();
      setState(() {
        if (querySnapshot.docs.isNotEmpty) {
          var discountData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;
          double discountPercentage =
              discountData['percentage']?.toDouble() ?? 0.0;
          _discountMessage =
              'Valid discount code! (${discountPercentage * 100}% off)';
          _isDiscountValid = true;
        } else {
          _discountMessage = 'Invalid discount code.';
          _isDiscountValid = false;
        }
      });
    } catch (e) {
      setState(() {
        _discountMessage = 'Error validating code.';
        _isDiscountValid = false;
      });
    }
  }

  void _submitForm() {
    String name = _nameController.text.trim();
    String surname = _surnameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String discountCode = _discountCodeController.text.trim();

    if (name.isEmpty || surname.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter all required information.')));
      return;
    }

    if (discountCode.isNotEmpty && !_isDiscountValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please enter a valid discount code or leave it empty.')),
      );
      return;
    }

    widget.onSubmit(name, surname, phone, email, discountCode);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
                labelText: 'First Name',
                labelStyle: Theme.of(context).textTheme.bodyMedium),
          ),
          TextField(
            controller: _surnameController,
            decoration: InputDecoration(
                labelText: 'Last Name',
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
          TextField(
            controller: _discountCodeController,
            decoration: InputDecoration(
                labelText: 'Discount Code (Optional)',
                labelStyle: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: 5),
          Text(
            _discountMessage,
            style: TextStyle(
              color: _isDiscountValid ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Confirm Book'),
          ),
        ],
      ),
    );
  }
}
