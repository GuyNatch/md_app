import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class EDScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialCardNumber;

  EDScreen({required this.initialName, required this.initialEmail, required this.initialCardNumber});

  @override
  _EDScreenState createState() => _EDScreenState();
}

class _EDScreenState extends State<EDScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _cardNumberController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _cardNumberController = TextEditingController(text: widget.initialCardNumber);
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  Future<void> _updateUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': _nameController.text,
          'card_number': _cardNumberController.text,
        });


        await _sendLineNotify();

        Navigator.pop(context, {
          'name': _nameController.text,
          'email': widget.initialEmail,
          'card_number': _cardNumberController.text,
        });
      } catch (e) {
        print("Error updating user data: $e");
      }
    }
  }
//เทสไลน์ Noti
 Future<void> _sendLineNotify() async {
    final String token = 'iYUtTdNSa1aON7tEuhSFFcA7R8lM1mYGyQgw3tvplwM';
    final String message = '''
      User ${FirebaseAuth.instance.currentUser?.email} has updated their profile:
      - Name: ${_nameController.text}
      - Card Number: ${_cardNumberController.text}
    ''';

    try {
      final response = await http.post(
        Uri.parse('https://notify-api.line.me/api/notify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'message': message},
      );

      if (response.statusCode == 200) {
        print("LINE Notify sent successfully.");
      } else {
        print("Failed to send LINE Notify: ${response.body}");
      }
    } catch (e) {
      print("Error sending LINE Notify: $e");
    }
  }

  Future<void> _changePassword() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _oldPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);
        if (_newPasswordController.text == _confirmPasswordController.text) {
          await user.updatePassword(_newPasswordController.text);
          print("Password changed successfully.");
        } else {
          print("New passwords do not match.");
        }
      } catch (e) {
        print("Error changing password: $e");
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cardNumberController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            SizedBox(height: 20),
            Text(
              'Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            TextField(
              controller: _oldPasswordController,
              decoration: InputDecoration(labelText: 'Old Password', labelStyle: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15)),
              obscureText: true,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(labelText: 'New Password', labelStyle: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15)),
              obscureText: true,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm New Password', labelStyle: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 15)),
              obscureText: true,
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _updateUserData();
                  _changePassword();
                },
                child: Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
