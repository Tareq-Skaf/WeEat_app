import 'package:flutter/material.dart';
import '../../widgets/navigation_bar.dart';
import 'new_chat_page.dart';
import 'chat_detail_page.dart';

class ChatItem {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final bool isGroup;

  ChatItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.isGroup,
  });
}

class AllChatPage extends StatefulWidget {
  const AllChatPage({super.key});

  @override
  State<AllChatPage> createState() => _AllChatPageState();
}

class _AllChatPageState extends State<AllChatPage> {
  static const Color background = Color(0xFFFEF9EE);
  static const Color cardYellow = Color(0xFFF3E3A9);
  static const Color accent = Color(0xFF6F8574);

  late List<ChatItem> allChats;
  late List<ChatItem> filteredChats;
  String filterType = 'All'; // 'All', 'Individual', 'Group'
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    allChats = [
      ChatItem(
        id: '1',
        name: 'Sara',
        lastMessage: 'Hey, how are you?',
        time: '12:33 pm',
        isGroup: false,
      ),
      ChatItem(
        id: '2',
        name: 'Birthday Plan',
        lastMessage: 'See you at the party!',
        time: 'Yesterday',
        isGroup: true,
      ),
      ChatItem(
        id: '3',
        name: 'Night owl',
        lastMessage: 'Let\'s meet tonight',
        time: 'Tuesday',
        isGroup: true,
      ),
      ChatItem(
        id: '4',
        name: 'Zeina',
        lastMessage: 'Thanks for the update',
        time: 'Tuesday',
        isGroup: false,
      ),
      ChatItem(
        id: '5',
        name: 'Maha',
        lastMessage: 'See you soon!',
        time: 'Wednesday',
        isGroup: false,
      ),
    ];
    filteredChats = allChats;
  }

  void _filterChats() {
    setState(() {
      filteredChats = allChats.where((chat) {
        final matchesFilter = filterType == 'All' ||
            (filterType == 'Individual' && !chat.isGroup) ||
            (filterType == 'Group' && chat.isGroup);

        final matchesSearch =
            chat.name.toLowerCase().contains(searchQuery.toLowerCase());

        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  void _deleteChat(String id) {
    setState(() {
      allChats.removeWhere((chat) => chat.id == id);
      _filterChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24).copyWith(bottom: 470),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chats',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final result = await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SizedBox(
                            height: MediaQuery.of(context).size.height * 0.9,
                            child: const NewChatPage(),
                          ),
                        );

                        // If a group was created, add it to the chat list
                        if (result != null && result is Map) {
                          setState(() {
                            allChats.insert(
                              0,
                              ChatItem(
                                id: result['id'],
                                name: result['name'],
                                lastMessage: 'Group created',
                                time: 'now',
                                isGroup: true,
                              ),
                            );
                            _filterChats();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26, width: 2),
                        ),
                        child: const Icon(Icons.add, size: 24),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  onChanged: (value) {
                    searchQuery = value;
                    _filterChats();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search',
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

                const SizedBox(height: 16),

                // Filter Buttons
                Row(
                  children: [
                    _filterButton('All'),
                    const SizedBox(width: 12),
                    _filterButton('Individual'),
                    const SizedBox(width: 12),
                    _filterButton('Group'),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey[300],
                ),

                const SizedBox(height: 8),

                // Chat List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    return _chatItem(filteredChats[index]);
                  },
                ),
              ],
            ),
          ),
          // Floating Navigation Bar - Fixed Position
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: FloatingNavBar(
              currentIndex: 3,
              homeName: 'User',
              onTap: (i) {
                // Optional handling for other nav items
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label) {
    final isSelected = filterType == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          filterType = label;
          _filterChats();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cardYellow : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.black26 : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _chatItem(ChatItem chat) {
    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteChat(chat.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${chat.name} deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(
                    conversationId: chat.id,
                    chatName: chat.name,
                    chatType: chat.isGroup ? 'group' : 'individual',
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 16),
                  // Chat Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (chat.isGroup)
                          Text(
                            'Group',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Time
                  Text(
                    chat.time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 16,
            thickness: 1,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}
