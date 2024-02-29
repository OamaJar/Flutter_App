// ignore_for_file: avoid_unnecessary_containers, deprecated_member_use, unused_element, unused_local_variable, library_private_types_in_public_api, library_prefixes, avoid_print, unused_field, unnecessary_cast, avoid_function_literals_in_foreach_calls, unrelated_type_equality_checks, unnecessary_string_interpolations, sized_box_for_whitespace
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:streetchicker/components/comments.dart';
import 'package:streetchicker/components/my_text_field.dart';
import 'package:streetchicker/components/post.dart';
import 'package:streetchicker/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/data_repository.dart';
import 'package:streetchicker/components/post.dart' as myPost;

class UserPostScreen extends StatefulWidget {
  const UserPostScreen({
    super.key,
    required this.initialEmail,
    required this.initialPassword,
  });

  final String initialEmail;
  final String initialPassword;

  @override
  _UserPostScreenState createState() => _UserPostScreenState();
}

class _UserPostScreenState extends State<UserPostScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<myPost.Post> posts = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _postsSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _postsSubscription = _firestore
        .collection('posts')
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      setState(() {
        posts.clear();
        posts.addAll(snapshot.docs.map((doc) => Post.fromJson(doc.data())));
      });
    });
  }

  @override
  void dispose() {
    _postsSubscription!.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void getPost() {
    FirebaseFirestore.instance.collection('posts').get().then((value) {
      value.docs.forEach((element) {
        element.reference.collection('likes').get().then((value) {
          posts.add(element.id as Post);
        }).catchError(
          (error) {},
        );

        posts.add(Post.fromJson(element.data()));
      });
    }).catchError((error) {});

    FirebaseFirestore.instance.collection('posts').get().then((value) {
      value.docs.forEach((element) {
        element.reference.collection('comment').get().then((value) {
          posts.add(element.id as Post);

          posts.add(Post.fromJson(element.data()));
        });
      });
    });
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

  void _sendPost(Post post) async {
    try {
      final postsCollection = FirebaseFirestore.instance.collection('posts');

      post.likes = [];

      await postsCollection.add(post.toJson());

      setState(() {
        posts.add(post);
      });
    } catch (e) {
      print('Error sending post: $e');
    }
  }

  Future<void> sendLikeToFirebase(String postId, String userId) async {
    try {
      final likesCollection = FirebaseFirestore.instance.collection('likes');
      await likesCollection.doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error sending like: $e');
    }
  }

  void _likePost(String postId, String userId) {
    final postIndex = posts.indexWhere((post) => post.likes == postId);
    if (postIndex != -1) {
      setState(() {
        posts[postIndex].addLike(userId);
      });
    }

    sendLikeToFirebase(postId, userId);
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

  void _openImage(File imageFile, YourLocation location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageGalleryView(
          imageFile: imageFile,
          location: location,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Post> posts = context.watch<DataRepository>().posts;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange[800],
          title: Text(
            "StreetChicker",
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                _openMaps(31.9539, 35.9106);
              }
            },
          ),
          actions: [
            AnimatedIconButton(
              animationController: _animationController,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        MyTextField(
                      onPostAdded: (Post post) {
                        setState(() {
                          posts.add(post);
                        });
                        getPost();
                      },
                      onSelectLocation: (YourLocation location) {},
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOutQuart;

                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));

                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: begin,
                          end: end,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: const Interval(0.0, 1.0, curve: curve),
                          ),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          MyTextField(
                        onPostAdded: (Post post) {
                          context.read<DataRepository>().addPost(post);
                          getPost();
                        },
                        onSelectLocation: (YourLocation location) {},
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOutQuart;
                        const Duration duration = Duration(seconds: 3);

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));

                        var offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: begin,
                            end: end,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: const Interval(0.0, 1.0, curve: curve),
                            ),
                          ),
                          child: child,
                        );
                      },
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.shade300,
                    ),
                    child: TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: "Write a Post",
                        hintStyle: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                for (var post in posts.reversed)
                  Container(
                    height: 350.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
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
                                if (post.location != null) {
                                  _openImage(
                                      post.selectedImage!, post.location!);
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
                                TextButton(
                                  child: const Text(
                                    "Like",
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  onPressed: () {},
                                ),
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
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
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

class _ImageGalleryView extends StatelessWidget {
  final File imageFile;
  final YourLocation? location;

  const _ImageGalleryView({Key? key, required this.imageFile, this.location});

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
      body: GestureDetector(
        onTap: () {
          if (location != null) {
            _openMaps(location!.latitude, location!.longitude);
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
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
            if (location != null)
              Positioned(
                top: 20,
                child: InkWell(
                  onTap: () {
                    if (location != null) {
                      _openMaps(location!.latitude, location!.longitude);
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white,
                        ),
                      ],
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

void _openMaps(double latitude, double longitude) async {
  var googleUrl =
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  if (await canLaunch(googleUrl)) {
    await launch(googleUrl);
  } else {
    throw 'Could not open the map.';
  }
}

class AnimatedIconButton extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onTap;

  const AnimatedIconButton({
    super.key,
    required this.animationController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.add_event,
        progress: animationController.view,
      ),
      onPressed: onTap,
    );
  }
}
