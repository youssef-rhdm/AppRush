import 'package:flutter/material.dart';
import '../models/user_model.dart';

class NotificationsPage extends StatefulWidget {
  final AppUser? currentUser;
  final VoidCallback? onAuthRequired;

  const NotificationsPage({Key? key, this.currentUser, this.onAuthRequired}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Notifications Page - Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
