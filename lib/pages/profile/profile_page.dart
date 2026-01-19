import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_models.dart';
import '../../services/profile_service.dart';
import '../../stores/card_store.dart';
import '../../stores/user_store.dart';
import '../../widgets/cards/card_grid.dart';
import '../../widgets/layout/app_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.username});

  final String username;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cardStore = context.read<CardStore>();
    try {
      final userData = await _profileService.getUserData(widget.username);
      if (!mounted) return;
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
      context.read<UserStore>().setCardOwner(userData);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
    await cardStore.loadCards(widget.username);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(showAuthButtons: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_userData != null) _buildProfileHeader(context, _userData!),
                  const SizedBox(height: 24),
                  const CardGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserData data) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage: data.avatarUrl.isNotEmpty ? NetworkImage(data.avatarUrl) : null,
          backgroundColor: const Color(0xFFE5E5E5),
          child: data.avatarUrl.isEmpty ? const Icon(Icons.person, size: 48) : null,
        ),
        const SizedBox(height: 12),
        Text(
          data.name.isNotEmpty ? data.name : widget.username,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (data.bio.isNotEmpty)
          Text(
            data.bio,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        const SizedBox(height: 12),
        Text(
          'dinq.me/${data.domain.isNotEmpty ? data.domain : widget.username}',
          style: const TextStyle(color: Color(0xFF171717), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

