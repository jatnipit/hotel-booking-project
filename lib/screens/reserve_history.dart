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

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    User? user = FirebaseAuth.instance.currentUser;
    String? userID = user?.uid;
    if (userID == null) return [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userID', isEqualTo: userID)
        .get();
    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  int calculateTotalPrice(String checkIn, String checkOut, int pricePerNight,
      double discountPercentage) {
    DateTime checkInDate = DateTime.parse(checkIn);
    DateTime checkOutDate = DateTime.parse(checkOut);
    int nights = checkOutDate.difference(checkInDate).inDays;
    int totalPrice = nights * pricePerNight;
    double discountAmount = totalPrice * discountPercentage;
    return (totalPrice - discountAmount).round();
  }

  int calculateNights(String checkIn, String checkOut) {
    DateTime checkInDate = DateTime.parse(checkIn);
    DateTime checkOutDate = DateTime.parse(checkOut);
    return checkOutDate.difference(checkInDate).inDays;
  }

  Future<void> cancelBooking(String bookingId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this trip?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No')),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .update({'isCancelled': true});
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking cancelled')));
                setState(() {});
              } catch (e) {
                print('Error cancelling booking: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error cancelling booking.')));
              }
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  String getRemainingTime(
      Timestamp? bookingTimestamp, bool isCancelled, bool isPast) {
    if (isCancelled) return 'Cancelled';
    if (isPast) return 'Completed';
    if (bookingTimestamp == null) return 'Not editable';
    DateTime bookingTime = bookingTimestamp.toDate();
    DateTime expirationTime = bookingTime.add(const Duration(minutes: 15));
    DateTime now = DateTime.now();
    return now.isBefore(expirationTime)
        ? 'Editable until ${DateFormat('HH:mm dd MMM yyyy').format(expirationTime)}'
        : 'Uneditable';
  }

  Widget buildBookingList(List<Map<String, dynamic>> bookings, String tabType) {
    if (bookings.isEmpty) {
      String message = tabType == 'active'
          ? 'No active bookings.'
          : tabType == 'past'
              ? 'No past bookings.'
              : 'No cancelled bookings.';
      return Center(
          child: Text(message, style: Theme.of(context).textTheme.bodyMedium));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        var booking = bookings[index];
        double discountPercentage =
            booking['discountPercentage']?.toDouble() ?? 0.0;
        int totalPrice = calculateTotalPrice(
          booking['checkInDate'],
          booking['checkOutDate'],
          int.parse(booking['pricePerNight'].toString()),
          discountPercentage,
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
          color: Theme.of(context).colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            children: [
              ListTile(
                title: Text(booking['roomName'] ?? 'Unknown Room',
                    style: TextStyle(fontSize: 20)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${booking['name']} ${booking['surname']}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                        'Check-in: ${DateFormat('dd MMM yyyy').format(DateTime.parse(booking['checkInDate']))}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                        'Check-out: ${DateFormat('dd MMM yyyy').format(DateTime.parse(booking['checkOutDate']))}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text('Price/Night: ${booking['pricePerNight']} ฿',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      'Total Price: $totalPrice ฿',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    if (discountPercentage > 0)
                      Text(
                        'Discount: ${discountPercentage * 100}% applied',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red, fontWeight: FontWeight.bold),
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
                        icon: Icon(Icons.edit,
                            color: Theme.of(context).iconTheme.color),
                        onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        EditBookingScreen(booking: booking)))
                            .then((_) => setState(() {})),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < 3; i++)
                  InkWell(
                    onTap: () {
                      _tabController.animateTo(i);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _tabController.index == i
                            ? AppColors.secondary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ['Active', 'Past', 'Cancelled'][i],
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
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
                        'cancelled'),
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
