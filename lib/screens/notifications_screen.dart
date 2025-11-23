import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import '../models/notification_model.dart';
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
          // Show Firebase service error if any
          if (firebaseService.lastError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(firebaseService.lastError!, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text('Check Firestore rules / indexes.', style: TextStyle(color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
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

              // ✅ Parse using NotificationModel (now matches your Firestore schema)
              final notif = NotificationModel.fromMap({...data, 'id': doc.id});

              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF7C3AED),
                    child: Text(notif.senderAvatar, style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(
                    _getTitle(notif),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getMessage(notif),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(notif.timeAgo, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                  trailing: _buildTrailingAction(notif),
                  onTap: () => _handleNotificationTap(notif),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ Updated to use NotificationModel
  void _handleNotificationTap(NotificationModel notif) async {
    // Mark as read
    await Provider.of<FirebaseService>(context, listen: false)
        .markNotificationAsRead(notif.id);

    // Navigate based on type
    if (notif.type == 'friend_request' && notif.senderId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: notif.senderId)),
      );
    } else if ((notif.type == 'post_like' || notif.type == 'post_comment') && notif.postId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommentsScreen(
            postId: notif.postId!,
            postContent: '',
          ),
        ),
      );
    } else if (notif.type == 'story_like' && notif.storyId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryLikesScreen(storyId: notif.storyId!),
        ),
      );
    } else if (notif.senderId.isNotEmpty) {
      // Fallback: go to user profile
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: notif.senderId)),
      );
    }
  }

  String _getTitle(NotificationModel notif) {
    switch (notif.type) {
      case 'friend_request':
        return '${notif.senderName} sent you a friend request';
      case 'friend_accepted':
        return 'Friend request accepted';
      case 'post_like':
        return 'Liked your post';
      case 'post_comment':
        return 'Commented on your post';
      case 'story_like':
        return 'Liked your story';
      default:
        return notif.title;
    }
  }

  String _getMessage(NotificationModel notif) {
    return notif.message;
  }

  Widget? _buildTrailingAction(NotificationModel notif) {
    if (notif.type == 'friend_request') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () async {
              await Provider.of<FirebaseService>(context, listen: false)
                  .acceptFriendRequest(notif.senderId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Friend request accepted')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () async {
              await Provider.of<FirebaseService>(context, listen: false)
                  .declineFriendRequest(notif.senderId);
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
}