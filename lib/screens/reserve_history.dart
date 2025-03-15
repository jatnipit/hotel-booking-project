import 'package:flutter/material.dart';
// import 'package:project/materials/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReserveHistory extends StatefulWidget {
  const ReserveHistory({super.key});

  @override
  _ReserveHistoryState createState() => _ReserveHistoryState();
}

class _ReserveHistoryState extends State<ReserveHistory> {
  // ดึงข้อมูลการจองที่ตรงกับ userID ของผู้ใช้ที่ล็อกอินอยู่
  Future<List<Map<String, dynamic>>> fetchBookings() async {
    // ดึง userID จาก Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;
    String? userID = user?.uid;

    if (userID == null) {
      // ถ้าผู้ใช้ยังไม่ได้ล็อกอิน
      return [];
    }

    // ดึงข้อมูลการจองที่มี userID ตรงกับผู้ใช้ที่ล็อกอินอยู่
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
    return nights * pricePerNight;
  }

  // ฟังก์ชันลบการจอง
  Future<void> deleteBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();
      print('Booking deleted successfully');
      // รีเฟรชหน้าจอหลังจากลบข้อมูลสำเร็จ
      setState(() {}); // ใช้ setState เพื่อรีเฟรชหน้าจอ
    } catch (e) {
      print('Error deleting booking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation History')),
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
                int.parse(booking['pricePerNight'].toString()), // แปลงเป็น int
              );

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(booking['roomName'] ?? 'Unknown Room',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${booking['name']} ${booking['surname']}'),
                      Text('Check-in: ${booking['checkInDate']}'),
                      Text('Check-out: ${booking['checkOutDate']}'),
                      Text('Price/Night: ${booking['pricePerNight']} ฿'),
                      Text('Total Price: $totalPrice ฿',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // เรียกฟังก์ชันลบข้อมูล
                      deleteBooking(booking['id']);
                      // หลังจากลบแล้ว อาจจะ refresh หรือออกจากหน้าจอ
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking deleted')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
