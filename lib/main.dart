import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';
import 'pages/my_events_page.dart';
import 'pages/notifications_page.dart';
import 'pages/settings_page.dart';
import 'pages/auth_page.dart';
import 'services/user_service.dart';
import 'models/user_model.dart';
import 'providers/theme_provider.dart';
import 'utils/app_themes.dart'; // Add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qhpkxntqljmtgyayssna.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFocGt4bnRxbGptdGd5YXlzc25hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg3MDM0MDUsImV4cCI6MjA2NDI3OTQwNX0.1xbWt4ceXG9eaXO1l5yvNHhN-vqm2MpCNm5QHhq9BTM',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: EventApp(),
   ),
  );
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
        // User is authenticated, fetch user data
        currentUser = await _userService.getCurrentUser();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing app: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
      _showAuthPage = false;
    });
  }

  void _showAuth() {
    setState(() {
      _showAuthPage = true;
    });
  }

  void _hideAuth() {
    setState(() {
      _showAuthPage = false;
    });
  }

  void _onLoginSuccess(AppUser user) {
    setState(() {
      currentUser = user;
      _showAuthPage = false;
    });
  }

  void _onLogout() {
    setState(() {
      currentUser = null;
      selectedIndex = 0;
      _showAuthPage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: '1337 Events',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          home: _isLoading
              ? Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                )
              : _showAuthPage
              ? AuthPage(onUserAuthenticated: _onLoginSuccess, onCancel: _hideAuth)
              : _buildMainApp(),
        );
      },
    );
  }

  Widget _buildMainApp() {
    final pages = [
      HomePage(
        currentUser: currentUser,
        onAuthRequired: _showAuth,
        onLogout: _onLogout,
      ),
      MyEventsPage(currentUser: currentUser, onAuthRequired: _showAuth),
      NotificationsPage(currentUser: currentUser, onAuthRequired: _showAuth),
      SettingsPage(
        currentUser: currentUser,
        onAuthRequired: _showAuth,
        onLogout: _onLogout,
      ),
    ];

    return Scaffold(
      body: pages[selectedIndex],
     bottomNavigationBar: BottomNavigationBar(
  currentIndex: selectedIndex,
  onTap: _onItemTapped,
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.event), label: 'My Events'),
    BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ],
),
    );
  }
}
