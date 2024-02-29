import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';

class NotificationButtonWidget extends StatelessWidget {
  final Function onNotificationPressed;
  final int notificationCount;

  const NotificationButtonWidget({
    super.key,
    required this.onNotificationPressed,
    required this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    return badges.Badge(
      position: BadgePosition.topEnd(top: 0, end: 3),
      badgeContent: Text(
        notificationCount.toString(),
        style: const TextStyle(color: Colors.white),
      ),
      child: IconButton(
        onPressed: () {
          onNotificationPressed();
        },
        icon: const Icon(Icons.notifications),
      ),
    );
  }
}
