import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../stores/user_store.dart';

class SettingsProfilePage extends StatelessWidget {
  const SettingsProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userStore = context.watch<UserStore>();
    final userData = userStore.user?.userData;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: userData?.name ?? '',
              decoration: const InputDecoration(labelText: 'Name'),
              onFieldSubmitted: (value) => userStore.updateUserData({'name': value}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: userData?.bio ?? '',
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
              onFieldSubmitted: (value) => userStore.updateUserData({'bio': value}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: userData?.avatarUrl ?? '',
              decoration: const InputDecoration(labelText: 'Avatar URL'),
              onFieldSubmitted: (value) => userStore.updateUserData({'avatar_url': value}),
            ),
          ],
        ),
      ),
    );
  }
}

