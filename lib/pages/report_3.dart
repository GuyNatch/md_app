import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // สำหรับ rootBundle
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:md_app/pages/Home.dart';
import 'report3firebase.dart';

class report3Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'อัตราการกระทำผิดในพื้นที่',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UserCurrentLocation(),
    );
  }
}

class UserCurrentLocation extends StatefulWidget {
  @override
  _UserCurrentLocationState createState() => _UserCurrentLocationState();
}

class _UserCurrentLocationState extends State<UserCurrentLocation> {
  GoogleMapController? mapController;
  LatLng? _center;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final FirestoreService firestoreService = FirestoreService();

  String _mapStyle = ''; // สำหรับ MapStyle

  Marker? _userMarker;
  CameraPosition? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // ดึงตำแหน่งปัจจุบัน
    _loadMarkers(); // โหลด Marker ของจังหวัด
    _loadMapStyle(); // โหลด MapStyle
  }

  void _loadMapStyle() async {
    // โหลดไฟล์ JSON สำหรับ MapStyle
    _mapStyle = await rootBundle.loadString('assets/map_style.json');
    print("MapStyle loaded: $_mapStyle"); // Debugging
  }

  void _loadMarkers() async {
  await firestoreService.updateProvinceOffenses(); // อัปเดตจำนวนการตรวจจับใน provinces
  var markers = await firestoreService.loadMarkers();
  setState(() {
    _markers.addAll(markers);
  });
}


  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _center = LatLng(position.latitude, position.longitude);
      _userMarker = Marker(
        markerId: MarkerId('user_location'),
        position: _center!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: 'Your Location'),
      );

      _userPosition = CameraPosition(
        target: _center!,
        zoom: 15.0,
      );

      // ตั้งกล้องไปที่ตำแหน่งปัจจุบัน
      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newCameraPosition(_userPosition!));
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController!.setMapStyle(_mapStyle).then((_) {
      print("MapStyle applied"); // Debugging
    }).catchError((error) {
      print("Failed to set MapStyle: $error"); // Debugging
    });

    // เมื่อโหลดแผนที่เสร็จแล้ว ให้ย้ายไปที่ตำแหน่งปัจจุบัน
    if (_userPosition != null) {
      controller.animateCamera(CameraUpdate.newCameraPosition(_userPosition!));
    }
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
          },
        ),
        title: Text(
          'อัตราการกระทำผิดในพื้นที่',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _center == null
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _center ?? LatLng(13.7563, 100.5018), // ตำแหน่งเริ่มต้น (กรุงเทพ)
                      zoom: 15.0,
                    ),
                    markers: _markers..addAll(_userMarker != null ? {_userMarker!} : {}),
                    trafficEnabled: false, // ปิด Traffic Layer
                    buildingsEnabled: false, // ปิดอาคาร
                    indoorViewEnabled: false, // ปิด Indoor View
                    mapToolbarEnabled: false, // ปิด Toolbar
                    myLocationButtonEnabled: false, // ปิดปุ่มแสดงตำแหน่ง
                  ),
                ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'จำนวนผู้กระทำผิดในจังหวัดต่างๆ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: firestoreService.loadProvinceOffenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available'));
                }

                List<Map<String, dynamic>> provinces = snapshot.data!
                    .where((province) =>
                        (province['offenses_count'] ?? 0) > 0 &&
                        province['name'] != 'Unknown Province')
                    .toList();

                return ListView.builder(
                  itemCount: provinces.length,
                  itemBuilder: (context, index) {
                    var province = provinces[index];
                    return _buildProvinceRow(
                      province['name'] ?? 'Unknown Province',
                      '${province['offenses_count'] ?? 0} ราย',
                      () => _goToLocation(
                        province['latitude'] ?? 0.0,
                        province['longitude'] ?? 0.0,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceRow(String province, String count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(province, style: TextStyle(fontSize: 16)),
            Text(count, style: TextStyle(fontSize: 16), textAlign: TextAlign.right),
          ],
        ),
      ),
    );
  }

  Future<void> _goToLocation(double lat, double lng) async {
    print('Moving to location: Latitude: $lat, Longitude: $lng'); // Debug
    if (mapController != null) {
      final CameraPosition newPosition = CameraPosition(target: LatLng(lat, lng), zoom: 15);
      await mapController!.animateCamera(CameraUpdate.newCameraPosition(newPosition));
    } else {
      print("MapController is not initialized");
    }
  }
}
