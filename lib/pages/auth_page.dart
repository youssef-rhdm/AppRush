import 'package:flutter/material.dart';
import '../services/auth42_service.dart';
import '../models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import '../services/user_service.dart';
import 'dart:async';
// import 'package:uni_links/uni_links.dart';
import 'package:app_links/app_links.dart';

class AuthPage extends StatefulWidget {
  final Function(AppUser) onUserAuthenticated;
  final VoidCallback? onCancel;

  const AuthPage({Key? key, required this.onUserAuthenticated, this.onCancel})
    : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final Auth42Service _authService = Auth42Service();
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _checkForDeepLink();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _handleSuccessfulAuth(data.session?.user);
      }
    });
  }

  Future<void> _handleSuccessfulAuth(User? user) async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      // Fetch user info from Supabase or your backend
      final userService = UserService();
      final appUser = await userService.getUserByAuthId(user.id);
      if (appUser != null) {
        widget.onUserAuthenticated(appUser);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Authentication failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkForDeepLink() async {
    try {
      final appLinks = AppLinks();
      debugPrint('Checking for deep links...');

      // Handle initial link (cold start)
      final initialUri = await appLinks.getInitialAppLink();
      if (initialUri != null) {
        debugPrint('Initial deep link: $initialUri');
        _processDeepLink(initialUri);
        return;
      }

      // Handle incoming links (while running)
      appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          debugPrint('Incoming deep link: $uri');
          _processDeepLink(uri);
        }
      });
    } catch (e) {
      debugPrint('Deep link error: $e');
    }
  }

  void _processDeepLink(Uri uri) {
    // Handle both scheme formats
    if ((uri.scheme == 'io.supabase.apprush' && uri.host == 'login') ||
        (uri.scheme == 'https' &&
            uri.host == 'bitwarlock.github.io' &&
            uri.path.startsWith('/auth42_callback'))) {
      _handleAuthCallback(uri);
    }
  }

  Future<void> _handleAuthCallback(Uri uri) async {
    if (uri.queryParameters.containsKey('code')) {
      setState(() => _isLoading = true);
      try {
        final code = uri.queryParameters['code']!;
        final tokenData = await _authService.exchangeCode(code);
        final accessToken = tokenData['access_token'];
        final userInfo = await _authService.getUserInfo(accessToken);

        // Create or get user from database
        final user = await _handleUserData(userInfo);
        if (user != null) {
          widget.onUserAuthenticated(user);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Authentication failed: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<AppUser?> _handleUserData(Map<String, dynamic> userInfo) async {
    final userName = userInfo['login'];
    final authProviderId = userInfo['id'].toString();
    final userService = UserService();

    // 1. Try to get existing user
    var user = await userService.getUserByAuthId(authProviderId);

    // 2. If user doesn't exist, create them
    if (user == null) {
      final userImage = userInfo['image']['link'];
      final isStaff = userInfo['staff?'] == true;
      final userType = isStaff ? UserType.admin : UserType.normalUser;
      final email = userInfo['email'] ?? '$userName@student.42.fr';

      user = await userService.createUser(
        userName: userName,
        userImage: userImage,
        userType: userType,
        authProviderId: authProviderId,
        email: email,
      );
    }

    return user;
  }

  Future<void> _authenticateWith42() async {
    setState(() => _isLoading = true);
    try {
      await _authService.authenticateWith42();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to authenticate: $e')));
    } finally {
      setState(() => _isLoading = false);
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
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onCancel,
              ),
              elevation: 0,
            )
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event, size: 80, color: Color(0xFF39A60A)),
              const SizedBox(height: 32),
              const Text(
                '1337 Events',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in with your 42 account to access events',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateWith42,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39A60A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign in with 42',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
