import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'public_profile_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text('Search: "$query"'),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: query)
            .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
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
                  const Text('Error loading users', style: TextStyle(color: Colors.white)),
                  Text('${snapshot.error}', style: const TextStyle(color: Color(0xFF94A3B8))),
                ],
              ),
            );
          }

          final users = snapshot.data?.docs ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Text('No users found', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final displayName = userData['displayName'] ?? 'User';
              final bio = userData['bio'] ?? '';
              final avatarLetter = displayName.isNotEmpty
                  ? displayName[0].toUpperCase()
                  : 'U';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF7C3AED),
                  child: Text(avatarLetter, style: const TextStyle(color: Colors.white, fontSize: 18)),
                ),
                title: Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(bio, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: userDoc.id)),
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