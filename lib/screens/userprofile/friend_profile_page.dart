import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/session.dart';
import '../chat/chat_detail_page.dart';

class FriendProfilePage extends StatefulWidget {
  final String userName;
  final String handle;
  final String? email;

  const FriendProfilePage({
    super.key,
    required this.userName,
    this.handle = '',
    this.email,
  });

  @override
  State<FriendProfilePage> createState() => _FriendProfilePageState();
}

class _FriendProfilePageState extends State<FriendProfilePage> {
  static const Color background = Color(0xFFFEF9EE);
  static const Color accent = Color(0xFF6F8574);
  static const Color cardYellow = Color(0xFFF3E3A9);

  final _api = ApiService();

  bool _loading = true;
  bool _isFollowing = false;
  bool _isPending = false;
  String _friendshipStatus = 'none';

  String _displayName = '';
  String _handle = '';
  String _bio = '';
  String _avatarUrl = '';
  int _postsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  List<dynamic> _userPosts = [];

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _handle = widget.handle;
    _loadProfile();
    _checkFriendshipStatus();
  }

  Future<void> _loadProfile() async {
    final email = widget.email;
    if (email == null || email.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final profile = await _api.getUserProfile(email: email);
      final stats = await _api.getUserStats(email: email);
      final posts = await _api.getPosts(limit: 10);

      if (!mounted) return;

      final user = profile['user'] ?? {};
      final userPosts = posts.where((p) => (p['user_email'] ?? '').toString().toLowerCase() == email.toLowerCase()).toList();

      setState(() {
        _displayName = (user['display_name'] ?? widget.userName).toString();
        _handle = (user['handle'] ?? widget.handle).toString();
        _bio = (user['bio'] ?? '').toString();
        _avatarUrl = (user['avatar_url'] ?? '').toString();
        _postsCount = userPosts.length;
        _followersCount = (stats['followers_count'] ?? 0) as int;
        _followingCount = (stats['following_count'] ?? 0) as int;
        _userPosts = userPosts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _checkFriendshipStatus() async {
    final myEmail = Session.email.trim();
    final friendEmail = widget.email;
    if (myEmail.isEmpty || friendEmail == null || friendEmail.isEmpty) return;

    try {
      final result = await _api.getFriendshipStatus(email: myEmail, otherEmail: friendEmail);
      if (!mounted) return;
      setState(() {
        _friendshipStatus = (result['status'] ?? 'none').toString();
        _isFollowing = _friendshipStatus == 'accepted';
        _isPending = _friendshipStatus == 'pending';
      });
    } catch (_) {}
  }

  Future<void> _handleFollowAction() async {
    final myEmail = Session.email.trim();
    final friendEmail = widget.email;
    if (myEmail.isEmpty || friendEmail == null || friendEmail.isEmpty) return;

    try {
      if (_isFollowing) {
        await _api.removeFriend(email: myEmail, friendEmail: friendEmail);
        if (!mounted) return;
        setState(() {
          _isFollowing = false;
          _isPending = false;
          _friendshipStatus = 'none';
          _followersCount = (_followersCount - 1).clamp(0, 999999);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unfollowed')));
      } else if (_isPending) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request already sent')));
      } else {
        await _api.sendFriendRequest(fromEmail: myEmail, toEmail: friendEmail);
        if (!mounted) return;
        setState(() {
          _isPending = true;
          _friendshipStatus = 'pending';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Follow request sent')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _startChat() async {
    final myEmail = Session.email.trim();
    final friendEmail = widget.email;
    if (myEmail.isEmpty || friendEmail == null || friendEmail.isEmpty) return;

    try {
      final result = await _api.createConversation(fromEmail: myEmail, toEmail: friendEmail);
      if (!mounted) return;

      final conv = result['conversation'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversationId: conv['id'],
            chatName: _displayName,
            chatType: 'individual',
            otherEmail: friendEmail,
            handle: _handle,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  String _formatTimeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_displayName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                    child: _avatarUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(_displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  if (_handle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(_handle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                  if (_bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_bio, style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statColumn('$_postsCount', 'Posts'),
                      _statColumn('$_followersCount', 'Followers'),
                      _statColumn('$_followingCount', 'Following'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleFollowAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.grey[300] : (_isPending ? Colors.orange : accent),
                            foregroundColor: _isFollowing ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(_isFollowing ? 'Unfollow' : (_isPending ? 'Pending' : 'Follow')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isFollowing ? _startChat : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(color: _isFollowing ? accent : Colors.grey[300]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Message'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_userPosts.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Recent Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 12),
                    ..._userPosts.map((post) => _buildPostCard(post)),
                  ] else ...[
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.post_add_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No reviews yet', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildPostCard(dynamic post) {
    final restaurantName = (post['restaurant_name'] ?? '').toString();
    final description = (post['description'] ?? '').toString();
    final rating = (post['rating'] ?? 0) as int;
    final timeAgo = _formatTimeAgo((post['created_at'] ?? '').toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, offset: const Offset(0, 2), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(restaurantName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, color: i < rating ? Colors.amber : Colors.grey[300], size: 14))),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}