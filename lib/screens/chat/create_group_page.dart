import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/session.dart';
import 'group_details_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  static const Color background = Color(0xFFFEF9EE);
  static const Color accent = Color(0xFF6F8574);
  static const Color cardYellow = Color(0xFFF3E3A9);

  final _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _friends = [];
  List<dynamic> _filteredFriends = [];
  Set<String> _selectedEmails = {};
  bool _loading = true;
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

  void _filterFriends() {
    if (_searchQuery.isEmpty) {
      _filteredFriends = _friends;
    } else {
      _filteredFriends = _friends.where((f) {
        final name = (f['name'] ?? '').toString().toLowerCase();
        final handle = (f['handle'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) ||
            handle.contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  void _toggleSelection(String email) {
    setState(() {
      if (_selectedEmails.contains(email)) {
        _selectedEmails.remove(email);
      } else {
        _selectedEmails.add(email);
      }
    });
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
                  'New Group',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterFriends();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search friends',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
          if (_selectedEmails.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cardYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedEmails.length} friend${_selectedEmails.length > 1 ? 's' : ''} selected',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty ? 'No friends found' : 'No friends yet',
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : _buildFriendsList(),
          ),
          if (_selectedEmails.length >= 2)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final selected = _friends.where((f) => _selectedEmails.contains(f['email'])).toList();
                    final members = selected.map((f) => GroupMember(
                      email: f['email'],
                      name: f['name'],
                      handle: f['handle'],
                    )).toList();

                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SizedBox(
                        height: MediaQuery.of(context).size.height * 0.9,
                        child: GroupDetailsPage(selectedMembers: members),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
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
                        final email = (contact['email'] ?? '').toString();
                        final isSelected = _selectedEmails.contains(email);
                        final isLast = index == contacts.length - 1;

                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleSelection(email),
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
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!, width: 2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const SizedBox(width: 16, height: 16),
                                      ),
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