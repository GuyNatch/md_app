import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateProvinceOffenses() async {
    var querySnapshot = await _firestore.collection('daily_counts').get();

    Map<String, int> offensesCount = {};

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String address = data['address'] ?? 'Unknown Address';
      String provinceName = _extractProvinceFromAddress(address);

      int violationsDetected = data['violations_detected'] ?? 0;

      if (offensesCount.containsKey(provinceName)) {
        offensesCount[provinceName] = offensesCount[provinceName]! + violationsDetected;
      } else {
        offensesCount[provinceName] = violationsDetected;
      }
    }

    for (var entry in offensesCount.entries) {
      String provinceName = entry.key;
      int count = entry.value;

      var provinceDoc = await _firestore
          .collection('provinces')
          .where('name', isEqualTo: provinceName)
          .get();

      if (provinceDoc.docs.isNotEmpty) {
        var docId = provinceDoc.docs.first.id;
        await _firestore
            .collection('provinces')
            .doc(docId)
            .update({'offenses_count': count});
      }
    }
  }

  Future<List<Map<String, dynamic>>> loadProvinceOffenses() async {
    List<Map<String, dynamic>> provinces = [];
    var querySnapshot = await _firestore.collection('provinces').get();

    for (var doc in querySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;

      double latitude = (data['latitude'] is String)
          ? double.tryParse(data['latitude']) ?? 0.0
          : data['latitude'] ?? 0.0;
      double longitude = (data['longitude'] is String)
          ? double.tryParse(data['longitude']) ?? 0.0
          : data['longitude'] ?? 0.0;

      provinces.add({
        'name': data['name'] ?? 'Unknown Province',
        'latitude': latitude,
        'longitude': longitude,
        'offenses_count': data['offenses_count'] ?? 0,
      });
    }

    return provinces;
  }

  Future<List<Marker>> loadMarkers() async {
    var snapshot = await _firestore.collection('provinces').get();
    return snapshot.docs.map((doc) {
      var data = doc.data();

      double latitude = (data['latitude'] is String)
          ? double.tryParse(data['latitude']) ?? 0.0
          : data['latitude'] ?? 0.0;
      double longitude = (data['longitude'] is String)
          ? double.tryParse(data['longitude']) ?? 0.0
          : data['longitude'] ?? 0.0;

      String provinceName = data['name'] ?? 'Unknown Province';
      int offensesCount = data['offenses_count'] ?? 0;

      return Marker(
        markerId: MarkerId(provinceName),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: provinceName,
          snippet: 'จำนวนการตรวจจับ $offensesCount ราย',
        ),
      );
    }).toList();
  }

  String _extractProvinceFromAddress(String address) {
    RegExp postalCodeRegex = RegExp(r'\b\d{5}\b');
    String? postalCode = postalCodeRegex.firstMatch(address)?.group(0);

    return postalCode != null ? _getProvinceFromPostalCode(postalCode) : 'Unknown Province';
  }

  String _getProvinceFromPostalCode(String postalCode) {
    int? code = int.tryParse(postalCode);
    if (code == null) return 'Unknown Province';

    if (code >= 10100 && code <= 10510) return 'กรุงเทพมหานคร';
    if (code >= 73000 && code <= 73170) return 'นครปฐม';
    if (code >= 11000 && code <= 11150) return 'นนทบุรี';
    if (code >= 12000 && code <= 12170) return 'ปทุมธานี';
    if (code >= 10270 && code <= 10560) return 'สมุทรปราการ';
    if (code == 75000) return 'สมุทรสงคราม';
    if (code >= 74000 && code <= 74130) return 'สมุทรสาคร';
    if (code >= 13000 && code <= 13290) return 'อยุธยา';
    if (code >= 18000 && code <= 18270) return 'สระบุรี';
    if (code >= 72000 && code <= 72230) return 'สุพรรณบุรี';

    return 'Unknown Province';
  }
}

