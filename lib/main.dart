import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/my_events_page.dart';
import 'pages/notifications_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(EventApp());
}

class EventApp extends StatefulWidget {
  @override
  _EventAppState createState() => _EventAppState();
}

class _EventAppState extends State<EventApp> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      HomePage(),
      MyEventsPage(),
      NotificationsPage(),
      SettingsPage(),
    ];

    void onItemSelect(int idx) {
      print(selectedIndex);
      setState(() {
        selectedIndex = idx;
      });
    }

    return MaterialApp(
      title: 'Events App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
          secondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black.withOpacity(
            0.85,
          ), // semi-transparent black
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          elevation: 10,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: IndexedStack(index: selectedIndex, children: pages),
        bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.event),
                label: 'My Event',
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
            backgroundColor: Colors.transparent, // let theme handle it
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
