// notification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all notifications (modified for testing - originally was user-specific)
  Future<List<AppNotification>> getUserNotifications(int userId) async {
    try {
      final response = await _supabase
          .from('notifications_table')
          .select('''
            *,
            event:events_table(*)
          ''')
          // .eq('user_id', userId) // Commented out for testing
          .order('timestamp', ascending: false);

      return response
          .map((json) => AppNotification.fromSupabase(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications_table')
          .update({'is_read': true})
          .eq('notification_id', notificationId);

      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read (modified for testing - originally was user-specific)
  Future<bool> markAllAsRead(int userId) async {
    try {
      await _supabase
          .from('notifications_table')
          .update({'is_read': true})
          // .eq('user_id', userId) // Commented out for testing
          .eq('is_read', false);

      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Create a new notification
  Future<bool> createNotification({
    required int userId,
    required NotificationType type,
    required String title,
    required String message,
    Event? relatedEvent,
    DateTime? reminderTime,
  }) async {
    try {
      final notificationData = {
        'user_id': userId,
        'type': _typeToString(type),
        'title': title,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
        if (relatedEvent != null) 'event_id': relatedEvent.eventId,
        if (reminderTime != null)
          'reminder_time': reminderTime.toIso8601String(),
      };

      await _supabase.from('notifications_table').insert(notificationData);
      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }

  String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.upcomingReminder:
        return 'upcoming_reminder';
      case NotificationType.lastMinuteReminder:
        return 'last_minute_reminder';
      case NotificationType.eventChange:
        return 'event_change';
      case NotificationType.cancellation:
        return 'cancellation';
      case NotificationType.newEvent:
        return 'new_event';
      case NotificationType.rsvpConfirmation:
        return 'rsvp_confirmation';
      case NotificationType.feedbackRequest:
        return 'feedback_request';
    }
  }

  // Schedule upcoming event reminder
  Future<bool> scheduleUpcomingReminder({
    required int userId,
    required Event event,
    required Duration timeBefore,
  }) async {
    final reminderTime = event.eventDate.subtract(timeBefore);
    final title = 'Upcoming Event: ${event.eventName}';
    final message =
        'Your event "${event.eventName}" starts in ${_formatDuration(timeBefore)}';

    return createNotification(
      userId: userId,
      type: NotificationType.upcomingReminder,
      title: title,
      message: message,
      relatedEvent: event,
      reminderTime: reminderTime,
    );
  }

  // Schedule last minute reminder
  Future<bool> scheduleLastMinuteReminder({
    required int userId,
    required Event event,
  }) async {
    const timeBefore = Duration(minutes: 15);
    final reminderTime = event.eventDate.subtract(timeBefore);
    final title = 'Starting Soon: ${event.eventName}';
    final message = 'Your event "${event.eventName}" starts in 15 minutes!';

    return createNotification(
      userId: userId,
      type: NotificationType.lastMinuteReminder,
      title: title,
      message: message,
      relatedEvent: event,
      reminderTime: reminderTime,
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0)
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    if (duration.inHours > 0)
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    if (duration.inMinutes > 0)
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    return 'a few moments';
  }

  // Send event change notification
  Future<bool> sendEventChangeNotification({
    required int userId,
    required Event event,
    required String changes,
  }) async {
    final title = 'Event Updated: ${event.eventName}';
    final message =
        'The event "${event.eventName}" has been updated. Changes: $changes';

    return createNotification(
      userId: userId,
      type: NotificationType.eventChange,
      title: title,
      message: message,
      relatedEvent: event,
    );
  }

  // Send cancellation notification
  Future<bool> sendCancellationNotification({
    required int userId,
    required Event event,
  }) async {
    final title = 'Event Cancelled: ${event.eventName}';
    final message = 'The event "${event.eventName}" has been cancelled.';

    return createNotification(
      userId: userId,
      type: NotificationType.cancellation,
      title: title,
      message: message,
      relatedEvent: event,
    );
  }

  // Send new event announcement
  Future<bool> sendNewEventNotification({
    required int userId,
    required Event event,
  }) async {
    final title = 'New Event: ${event.eventName}';
    final message =
        'A new event "${event.eventName}" has been added. Check it out!';

    return createNotification(
      userId: userId,
      type: NotificationType.newEvent,
      title: title,
      message: message,
      relatedEvent: event,
    );
  }

  // Send RSVP confirmation
  Future<bool> sendRSVPConfirmation({
    required int userId,
    required Event event,
  }) async {
    final title = 'RSVP Confirmed: ${event.eventName}';
    final message =
        'You have successfully registered for "${event.eventName}" on ${event.eventDate.toString().split(' ')[0]}';

    return createNotification(
      userId: userId,
      type: NotificationType.rsvpConfirmation,
      title: title,
      message: message,
      relatedEvent: event,
    );
  }

  // Send feedback request
  Future<bool> sendFeedbackRequest({
    required int userId,
    required Event event,
  }) async {
    final title = 'Feedback Request: ${event.eventName}';
    final message = 'How was "${event.eventName}"? Please share your feedback!';

    return createNotification(
      userId: userId,
      type: NotificationType.feedbackRequest,
      title: title,
      message: message,
      relatedEvent: event,
    );
  }

  // Get unread notifications count (modified for testing - originally was user-specific)
  Future<int> getUnreadCount(int userId) async {
    try {
      final response = await _supabase
          .from('notifications_table')
          .select('count')
          // .eq('user_id', userId) // Commented out for testing
          .eq('is_read', false)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Added for testing - get all notifications without any filters
  Future<List<AppNotification>> getAllNotifications() async {
    try {
      final response = await _supabase
          .from('notifications_table')
          .select('''
            *,
            event:events_table(*)
          ''')
          .order('timestamp', ascending: false);

      return response
          .map((json) => AppNotification.fromSupabase(json))
          .toList();
    } catch (e) {
      print('Error fetching all notifications: $e');
      return [];
    }
  }
}
