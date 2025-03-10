import 'package:flutter/material.dart';

class ReserveHistory extends StatefulWidget {
  const ReserveHistory({super.key});

  @override
  State<ReserveHistory> createState() => _ReserveHistoryState();
}

class _ReserveHistoryState extends State<ReserveHistory> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber,
      child: Text('This is History Screen'),
    );
  }
}
