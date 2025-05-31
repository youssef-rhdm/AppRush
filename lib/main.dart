import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/my_events_page.dart';
import 'pages/notifications_page.dart';
import 'pages/settings_page.dart';
import 'pages/auth_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/user_service.dart';
import 'models/user_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qhpkxntqljmtgyayssna.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFocGt4bnRxbGptdGd5YXlzc25hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg3MDM0MDUsImV4cCI6MjA2NDI3OTQwNX0.1xbWt4ceXG9eaXO1l5yvNHhN-vqm2MpCNm5QHhq9BTM',
  );

  runApp(EventApp());
}

class EventApp extends StatefulWidget {
  @override
  _EventAppState createState() => _EventAppState();
}

class _EventAppState extends State<EventApp> {
  int selectedIndex = 0;
  AppUser? currentUser;
  final UserService _userService = UserService();
  bool _isLoading = true;
  bool _showAuthPage = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if user is already authenticated
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser != null) {
        final user = await _userService.getUserByAuthId(authUser.id);
        setState(() {
          currentUser = user;
          _isLoading = false;
        });
      } else {
        // Start as guest user
        setState(() {
          currentUser = AppUser.guest();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing app: $e');
      // Fallback to guest mode
      setState(() {
        currentUser = AppUser.guest();
        _isLoading = false;
      });
    }
  }

  void _showAuthDialog() {
    setState(() {
      _showAuthPage = true;
    });
  }

  void _onUserAuthenticated(AppUser user) {
    setState(() {
      currentUser = user;
      _showAuthPage = false;
    });
  }

  void _onAuthCancelled() {
    setState(() {
      _showAuthPage = false;
    });
  }

  void _logout() {
    setState(() {
      currentUser = AppUser.guest();
    });
    Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (_isLoading) {
      return MaterialApp(
        title: 'Events App',
        theme: _buildTheme(),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF39A60A)),
                SizedBox(height: 20),
                Text(
                  'Loading...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show auth page if requested
    if (_showAuthPage) {
      return MaterialApp(
        title: 'Events App',
        theme: _buildTheme(),
        home: AuthPage(
          onUserAuthenticated: _onUserAuthenticated,
          onCancel: _onAuthCancelled,
        ),
      );
    }

    // Show main app
    List<Widget> pages = [
      HomePage(currentUser: currentUser, onAuthRequired: _showAuthDialog),
      MyEventsPage(currentUser: currentUser, onAuthRequired: _showAuthDialog),
      NotificationsPage(
        currentUser: currentUser,
        onAuthRequired: _showAuthDialog,
      ),
      SettingsPage(
        currentUser: currentUser,
        onAuthRequired: _showAuthDialog,
        onLogout: _logout,
      ),
    ];

    void onItemSelect(int idx) {
      setState(() {
        selectedIndex = idx;
      });
    }

    return MaterialApp(
      title: 'Events App',
      theme: _buildTheme(),
      home: Scaffold(
        body: IndexedStack(index: selectedIndex, children: pages),
        bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.event),
                label: 'My Events',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: selectedIndex,
            onTap: onItemSelect,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        primary: Colors.black,
        secondary: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.black.withOpacity(0.85),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        elevation: 10,
      ),
      useMaterial3: true,
    );
  }
}
