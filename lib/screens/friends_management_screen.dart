import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:social_nest/models/user_model.dart';
import 'package:social_nest/widgets/user_tile.dart';
import 'package:social_nest/firebase_service.dart';

class FriendsManagementScreen extends StatefulWidget {
  final String currentUserId;

  const FriendsManagementScreen({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<FriendsManagementScreen> createState() => _FriendsManagementScreenState();
}

class _FriendsManagementScreenState extends State<FriendsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _viewFriendProfile(UserModel friend) {
    // Navigate to friend's profile
    // You can implement this based on your existing profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${friend.username}\'s profile'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
    );
    // TODO: Implement navigation to friend's profile screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: friend.uid)));
  }

  Future<void> _removeFriend(String friendId, String friendName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Remove Friend',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove $friendName from your friends?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<FirebaseService>(context, listen: false)
            .removeFriend(friendId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $friendName from friends'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove friend: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Friends Management'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[100],
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
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Error Loading Friends',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 80, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 16),
                        const Text(
                          'No Friends Yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add friends to see them here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var friends = snapshot.data!;

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  friends = friends.where((friend) {
                    return friend.username.toLowerCase().contains(_searchQuery) ||
                        friend.fullName.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: UserTile(
                        user: friend,
                        onTap: () => _viewFriendProfile(friend),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}