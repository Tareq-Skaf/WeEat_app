import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import '../widgets/navigation_bar.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../services/theme_provider.dart';
import 'chat/chat_detail_page.dart';
import 'chat/new_chat_page.dart';

class ChatPage extends StatefulWidget {
  final String? homeName;
  
  const ChatPage({super.key, this.homeName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  TabController? _tabController;
  String _searchQuery = '';
  String _filterType = 'all';
  
  List<dynamic> _conversations = [];
  List<dynamic> _filteredConversations = [];
  bool _loading = false;
  bool _isSearching = false;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(_onTabChanged);
    _loadConversations();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final email = Session.email.trim();
    if (email.isEmpty) return;

    try {
      final channel = _api.connectWebSocket(email);
      _wsSubscription = channel.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map && decoded['type'] == 'new_message') {
              _loadConversations();
            }
          } catch (e) {}
        },
        onDone: () {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) _connectWebSocket();
          });
        },
        onError: (e) {},
      );
    } catch (e) {}
  }

  void _onTabChanged() {
    if (!_tabController!.indexIsChanging) {
      setState(() {
        switch (_tabController!.index) {
          case 0:
            _filterType = 'all';
            break;
          case 1:
            _filterType = 'individual';
            break;
          case 2:
            _filterType = 'group';
            break;
        }
        _applyFilter();
      });
    }
  }

  Future<void> _loadConversations() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;

    setState(() => _loading = true);
    try {
      final data = await _api.getConversations(email: email);
      if (!mounted) return;
      setState(() {
        _conversations = data;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      if (_filterType == 'all') {
        _filteredConversations = List.from(_conversations);
      } else if (_filterType == 'individual') {
        _filteredConversations = _conversations.where((c) => c['is_group'] != true).toList();
      } else {
        _filteredConversations = _conversations.where((c) => c['is_group'] == true).toList();
      }
    } else {
      _filteredConversations = _conversations.where((c) {
        final matchesFilter = _filterType == 'all' ||
            (_filterType == 'individual' && c['is_group'] != true) ||
            (_filterType == 'group' && c['is_group'] == true);
        final name = (c['name'] ?? '').toString().toLowerCase();
        final handle = (c['handle'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
            handle.contains(_searchQuery.toLowerCase());
        return matchesFilter && matchesSearch;
      }).toList();
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
      _applyFilter();
    });
  }

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final date = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) {
        if (diff.inDays == 1) return 'Yesterday';
        if (diff.inDays < 7) return '${diff.inDays}d ago';
        return '${date.day}/${date.month}';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: themeProvider.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chats',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: themeProvider.textPrimary),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: themeProvider.textPrimary,
                unselectedLabelColor: themeProvider.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3E3A9),
                  borderRadius: BorderRadius.circular(22),
                ),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Individual'),
                  Tab(text: 'Group'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: TextStyle(color: themeProvider.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by name or handle',
                    hintStyle: TextStyle(color: themeProvider.textSecondary),
                    prefixIcon: Icon(Icons.search, color: themeProvider.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: themeProvider.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: themeProvider.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Color(0xFF6F8574), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6F8574)))
                    : _filteredConversations.isEmpty
                        ? _buildEmptyState(themeProvider)
                        : RefreshIndicator(
                            onRefresh: _loadConversations,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              itemCount: _filteredConversations.length,
                              itemBuilder: (context, index) {
                                final conv = _filteredConversations[index];
                                return _chatItem(conv, themeProvider);
                              },
                            ),
                          ),
              ),
            ],
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: FloatingNavBar(
              currentIndex: 3,
              homeName: widget.homeName ?? 'User',
              onTap: (i) {},
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewChat,
        backgroundColor: const Color(0xFF6F8574),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No chats found' : 'No chats yet',
            style: TextStyle(color: themeProvider.textSecondary, fontSize: 16),
          ),
          if (!_isSearching) ...[
            const SizedBox(height: 8),
            Text(
              'Start a conversation with friends',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chatItem(Map<String, dynamic> conv, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    final name = (conv['name'] ?? 'Unknown').toString();
    final handle = (conv['handle'] ?? '').toString();
    final lastMessage = (conv['last_message'] ?? '').toString();
    final timeStr = (conv['last_message_time'] ?? '').toString();
    final unread = conv['unread_count'] as int? ?? 0;
    final isGroup = conv['is_group'] == true;
    final convId = (conv['id'] ?? '').toString();

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              conversationId: convId,
              chatName: name,
              chatType: isGroup ? 'group' : 'individual',
              otherEmail: conv['other_email'] ?? '',
              handle: handle,
            ),
          ),
        );
        _loadConversations();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: isDark ? Colors.black38 : Colors.black12, offset: const Offset(0, 2), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isGroup
                  ? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3E3A9))
                  : const Color(0xFF6F8574),
              child: isGroup
                  ? Icon(Icons.group, color: themeProvider.textPrimary, size: 24)
                  : Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 16,
                            color: themeProvider.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(timeStr),
                        style: TextStyle(color: themeProvider.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                          style: TextStyle(
                            color: lastMessage.isEmpty
                                ? (isDark ? Colors.white38 : Colors.grey[400])
                                : themeProvider.textSecondary,
                            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                            fontStyle: lastMessage.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6F8574),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openNewChat() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: const NewChatPage(),
      ),
    );

    if (result != null && result is Map) {
      final convId = result['conversation_id']?.toString();
      final name = (result['name'] ?? 'Unknown').toString();
      final isGroup = result['is_group'] == true;
      final handle = (result['handle'] ?? '').toString();

      if (convId != null && convId.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailPage(
              conversationId: convId,
              chatName: name,
              chatType: isGroup ? 'group' : 'individual',
              otherEmail: result['other_email'] ?? '',
              handle: handle,
            ),
          ),
        );
        _loadConversations();
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }
}
