import 'package:flutter/material.dart';
import '../models/feedbacks_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

class HomePage extends StatefulWidget {
  final AppUser? currentUser;
  final VoidCallback? onAuthRequired;
  final VoidCallback? onLogout;

  const HomePage({Key? key, this.currentUser, this.onAuthRequired, this.onLogout})
    : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final EventService _eventService = EventService();
  List<Event> events = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _userRSVPCount = 0;

  static const Color accentGreen = Color(0xFF39A60A);
  static const Color cardGrey = Color(0xFF222222);

  @override
  void initState() {
    super.initState();
    _loadEvents();
    if (widget.currentUser != null && !widget.currentUser!.isGuest) {
      _loadUserRSVPCount();
    }
  }
  Future<void> _loadEvents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Debug: Check database content
      await _eventService.debugDatabase();

      final fetchedEvents = await _eventService.getAllEvents(
        approvedOnly: true,
        upcomingOnly: true,
        limit: 10,
        currentUserId: widget.currentUser?.userId,
      );

      setState(() {
        events = fetchedEvents;
        _isLoading = false;
      });

      print('✅ Loaded ${events.length} events successfully');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load events: $e';
      });
      print('❌ Error loading events: $e');
    }
  }

  Future<void> _loadUserRSVPCount() async {
    if (widget.currentUser == null || widget.currentUser!.isGuest) return;

    try {
      final userEvents = await _eventService.getUserAttendingEvents(
        widget.currentUser!.userId!,
      );
      setState(() {
        _userRSVPCount = userEvents.length;
      });
    } catch (e) {
      print('Error loading user RSVP count: $e');
    }
  }

  Future<void> _handleRSVP(Event event) async {
    if (widget.currentUser == null || widget.currentUser!.isGuest) {
      _showLoginRequiredDialog();
      return;
    }

    try {
      bool success;
      if (event.isUserAttending) {
        success = await _eventService.cancelRsvp(
          event.eventId,
          widget.currentUser!.userId!,
        );
      } else {
        success = await _eventService.rsvpToEvent(
          event.eventId,
          widget.currentUser!.userId!,
        );
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              event.isUserAttending
                  ? 'RSVP cancelled for ${event.eventName}'
                  : 'Successfully registered for ${event.eventName}!',
            ),
            backgroundColor: accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _loadEvents();
        _loadUserRSVPCount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update RSVP. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Account Required',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Please create an account to register for events and access additional features.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onAuthRequired?.call();
              },
              child: Text('Sign Up', style: TextStyle(color: accentGreen)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = widget.currentUser?.isGuest ?? true;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '1337 Events',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEvents,
          ),
          if (isGuest)
            IconButton(
              icon: Icon(Icons.login, color: accentGreen),
              onPressed: widget.onAuthRequired,
            )
          else
            IconButton(
              icon: Icon(Icons.person, color: Colors.white),
              onPressed: () {
                // Navigate to profile
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        color: accentGreen,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              // Guest banner
              if (isGuest)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: accentGreen),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You\'re browsing as a guest. Sign up to Register for events!',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onAuthRequired,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(color: accentGreen),
                        ),
                      ),
                    ],
                  ),
                ),

              if (isGuest) SizedBox(height: 20),

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
                        isGuest ? 'Sign up to RSVP' : 'My RSVPs',
                        isGuest ? '-' : '$_userRSVPCount',
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
                        // Navigate to all events page
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

              // Content based on loading state
              if (_isLoading)
                _buildLoadingWidget()
              else if (_errorMessage != null)
                _buildErrorWidget()
              else if (events.isEmpty)
                _buildEmptyStateWidget()
              else
                _buildEventsList(),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.currentUser?.canCreateEvents == true
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create-event');
              },
              backgroundColor: accentGreen,
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // ... rest of the widget methods remain the same but update RSVP button text for guests

  Widget _buildEventCard(Event event) {
    final isGuest = widget.currentUser?.isGuest ?? true;

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
          // Event Image Placeholder
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentGreen.withOpacity(0.8), accentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event, size: 50, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    event.eventName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
                  event.eventName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 8),

                // Event Description
                if (event.eventDescription != null)
                  Text(
                    event.eventDescription!,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                SizedBox(height: 15),

                // Event Details
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                    Icon(Icons.access_time, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      '${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        event.eventLocation,
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                    if (event.eventSpeakers != null) ...[
                      Icon(Icons.person, size: 16, color: Colors.white),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.eventSpeakers!,
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    ],
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
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        Text(
                          event.eventMaxCapacity != null
                              ? '${event.attendeeCount}/${event.eventMaxCapacity}'
                              : '${event.attendeeCount} registered',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: event.isFull ? Colors.red : accentGreen,
                          ),
                        ),
                      ],
                    ),

                    ElevatedButton(
                      onPressed: () => _handleRSVP(event),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isGuest
                            ? accentGreen.withOpacity(0.7)
                            : event.isUserAttending
                            ? Colors.orange
                            : event.isFull
                            ? Colors.grey
                            : accentGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isGuest
                            ? 'Sign Up to RSVP'
                            : event.isUserAttending
                            ? 'Cancel'
                            : event.isFull
                            ? 'Full'
                            : 'RSVP',
                      ),
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

  // Add the missing widget methods
  Widget _buildLoadingWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: List.generate(3, (index) => _buildLoadingCard())),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      height: 300,
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(child: CircularProgressIndicator(color: accentGreen)),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardGrey,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 10),
            Text(
              'Error Loading Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: _loadEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cardGrey,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.white54),
            SizedBox(height: 20),
            Text(
              'No Events Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'There are no upcoming events at the moment. Check back later!',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildEventCard(events[index]);
      },
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
            style: TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
