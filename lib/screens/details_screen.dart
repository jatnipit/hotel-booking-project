import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  double discountPercentage = 0.0; // เก็บส่วนลดที่โหลดมาจาก SharedPreferences

  @override
  void initState() {
    super.initState();
    _getDiscountPercentage(); // โหลดส่วนลดเมื่อเริ่มต้นหน้าจอ
  }

  Future<void> _getDiscountPercentage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasDiscount = prefs.containsKey('discountPercentage');
    if (hasDiscount) {
      setState(() {
        discountPercentage = prefs.getDouble('discountPercentage') ?? 0.0;
      });
    } else {
      setState(() {
        discountPercentage = 0.0; // ไม่มีส่วนลดให้
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  int calculateTotalPrice(
      DateTime checkInDate, DateTime checkOutDate, int pricePerNight, double discountPercentage) {
    int nights = checkOutDate.difference(checkInDate).inDays;
    int totalPrice = nights * pricePerNight;

    // ถ้ามีส่วนลด (discountPercentage != 0) คำนวณราคาหลังจากหักส่วนลด
    if (discountPercentage > 0) {
      double discountAmount = totalPrice * discountPercentage;
      totalPrice -= discountAmount.round(); // หักส่วนลด
    }

    return totalPrice;
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
        } else {
          if (picked.isBefore(checkInDate ?? today)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Check-out date must be after check-in date.')),
            );
            return;
          }
          checkOutDate = picked;
        }
      });
    }
  }

  void _bookNow() {
    if (checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select check-in and check-out dates.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Information for booking'),
          content: UserInfoForm(
            onSubmit:
                (String name, String surname, String phone, String email) {
              _saveToFirebase(name, surname, phone, email);
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  Future<void> _saveToFirebase(
      String name, String surname, String phone, String email) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String? userID = user?.uid;

      await FirebaseFirestore.instance.collection('bookings').add({
        'userID': userID,
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
        'checkInDate': checkInDate?.toString(),
        'checkOutDate': checkOutDate?.toString(),
        'roomName': widget.roomData['name'],
        'pricePerNight': widget.roomData['pricePerNight'],
        'discountPercentage': discountPercentage, // ใช้ส่วนลดจาก SharedPreferences
        'bookingTime': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book success.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrls =
        List<String>.from(widget.roomData['roomImages'] ?? []);
    int totalPrice = 0;
    if (checkInDate != null && checkOutDate != null) {
      int pricePerNight =
          int.tryParse(widget.roomData['pricePerNight'].toString()) ?? 0;
      totalPrice =
          calculateTotalPrice(checkInDate!, checkOutDate!, pricePerNight, discountPercentage);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.roomData['name'] ?? 'Room Details')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imageUrls.isEmpty
                  ? Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(
                          child:
                              Icon(Icons.image, color: Colors.white, size: 50)),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrls[index],
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          left: 10,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () {
                              if (_pageController.hasClients) {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                        ),
                        Positioned(
                          right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.white),
                            onPressed: () {
                              if (_pageController.hasClients) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
              Text(
                '${widget.roomData['name'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('Location: ${widget.roomData['location'] ?? 'Unknown'}'),
              const SizedBox(height: 10),
              Text('Price/Night: ${widget.roomData['pricePerNight']} ฿',
                  style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 10),
              Text('Facilities: ${widget.roomData['Facilities'] ?? 'Unknown'}'),
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
                                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                  'Total Price: $totalPrice ฿',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _bookNow,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.green,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.book_online_outlined, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Book',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
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
  final Function(String name, String surname, String phone, String email)
      onSubmit;

  const UserInfoForm({super.key, required this.onSubmit});

  @override
  _UserInfoFormState createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  void _submitForm() {
    String name = _nameController.text.trim();
    String surname = _surnameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();

    if (name.isEmpty || surname.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter information.')),
      );
      return;
    }

    widget.onSubmit(name, surname, phone, email);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        TextField(
          controller: _surnameController,
          decoration: const InputDecoration(labelText: 'Surname'),
        ),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Tel'),
        ),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}