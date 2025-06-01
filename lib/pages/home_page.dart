import 'package:apprush/utils/app_themes.dart';
import 'package:flutter/material.dart';
import '../models/feedbacks_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import 'event_details_page.dart';

class HomePage extends StatefulWidget {
  final AppUser? currentUser;
  final VoidCallback? onAuthRequired;
  final VoidCallback? onLogout;

  const HomePage({
    Key? key,
    this.currentUser,
    this.onAuthRequired,
    this.onLogout,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final EventService _eventService = EventService();
  List<Event> events = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _userRSVPCount = 0;

  Color get accentGreen => Theme.of(context).primaryColor;
  Color get cardColor =>
      Theme.of(context).cardTheme.color ??
      Theme.of(context).colorScheme.surface;
  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
  Color get subtitleColor =>
      Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70;

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
      await _eventService.debugNotificationsTable();

      // First try to get upcoming events
      List<Event> fetchedEvents = await _eventService.getAllEvents(
        approvedOnly: true,
        upcomingOnly: true,
        limit: 10,
        currentUserId: widget.currentUser?.userId,
      );

      // If no upcoming events, get recent past events for demo
      if (fetchedEvents.isEmpty) {
        fetchedEvents = await _eventService.getAllEvents(
          approvedOnly: true,
          upcomingOnly: false,
          limit: 10,
          currentUserId: widget.currentUser?.userId,
        );
      }

      setState(() {
        events = fetchedEvents;
        _isLoading = false;
      });

      print('✅ Loaded ${events.length} events successfully');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load events: $e';
        });
      }
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
          backgroundColor: AppThemes.cardGrey,
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

  void _navigateToEventDetails(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(
          event: event,
          currentUser: widget.currentUser,
          onAuthRequired: widget.onAuthRequired,
          onRSVPChanged: () {
            _loadEvents();
            _loadUserRSVPCount();
          },
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isGuest = widget.currentUser?.isGuest ?? true;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '1337 Events',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.appBarTheme.foregroundColor),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.appBarTheme.foregroundColor),
            onPressed: _loadEvents,
          ),
          if (isGuest)
            TextButton(
              onPressed: widget.onAuthRequired,
              child: Text(
                'Sign In',
                style: TextStyle(color: theme.primaryColor),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'RSVPs: $_userRSVPCount',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        color: theme.primaryColor,
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
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.primaryColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You\'re browsing as a guest. Sign up to Register for events!',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onAuthRequired,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(color: theme.primaryColor),
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
                    if (widget.currentUser != null &&
                        (widget.currentUser!.isClubAdmin ||
                            widget.currentUser!.isNormalUser)) ...[
                      SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          'My RSVPs',
                          '$_userRSVPCount',
                          Icons.check_circle,
                        ),
                      ),
                    ],
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
                        color: theme.textTheme.headlineSmall?.color,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to all events page
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
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
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: theme.primaryColor, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: theme.primaryColor),
              SizedBox(height: 16),
              Text(
                'Loading Events...',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cardColor,
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
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 5),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: _loadEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              color: theme.textTheme.bodyMedium?.color,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No events available',
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for new events!',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final isGuest = widget.currentUser?.isGuest ?? true;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _navigateToEventDetails(event),
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: cardColor,
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
                  colors: [
                    theme.primaryColor.withOpacity(0.8),
                    theme.primaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Stack(
                children: [
                  Center(
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
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'View Details',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Event Description
                  if (event.eventDescription != null)
                    Text(
                      event.eventDescription!,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  SizedBox(height: 15),

                  // Event Details
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      SizedBox(width: 5),
                      Text(
                        '${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.eventLocation,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      if (event.eventSpeakers != null) ...[
                        Icon(
                          Icons.person,
                          size: 16,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.eventSpeakers!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                          Text(
                            event.eventMaxCapacity != null
                                ? '${event.attendeeCount}/${event.eventMaxCapacity}'
                                : '${event.attendeeCount} registered',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: event.isFull
                                  ? Colors.red
                                  : theme.primaryColor,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () => _navigateToEventDetails(event),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'Details',
                              style: TextStyle(color: theme.primaryColor),
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {},
                            child: ElevatedButton(
                              onPressed: () => _handleRSVP(event),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isGuest
                                    ? theme.primaryColor.withOpacity(0.7)
                                    : event.isUserAttending
                                    ? Colors.orange
                                    : event.isFull
                                    ? Colors.grey
                                    : theme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isGuest
                                    ? 'Sign Up'
                                    : event.isUserAttending
                                    ? 'Cancel'
                                    : event.isFull
                                    ? 'Full'
                                    : 'RSVP',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
