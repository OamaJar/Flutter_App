// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController usernameController = TextEditingController();
  String errorText = '';
  String successText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[800],
        title: Text(
          "Settings",
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Card(
                child: Container(
                  height: 350.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: usernameController,
                              decoration: const InputDecoration(
                                hintText: 'Enter new username',
                                border: InputBorder.none,
                                enabledBorder: UnderlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          String newUsername = usernameController.text;
                          if (_containsSpecialCharacters(newUsername) ||
                              _startsWithLowerCase(newUsername) ||
                              _containsNumbers(newUsername)) {
                            setState(() {
                              errorText = 'Invalid username format';
                              successText = '';
                            });
                          } else {
                            print('New Username: $newUsername');
                            setState(() {
                              errorText = '';
                              successText = 'Username updated successfully!';
                            });
                          }
                          if (errorText.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorText),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else if (successText.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(successText),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _containsSpecialCharacters(String value) {
    RegExp specialCharacters = RegExp(r'[!@#\$%^&*()\-_/\\]');
    return specialCharacters.hasMatch(value);
  }

  bool _startsWithLowerCase(String value) {
    RegExp startsWithLowerCase = RegExp(r'^[a-z]');
    return startsWithLowerCase.hasMatch(value);
  }

  bool _containsNumbers(String value) {
    RegExp containsNumbers = RegExp(r'[0-9]');
    return containsNumbers.hasMatch(value);
  }
}
