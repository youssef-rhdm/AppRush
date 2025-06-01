import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'utils/app_themes.dart';
import 'pages/create_event_page.dart';
import 'pages/pending_events_page.dart';
import 'package:badges/badges.dart' as badges;

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
  int unreadNotificationsCount = 0;
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _fetchUnreadNotificationsCount() async {
    try {
      final response = await Supabase.instance.client
          .from('notifications_table')
          .select('*')
          .eq('is_read', false)
          .count(CountOption.exact);

      if (mounted) {
        setState(() => unreadNotificationsCount = response.count ?? 0);
      }
      print('✅ Unread notifications count: ${response.count}');
    } catch (e) {
      print('❌ Error fetching unread count: $e');
      if (mounted) {
        setState(() => unreadNotificationsCount = 0);
      }
    }
  }

  Widget _buildNotificationIcon() {
    return unreadNotificationsCount > 0
        ? badges.Badge(
            badgeContent: Text(
              unreadNotificationsCount.toString(),
              style: TextStyle(color: Colors.white),
            ),
            child: Icon(Icons.notifications),
          )
        : Icon(Icons.notifications);
  }

  Future<void> _initializeApp() async {
    try {
      // Check if user is already authenticated
      final authUser = Supabase.instance.client.auth.currentUser;

      if (authUser != null) {
        // User is authenticated, fetch user data
        currentUser = await _userService.getCurrentUser();
        await _fetchUnreadNotificationsCount();
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
    _fetchUnreadNotificationsCount();
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
              : currentUser == null
              ? AuthPage(
                  onUserAuthenticated: _onLoginSuccess,
                  onCancel: () {
                    // Optional: You can exit the app or keep showing auth page
                    SystemNavigator.pop(); // This will close the app
                  },
                )
              : _buildMainApp(),
        );
      },
    );
  }

  Widget _buildMainApp() {
    final pages = <Widget>[];
    final bottomNavItems = <BottomNavigationBarItem>[];

    // Always add Home page (index 0)
    pages.add(
      HomePage(
        currentUser: currentUser,
        onAuthRequired: _showAuth,
        onLogout: _onLogout,
      ),
    );
    bottomNavItems.add(
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    );

    if (currentUser == null || currentUser!.isGuest) {
      // Guest user - only Home and Settings
      pages.add(
        SettingsPage(
          currentUser: currentUser,
          onAuthRequired: _showAuth,
          onLogout: _onLogout,
        ),
      );

      bottomNavItems.add(
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      );
    } else if (currentUser!.isAdmin) {
      // Admin: Home, Pending Events, Create Event, Notifications, Settings
      pages.addAll([
        PendingEventsPage(
          currentUser: currentUser,
          onAuthRequired: _showAuth,
        ), // index 1
        CreateEventPage(
          currentUser: currentUser,
          onAuthRequired: _showAuth,
        ), // index 2
        NotificationsPage(
          currentUser: currentUser,
          onAuthRequired: _showAuth,
        ), // index 3
        SettingsPage(
          // index 4
          currentUser: currentUser,
          onAuthRequired: _showAuth,
          onLogout: _onLogout,
        ),
      ]);

      bottomNavItems.addAll([
        BottomNavigationBarItem(
          icon: Icon(Icons.pending_actions),
          label: 'Pending',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Create',
        ),
        BottomNavigationBarItem(
          icon: _buildNotificationIcon(),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ]);
    } else if (currentUser!.isClubAdmin) {
      // Club Admin: Home, My Events, Create Event, Notifications, Settings
      pages.addAll([
        MyEventsPage(
          currentUser: currentUser,
          onAuthRequired: _showAuth,
        ), // index 1
        CreateEventPage(
          currentUser: currentUser,
          onAuthRequired: _showAuth,
        ), // index 2
        NotificationsPage(
          currentUser: currentUser,
          onAuthRequired: _showAuth,
        ), // index 3
        SettingsPage(
          // index 4
          currentUser: currentUser,
          onAuthRequired: _showAuth,
          onLogout: _onLogout,
        ),
      ]);

      bottomNavItems.addAll([
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'My Events'),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Create',
        ),
        BottomNavigationBarItem(
          icon: _buildNotificationIcon(),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ]);
    } else {
      // Normal User: Home, My Events, Notifications, Settings
      pages.addAll([
        MyEventsPage(
          currentUser: currentUser,
          onAuthRequired: _showAuth,
        ), // index 1
        NotificationsPage(
          currentUser: currentUser,
          onAuthRequired: _showAuth,
        ), // index 2
        SettingsPage(
          // index 3
          currentUser: currentUser,
          onAuthRequired: _showAuth,
          onLogout: _onLogout,
        ),
      ]);

      bottomNavItems.addAll([
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'My Events'),
        BottomNavigationBarItem(
          icon: _buildNotificationIcon(),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ]);
    }

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type:
            BottomNavigationBarType.fixed, // This ensures all tabs are visible
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        items: bottomNavItems,
      ),
    );
  }
}
