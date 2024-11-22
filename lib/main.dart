import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:md_app/pages/Signin.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyDdoZIAxu_grqBEtJSnqrFNfn4E9oBqBtg',
      authDomain: 'mdapp-d52ba.firebaseapp.com',
      projectId: 'mdapp-d52ba',
      storageBucket: 'mdapp-d52ba.appspot.com',
      messagingSenderId: '344716341428',
      appId: '1:344716341428:android:4cc4aeeaf8867bc19d27e1',
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyDdoZIAxu_grqBEtJSnqrFNfn4E9oBqBtg',
      authDomain: 'mdapp-d52ba.firebaseapp.com',
      projectId: 'mdapp-d52ba',
      storageBucket: 'mdapp-d52ba.appspot.com',
      messagingSenderId: '344716341428',
      appId: '1:344716341428:android:4cc4aeeaf8867bc19d27e1',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Email & Password',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: LoginPage(),
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
