import 'package:flutter/material.dart';
import '../models/user_model.dart';

class SettingsPage extends StatefulWidget {
  final AppUser? currentUser;
  final VoidCallback? onAuthRequired;
  final VoidCallback? onLogout;

  const SettingsPage({Key? key, this.currentUser, this.onAuthRequired, this.onLogout}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          'Settings Page - Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
