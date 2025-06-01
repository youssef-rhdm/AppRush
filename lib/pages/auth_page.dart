import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AuthPage extends StatefulWidget {
  final Function(AppUser) onUserAuthenticated;
  final VoidCallback? onCancel;

  const AuthPage({Key? key, required this.onUserAuthenticated, this.onCancel})
    : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _authenticateWith42() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Replace with actual 42 authentication
      // Temporary implementation for testing
      final user = await _userService.createUser(
        userName: '42 User',
        userType: UserType.admin, // Changed from 'user' to 'normal'
        authProviderId: '42-user-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (user != null) {
        widget.onUserAuthenticated(user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to authenticate with 42')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: widget.onCancel != null
          ? AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: widget.onCancel,
              ),
              elevation: 0,
            )
          : null,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event, size: 80, color: Color(0xFF39A60A)),
              SizedBox(height: 32),
              Text(
                '1337 Events',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Sign in with your 42 account to create events and RSVP',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateWith42,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF39A60A),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Sign in with 42 Account',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              if (widget.onCancel != null) ...[
                SizedBox(height: 16),
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
