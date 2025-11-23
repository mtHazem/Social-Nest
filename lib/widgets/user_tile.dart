import 'package:flutter/material.dart';
import 'package:social_nest/models/user_model.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback? onRemovePressed; // optional

  const UserTile({
    Key? key,
    required this.user,
    required this.onTap,
    this.onRemovePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.username[0].toUpperCase()),
      ),
      title: Text(user.username),
      subtitle: Text(user.fullName ?? ''),
      onTap: onTap,
      trailing: onRemovePressed != null
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: onRemovePressed,
            )
          : null,
    );
  }
}