import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:md_app/pages/user_upload.dart';
import 'reverse_geocode.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  User? _user;
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  late String videoPath;
  bool isRecording = false;

  final ImagePicker _picker = ImagePicker();
  final String lineNotifyToken = 'iYUtTdNSa1aON7tEuhSFFcA7R8lM1mYGyQgw3tvplwM';
  late LineNotifyFirebaseService _lineNotifyService;

  // ข้อมูลตำแหน่ง
  Position? _currentPosition;
  LatLng? _center;
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    _initializeLineNotify();
    _startPollingForNewDocuments();
    _initializeCamera();
    _getUserLocation();// map
    _checkUserLoginStatus();
  }

  void _initializeLineNotify() {
    _lineNotifyService = LineNotifyFirebaseService(lineNotifyToken: lineNotifyToken);
  }

  Future<void> _startPollingForNewDocuments() async {
    Timer.periodic(Duration(seconds: 30), (timer) async { // minute: 30
      await _lineNotifyService.checkForNewDocuments();
    });
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    _initializeControllerFuture = controller.initialize();

    if (mounted) {
      setState(() {});
    }
  }
  Future<void> _checkUserLoginStatus() async {
    _user = FirebaseAuth.instance.currentUser;  
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user logged in!'), backgroundColor: Colors.red),
      );
    }
  }

  // ฟังก์ชันตำแหน่งปัจจุบัน
  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.'), backgroundColor: Colors.red),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String address = await reverseGeocode(position.latitude, position.longitude);

    setState(() {
      _currentPosition = position;
      _center = LatLng(position.latitude, position.longitude);
      _currentAddress = address;
    });
  }

  Future<void> _startRecording() async {
    if (!controller.value.isInitialized) {
      print("Controller not initialized");
      return;
    }
    try {
      final tempDir = await Directory.systemTemp.createTemp();
      final filePath = '${tempDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      await controller.startVideoRecording();
      setState(() {
        isRecording = true;
      });
      videoPath = filePath;
    } catch (e) {
      print("Error starting video recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (!controller.value.isRecordingVideo) {
      print("No video is being recorded");
      return;
    }
    try {
      final videoFile = await controller.stopVideoRecording();
      setState(() {
        isRecording = false;
      });
      await _uploadVideoToFirebase(videoFile.path);
    } catch (e) {
      print("Error stopping video recording: $e");
    }
  }


  Future<void> _uploadVideo(BuildContext context) async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    File videoFile = File(video.path);
    String fileName = video.name;

    try {
      if (_user == null) {  // ใช้ _user ที่ได้จากการตรวจสอบ บนๆ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user logged in!'), backgroundColor: Colors.red),
        );
        return;
      }

      String uid = _user!.uid;
      await FirebaseStorage.instance.ref('Vdo_user_upload/$fileName').putFile(videoFile);

      await FirebaseFirestore.instance.collection('offline_video').add({
        'filePath': 'Vdo_user_upload/$fileName',
        'uploadTime': Timestamp.now(),
        'uid': uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video uploaded successfully!'), backgroundColor: Colors.blueAccent),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading video: $e'), backgroundColor: Colors.red),
      );
    }
  }
  // แผน2
  /*Future<void> _uploadVideo(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UULScreen()),
    );
  }*/


  Future<void> _uploadVideoToFirebase(String filePath) async {
    try {
      if (_user == null) {  
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user logged in!'), backgroundColor: Colors.red),
        );
        return;
      }

      String uid = _user!.uid;

      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current location is not available!'), backgroundColor: Colors.red),
        );
        return;
      }

      File videoFile = File(filePath);
      String fileName = 'realtimevideo/${DateTime.now().millisecondsSinceEpoch}.mp4';
      await FirebaseStorage.instance.ref(fileName).putFile(videoFile);

      String address = _currentAddress ?? await reverseGeocode(_currentPosition!.latitude, _currentPosition!.longitude);

      await FirebaseFirestore.instance.collection('videos').add({
        'filePath': fileName,
        'uploadTime': Timestamp.now(),
        'uid': uid,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'address': address,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video uploaded successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print("Error sending to database: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[100],
        title: Text('Camera',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            iconSize: 32,
            icon: Icon(Icons.download),
            onPressed: () => _uploadVideo(context),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return GestureDetector(
              child: Stack(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: CameraPreview(controller),
                  ),

                  Positioned(
                    bottom: 20,
                    left: MediaQuery.of(context).size.width / 2 - 40, // ตั้งอยู่กลาง
                    child: FloatingActionButton(
                      onPressed: isRecording ? _stopRecording : _startRecording,
                      child: Icon(isRecording ? Icons.stop : Icons.videocam),
                      backgroundColor: isRecording ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
class LineNotifyFirebaseService {
  final String lineNotifyToken;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LineNotifyFirebaseService({required this.lineNotifyToken});

  Future<void> checkForNewDocuments() async {
    try {
      Query query = _firestore.collection('test')
          .orderBy('timestamp', descending: true)
          .limit(150);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('ไม่พบข้อมูลใหม่');
        return;
      }

      for (var doc in snapshot.docs) {
        bool isProcessed = await _isDocumentProcessed(doc.id);
        if (isProcessed) {
          debugPrint('ประมวลผลแล้ว: ${doc.id}');
          continue;
        }

        await _processDocument(doc);
        await _markDocumentAsProcessed(doc.id);
      }

    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการตรวจสอบเอกสารใหม่: $e');
    }
  }

  Future<bool> _isDocumentProcessed(String docId) async {
    final docRef = _firestore.collection('processed_documents').doc(docId);
    final docSnapshot = await docRef.get();
    return docSnapshot.exists;
  }

  Future<void> _markDocumentAsProcessed(String docId) async {
    final docRef = _firestore.collection('processed_documents').doc(docId);
    await docRef.set({'processed': true});
  }

  Future<void> _processDocument(DocumentSnapshot doc) async {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (!_validateDocumentData(data)) {
        debugPrint('ข้อมูลไม่ครบหรือไม่ถูกต้อง: ${doc.id}');
        await sendLineNotify('ข้อมูลในเอกสาร ID ${doc.id} ไม่ครบ');
        return;
      }

      Map<String, dynamic>? userData = await _getUserDataFromUID(data['uid']);

      String? imageUrl = data['original_image_url']?.toString();

      String message = _prepareNotificationMessage(data, userData);
      await sendLineNotify(message, imageUrl: imageUrl);

    } catch (e) {
      debugPrint('เอกสาร error {doc.id}: $e');
    }
  }

  Future<void> sendLineNotify(String message, {String? imageUrl}) async {
    final Uri url = Uri.parse('https://notify-api.line.me/api/notify');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $lineNotifyToken'
        },
        body: {
          'message': message,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageThumbnail': imageUrl,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageFullsize': imageUrl,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('ส่งการแจ้งเตือนสำเร็จ');
      } else {
        debugPrint('ส่งการแจ้งเตือนไม่สำเร็จ: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการส่งการแจ้งเตือน: $e');
    }
  }

  Future<Map<String, dynamic>?> _getUserDataFromUID(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (userDoc.exists) {
      final data = userDoc.data();
      return {
        'card_number': data?['card_number']?.toString(),
        'name': data?['name']?.toString(),
        'email': data?['email']?.toString(),
      };
    }
    return null;
  }
  bool _validateDocumentData(Map<String, dynamic> data) {
    return data.containsKey('original_image_url') &&
        data.containsKey('timestamp') &&
        data.containsKey('uid') &&
        data['original_image_url'] != null;
  }

  String _prepareNotificationMessage(Map<String, dynamic> data, Map<String, dynamic>? userData) {
    String timestamp = '';

    var timestampData = data['timestamp'];
    if (timestampData is Timestamp) {
      timestamp = timestampData.toDate().toString();
    } else if (timestampData is String) {
      timestamp = timestampData;
    } else {
      timestamp = 'ตรวจไม่พบเวลา';
    }

    String address = data['address'] == "No address" ? "offline" : data['address'] ?? "offline";
    String cardNumber = userData?['card_number'] ?? 'No information';
    String name = userData?['name'] ?? 'No information ';
    String email = userData?['email'] ?? 'No information';

    return '''informant
    👤 Name: $name
    📧 Email: $email
    🪪 Card Number(user): $cardNumber
    ⏰ Date&Time: $timestamp
  ''';
  }
  
}