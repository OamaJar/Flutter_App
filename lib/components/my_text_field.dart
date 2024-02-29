// ignore_for_file: avoid_unnecessary_containers, deprecated_member_use, avoid_print, unused_element, unused_field, library_private_types_in_public_api, prefer_const_declarations, unused_local_variable

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:streetchicker/components/post.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:uuid/uuid.dart';

class YourLocation {
  final double latitude;
  final double longitude;
  final String address;

  YourLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory YourLocation.fromJson(Map<String, dynamic> json) {
    return YourLocation(
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class MyTextField extends StatefulWidget {
  const MyTextField({
    super.key,
    required this.onSelectLocation,
    required this.onPostAdded,
  });

  final void Function(YourLocation location) onSelectLocation;
  final void Function(Post post) onPostAdded;

  @override
  _MyTextFieldState createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField>
    with SingleTickerProviderStateMixin {
  final TextEditingController _postController = TextEditingController();
  late AnimationController _animationController;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  YourLocation? _pickedLocation;
  var _isGettingLocation = false;
  bool _isLoading = false;
  String? _selectedCategory;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Uuid uuid = const Uuid();

  void _configureFirebaseMessaging() {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Subscribe admin to the 'admin' topic
    messaging.subscribeToTopic('admin');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received notification: ${message.notification?.title}");
      // Handle the received notification, e.g., show a local notification
      _showNotification((message.notification?.title ?? '') as Function);
    });
  }

  void _showNotification(Function callback) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

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
      'A new post has been added!',
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );

    // Call the callback function
    callback();
  }

  void handleNotification() {
    print('Notification received in main widget!');
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Water'),
                onTap: () {
                  setState(() {
                    _selectedCategory = 'Water';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Street'),
                onTap: () {
                  setState(() {
                    _selectedCategory = 'Street';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Electricity'),
                onTap: () {
                  setState(() {
                    _selectedCategory = 'Electricity';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadPostToFirebase(Post post) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await FirebaseFirestore.instance.collection('posts').add(post.toJson());
      await _sendAdminNotification('New Post', 'A new post has been added!');

      print('Uploading post to Firebase...');

      if (post.selectedImage != null) {
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('images/${DateTime.now()}.png');
        await storageRef.putFile(post.selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        post.imageURL = imageUrl;
      }
      post.postId = uuid.v4();
      post.comments = [];
      await FirebaseFirestore.instance.collection('posts').add(post.toJson());

      setState(() {
        _selectedImage = null;
        _pickedLocation = null;
        _isLoading = false;
        _postController.clear();
        _selectedCategory = null;
      });

      widget.onPostAdded(post);

      print('Post uploaded successfully!');
    } catch (e) {
      print('Error uploading post to Firebase: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendAdminNotification(String title, String body) async {
    try {
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings =
          const InitializationSettings(
        android: androidInitializationSettings,
        iOS: null,
      );
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
        title,
        body,
        platformChannelSpecifics,
        payload: 'Default_Sound',
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  void _getImageFromCamera() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);

    setState(() {
      _selectedImage = pickedFile != null ? File(pickedFile.path) : null;
    });
  }

  Future<void> savePlace(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=API_KEY',
    );

    final response = await http.get(url);
    final resData = json.decode(response.body);
    final address = resData['results'][0]['formatted_address'];

    void setupPushNotfications() async {
      final fcm = FirebaseMessaging.instance;

      final notificationSettings = await fcm.requestPermission();
      notificationSettings.alert;

      fcm.subscribeToTopic('post');
    }

    setState(() {
      _pickedLocation = YourLocation(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      _isGettingLocation = false;
    });

    widget.onSelectLocation(_pickedLocation!);

    setupPushNotfications();
  }

  Future<void> _saveCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    setState(() {
      _isGettingLocation = true;
    });

    locationData = await location.getLocation();
    final lat = locationData.latitude;
    final lng = locationData.longitude;

    if (lat == null || lng == null) {
      return;
    }
    savePlace(lat, lng);

    _openMaps(lat, lng);
  }

  void _openMaps(double latitude, double longitude) async {
    var googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleUrl)) {
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  void _openImage(File imageFile) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageGalleryView(imageFile: imageFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: Colors.grey[800],
        appBar: AppBar(
          backgroundColor: Colors.grey[800],
          actions: [
            TextButton(
              onPressed: () {
                if (_postController.text.isNotEmpty || _selectedImage != null) {
                  final newPost = Post(
                    postId: uuid.v4(),
                    postText: _postController.text,
                    selectedImage: _selectedImage,
                    likes: [],
                    comments: [],
                    category: _selectedCategory,
                    location: _pickedLocation,
                  );

                  _uploadPostToFirebase(newPost);
                  _showNotification(handleNotification);

                  widget.onPostAdded(newPost);

                  Navigator.pop(context);
                } else {
                  print("error");
                }
              },
              child: const Text(
                "Post",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 598,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.shade600,
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _postController,
                          onTap: () {
                            setState(() {
                              _animationController.forward();
                            });
                          },
                          onSubmitted: (String value) {
                            setState(() {
                              _animationController.reverse();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: "Write a Post",
                            helperStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        Container(
                          height: 500,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                          ),
                          child: InkWell(
                            onTap: () {
                              if (_selectedImage != null) {
                                _openImage(_selectedImage!);
                              }
                            },
                            child: Container(
                              height: 500,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade500,
                              ),
                              child: _selectedImage != null
                                  ? Stack(
                                      children: [
                                        Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                        if (_pickedLocation != null)
                                          Positioned(
                                            top: 20,
                                            left: 20,
                                            child: InkWell(
                                              onTap: () {
                                                if (_pickedLocation != null) {
                                                  _openMaps(
                                                    _pickedLocation!.latitude,
                                                    _pickedLocation!.longitude,
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
                        Container(
                          height: 50,
                          color: Colors.grey.shade400,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _showCategoryBottomSheet();
                                },
                                child: Text(
                                  _selectedCategory ?? 'Select Category',
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  _getImageFromCamera();
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                ),
                                onPressed: _saveCurrentLocation,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImageGalleryView extends StatelessWidget {
  final File imageFile;

  const _ImageGalleryView({super.key, required this.imageFile});

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
    );
  }
}
