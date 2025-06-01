import 'package:flutter/material.dart';

class Event {
  final int eventId;
  final String eventName;
  final DateTime eventDate;
  final String eventLocation;
  final String? eventDescription;
  final String? eventSpeakers;
  final int? eventMaxCapacity;
  final int organizerId;
  final EventStatus eventStatus;
  final int attendeeCount;
  final bool isUserAttending;

  Event({
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.eventLocation,
    this.eventDescription,
    this.eventSpeakers,
    this.eventMaxCapacity,
    required this.organizerId,
    required this.eventStatus,
    this.attendeeCount = 0,
    this.isUserAttending = false,
  });

  factory Event.fromSupabase(Map<String, dynamic> json, {int? currentUserId}) {
    // Debug: Print the attendee_count value to see what type it is
    print(
      '🔍 attendee_count value: ${json['attendee_count']} (type: ${json['attendee_count'].runtimeType})',
    );

    return Event(
      eventId: json['event_id'] as int,
      eventName: json['event_name'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      eventLocation: json['event_location'] as String,
      eventDescription: json['event_description'] as String?,
      eventSpeakers: json['event_speakers'] as String?,
      eventMaxCapacity: json['event_max_capacity'] as int?,
      organizerId: json['organizer_id'] as int,
      eventStatus: EventStatus.fromString(
        json['event_status'] as String? ?? 'pending',
      ),
      attendeeCount: _safeParseInt(json['attendee_count']),
      isUserAttending: json['is_user_attending'] as bool? ?? false,
    );
  }

  static int _safeParseInt(dynamic value) {
    try {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is List) {
        if (value.isEmpty) return 0;
        return _safeParseInt(value.first);
      }
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.round();
      return 0;
    } catch (e) {
      print('❌ Error parsing int from $value: $e');
      return 0;
    }
  }

  Map<String, dynamic> toSupabaseInsert() {
    return {
      'event_name': eventName,
      'event_date': eventDate.toIso8601String(),
      'event_location': eventLocation,
      'event_description': eventDescription,
      'event_speakers': eventSpeakers,
      'event_max_capacity': eventMaxCapacity,
      'organizer_id': organizerId,
      'event_status': eventStatus.value,
    };
  }

  bool get isUpcoming => eventDate.isAfter(DateTime.now());
  bool get isPast => eventDate.isBefore(DateTime.now());
  bool get isFull =>
      eventMaxCapacity != null && attendeeCount >= eventMaxCapacity!;
  bool get canJoin =>
      isUpcoming && !isFull && eventStatus == EventStatus.approved;
}

enum EventStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  cancelled('cancelled');

  const EventStatus(this.value);
  final String value;

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EventStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case EventStatus.pending:
        return 'Pending Approval';
      case EventStatus.approved:
        return 'Approved';
      case EventStatus.rejected:
        return 'Rejected';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case EventStatus.pending:
        return Colors.orange;
      case EventStatus.approved:
        return Colors.green;
      case EventStatus.rejected:
        return Colors.red;
      case EventStatus.cancelled:
        return Colors.grey;
    }
  }
}
