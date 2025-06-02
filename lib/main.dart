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
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase without auth
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
  int unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if we have a stored user ID (using shared_preferences)
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('current_user_id');

      if (storedUserId != null) {
        final user = await _userService.getUserByAuthId(storedUserId);
        if (user != null && mounted) {
          setState(() {
            currentUser = user;
            _isLoading = false;
          });
          return;
        }
      }

      // No stored user - show auth page
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchUserData(String authProviderId) async {
    try {
      final user = await _userService.getUserByAuthId(authProviderId);
      if (user == null) {
        print('User not found in database');
        return;
      }

      // Store user ID for future sessions
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', authProviderId);

      if (mounted) {
        setState(() => currentUser = user);
        await _fetchUnreadNotificationsCount();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchUnreadNotificationsCount() async {
    try {
      if (currentUser == null) return;
      final response = await Supabase.instance.client
          .from('notifications_table')
          .select('*')
          .eq('user_id', currentUser!.userId!)
          .eq('is_read', false)
          .count(CountOption.exact);

      if (mounted) {
        setState(() => unreadNotificationsCount = response.count ?? 0);
      }
    } catch (e) {
      print('Error fetching unread count: $e');
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

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _onLoginSuccess(AppUser user) {
    _fetchUserData(user.authProviderId!);
  }

  void _onLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      setState(() {
        currentUser = null;
        selectedIndex = 0;
      });
    } catch (e) {
      print('Error logging out: $e');
    }
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
                  onCancel: () => SystemNavigator.pop(),
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
    pages.add(HomePage(currentUser: currentUser, onLogout: _onLogout));
    bottomNavItems.add(
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    );

    if (currentUser == null || currentUser!.isGuest) {
      // Guest user - only Home and Settings
      pages.add(SettingsPage(currentUser: currentUser, onLogout: _onLogout));

      bottomNavItems.add(
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      );
    } else if (currentUser!.isAdmin) {
      // Admin: Home, Pending Events, Create Event, Notifications, Settings
      pages.addAll([
        // PendingEventsPage(currentUser: currentUser),
        // CreateEventPage(currentUser: currentUser),
        NotificationsPage(currentUser: currentUser),
        SettingsPage(currentUser: currentUser, onLogout: _onLogout),
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
        MyEventsPage(currentUser: currentUser),
        // CreateEventPage(currentUser: currentUser),
        NotificationsPage(currentUser: currentUser),
        SettingsPage(currentUser: currentUser, onLogout: _onLogout),
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
        MyEventsPage(currentUser: currentUser),
        NotificationsPage(currentUser: currentUser),
        SettingsPage(currentUser: currentUser, onLogout: _onLogout),
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
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        items: bottomNavItems,
      ),
    );
  }
}
