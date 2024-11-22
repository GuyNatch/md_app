import 'package:flutter/material.dart';
import 'report2firebase.dart'; // Import your Firestore service

class report2Screen extends StatefulWidget {
  @override
  _Report2ScreenState createState() => _Report2ScreenState();
}

class _Report2ScreenState extends State<report2Screen> {
  List<int> dataSet = [0, 0, 0, 0]; // List for storing offense counts by time range
  String mostOffensiveTime = ''; // Store the most offensive time range
  int maxCount = 0; // Store the max offense count

  @override
  void initState() {
    super.initState();
    fetchDataFromFirestore(); // Fetch data when screen initializes
  }

  Future<void> fetchDataFromFirestore() async {
    final data = await FirestoreService().fetchOffenseData();
    setState(() {
      // Assume data['countData'] is a Map with offense counts for each time range
      final countData = data['countData'] as Map<String, int>;
      dataSet[0] = countData['00:01-06:00'] ?? 0;
      dataSet[1] = countData['06:01-12:00'] ?? 0;
      dataSet[2] = countData['12:01-18:00'] ?? 0;
      dataSet[3] = countData['18:01-00:00'] ?? 0;

      // Update the most offensive time range and the count
      mostOffensiveTime = data['mostOffensiveTime'] ?? 'No Data';
      maxCount = data['maxCount'] ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[200],
      appBar: AppBar(
        backgroundColor: Colors.brown[100],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'ช่วงเวลาการตรวจจับ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'แผนภูมิแท่งแสดงช่วงเวลาที่มีการกระทำผิด',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'จำนวนผู้กระทำผิด 4 ช่วงเวลา',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 22),
                  Container(
                    height: 300,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _progress(dataSet[0], '00:01', '-\n06:00'),
                        _progress(dataSet[1], '06:01', '-\n12:00'),
                        _progress(dataSet[2], '12:01', '-\n18:00'),
                        _progress(dataSet[3], '18:01', '-\n00:00'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ช่วงเวลาที่มีผู้กระทำผิดมากที่สุด',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'ได้แก่    $mostOffensiveTime    นาฬิกา',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'จำนวน   $maxCount   ราย',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress(int progress, String start, String end) {
    // Bar chart with offense count displayed above
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 150 * (progress / (maxCount > 0 ? maxCount : 1)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(height: 8),
        Text(
          progress.toString(),
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        SizedBox(height: 8),
        Text(
          '$start\n$end',
          style: TextStyle(color: Colors.white, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
