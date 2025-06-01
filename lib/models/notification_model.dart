// notification_model.dart
import 'package:flutter/material.dart';
import 'event_model.dart';

enum NotificationType {
  upcomingReminder,
  lastMinuteReminder,
  eventChange,
  cancellation,
  newEvent,
  rsvpConfirmation,
  feedbackRequest,
}

class AppNotification {
  final String notificationId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final Event? relatedEvent;
  final DateTime? reminderTime;

  AppNotification({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.relatedEvent,
    this.reminderTime,
  });

  factory AppNotification.fromSupabase(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notification_id'] as String,
      type: _parseNotificationType(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool,
      relatedEvent: json['event'] != null
          ? Event.fromSupabase(json['event'] as Map<String, dynamic>)
          : null,
      reminderTime: json['reminder_time'] != null
          ? DateTime.parse(json['reminder_time'] as String)
          : null,
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'upcoming_reminder':
        return NotificationType.upcomingReminder;
      case 'last_minute_reminder':
        return NotificationType.lastMinuteReminder;
      case 'event_change':
        return NotificationType.eventChange;
      case 'cancellation':
        return NotificationType.cancellation;
      case 'new_event':
        return NotificationType.newEvent;
      case 'rsvp_confirmation':
        return NotificationType.rsvpConfirmation;
      case 'feedback_request':
        return NotificationType.feedbackRequest;
      default:
        return NotificationType.upcomingReminder;
    }
  }

  String get typeString {
    switch (type) {
      case NotificationType.upcomingReminder:
        return 'Upcoming Reminder';
      case NotificationType.lastMinuteReminder:
        return 'Last Minute Reminder';
      case NotificationType.eventChange:
        return 'Event Change';
      case NotificationType.cancellation:
        return 'Cancellation';
      case NotificationType.newEvent:
        return 'New Event';
      case NotificationType.rsvpConfirmation:
        return 'RSVP Confirmation';
      case NotificationType.feedbackRequest:
        return 'Feedback Request';
    }
  }

  IconData get icon {
    switch (type) {
      case NotificationType.upcomingReminder:
      case NotificationType.lastMinuteReminder:
        return Icons.notifications_active;
      case NotificationType.eventChange:
        return Icons.edit_calendar;
      case NotificationType.cancellation:
        return Icons.cancel;
      case NotificationType.newEvent:
        return Icons.new_releases;
      case NotificationType.rsvpConfirmation:
        return Icons.check_circle;
      case NotificationType.feedbackRequest:
        return Icons.feedback;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.upcomingReminder:
      case NotificationType.lastMinuteReminder:
        return Colors.orange;
      case NotificationType.eventChange:
        return Colors.blue;
      case NotificationType.cancellation:
        return Colors.red;
      case NotificationType.newEvent:
        return Colors.green;
      case NotificationType.rsvpConfirmation:
        return Colors.teal;
      case NotificationType.feedbackRequest:
        return Colors.purple;
    }
  }
}
