import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:md_app/main.dart';
import 'package:md_app/pages/Eduserdata.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedImageUrl;
  String? name = '';
  String? email = '';
  String? card_number = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        setState(() {
          name = userData['name'] ?? 'No Name';
          email = userData['email'] ?? 'No Email';
          card_number = userData['card_number'] ?? 'No Card Number';
          _selectedImageUrl = userData['profile_image'] ?? '';
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _deleteUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        await user.delete(); // Delete the user's account
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyApp()));
      }
    } catch (e) {
      print("Error deleting user data: $e");
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Profile'),
          content: Text('Are you sure you want to delete your profile?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                _deleteUserData();
                Navigator.of(context).pop();
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final storageRef = FirebaseStorage.instance.ref().child('user_img/${FirebaseAuth.instance.currentUser!.uid}.jpg');
      await storageRef.putFile(File(pickedImage.path));
      final imageUrl = await storageRef.getDownloadURL();

      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'profile_image': imageUrl});

      setState(() {
        _selectedImageUrl = imageUrl; // Set the selected image
      });
    }
  }

  void _navigateToExit(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => MyApp()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[200],
      appBar: AppBar(
        backgroundColor: Colors.brown[100],
        title: Text('Profile',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            iconSize: 32,
            icon: Icon(Icons.door_back_door),
            onPressed: () => _navigateToExit(context),
          ),
        ],
      ),
      body: Container(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: _selectedImageUrl != null && _selectedImageUrl!.isNotEmpty
                          ? NetworkImage(_selectedImageUrl!)
                          : null,
                      child: (_selectedImageUrl == null || _selectedImageUrl!.isEmpty)
                          ? Icon(Icons.person, size: 70)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: IconButton(
                        onPressed: _pickImageFromGallery,
                        icon: Icon(Icons.camera_alt, size: 30),
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  name ?? 'Loading...',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  email ?? 'Loading...',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                ),
                SizedBox(height: 10),
                Text(
                  card_number ?? 'Loading...',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final updatedData = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EDScreen(
                          initialName: name ?? '',
                          initialEmail: email ?? '',
                          initialCardNumber: card_number ?? '',
                        ),
                      ),
                    );

                    if (updatedData != null) {
                      setState(() {
                        name = updatedData['name'];
                        email = updatedData['email'];
                        card_number = updatedData['card_number'];
                      });
                      _fetchUserData();
                    }
                  },
                  child: Text('Edit Profile'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _confirmDelete,
                  child: Text('Delete Profile'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
