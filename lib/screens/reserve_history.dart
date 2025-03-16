import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:project/materials/app_colors.dart';
import 'package:project/screens/edit_booking_screen.dart';

class ReserveHistory extends StatefulWidget {
  const ReserveHistory({super.key});

  @override
  State<ReserveHistory> createState() => _ReserveHistoryState();
}

class _ReserveHistoryState extends State<ReserveHistory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return nights * pricePerNight;
  }

  int calculateNights(String checkIn, String checkOut) {
    DateTime checkInDate = DateTime.parse(checkIn);
    DateTime checkOutDate = DateTime.parse(checkOut);
    return checkOutDate.difference(checkInDate).inDays;
  }

  Future<void> cancelBooking(String bookingId) async {
    // Show confirmation dialog before cancelling
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const Text('Are you sure you want to cancel this trip?'),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(bookingId)
                      .update({'isCancelled': true});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking cancelled')),
                  );
                  setState(() {});
                } catch (e) {
                  print('Error cancelling booking: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error cancelling booking.')),
                  );
                }
                Navigator.of(context).pop(); // Dismiss the dialog after action
              },
            ),
          ],
        );
      },
    );
  }

  String getRemainingTime(
      Timestamp? bookingTimestamp, bool isCancelled, bool isPast) {
    if (isCancelled) {
      return 'Cancelled';
    }
    if (isPast) {
      return 'Completed';
    }
    if (bookingTimestamp == null) return 'Not editable';
    DateTime bookingTime = bookingTimestamp.toDate();
    DateTime expirationTime = bookingTime.add(const Duration(minutes: 15));
    DateTime now = DateTime.now();

    if (now.isBefore(expirationTime)) {
      String formattedTime =
          DateFormat('HH:mm dd MMM yyyy').format(expirationTime);
      return 'Editable until $formattedTime';
    } else {
      return 'Uneditable';
    }
  }

  Widget buildBookingList(List<Map<String, dynamic>> bookings, String tabType) {
    if (bookings.isEmpty) {
      String message = tabType == 'active'
          ? 'No active bookings.'
          : tabType == 'past'
              ? 'No past bookings.'
              : 'No cancelled bookings.';
      return Center(child: Text(message));
    }

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
        int nights =
            calculateNights(booking['checkInDate'], booking['checkOutDate']);

        Timestamp? bookingTimestamp = booking['bookingTime'];
        bool isPast =
            DateTime.parse(booking['checkOutDate']).isBefore(DateTime.now());
        bool canEdit = !(booking['isCancelled'] ?? false) &&
            DateTime.parse(booking['checkOutDate']).isAfter(DateTime.now()) &&
            bookingTimestamp != null &&
            DateTime.now().difference(bookingTimestamp.toDate()).inMinutes < 15;
        String remainingTime = getRemainingTime(
            bookingTimestamp, booking['isCancelled'] ?? false, isPast);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          elevation: 5,
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    Text(
                        'Check-in: ${DateFormat('dd MMM yyyy').format(DateTime.parse(booking['checkInDate']))}'),
                    Text(
                        'Check-out: ${DateFormat('dd MMM yyyy').format(DateTime.parse(booking['checkOutDate']))}'),
                    Text('Price/Night: ${booking['pricePerNight']} ฿'),
                    Text(
                      'Total Price: $totalPrice ฿',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      remainingTime,
                      style: TextStyle(
                        color: remainingTime.startsWith('Editable')
                            ? Colors.blue
                            : remainingTime == 'Cancelled'
                                ? Colors.red
                                : Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditBookingScreen(booking: booking),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => cancelBooking(booking['id']),
                      ),
                    ],
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
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom Tab Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < 3; i++)
                  InkWell(
                    onTap: () {
                      _tabController.animateTo(i);
                      setState(() {}); // Rebuild to update tab appearance
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _tabController.index == i
                            ? AppColors.secondary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ['Active', 'Past', 'Cancelled'][i],
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: _tabController.index == i
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var allBookings = snapshot.data ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: [
                    buildBookingList(
                      allBookings
                          .where((b) =>
                              !(b['isCancelled'] ?? false) &&
                              DateTime.parse(b['checkOutDate'])
                                  .isAfter(DateTime.now()))
                          .toList(),
                      'active',
                    ),
                    buildBookingList(
                      allBookings
                          .where((b) =>
                              !(b['isCancelled'] ?? false) &&
                              DateTime.parse(b['checkOutDate'])
                                  .isBefore(DateTime.now()))
                          .toList(),
                      'past',
                    ),
                    buildBookingList(
                      allBookings
                          .where((b) => b['isCancelled'] ?? false)
                          .toList(),
                      'cancelled',
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
