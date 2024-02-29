// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously, unused_element, unused_local_variable

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:streetchicker/screens/admin_post_screen.dart';
import 'package:streetchicker/screens/login_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  Future<void> _registerWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      String email = userCredential.user?.email ?? "";
      String password = "";
      String username = "";

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminPostScreen(
            initialEmail: email,
            initialPassword: password,
          ),
        ),
      );
    } catch (e) {
      print("Error during Google registration: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image, String userId) async {
    try {
      final fileName =
          'userImages/$userId/${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final result = await ref.putFile(image);
      final imageUrl = await result.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  void _showErrorSnackBar(String errorMessage) {
    final snackBar = SnackBar(
      content: Text(errorMessage),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      _showErrorSnackBar("Please fill in all fields.");
      return;
    }
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (_image != null) {
        final imageUrl = await _uploadImage(_image!, userCredential.user!.uid);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(
            initialEmail: '',
            initialPassword: '',
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar("Error during registration: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [
                Colors.orange.shade900,
                Colors.orange.shade800,
                Colors.orange.shade400,
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 80),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Let's Begin",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Fix your city",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(60),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        GestureDetector(
                          onTap: _pickImage,
                          child: Center(
                            child: (CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  _image != null ? FileImage(_image!) : null,
                              child: _image == null
                                  ? Icon(
                                      Icons.add_a_photo,
                                      color: Colors.grey.shade800,
                                    )
                                  : null,
                            )),
                          ),
                        ),
                        const SizedBox(height: 60),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromARGB(225, 95, 27, 3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    hintText: "Email",
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: "Password",
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                child: TextField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    hintText: "Username",
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Text(
                                      "Already have an account?",
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPage(
                                              initialPassword: '',
                                              initialEmail: '',
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Login",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              ElevatedButton(
                                onPressed: () async {
                                  String email = _emailController.text.trim();
                                  String password =
                                      _passwordController.text.trim();
                                  String username =
                                      _usernameController.text.trim();

                                  if (email.isEmpty ||
                                      password.isEmpty ||
                                      username.isEmpty) {
                                    _showErrorSnackBar(
                                        "Please enter username, email, and password.");
                                    return;
                                  }

                                  if (!RegExp(
                                          r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+')
                                      .hasMatch(email)) {
                                    _showErrorSnackBar(
                                        "Please provide a valid email address.");
                                    return;
                                  }

                                  if (!RegExp(r'^[a-zA-Z0-9]+$')
                                      .hasMatch(username)) {
                                    _showErrorSnackBar(
                                        "Invalid characters in the username.");
                                    return;
                                  }

                                  if (!RegExp(
                                          r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$')
                                      .hasMatch(password)) {
                                    _showErrorSnackBar(
                                        "Invalid password format. It should be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, and one special character.");
                                    return;
                                  }

                                  try {
                                    UserCredential userCredential = await _auth
                                        .createUserWithEmailAndPassword(
                                      email: email,
                                      password: password,
                                    );

                                    String registeredEmail =
                                        userCredential.user?.email ?? "";
                                    String registeredPassword = password;

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginPage(
                                          initialEmail: registeredEmail,
                                          initialPassword: registeredPassword,
                                        ),
                                      ),
                                    );
                                    print(
                                        "User registered: ${userCredential.user?.email}");
                                  } catch (e) {
                                    _showErrorSnackBar(
                                        "Error during registration: $e");
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade900,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 50),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.black,
                                      ),
                                      child: Center(
                                        child: TextButton(
                                          onPressed: _registerWithGoogle,
                                          child: const Text(
                                            "Google",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
