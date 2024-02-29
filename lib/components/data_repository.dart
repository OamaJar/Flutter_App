// ignore_for_file: unused_element, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:streetchicker/components/post.dart';

class DataRepository extends ChangeNotifier {
  List<Post> posts;
  List<Post> _posts = [];

  List<Post> get _postss => _posts;

  DataRepository() : posts = [];

  void addPost(Post post) {
    posts.add(post);
    notifyListeners();
  }

  void addPosts(List<Post> newPosts) {
    posts.addAll(newPosts);
    notifyListeners();
  }

  void deletePost(String postId) {
    posts.removeWhere((post) => post.postId == postId);
    notifyListeners();
  }
}
