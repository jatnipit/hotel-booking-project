import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSettings extends StatefulWidget {
  final String userId;

  const DeviceSettings({super.key, required this.userId});

  @override
  State<DeviceSettings> createState() => _DeviceSettingsState();
}

class _DeviceSettingsState extends State<DeviceSettings> {
  final TextEditingController _discountCodeController = TextEditingController();
  String _message = '';
  bool _isUsed = false;

  @override
  void initState() {
    super.initState();
    _checkIfCodeUsed();
    // _resetDiscountStatus(); // รีเซ็ตสถานะส่วนลดทุกครั้งที่หน้าโหลด
  }

  // ฟังก์ชันในการรีเซ็ตสถานะส่วนลด
  Future<void> _resetDiscountStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('discount_used_${widget.userId}', false);
    await prefs.setDouble('discountPercentage', 0.0);

    // รีเซ็ตข้อความด้วย
    setState(() {
      _message = ''; // เคลียร์ข้อความเมื่อรีเซ็ต
    });
  }

  // ตรวจสอบว่าใช้โค้ดส่วนลดแล้วหรือยัง
  Future<void> _checkIfCodeUsed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool used = prefs.getBool('discount_used_${widget.userId}') ?? false;
    setState(() {
      _isUsed = used;
    });
  }

  // ฟังก์ชันในการใช้โค้ดส่วนลด
  Future<void> _applyDiscountCode() async {
    String enteredCode = _discountCodeController.text.trim();

    if (_isUsed) {
      setState(() {
        _message = 'You have already used this discount code.'; // แจ้งว่าผู้ใช้เคยใช้โค้ดแล้ว
      });
      return;
    }

    if (enteredCode.isEmpty) {
      setState(() {
        _message = 'Please enter a discount code.'; // แจ้งว่าไม่ได้กรอกโค้ด
      });
      return;
    }

    if (enteredCode == 'DISCOUNT10') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('discount_used_${widget.userId}', true);

      // บันทึกเปอร์เซ็นต์ส่วนลด (เช่น 10%) ใน SharedPreferences
      await prefs.setDouble('discountPercentage', 0.1); // บันทึกเป็น 10% หรือ 0.1

      setState(() {
        _message = 'You receive a 10% discount!';
        _isUsed = true;
      });
    } else {
      setState(() {
        _message = 'Discount code is incorrect.'; // แจ้งว่าโค้ดไม่ถูกต้อง
      });
    }
  }

  // ฟังก์ชันในการตรวจสอบว่าไม่มีส่วนลดหากไม่ได้กรอกโค้ด
  Future<void> _checkDiscountStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double discountPercentage = prefs.getDouble('discountPercentage') ?? 0.0;
    
    if (discountPercentage == 0.0) {
      setState(() {
        _message = 'No discount applied.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enter Discount Code',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: _discountCodeController,
              decoration: const InputDecoration(
                labelText: 'Enter discount code',
                border: OutlineInputBorder(),
              ),
              enabled: !_isUsed,  // ปิดการกรอกหากใช้โค้ดไปแล้ว
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUsed ? null : _applyDiscountCode,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Confirm'),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                color: _message.contains('incorrect') || _message.contains('already used') ? Colors.red : Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            // ตรวจสอบว่าไม่มีส่วนลดหากไม่ได้กรอกโค้ด
            ElevatedButton(
              onPressed: _checkDiscountStatus,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Check Discount Status'),
            ),
            // เพิ่มปุ่มเพื่อรีเซ็ตสถานะส่วนลด
            // ElevatedButton(
            //   onPressed: _resetDiscountStatus,
            //   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            //   child: const Text('Reset Discount Status'),
            // ),
          ],
        ),
      ),
    );
  }
}
