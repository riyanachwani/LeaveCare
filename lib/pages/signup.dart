import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:leavecare/utils/routes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SignupPage extends StatefulWidget {
  const SignupPage({Key? key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static Future<User?> signUp(
  {required String email,
  required String password,
  required BuildContext context}) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  try {
    // Create user account with email and password
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Get the newly created user's ID
    String userId = userCredential.user!.uid;

    // Create a new document in the 'users' collection with the user's ID
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'Email': email, // Store user's email
      'Phone Number':null,
      'Department':null,
      // Add more fields as needed
    });

    return userCredential.user;
  } on FirebaseAuthException catch (e) {
    if (e.code == "email-already-in-use") {
      print("The email address is already in use.");
    }
    print("Error signing up: ${e.code}");
    return null;
  }
}

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoggedIn = false; // Tracks login state
  final _formKey = GlobalKey<FormState>();

  void moveToLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = await signUp(
          email: _emailController.text,
          password: _passwordController.text,
          context: context,
        );
        if (user != null) {
          // User successfully created, set login status and navigate to login
          await _saveLoginStatus(true);
          Navigator.pushReplacementNamed(context, MyRoutes.loginRoute);
        } else {
          _showAlertDialog("Sign Up Failed. Please try again.");
        }
      } catch (e) {
        print("Error signing up: $e");
        _showAlertDialog("An error occurred. Please try again later.");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (_isLoggedIn) {
        // If logged in, navigate to home page directly
        Navigator.of(context).pushReplacementNamed(MyRoutes.homeRoute);
      }
    });
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Up Failed"),
        content: Text(
          message,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: SvgPicture.asset(
          "assets/images/completelogo.svg",
          width: 300,
          height: 60,
        ),
      ),
      body: Material(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        "assets/images/signup.svg",
                        fit: BoxFit.cover,
                        width: 500,
                        height: 420,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ), // Add some space between widgets
                          GestureDetector(
                            onTap: () {
                              // Navigate to login page when clicked
                              Navigator.pushNamed(context, MyRoutes.loginRoute);
                            },
                            child: Text(
                              "Already Signed Up? Login",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(
                                    0xFF417141), // Use the color code you provided
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              hintText: "Enter Email",
                              labelText: "Email",
                              labelStyle: TextStyle(fontSize: 20),
                              hintStyle: TextStyle(fontSize: 22),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Email cannot be Empty";
                              } else {
                                return null;
                              }
                            },
                          ),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              hintText: "Enter Password",
                              labelText: "Password",
                              labelStyle: TextStyle(fontSize: 20),
                              hintStyle: TextStyle(fontSize: 22),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Password cannot be Empty";
                              } else {
                                return null;
                              }
                            },
                          ),
                          const SizedBox(height: 30.0),
                          Material(
                            color: Color(0xFF69BF6F),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () => moveToLogin(context),
                              child: AnimatedContainer(
                                duration: const Duration(seconds: 1),
                                width: 150,
                                height: 50,
                                alignment: Alignment.center,
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
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
