import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:project/screens/edit_booking_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReserveHistory extends StatefulWidget {
  const ReserveHistory({super.key});

  @override
  State<ReserveHistory> createState() => _ReserveHistoryState();
}

class _ReserveHistoryState extends State<ReserveHistory> {
  double discountPercentage = 0.0; // ค่าเริ่มต้นของส่วนลดเป็น 0%

  // ฟังก์ชันในการดึงค่าส่วนลดจาก SharedPreferences
  Future<void> _loadDiscount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // ตรวจสอบว่าไม่มีการบันทึกส่วนลดใน SharedPreferences หรือยังไม่ได้กรอกโค้ด
    double savedDiscount = prefs.getDouble('discountPercentage') ?? 0.0;

    setState(() {
      // หากไม่พบส่วนลด (หรือยังไม่ได้กรอกโค้ด) จะตั้งเป็น 0.0
      discountPercentage = savedDiscount > 0.0 ? savedDiscount : 0.0;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDiscount(); // โหลดส่วนลดเมื่อเริ่มหน้าจอ
  }

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? userID = user?.uid;

    if (userID == null) {
      return [];
    }

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userID', isEqualTo: userID)
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  int calculateTotalPrice(String checkIn, String checkOut, int pricePerNight) {
    DateTime checkInDate = DateTime.parse(checkIn);
    DateTime checkOutDate = DateTime.parse(checkOut);
    int nights = checkOutDate.difference(checkInDate).inDays;

    // คำนวณราคาเต็มก่อนหักส่วนลด
    int totalPrice = nights * pricePerNight;

    // คำนวณส่วนลด
    double discountAmount = totalPrice * discountPercentage;

    // คำนวณราคาใหม่หลังหักส่วนลด
    double finalPrice = totalPrice - discountAmount;

    return finalPrice.round();  // ปัดเศษเพื่อให้เป็นจำนวนเต็ม
  }

  int calculateNights(String checkIn, String checkOut) {
    DateTime checkInDate = DateTime.parse(checkIn);
    DateTime checkOutDate = DateTime.parse(checkOut);
    return checkOutDate.difference(checkInDate).inDays;
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking deleted')),
      );
      setState(() {});
    } catch (e) {
      print('Error deleting booking: $e');
    }
  }

  String getRemainingTime(Timestamp? bookingTimestamp) {
    if (bookingTimestamp == null) return 'Not editable';
    DateTime bookingTime = bookingTimestamp.toDate();
    DateTime expirationTime = bookingTime.add(const Duration(minutes: 15));
    DateTime now = DateTime.now();

    if (now.isBefore(expirationTime)) {
      String formattedTime =
          DateFormat('HH:mm dd MMM yyyy').format(expirationTime);
      return 'Editable until $formattedTime';
    } else {
      return 'Edit window closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>( 
        future: fetchBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No reservation history found.'));
          }

          var bookings = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var booking = bookings[index];
              int totalPrice = calculateTotalPrice(
                booking['checkInDate'],
                booking['checkOutDate'],
                int.parse(booking['pricePerNight'].toString()),
              );
              int nights = calculateNights(
                booking['checkInDate'],
                booking['checkOutDate'],
              );

              Timestamp? bookingTimestamp = booking['bookingTime'];
              bool canEdit = bookingTimestamp != null &&
                  DateTime.now()
                          .difference(bookingTimestamp.toDate())
                          .inMinutes <
                      15;
              String remainingTime = getRemainingTime(bookingTimestamp);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                elevation: 5,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    ListTile(
                      title: Text(
                        booking['roomName'] ?? 'Unknown Room',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${booking['name']} ${booking['surname']}'),
                          Text('Check-in: ${DateFormat('dd MMM yyyy').format(DateTime.parse(booking['checkInDate']))}'),
                          Text('Check-out: ${DateFormat('dd MMM yyyy').format(DateTime.parse(booking['checkOutDate']))}'),
                          Text('Price/Night: ${booking['pricePerNight']} ฿'),
                          // แสดงราคาหลังหักส่วนลด
                          Text(
                            'Total Price : $totalPrice ฿',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          if (discountPercentage > 0)
                            Text(
                              'Discount: ${discountPercentage * 100}%',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            remainingTime,
                            style: TextStyle(
                              color: canEdit ? Colors.blue : Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canEdit)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditBookingScreen(booking: booking),
                                  ),
                                ).then((_) {
                                  setState(() {});
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteBooking(booking['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 12,
                      child: Text(
                        '$nights night${nights != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
