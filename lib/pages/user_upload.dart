import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UULScreen extends StatelessWidget {
  final ImagePicker _picker = ImagePicker();

  Future<void> _uploadVideo(BuildContext context) async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    File videoFile = File(video.path);
    String fileName = video.name;

    try {
      await FirebaseStorage.instance
          .ref('Vdo_user_upload/$fileName')
          .putFile(videoFile);


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video uploaded successfully!')),
      );

    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Upload'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to Camera Screen!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _uploadVideo(context),
              child: Text('Upload Video'),
            ),
          ],
        ),
      ),
    );
  }
}
