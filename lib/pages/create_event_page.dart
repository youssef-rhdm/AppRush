import 'package:flutter/material.dart';
import '../models/user_model.dart';

class CreateEventPage extends StatelessWidget {
  final AppUser? currentUser;
  final VoidCallback onAuthRequired;

  const CreateEventPage({
    required this.currentUser,
    required this.onAuthRequired,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Event')),
      body: Center(child: Text('Create Event Page Content')),
    );
  }
}
