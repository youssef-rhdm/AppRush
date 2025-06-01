import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/feedbacks_model.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;
  final AppUser? currentUser;
  final VoidCallback? onAuthRequired;
  final VoidCallback? onRSVPChanged;

  const EventDetailsPage({
    Key? key,
    required this.event,
    this.currentUser,
    this.onAuthRequired,
    this.onRSVPChanged,
  }) : super(key: key);

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final EventService _eventService = EventService();
  late Event _event;
  bool _isLoading = false;

  static const Color accentGreen = Color(0xFF39A60A);
  static const Color cardGrey = Color(0xFF222222);

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  Future<void> _handleRSVP() async {
    if (widget.currentUser == null || widget.currentUser!.isGuest) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_event.isUserAttending) {
        success = await _eventService.cancelRsvp(
          _event.eventId,
          widget.currentUser!.userId!,
        );
      } else {
        success = await _eventService.rsvpToEvent(
          _event.eventId,
          widget.currentUser!.userId!,
        );
      }

      if (success) {
        // Update the local event state
        setState(() {
          _event = Event(
            eventId: _event.eventId,
            eventName: _event.eventName,
            eventDate: _event.eventDate,
            eventLocation: _event.eventLocation,
            eventDescription: _event.eventDescription,
            eventSpeakers: _event.eventSpeakers,
            eventMaxCapacity: _event.eventMaxCapacity,
            organizerId: _event.organizerId,
            eventStatus: _event.eventStatus,
            attendeeCount: _event.isUserAttending
                ? _event.attendeeCount - 1
                : _event.attendeeCount + 1,
            isUserAttending: !_event.isUserAttending,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _event.isUserAttending
                  ? 'Successfully registered for ${_event.eventName}!'
                  : 'RSVP cancelled for ${_event.eventName}',
            ),
            backgroundColor: accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );

        widget.onRSVPChanged?.call();
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
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        title: Text('Event Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardGrey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _event.eventName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _event.eventStatus.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _event.eventStatus.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.access_time,
                    'Date & Time',
                    _formatDateTime(_event.eventDate),
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on,
                    'Location',
                    _event.eventLocation,
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.people,
                    'Attendees',
                    '${_event.attendeeCount}${_event.eventMaxCapacity != null ? '/${_event.eventMaxCapacity}' : ''} registered',
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Description
            if (_event.eventDescription != null) ...[
              Text(
                'Description',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _event.eventDescription!,
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Speakers
            if (_event.eventSpeakers != null) ...[
              Text(
                'Speakers',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _event.eventSpeakers!,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Registration Status
            if (_event.isUserAttending) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: accentGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You are registered for this event!',
                        style: TextStyle(
                          color: accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(child: _buildActionButton()),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(value, style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (!_event.canJoin && !_event.isUserAttending) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _event.isFull ? 'Event Full' : 'Registration Closed',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRSVP,
        style: ElevatedButton.styleFrom(
          backgroundColor: _event.isUserAttending ? Colors.red : accentGreen,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(
                _event.isUserAttending
                    ? 'Cancel Registration'
                    : 'Register for Event',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
