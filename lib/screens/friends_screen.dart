// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import '../models/user_model.dart';
import 'public_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Friends'),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Color(0xFF1E293B)),
                ),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Friends List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: Provider.of<FirebaseService>(context, listen: false).getFriendsList(),
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
                        const Text('Error Loading Friends', style: TextStyle(color: Colors.white, fontSize: 18)),
                        Text('${snapshot.error}', style: const TextStyle(color: Color(0xFF94A3B8))),
                      ],
                    ),
                  );
                }
                var friends = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  friends = friends.where((friend) {
                    return friend.username.toLowerCase().contains(_searchQuery) ||
                        (friend.fullName?.toLowerCase() ?? '').contains(_searchQuery);
                  }).toList();
                }
                if (friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 80, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 16),
                        const Text('No friends found', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return _buildFriendTile(friend);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(UserModel friend) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF7C3AED),
            child: Text(
              friend.username.isNotEmpty ? friend.username[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            friend.username,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            friend.bio ?? '',
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _removeFriend(friend.uid, friend.username),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: friend.uid)),
            );
          },
        ),
      ),
    );
  }

  Future<void> _removeFriend(String friendId, String friendName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Remove Friend', style: TextStyle(color: Colors.white)),
        content: Text('Remove $friendName from friends?', style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<FirebaseService>(context, listen: false).removeFriend(friendId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed $friendName')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to remove friend')));
        }
      }
    }
  }
}