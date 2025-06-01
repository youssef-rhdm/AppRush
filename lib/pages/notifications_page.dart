// notifications_page.dart
import 'package:flutter/material.dart';
import 'package:apprush/models/notification_model.dart';
import 'package:apprush/models/user_model.dart';
import 'package:apprush/services/notification_service.dart';
import 'package:apprush/utils/app_themes.dart';
import 'package:apprush/models/event_model.dart';
import 'event_details_page.dart';

class NotificationsPage extends StatefulWidget {
  final AppUser? currentUser;
  final VoidCallback? onAuthRequired;

  const NotificationsPage({Key? key, this.currentUser, this.onAuthRequired})
    : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (widget.currentUser == null || widget.currentUser!.isGuest) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final notifications = await _notificationService.getUserNotifications(
        widget.currentUser!.userId!,
      );

      final unreadCount = await _notificationService.getUnreadCount(
        widget.currentUser!.userId!,
      );

      setState(() {
        _notifications = notifications;
        _hasUnread = unreadCount > 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading notifications: $e');
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.notificationId);

      // Update the notification state
      setState(() {
        notification.isRead = true;
      });

      // Fetch updated unread count
      final unreadCount = await _notificationService.getUnreadCount(
        widget.currentUser!.userId!,
      );

      // Update badge visibility
      setState(() {
        _hasUnread = unreadCount > 0;
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead(widget.currentUser!.userId!);

      // Update all notifications as read
      setState(() {
        for (var notification in _notifications) {
          notification.isRead = true;
        }
      });

      // Update badge visibility
      setState(() {
        _hasUnread = false;
      });
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  void _navigateToEventDetails(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(
          event: event,
          currentUser: widget.currentUser,
          onAuthRequired: widget.onAuthRequired,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.notificationId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        // TODO: Implement delete notification functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification dismissed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _notifications.insert(
                    _notifications.indexOf(notification),
                    notification,
                  );
                });
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          _markAsRead(notification);
          if (notification.relatedEvent != null) {
            _navigateToEventDetails(notification.relatedEvent!);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: notification.isRead
                ? theme.cardColor
                : isDark
                ? Colors.blueGrey[900]
                : Colors.blue[50],
            border: Border(
              left: BorderSide(width: 4, color: notification.iconColor),
            ),
          ),
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.iconColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(notification.icon, color: notification.iconColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                            overflow: TextOverflow
                                .ellipsis, // Prevent overflow for long titles
                            maxLines: 1, // Ensure the text stays on one line
                          ),
                        ),
                        SizedBox(
                          width: 8,
                        ), // Add spacing between the title and timestamp
                        Text(
                          _formatTime(notification.timestamp),
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // Prevent overflow for timestamps
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    if (notification.reminderTime != null) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Reminder set for ${_formatTime(notification.reminderTime!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final notificationDate = DateTime(time.year, time.month, time.day);

    if (notificationDate == today) {
      return 'Today at ${_formatHourMinute(time)}';
    } else if (notificationDate == yesterday) {
      return 'Yesterday at ${_formatHourMinute(time)}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _formatHourMinute(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildGuestMessage() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: theme.textTheme.bodyMedium?.color,
          ),
          SizedBox(height: 16),
          Text(
            'Notifications unavailable',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please sign in to view your notifications',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onAuthRequired,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: theme.textTheme.bodyMedium?.color,
          ),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your notifications will appear here',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = widget.currentUser?.isGuest ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          if (!isGuest && _hasUnread)
            IconButton(
              icon: Icon(Icons.mark_email_read),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isGuest
          ? _buildGuestMessage()
          : _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: theme.primaryColor,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationItem(_notifications[index]);
                },
              ),
            ),
    );
  }
}
