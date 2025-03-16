import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'details_screen.dart';
import 'package:project/authen/login_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const LoginPage()), // เปลี่ยนไปหน้า LoginPage
    );
  }

  Future<QuerySnapshot> fetchAllRoomsData() async {
    return await FirebaseFirestore.instance.collection('hotels').get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<QuerySnapshot>(
        future: fetchAllRoomsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            var rooms = snapshot.data?.docs ?? [];
            if (rooms.isEmpty) {
              return const Center(child: Text('No data found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                var roomData = rooms[index].data() as Map<String, dynamic>;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(roomData: roomData),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  roomData['name'] ?? 'ไม่ระบุ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                    ' Location : ${roomData['location'] ?? 'ไม่ระบุ'}'),
                                const SizedBox(height: 10),
                                Text(
                                  ' Price/Night : ${roomData['pricePerNight'] ?? 'ไม่ระบุ'} ฿',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                roomData['imageURL'] ??
                                    'https://via.placeholder.com/150',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }
}