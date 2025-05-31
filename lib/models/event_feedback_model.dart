class EventFeedback {
  final int feedbackId;
  final int userId;
  final int eventId;
  final int rating;
  final String? comment;
  final DateTime timestamp;

  EventFeedback({
    required this.feedbackId,
    required this.userId,
    required this.eventId,
    required this.rating,
    this.comment,
    required this.timestamp,
  });

  factory EventFeedback.fromSupabase(Map<String, dynamic> json) {
    return EventFeedback(
      feedbackId: json['feedback_id'] as int,
      userId: json['user_id'] as int,
      eventId: json['event_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toSupabaseInsert() {
    return {
      'user_id': userId,
      'event_id': eventId,
      'rating': rating,
      'comment': comment,
    };
  }

  bool get isPositive => rating >= 4;
  bool get isNegative => rating <= 2;
}
