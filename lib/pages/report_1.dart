import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class report1Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WeeklyReportScreen();
}

class WeeklyReportScreen extends StatefulWidget {
  @override
  _WeeklyReportScreenState createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  DateTime selectedDate = DateTime.now();
  Map<String, Map<String, dynamic>> weeklyData = {};

  @override
  void initState() {
    super.initState();
    _updateWeeklyData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[200],
      appBar: AppBar(
        backgroundColor: Colors.brown[100],
        title: Text('สถิติการตรวจจับ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSelector(),
            SizedBox(height: 25),
            _buildBarChart(),
            SizedBox(height: 25),
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('เลือกวันที่ได้เฉพาะวันจันทร์:', style: TextStyle(fontSize: 16)),
        ElevatedButton(
          onPressed: _pickDate,
          child: Text(_dateFormat.format(selectedDate)),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate.weekday == DateTime.monday) {
      setState(() {
        selectedDate = pickedDate;
        _updateWeeklyData();
      });
    } else if (pickedDate != null) {
      _showAlert('เลือกเฉพาะวันจันทร์', 'โปรดเลือกเฉพาะวันจันทร์ที่เป็นวันเริ่มต้นของสัปดาห์');
    }
  }

  void _showAlert(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('ตกลง')),
        ],
      ),
    );
  }

  Future<void> _updateWeeklyData() async {
    weeklyData = {};
    try {
      CollectionReference collection = FirebaseFirestore.instance.collection('daily_counts');

      for (int i = 0; i < 7; i++) {
        DateTime day = selectedDate.add(Duration(days: i));
        String dayName = _dayOfWeek(i);
        String formattedDate = _dateFormat.format(day);

        // ดึงข้อมูลเอกสารที่ตรงกับวันที่
        DocumentSnapshot snapshot = await collection.doc(formattedDate).get();

        if (snapshot.exists) {
          // อ่านค่าจากฟิลด์ violations_detected
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          int violationsDetected = data['violations_detected'] ?? 0;

          weeklyData[dayName] = {
            'count': violationsDetected,
            'date': formattedDate,
          };
        } else {
          // ถ้าไม่มีข้อมูลสำหรับวันนั้น
          weeklyData[dayName] = {
            'count': 0,
            'date': formattedDate,
          };
        }
      }

      setState(() {});
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Widget _buildBarChart() {
    if (weeklyData.isEmpty) {
      return Center(child: Text('ไม่มีข้อมูลสำหรับแสดงแผนภูมิแท่ง', style: TextStyle(fontSize: 16)));
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: weeklyData.entries.map((entry) {
            return BarChartGroupData(
              x: _dayIndex(entry.key),
              barRods: [
                BarChartRodData(
                  toY: entry.value['count'].toDouble(),
                  color: _colorForDay(entry.key),
                  width: 20,
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  String day = _dayAbbreviation(value.toInt());
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(day, style: TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (weeklyData.isEmpty) {
      return Center(child: Text('ไม่มีข้อมูลสำหรับแสดง', style: TextStyle(fontSize: 16)));
    }

    return Expanded(
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: weeklyData.entries.map((entry) {
          return Card(
            color: _colorForDay(entry.key),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(entry.key, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Text(entry.value['date'], style: TextStyle(fontSize: 13, color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('${entry.value['count']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  int _dayIndex(String day) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(day);

  String _dayAbbreviation(int index) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];

  Color _colorForDay(String day) {
    switch (day) {
      case 'Mon': return Colors.amber.shade700;
      case 'Tue': return Colors.pink.shade400;
      case 'Wed': return Colors.green.shade700;
      case 'Thu': return Colors.orange.shade700;
      case 'Fri': return Colors.blue.shade600;
      case 'Sat': return Colors.purple.shade700;
      case 'Sun': return Colors.red.shade700;
      default: return Colors.grey;
    }
  }

  String _dayOfWeek(int index) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];
}
