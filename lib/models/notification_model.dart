// notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String senderId;        // maps to 'from' in Firestore
  final String senderName;      // maps to 'fromName'
  final String senderAvatar;    // maps to 'fromAvatar'
  final String? postId;         // from data['postId']
  final String? storyId;        // from data['storyId']
  final bool isRead;
  final int createdAt;          // milliseconds since epoch
  final Timestamp timestamp;    // server timestamp

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    this.postId,
    this.storyId,
    this.isRead = false,
    required this.createdAt,
    required this.timestamp,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      senderId: map['from'] ?? '',                // ✅ 'from' → senderId
      senderName: map['fromName'] ?? '',          // ✅ 'fromName'
      senderAvatar: map['fromAvatar'] ?? '',      // ✅ 'fromAvatar'
      postId: map['postId'],                      // ✅ direct field (not nested in 'data')
      storyId: map['storyId'],                    // ✅ direct field
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      timestamp: map['timestamp'] is Timestamp
          ? map['timestamp']
          : Timestamp.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': senderId, // ❗ Note: This model doesn't store receiver ID — for display only
      'type': type,
      'title': title,
      'message': message,
      'from': senderId,
      'fromName': senderName,
      'fromAvatar': senderAvatar,
      'postId': postId,
      'storyId': storyId,
      'isRead': isRead,
      'createdAt': createdAt,
      'timestamp': timestamp,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }
}