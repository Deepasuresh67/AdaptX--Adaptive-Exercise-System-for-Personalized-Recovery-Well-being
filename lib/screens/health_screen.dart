import 'package:flutter/material.dart';
import 'home_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({Key? key}) : super(key: key);

  @override
  _HealthScreenState createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  int heartRate = 72; // Mock Heart Rate (Replace with IoT data)
  int bloodOxygen = 98; // Mock Blood Oxygen Level (Replace with IoT data)

  void showHealthInfo(String title, int value, String unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Your current $title is $value $unit'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Data"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Heart Rate Icon
                GestureDetector(
                  onTap: () => showHealthInfo("Heart Rate", heartRate, "BPM"),
                  child: Column(
                    children: [
                      Icon(Icons.favorite, size: 50, color: Colors.red),
                      const SizedBox(height: 10),
                      const Text("Heart Rate", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),

                // Blood Oxygen Icon
                GestureDetector(
                  onTap: () => showHealthInfo("Blood Oxygen", bloodOxygen, "%"),
                  child: Column(
                    children: [
                      Icon(Icons.bloodtype, size: 50, color: Colors.blue),
                      const SizedBox(height: 10),
                      const Text("Blood Oxygen", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
