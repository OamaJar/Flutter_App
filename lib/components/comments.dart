// ignore_for_file: library_private_types_in_public_api, avoid_print, unused_element, use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  late TextEditingController _commentController;
  late List<String> _comments;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _commentsSubscription;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _comments = [];
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      _commentsSubscription =
          _firestore.collection('comments').snapshots().listen(
        (QuerySnapshot<Map<String, dynamic>> snapshot) {
          setState(() {
            _comments =
                snapshot.docs.map((doc) => doc['comment'].toString()).toList();
          });
        },
      );
    } catch (e) {
      print('Error loading comments: $e');
    }
  }

  @override
  void dispose() {
    _commentsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _saveComments() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('comments', _comments);
  }

  void _addComment(String comment) async {
    try {
      await _firestore.collection('comments').add({
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _commentController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We will contact the relevant authorities.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
      ),
      body: Container(
        height: 800,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black),
                      ),
                    ),
                    child: ListTile(
                      title: Text(_comments[index]),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: 'Enter a comment',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _addComment(_commentController.text),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
