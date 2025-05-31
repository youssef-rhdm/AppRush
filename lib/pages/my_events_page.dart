import 'package:flutter/material.dart';
import '../models/user_model.dart';

class MyEventsPage extends StatefulWidget {
  final AppUser? currentUser;
  final VoidCallback? onAuthRequired;

  const MyEventsPage({Key? key, this.currentUser, this.onAuthRequired}) : super(key: key);

  @override
  _MyEventsPageState createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('My Events', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'My Events Page - Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
