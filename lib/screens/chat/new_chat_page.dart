import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/session.dart';
import 'create_group_page.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  static const Color background = Color(0xFFFEF9EE);
  static const Color accent = Color(0xFF6F8574);

  final _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _friends = [];
  List<dynamic> _filteredFriends = [];
  List<dynamic> _searchResults = [];
  bool _loading = true;
  bool _searching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;

    setState(() => _loading = true);
    try {
      final data = await _api.getFriends(email: email);
      if (!mounted) return;

      final List<dynamic> friends = [];
      for (var f in data) {
        final friendEmail = (f['friend_email'] ?? '').toString();
        final friendName = (f['friend_name'] ?? 'Unknown').toString();
        final friendHandle = (f['friend_handle'] ?? '').toString();
        if (friendEmail.isNotEmpty) {
          friends.add({
            'email': friendEmail,
            'name': friendName,
            'handle': friendHandle,
          });
        }
      }

      friends.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

      setState(() {
        _friends = friends;
        _filteredFriends = friends;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
        _filteredFriends = _searchQuery.isEmpty
            ? _friends
            : _friends.where((f) {
                final name = (f['name'] ?? '').toString().toLowerCase();
                final handle = (f['handle'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery.toLowerCase()) ||
                    handle.contains(_searchQuery.toLowerCase());
              }).toList();
      });
      return;
    }

    setState(() => _searching = true);
    try {
      final data = await _api.searchUsers(query: query, limit: 10);
      if (!mounted) return;

      final currentEmail = Session.email.toLowerCase().trim();
      final results = data.where((u) => (u['email'] ?? '').toString().toLowerCase() != currentEmail).toList();

      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      if (value.isEmpty) {
        _filteredFriends = _friends;
        _searchResults = [];
      }
    });
    _searchUsers(value);
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    final email = Session.email.trim();
    final toEmail = (user['email'] ?? '').toString();

    if (email.isEmpty || toEmail.isEmpty) return;

    try {
      final result = await _api.createConversation(
        fromEmail: email,
        toEmail: toEmail,
      );
      if (!mounted) return;

      final conv = result['conversation'];
      Navigator.pop(context, {
        'conversation_id': conv['id'],
        'name': user['name'] ?? 'Unknown',
        'handle': user['handle'] ?? '',
        'is_group': false,
        'other_email': toEmail,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Chat',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 28, color: Colors.black),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search friends or users (e.g., tarek#0001)',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.black26, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.black26, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: accent, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: const CreateGroupPage(),
                  ),
                );
                if (result != null && mounted) {
                  Navigator.pop(context, result);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.group, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'New Group',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    if (_searchQuery.isNotEmpty && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No users found', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return _buildFriendsList();
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final name = (user['name'] ?? 'Unknown').toString();
        final handle = (user['handle'] ?? '').toString();
        final email = (user['email'] ?? '').toString();

        final isFriend = _friends.any((f) => f['email'] == email);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: accent,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(handle, style: const TextStyle(color: Colors.grey)),
          trailing: isFriend
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Friend', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                )
              : null,
          onTap: () => _startChat(user),
        );
      },
    );
  }

  Widget _buildFriendsList() {
    if (_filteredFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No friends yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 4),
            Text('Add friends to start chatting', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ],
        ),
      );
    }

    final Map<String, List<dynamic>> grouped = {};
    for (var friend in _filteredFriends) {
      final name = (friend['name'] ?? 'Unknown').toString();
      final letter = name.isNotEmpty ? name[0].toUpperCase() : '#';
      if (!grouped.containsKey(letter)) {
        grouped[letter] = [];
      }
      grouped[letter]!.add(friend);
    }

    final sortedKeys = grouped.keys.toList()..sort();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('Friends', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey, fontSize: 14)),
          ),
          ...sortedKeys.map((letter) {
            final contacts = grouped[letter]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
                  child: Text(letter, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26, width: 1.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: List.generate(contacts.length, (index) {
                        final contact = contacts[index];
                        final name = (contact['name'] ?? 'Unknown').toString();
                        final handle = (contact['handle'] ?? '').toString();
                        final isLast = index == contacts.length - 1;

                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () => _startChat(contact),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: accent,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                          if (handle.isNotEmpty)
                                            Text(handle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chat_bubble_outline, color: Colors.grey[400], size: 20),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(height: 1, thickness: 1, color: Colors.grey[200], indent: 72),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}