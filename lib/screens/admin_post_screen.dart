// ignore_for_file: deprecated_member_use, unused_element, library_private_types_in_public_api, library_prefixes, avoid_unnecessary_containers, non_constant_identifier_names, unused_label, unused_import, avoid_print, unnecessary_string_interpolations

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:like_button/like_button.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:streetchicker/components/comments.dart';
import 'package:streetchicker/components/show_notification_widget.dart';
import 'package:streetchicker/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:streetchicker/components/data_repository.dart';
import 'package:streetchicker/components/my_text_field.dart' as myTextField;
import 'package:streetchicker/components/post.dart';
import 'package:streetchicker/screens/settings_screen.dart';

class AdminPostScreen extends StatefulWidget {
  const AdminPostScreen({
    super.key,
    required this.initialEmail,
    required this.initialPassword,
  });

  final String initialEmail;
  final String initialPassword;

  @override
  _AdminPostScreenState createState() => _AdminPostScreenState();
}

class _AdminPostScreenState extends State<AdminPostScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<Post> posts = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _configureFirebaseMessaging();
  }

  void _configureFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received notification: ${message.notification?.title}");
      _showNotification(message.notification?.title ?? '');
    });
  }

  void _deletePost(String postId) async {
    try {
      setState(() {
        posts.removeWhere((post) => post.postId == postId);
      });
      context.read<DataRepository>().deletePost(postId);

      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'Your App Name',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Post',
      message,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
    setState(() {
      notificationCount++;
    });
  }

  void _openImage(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageGalleryView(imageFile: imageFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Post> posts = context.watch<DataRepository>().posts;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lightBlueAccent,
          title: Text(
            "StreetChicker",
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  notificationCount = 0;
                });
              },
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (notificationCount > 0)
                    Positioned(
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 10,
                        child: Text(
                          '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Icon(
                  Icons.logout_rounded,
                  color: Colors.grey[800],
                ),
                text: "Logout",
              ),
              Tab(
                icon: Icon(
                  Icons.settings,
                  color: Colors.grey[800],
                ),
                text: "Settings",
              ),
              Tab(
                icon: Icon(
                  Icons.map,
                  color: Colors.grey[800],
                ),
                text: "Map",
              ),
            ],
            onTap: (index) {
              if (index == 0) {
                _logout();
              } else if (index == 1) {
                _settings();
              } else if (index == 2) {
                _openMaps(31.9539, 35.9106);
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                for (var post in posts.reversed)
                  Card(
                    child: Container(
                      height: 350.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey[100],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Category: ${post.category}",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "${post.postText}",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Container(
                              width: 400,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.blue,
                                image: post.selectedImage != null
                                    ? DecorationImage(
                                        image: FileImage(post.selectedImage!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: InkWell(
                                onTap: () {
                                  if (post.selectedImage != null) {
                                    _openImage(post.selectedImage!);
                                  }
                                },
                                child: post.location != null
                                    ? Stack(
                                        children: [
                                          Positioned(
                                            top: 20,
                                            left: 20,
                                            child: InkWell(
                                              onTap: () {
                                                if (post.location != null) {
                                                  _openMaps(
                                                    post.location!.latitude,
                                                    post.location!.longitude,
                                                  );
                                                }
                                              },
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.blue,
                                                ),
                                                child: const Icon(
                                                  Icons.location_on,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Container(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  LikeButton(
                                    countPostion: CountPostion.bottom,
                                    likeBuilder: (isLiked) {
                                      return Icon(
                                        Icons.favorite,
                                        color: isLiked
                                            ? Colors.orange[800]
                                            : Colors.grey,
                                      );
                                    },
                                  ),
                                  const Text(
                                    "Like",
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  LikeButton(
                                    countPostion: CountPostion.bottom,
                                    likeBuilder: (isTapped) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const CommentsScreen(),
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          Icons.comment,
                                          color: isTapped
                                              ? Colors.orange[800]
                                              : Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                  const Text(
                                    "Comment",
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Delete Post"),
                                            content: const Text(
                                                "Are you sure you want to delete this post?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _deletePost(post.postId);
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text("Delete"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.grey,
                                    ),
                                    label: const Text(
                                      "delete",
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(
          initialEmail: '',
          initialPassword: '',
        ),
      ),
    );
  }

  void _settings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _openMaps(double latitude, double longitude) async {
    final googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _ImageGalleryView extends StatelessWidget {
  final File imageFile;
  final myTextField.YourLocation? location;

  const _ImageGalleryView({super.key, required this.imageFile, this.location});

  void _openMaps(double latitude, double longitude) async {
    final googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        child: PhotoViewGallery.builder(
          itemCount: 1,
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: FileImage(imageFile),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          },
          scrollPhysics: const BouncingScrollPhysics(),
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          pageController: PageController(),
        ),
      ),
      floatingActionButton: location != null
          ? FloatingActionButton(
              onPressed: () {
                if (location != null) {
                  _openMaps(location!.latitude, location!.longitude);
                }
              },
              child: const Icon(Icons.location_on),
            )
          : null,
    );
  }
}
