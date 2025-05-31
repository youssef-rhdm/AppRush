import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Sample event data
  final List<Map<String, dynamic>> events = [
    {
      'title': 'Flutter Workshop',
      'description': 'Learn mobile app development with Flutter',
      'date': 'Dec 15, 2024',
      'time': '14:00 - 17:00',
      'location': 'Room A-101',
      'speaker': 'John Doe',
      'capacity': 30,
      'registered': 18,
      'image': 'https://via.placeholder.com/300x150/4285F4/FFFFFF?text=Flutter',
    },
    {
      'title': 'AI & Machine Learning Talk',
      'description': 'Exploring the future of artificial intelligence',
      'date': 'Dec 18, 2024',
      'time': '10:00 - 12:00',
      'location': 'Auditorium',
      'speaker': 'Jane Smith',
      'capacity': 100,
      'registered': 67,
      'image': 'https://via.placeholder.com/300x150/FF6B6B/FFFFFF?text=AI+ML',
    },
    {
      'title': 'Coding Night',
      'description': 'Collaborative coding session and networking',
      'date': 'Dec 20, 2024',
      'time': '19:00 - 23:00',
      'location': 'Lab B-205',
      'speaker': 'Multiple Mentors',
      'capacity': 50,
      'registered': 23,
      'image': 'https://via.placeholder.com/300x150/4ECDC4/FFFFFF?text=Coding',
    },
    {
      'title': 'Web Development Bootcamp',
      'description': 'Full-stack web development intensive course',
      'date': 'Dec 22, 2024',
      'time': '09:00 - 18:00',
      'location': 'Room C-301',
      'speaker': 'Tech Team',
      'capacity': 25,
      'registered': 25,
      'image': 'https://via.placeholder.com/300x150/45B7D1/FFFFFF?text=Web+Dev',
    },
  ];

  static const Color accentGreen = Color(0xFF39A60A);
  static const Color cardGrey = Color(0xFF222222);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '1337 Events',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Navigate to profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),

            // Quick Stats
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Upcoming Events',
                      '${events.length}',
                      Icons.event,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      'My RSVPs',
                      '3',
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Section Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // View all events
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text('View All'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),

            // Events List
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return _buildEventCard(events[index]);
              },
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-event');
        },
        backgroundColor: accentGreen,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    bool isFull = event['registered'] >= event['capacity'];

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: event['image'] != null
                ? Image.network(
                    event['image'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey[800],
                      child: Center(
                        child: Icon(Icons.event, size: 50, color: Colors.white),
                      ),
                    ),
                  )
                : Container(
                    height: 150,
                    color: Colors.grey[800],
                    child: Center(
                      child: Icon(Icons.event, size: 50, color: Colors.white),
                    ),
                  ),
          ),

          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Title
                Text(
                  event['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 8),

                // Event Description
                Text(
                  event['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),

                SizedBox(height: 15),

                // Event Details
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      event['date'],
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    SizedBox(width: 15),
                    Icon(Icons.access_time, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      event['time'],
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      event['location'],
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    SizedBox(width: 15),
                    Icon(Icons.person, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      event['speaker'],
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),

                SizedBox(height: 15),

                // Capacity and RSVP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Capacity',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '${event['registered']}/${event['capacity']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isFull ? Colors.red : accentGreen,
                          ),
                        ),
                      ],
                    ),

                    ElevatedButton(
                      onPressed: isFull
                          ? null
                          : () {
                              _showRSVPDialog(event['title']);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFull ? Colors.grey : accentGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        disabledBackgroundColor: Colors.grey[700],
                        disabledForegroundColor: Colors.white54,
                        elevation: 0,
                      ),
                      child: Text(isFull ? 'Full' : 'RSVP'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRSVPDialog(String eventTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('RSVP Confirmation', style: TextStyle(color: Colors.white)),
          content: Text(
            'Do you want to register for "$eventTitle"?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: accentGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully registered for $eventTitle!'),
                    backgroundColor: accentGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}