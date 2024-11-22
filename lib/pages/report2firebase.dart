import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchOffenseData() async {
    // Initialize count data for each time range
    Map<String, int> countData = {
      '00:01-06:00': 0,
      '06:01-12:00': 0,
      '12:01-18:00': 0,
      '18:01-00:00': 0,
    };

    try {
      // Fetch all documents in the 'test' collection
      QuerySnapshot querySnapshot = await _firestore.collection('test').get();

      // Debug: Check if documents are retrieved
      print('Documents retrieved: ${querySnapshot.docs.length}');

      for (var doc in querySnapshot.docs) {
        // แปลง doc.data() เป็น Map<String, dynamic>
        final data = doc.data() as Map<String, dynamic>;

        // ตรวจสอบว่ามีฟิลด์ 'timestamp' หรือไม่
        if (data.containsKey('timestamp') && data['timestamp'] != null) {
          try {
            // แปลง timestamp จากสตริงเป็น DateTime
            String timestampString = data['timestamp'];
            DateTime dateTime = DateTime.parse(timestampString);
            int hour = dateTime.hour;

            // จัดประเภทตามช่วงเวลา
            if (hour >= 0 && hour < 6) {
              countData['00:01-06:00'] = (countData['00:01-06:00'] ?? 0) + 1;
            } else if (hour >= 6 && hour < 12) {
              countData['06:01-12:00'] = (countData['06:01-12:00'] ?? 0) + 1;
            } else if (hour >= 12 && hour < 18) {
              countData['12:01-18:00'] = (countData['12:01-18:00'] ?? 0) + 1;
            } else if (hour >= 18 && hour < 24) {
              countData['18:01-00:00'] = (countData['18:01-00:00'] ?? 0) + 1;
            }
          } catch (e) {
            print('Error parsing timestamp for document: ${doc.id}, error: $e');
          }
        } else {
          print("Document missing 'timestamp' field or it is null: ${doc.id}");
        }
      }

      // Debug: Output count data to verify
      print('Count data: $countData');

      // Determine the time range with the most offenses
      String mostOffensiveTime = '';
      int maxCount = 0;

      countData.forEach((timeRange, count) {
        if (count > maxCount) {
          maxCount = count;
          mostOffensiveTime = timeRange;
        }
      });

      // Return data as a map
      return {
        'countData': countData,
        'mostOffensiveTime': mostOffensiveTime.isNotEmpty ? mostOffensiveTime : 'No Data',
        'maxCount': maxCount,
      };
    } catch (e) {
      print('Error fetching data: $e');
      return {
        'countData': countData,
        'mostOffensiveTime': 'No Data',
        'maxCount': 0,
      };
    }
  }
}