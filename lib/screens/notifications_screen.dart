// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import 'comments_screen.dart';
import 'story_likes_screen.dart';
import 'public_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when entering screen (optional)
    // Provider.of<FirebaseService>(context, listen: false).markAllNotificationsAsRead();
  }

  void _handleNotificationTap(Map<String, dynamic> notif) async {
    final type = notif['type'] as String?;
    final from = notif['from'] as String?;
    final postId = notif['postId'] as String?;
    final storyId = notif['storyId'] as String?;

    if (type == 'friend_request' && from != null) {
      // Navigate to public profile to handle accept/decline
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: from)),
      );
    } else if ((type == 'post_like' || type == 'post_comment') && postId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommentsScreen(postId: postId, postContent: ''),
        ),
      );
    } else if (type == 'story_like' && storyId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryLikesScreen(storyId: storyId),
        ),
      );
    } else if (from != null) {
      // Fallback: go to user profile
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: from)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Notifications'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.markunread_mailbox_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  title: const Text('Mark All as Read'),
                  content: const Text('Are you sure you want to mark all notifications as read?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        firebaseService.markAllNotificationsAsRead();
                      },
                      child: const Text('Mark All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firebaseService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load notifications', style: TextStyle(color: Colors.white)),
                  Text('${snapshot.error}', style: const TextStyle(color: Color(0xFF94A3B8))),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 80, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You’ll see likes, comments, friend requests, and more here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] == true;
              final senderName = data['fromName'] ?? 'User';
              final senderAvatar = data['fromAvatar'] ?? senderName[0];
              final timeAgo = _getTimeAgo(data['timestamp'] as Timestamp);

              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF7C3AED),
                    child: Text(senderAvatar, style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(
                    _getTitle(data),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMessage(data),
                        style: TextStyle(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: _buildTrailingAction(data),
                  onTap: () => _handleNotificationTap(data),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getTitle(Map<String, dynamic> notif) {
    switch (notif['type']) {
      case 'friend_request':
        return '${notif['fromName'] ?? 'User'} sent you a friend request';
      case 'friend_accepted':
        return 'Friend request accepted';
      case 'post_like':
        return 'Liked your post';
      case 'post_comment':
        return 'Commented on your post';
      case 'story_like':
        return 'Liked your story';
      default:
        return notif['title'] ?? 'New notification';
    }
  }

  String _getMessage(Map<String, dynamic> notif) {
    return notif['message'] ?? '';
  }

  Widget? _buildTrailingAction(Map<String, dynamic> notif) {
    if (notif['type'] == 'friend_request') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () async {
              await Provider.of<FirebaseService>(context, listen: false)
                  .acceptFriendRequest(notif['from'] as String);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Friend request accepted')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () async {
              await Provider.of<FirebaseService>(context, listen: false)
                  .declineFriendRequest(notif['from'] as String);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Friend request declined')),
                );
              }
            },
          ),
        ],
      );
    }
    return null;
  }

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }
}