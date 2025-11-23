// lib/screens/story_likes_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'public_profile_screen.dart';

class StoryLikesScreen extends StatelessWidget {
  final String storyId;

  const StoryLikesScreen({super.key, required this.storyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Story Likes'),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .doc(storyId)
            .collection('likes')
            .snapshots(),
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
                  const Text('Failed to load likes', style: TextStyle(color: Colors.white)),
                  Text('${snapshot.error}', style: const TextStyle(color: Color(0xFF94A3B8))),
                ],
              ),
            );
          }

          final likes = snapshot.data?.docs ?? [];
          if (likes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 80, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 16),
                  const Text(
                    'No likes yet',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Be the first to like this story!',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: likes.length,
            itemBuilder: (context, index) {
              final userId = (likes[index].data() as Map<String, dynamic>)['userId'];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const ListTile(title: Text('Loading...', style: TextStyle(color: Colors.white70)));
                  }
                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final displayName = userData['displayName'] ?? 'User';
                  final avatar = userData['avatar']?.toString() ?? displayName[0].toUpperCase();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF7C3AED),
                      child: Text(avatar, style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(displayName, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Liked your story', style: const TextStyle(color: Color(0xFF94A3B8))),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PublicProfileScreen(userId: userId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}