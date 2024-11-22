import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:md_app/main.dart';
import 'package:md_app/pages/Signup.dart';

class Forgetpass extends StatefulWidget {
  @override
  _ForgetpassState createState() => _ForgetpassState();
}

class _ForgetpassState extends State<Forgetpass> {
  final _formKey = GlobalKey<FormState>();
  var email = "";

  final emailController = TextEditingController();

  Future<void> resetPass() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.grey,
        content: Text(
          'Password Reset Email has been sent',
          style: TextStyle(fontSize: 10.0, color: Colors.redAccent),
        ),
      ));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') {
        print('User not found for this email');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'User not found for this email',
            style: TextStyle(fontSize: 10.0, color: Colors.white),
          ),
        ));
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[100],
      appBar: AppBar(
        backgroundColor: Colors.brown[200],
        title: Text('Reset Password',
        style: TextStyle(color: Colors.black,
          fontWeight: FontWeight.bold,),),

      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Image.asset("assets/img/key.png",
                  width: 800.0,
                  height: 300.0,),
                Container(
                  margin: EdgeInsets.only(top: 20.0),
                  child: Text(
                    'Please Enter Your Email',
                    style: TextStyle(fontSize: 20,color: Colors.orange),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 30.0),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 5.0),
                          child: TextFormField(
                            autofocus: false,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                fontSize: 20,
                              ),
                              prefixIcon: Icon(Icons.mail), // Corrected placement
                            ),
                            controller: emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Your Email';
                              } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(value)) {
                                return 'Please Enter Valid Email';
                              }
                              return null;
                            },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      email = emailController.text;
                                    });
                                    resetPass();
                                  }
                                },
                                child: Text(
                                  'Send Email',
                                  style: TextStyle(fontSize: 15.0),
                                ),
                              ),

                            ],
                          ),
                        ),
                        Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account?"),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Signup',
                                  style:
                                  TextStyle(fontSize: 15, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
