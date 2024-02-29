import 'dart:io';

import 'package:streetchicker/components/my_text_field.dart';

class Post {
  String postId;
  final String postText;
  final File? selectedImage;
  final YourLocation? location;
  late final String? imageURL;
  late final List<String> likes;
  final String? category;
  List<String> comments;

  Post({
    required this.postId,
    required this.postText,
    required this.likes,
    this.selectedImage,
    this.location,
    this.imageURL,
    this.category,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'] as String,
      postText: json['postText'] as String,
      selectedImage: json['selectedImage'] != null
          ? File(json['selectedImage'] as String)
          : null,
      location: json['location'] != null
          ? YourLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      imageURL: json['imageURL'] as String?,
      likes: (json['likes'] as List<dynamic>?)?.cast<String>() ?? [],
      category: json['category'] as String?,
      comments: List<String>.from(json['comments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'postText': postText,
      'selectedImage': selectedImage?.path,
      'location': location?.toJson(),
      'imageURL': imageURL,
      'likes': likes,
      'category': category,
      'comments': comments,
    };
  }

  void addLike(String userId) {
    likes.add(userId);
  }

  void addComment(String commentId) {
    comments.add(commentId);
  }
}
