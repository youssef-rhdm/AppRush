import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../models/event_feedback_model.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user from auth
  User? get currentAuthUser => _supabase.auth.currentUser;

  // Create a new event
  Future<Event?> createEvent({
    required String eventName,
    required DateTime eventDate,
    required String eventLocation,
    String? eventDescription,
    String? eventSpeakers,
    int? eventMaxCapacity,
    required int organizerId,
  }) async {
    try {
      final eventData = {
        'event_name': eventName,
        'event_date': eventDate.toIso8601String(),
        'event_location': eventLocation,
        'event_description': eventDescription,
        'event_speakers': eventSpeakers,
        'event_max_capacity': eventMaxCapacity,
        'organizer_id': organizerId,
        'event_status': 'pending', // Default status
      };

      final response = await _supabase
          .from('events_table')
          .insert(eventData)
          .select('''
            *,
            attendee_count:user_events_table(count)
          ''')
          .single();

      return Event.fromSupabase(response);
    } on PostgrestException catch (e) {
      print('Database error creating event: ${e.message}');
      return null;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }  // Get all approved events with attendee count and user attendance status
  Future<List<Event>> getAllEvents({
    bool approvedOnly = true,
    bool upcomingOnly = true,
    int? limit,
    int? currentUserId,
  }) async {
    try {
      // Start with base query - get all events with their attendee counts
      var baseQuery = _supabase.from('events_table').select('''
            *,
            attendee_count:user_events_table(count)
          ''');

      // Apply filters step by step
      if (approvedOnly) {
        baseQuery = baseQuery.eq('event_status', 'approved');
      }

      if (upcomingOnly) {
        baseQuery = baseQuery.gte(
          'event_date',
          DateTime.now().toIso8601String(),
        );
      }

      // Apply ordering and limit in a single chain
      var finalQuery = baseQuery.order('event_date', ascending: true);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;

      // Convert to Event objects
      List<Event> events = response
          .map((json) => Event.fromSupabase(json))
          .toList();

      // If we have a current user, check their attendance for each event
      if (currentUserId != null) {
        // Get all user's RSVPs in one query
        final userRSVPs = await _supabase
            .from('user_events_table')
            .select('event_id')
            .eq('user_id', currentUserId);

        final userEventIds = userRSVPs.map((rsvp) => rsvp['event_id'] as int).toSet();

        // Update events with user attendance
        events = events.map((event) => Event(
          eventId: event.eventId,
          eventName: event.eventName,
          eventDate: event.eventDate,
          eventLocation: event.eventLocation,
          eventDescription: event.eventDescription,
          eventSpeakers: event.eventSpeakers,
          eventMaxCapacity: event.eventMaxCapacity,
          organizerId: event.organizerId,
          eventStatus: event.eventStatus,
          attendeeCount: event.attendeeCount,
          isUserAttending: userEventIds.contains(event.eventId),
        )).toList();
      }

      return events;
    } on PostgrestException catch (e) {
      print('Database error fetching events: ${e.message}');
      return [];
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  // Get events that a user is attending
  Future<List<Event>> getUserAttendingEvents(int userId) async {
    try {
      final response = await _supabase
          .from('events_table')
          .select('''
            *,
            attendee_count:user_events_table(count)
          ''')
          .eq('user_events_table.user_id', userId)
          .eq('event_status', 'approved')
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date', ascending: true);

      return response
          .map((json) => Event.fromSupabase(json, currentUserId: userId))
          .toList();
    } on PostgrestException catch (e) {
      print('Database error fetching user events: ${e.message}');
      return [];
    } catch (e) {
      print('Error fetching user events: $e');
      return [];
    }
  }

  // Get events created by a user (organizer)
  Future<List<Event>> getEventsCreatedByUser(int userId) async {
    try {
      final response = await _supabase
          .from('events_table')
          .select('''
            *,
            attendee_count:user_events_table(count)
          ''')
          .eq('organizer_id', userId)
          .order('event_date', ascending: true);

      return response
          .map((json) => Event.fromSupabase(json, currentUserId: userId))
          .toList();
    } on PostgrestException catch (e) {
      print('Database error fetching created events: ${e.message}');
      return [];
    } catch (e) {
      print('Error fetching created events: $e');
      return [];
    }
  }

  // Get single event by ID
  Future<Event?> getEventById(int eventId, {int? currentUserId}) async {
    try {
      final response = await _supabase
          .from('events_table')
          .select('''
            *,
            attendee_count:user_events_table(count),
            is_user_attending:user_events_table!left(user_id)
          ''')
          .eq('event_id', eventId)
          .single();

      return Event.fromSupabase(response, currentUserId: currentUserId);
    } on PostgrestException catch (e) {
      print('Database error fetching event: ${e.message}');
      return null;
    } catch (e) {
      print('Error fetching event: $e');
      return null;
    }
  }

  // RSVP to an event
  Future<bool> rsvpToEvent(int eventId, int userId) async {
    try {
      await _supabase.from('user_events_table').insert({
        'user_id': userId,
        'event_id': eventId,
      });

      return true;
    } on PostgrestException catch (e) {
      print('Database error RSVPing to event: ${e.message}');
      return false;
    } catch (e) {
      print('Error RSVPing to event: $e');
      return false;
    }
  }

  // Cancel RSVP to an event
  Future<bool> cancelRsvp(int eventId, int userId) async {
    try {
      await _supabase
          .from('user_events_table')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);

      return true;
    } on PostgrestException catch (e) {
      print('Database error cancelling RSVP: ${e.message}');
      return false;
    } catch (e) {
      print('Error cancelling RSVP: $e');
      return false;
    }
  }

  // Update event (organizer only)
  Future<Event?> updateEvent(
    int eventId, {
    String? eventName,
    DateTime? eventDate,
    String? eventLocation,
    String? eventDescription,
    String? eventSpeakers,
    int? eventMaxCapacity,
    EventStatus? eventStatus,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (eventName != null) updateData['event_name'] = eventName;
      if (eventDate != null)
        updateData['event_date'] = eventDate.toIso8601String();
      if (eventLocation != null) updateData['event_location'] = eventLocation;
      if (eventDescription != null)
        updateData['event_description'] = eventDescription;
      if (eventSpeakers != null) updateData['event_speakers'] = eventSpeakers;
      if (eventMaxCapacity != null)
        updateData['event_max_capacity'] = eventMaxCapacity;
      if (eventStatus != null) updateData['event_status'] = eventStatus.value;

      final response = await _supabase
          .from('events_table')
          .update(updateData)
          .eq('event_id', eventId)
          .select('''
            *,
            attendee_count:user_events_table(count)
          ''')
          .single();

      return Event.fromSupabase(response);
    } on PostgrestException catch (e) {
      print('Database error updating event: ${e.message}');
      return null;
    } catch (e) {
      print('Error updating event: $e');
      return null;
    }
  }

  // Delete event (organizer only)
  Future<bool> deleteEvent(int eventId) async {
    try {
      // Delete all RSVPs first
      await _supabase
          .from('user_events_table')
          .delete()
          .eq('event_id', eventId);

      // Delete all feedback
      await _supabase.from('feedback_table').delete().eq('event_id', eventId);

      // Delete the event
      await _supabase.from('events_table').delete().eq('event_id', eventId);

      return true;
    } on PostgrestException catch (e) {
      print('Database error deleting event: ${e.message}');
      return false;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  // Search events
  Future<List<Event>> searchEvents(String query, {int? currentUserId}) async {
    try {
      final response = await _supabase
          .from('events_table')
          .select('''
            *,
            attendee_count:user_events_table(count)
          ''')
          .or(
            'event_name.ilike.%$query%,event_location.ilike.%$query%,event_description.ilike.%$query%',
          )
          .eq('event_status', 'approved')
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date', ascending: true);

      return response
          .map((json) => Event.fromSupabase(json, currentUserId: currentUserId))
          .toList();
    } on PostgrestException catch (e) {
      print('Database error searching events: ${e.message}');
      return [];
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }

  // Get pending events (admin only)
  Future<List<Event>> getPendingEvents() async {
    try {
      final response = await _supabase
          .from('events_table')
          .select('''
            *,
            attendee_count:user_events_table(count)
          ''')
          .eq('event_status', 'pending')
          .order('event_date', ascending: true);

      return response.map((json) => Event.fromSupabase(json)).toList();
    } on PostgrestException catch (e) {
      print('Database error fetching pending events: ${e.message}');
      return [];
    } catch (e) {
      print('Error fetching pending events: $e');
      return [];
    }
  }

  // Submit feedback for an event
  Future<bool> submitFeedback(
    int eventId,
    int userId,
    int rating,
    String? comment,
  ) async {
    try {
      await _supabase.from('feedback_table').insert({
        'user_id': userId,
        'event_id': eventId,
        'rating': rating,
        'comment': comment,
      });

      return true;
    } on PostgrestException catch (e) {
      print('Database error submitting feedback: ${e.message}');
      return false;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  // Get feedback for an event
  Future<List<EventFeedback>> getEventFeedback(int eventId) async {
    try {
      final response = await _supabase
          .from('feedback_table')
          .select()
          .eq('event_id', eventId)
          .order('timestamp', ascending: false);

      return response.map((json) => EventFeedback.fromSupabase(json)).toList();
    } on PostgrestException catch (e) {
      print('Database error fetching feedback: ${e.message}');
      return [];
    } catch (e) {
      print('Error fetching feedback: $e');
      return [];
    }
  }

  // Watch events with real-time updates
  Stream<List<Event>> watchEvents({
    bool approvedOnly = true,
    int? currentUserId,
  }) {
    var query = _supabase
        .from('events_table')
        .stream(primaryKey: ['event_id'])
        .order('event_date', ascending: true);

    return query.map((data) {
      var events = data
          .map((json) => Event.fromSupabase(json, currentUserId: currentUserId))
          .toList();

      if (approvedOnly) {
        events = events
            .where((event) => event.eventStatus == EventStatus.approved)
            .toList();
      }

      return events.where((event) => event.isUpcoming).toList();
    });
  }

  // Test connection method
  Future<bool> testConnection() async {
    try {
      print('🔍 Testing Supabase connection...');

      final response = await _supabase
          .from('events_table')
          .select('count')
          .count(CountOption.exact);

      print('✅ Connection successful! Events count: ${response.count}');
      return true;
    } catch (e) {
      print('❌ Connection failed: $e');
      return false;
    }
  }

  // Check if tables exist
  Future<void> checkTablesExist() async {
    final tables = [
      'events_table',
      'users_table',
      'user_events_table',
      'feedback_table',
    ];

    for (String table in tables) {      try {
        print('🔍 Checking table: $table');
        await _supabase.from(table).select('*').limit(1);
        print('✅ Table $table exists and is accessible');
      } catch (e) {
        print('❌ Table $table error: $e');
      }
    }
  }
  // Debug method to check what's in the database
  Future<void> debugDatabase() async {
    try {
      print('🔍 Debug: Checking database content...');

      // Check if tables exist and count records
      final eventsResponse = await _supabase
          .from('events_table')
          .select('*')
          .count(CountOption.exact);

      print('📊 Events table count: ${eventsResponse.count}');

      if (eventsResponse.count > 0) {
        final sampleEvent = await _supabase
            .from('events_table')
            .select('*')
            .limit(1);
        print('📝 Sample event: ${sampleEvent.first}');
      }

      // Check approved events
      final approvedResponse = await _supabase
          .from('events_table')
          .select('*')
          .eq('event_status', 'approved')
          .count(CountOption.exact);

      print('✅ Approved events count: ${approvedResponse.count}');

      // Check upcoming events
      final upcomingResponse = await _supabase
          .from('events_table')
          .select('*')
          .eq('event_status', 'approved')
          .gte('event_date', DateTime.now().toIso8601String())
          .count(CountOption.exact);

      print('📅 Upcoming approved events count: ${upcomingResponse.count}');

    } catch (e) {
      print('❌ Debug error: $e');
    }
  }
}
