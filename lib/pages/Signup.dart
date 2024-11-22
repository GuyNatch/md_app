import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Signin.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formkey = GlobalKey<FormState>();
  var name = "";
  var cardnum = "";
  var email = "";
  var password = "";
  var conpassword = "";

  final _fullNameController = TextEditingController();
  final _cardController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  registration() async {
    if (password == conpassword) {
      try { 
        var cardNumberSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('card_number', isEqualTo: _cardController.text)
            .get();

        if (cardNumberSnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.grey,
            content: Text(
              'Card Number is already in use.',
              style: TextStyle(fontSize: 20.0, color: Colors.redAccent),
            ),
          ));
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );


        FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'card_number': cardnum,
          'email': email,
          'created_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.grey,
          content: Text(
            'Registered Successfully! Please sign in.',
            style: TextStyle(fontSize: 20.0, color: Colors.redAccent),
          ),
        ));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } on FirebaseAuthException catch (error) {
        String message = '';

        if (error.code == 'email-already-in-use') {
          message = 'Account already exists.';
        } else if (error.code == 'weak-password') {
          message = 'Password is too weak.';
        } else {
          message = 'An error occurred: ${error.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.grey,
          content: Text(
            message,
            style: TextStyle(fontSize: 20.0, color: Colors.redAccent),
          ),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.grey,
        content: Text(
          'Passwords do not match',
          style: TextStyle(fontSize: 20.0, color: Colors.redAccent),
        ),
      ));
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _cardController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(backgroundColor: Colors.brown[100],),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: _formkey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 40.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 50.0),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'FULL NAME',
                    prefixIcon: Icon(Icons.drive_file_rename_outline),
                  ),
                ),
                SizedBox(height: 15.0),

                TextFormField(
                  controller: _cardController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your card number';
                    } else if (value.length != 13) {
                      return 'Card number must be 13 digits';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'CARD NUMBER',
                    prefixIcon: Icon(Icons.add_card_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                  ],
                ),
                SizedBox(height: 15.0),

            
                TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'EMAIL',
                    prefixIcon: Icon(Icons.mail),
                  ),
                ),
                SizedBox(height: 15.0),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    } else if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'PASSWORD',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                SizedBox(height: 15.0),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    } else if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'CONFIRM PASSWORD',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                SizedBox(height: 30.0),

                ElevatedButton(
                  onPressed: () {
                    if (_formkey.currentState!.validate()) {
                      setState(() {
                        name = _fullNameController.text;
                        cardnum = _cardController.text;
                        email = _emailController.text;
                        password = _passwordController.text;
                        conpassword = _confirmPasswordController.text;
                      });
                      registration();
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.orangeAccent),
                  ),
                  child: Text(
                    'SIGNUP',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Already have an account?",
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}