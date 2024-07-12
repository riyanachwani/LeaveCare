import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leavecare/utils/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoggedIn = false; // Tracks login state

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false; // Default to false
      if (_isLoggedIn) {
        // If logged in, navigate to home page directly
        Navigator.of(context).pushReplacementNamed(MyRoutes.homeRoute);
      }
    });
  }

  static Future<User?> login(
      {required String email,
      required String password,
      required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        print("No user found for entered email");
        return null; // Handle user not found gracefully (optional)
      } else if (e.code == "wrong-password") {
        print("Incorrect password");
        return null; // Handle wrong password gracefully (optional)
      }
      return null; // Handle other errors (optional)
    }
  }

  Future<void> _saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  void moveToHome(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = await login(
            email: _emailController.text,
            password: _passwordController.text,
            context: context);
        if (user != null) {
          await _saveLoginStatus(true); // Set login status to true
          Navigator.of(context).pushReplacementNamed(MyRoutes.homeRoute);
        } else {
          _showAlertDialog("Incorrect credentials. Please try again.");
        }
      } on FirebaseAuthException catch (e) {
        print("Error logging in: ${e.code}"); // Log the error for debugging
        _showAlertDialog("An error occurred. Please try again later.");
      }
    }
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Failed"),
        content: Text(
          message,
          style: TextStyle(fontSize: 16), // Increase text size
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Adjust to avoid bottom overflow issues
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
                Padding(
                  padding: const EdgeInsets.only(top: 65.0),
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: SvgPicture.asset(
                            "assets/images/login.svg",
                            fit: BoxFit.cover,
                            height: 340,
                          ),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Log in",
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
                                  Navigator.pushNamed(
                                      context, MyRoutes.signupRoute);
                                },
                                child: Text(
                                  "Create a new account",
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
                        const SizedBox(height: 5.0),
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
                                  onTap: () => moveToHome(context),
                                  child: AnimatedContainer(
                                    duration: const Duration(seconds: 1),
                                    width: 150,
                                    height: 50,
                                    alignment: Alignment.center,
                                    child: const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22, // Increase text size
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
