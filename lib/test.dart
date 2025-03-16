import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart'; // Needed for WidgetsFlutterBinding
import 'dart:io'; // For exit()

Future<void> main() async {
  // Ensure Flutter bindings are initialized.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (ensure your Firebase setup is complete).
  await Firebase.initializeApp();

  // Reference to the 'hotels' collection.
  final CollectionReference hotels =
      FirebaseFirestore.instance.collection('hotels');

  try {
    // Insert a new document with the specified hotel data.
    await hotels.add({
      'facilities':
          "Free Wi-Fi, Paid breakfast, Free parking, Accessible for disabled guests, Outdoor swimming pool, Air conditioning, Laundry service, Business center, Pet-friendly, Room service, Family-friendly, Restaurant, Some rooms have a kitchen, Airport shuttle, Hot tub, Fitness center, Bar, No smoking",
      'description': "Good view",
      'imageURL':
          "https://lh5.googleusercontent.com/p/AF1QipOGWBHA_EqtlZ-Wffa5JclCO3wK70HVFOmGPmD2=w408-h271-k-no",
      'location': "Sriracha",
      'name': "Holiday Inn & Suites Siracha Laemchabang, an IHG Hotel",
      'pricePerNight': "2000",
      'roomImages': [
        "https://cf.bstatic.com/xdata/images/hotel/max1024x768/237664337.jpg?k=49d68164d5c16727754ea4ff71f956ab5c13f3fcde2b629d0309abd965ac6b0e&o=&hp=1",
        "https://q-xx.bstatic.com/xdata/images/hotel/max500/275203927.jpg?k=69e91e89d20d07d82e9f3d6cf17c74adde9418618e777e3c56d29ae1e03c43da&o=",
        "https://cf.bstatic.com/xdata/images/hotel/max1024x768/237664259.jpg?k=a0b0049f676247c60a0823525d3709ffb22225f4194a00b5e7ac951b702d0f51&o=&hp=1"
      ],
    });
    print("Hotel data inserted successfully!");
  } catch (e) {
    print("Failed to insert hotel data: $e");
  }

  // Exit the program.
  exit(0);
}
