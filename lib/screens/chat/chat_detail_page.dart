import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../services/session.dart';
import '../../services/theme_provider.dart';
import '../../widgets/smart_image.dart';
import '../../widgets/map_marker.dart';

class ChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String chatName;
  final String chatType;
  final String otherEmail;
  final String handle;
  
  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.chatName,
    required this.chatType,
    this.otherEmail = '',
    this.handle = '',
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  static const Color background = Color(0xFFFEF9EE);
  static const Color accent = Color(0xFF6F8574);
  static const Color cardYellow = Color(0xFFF3E3A9);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _api = ApiService();

  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  StreamSubscription? _wsSubscription;
  bool _otherTyping = false;
  bool _otherOnline = false;
  Timer? _typingTimer;
  String? _replyTo;
  String _replyContent = '';
  String _replySender = '';
  bool _isMuted = false;
  bool _isPinned = false;
  bool _isBlocked = false;

  final List<String> _quickEmojis = ['❤️', '😂', '😮', '😢', '😡', '👍', '👎', '🔥', '🎉', '💯'];

  @override
  void initState() {
    super.initState();
    _loadConversationState();
    _loadMessages();
    _connectWebSocket();
    _markAsRead();
  }

  Future<void> _loadConversationState() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;
    try {
      final conv = await _api.getConversation(conversationId: widget.conversationId, email: email);
      if (!mounted) return;
      setState(() {
        _isMuted = conv['is_muted'] == true;
        _isPinned = conv['is_pinned'] == true;
      });
    } catch (_) {}
  }

  Future<void> _markAsRead() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;
    try {
      await _api.markConversationRead(conversationId: widget.conversationId, email: email);
    } catch (_) {}
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
            if (decoded is Map) {
              final type = decoded['type'] ?? '';
              if (type == 'new_message') {
                final msg = decoded['message'];
                if (msg != null && msg['conversation_id'] == widget.conversationId) {
                  if (!mounted) return;
                  setState(() {
                    _messages.add(msg);
                    _otherTyping = false;
                  });
                  _scrollToBottom();
                  _markAsRead();
                }
              } else if (type == 'typing') {
                if (decoded['conversation_id'] == widget.conversationId && decoded['email'] != Session.email) {
                  if (!mounted) return;
                  setState(() => _otherTyping = true);
                  _typingTimer?.cancel();
                  _typingTimer = Timer(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _otherTyping = false);
                  });
                }
              } else if (type == 'stop_typing') {
                if (decoded['conversation_id'] == widget.conversationId && decoded['email'] != Session.email) {
                  if (!mounted) return;
                  setState(() => _otherTyping = false);
                }
              } else if (type == 'user_online') {
                if (decoded['email'] == widget.otherEmail) {
                  if (!mounted) return;
                  setState(() => _otherOnline = true);
                }
              } else if (type == 'user_offline') {
                if (decoded['email'] == widget.otherEmail) {
                  if (!mounted) return;
                  setState(() => _otherOnline = false);
                }
              } else if (type == 'messages_read') {
                if (mounted) setState(() {});
              } else if (type == 'reaction_updated') {
                final msgId = decoded['message_id'];
                final reactions = decoded['reactions'];
                if (mounted) {
                  setState(() {
                    final idx = _messages.indexWhere((m) => m['id'] == msgId);
                    if (idx >= 0) {
                      _messages[idx]['reactions'] = reactions;
                    }
                  });
                }
              } else if (type == 'message_deleted') {
                final msgId = decoded['message_id'];
                if (mounted) {
                  setState(() {
                    final idx = _messages.indexWhere((m) => m['id'] == msgId);
                    if (idx >= 0) {
                      _messages[idx]['is_deleted'] = true;
                      _messages[idx]['content'] = 'This message was deleted';
                    }
                  });
                }
              } else if (type == 'poll_updated') {
                final pollId = decoded['poll_id'];
                final options = decoded['options'];
                final totalVotes = decoded['total_votes'];
                if (mounted) {
                  setState(() {
                    final idx = _messages.indexWhere((m) => m['extra_data']?['poll_id'] == pollId);
                    if (idx >= 0 && _messages[idx]['poll'] != null) {
                      _messages[idx]['poll']['options'] = options;
                      _messages[idx]['poll']['total_votes'] = totalVotes;
                    }
                  });
                }
              }
            }
          } catch (_) {}
        },
        onDone: () {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) _connectWebSocket();
          });
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;

    setState(() => _loading = true);
    try {
      final data = await _api.getMessages(conversationId: widget.conversationId, email: email, limit: 100);
      if (!mounted) return;
      setState(() {
        _messages = data;
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    final email = Session.email.trim();
    if (email.isEmpty) return;

    setState(() => _sending = true);
    _messageController.clear();

    try {
      final result = await _api.sendMessage(
        conversationId: widget.conversationId,
        senderEmail: email,
        content: text,
        replyTo: _replyTo,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(result['message']);
        _sending = false;
        _replyTo = null;
        _replyContent = '';
        _replySender = '';
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final email = Session.email.trim();
    try {
      await _api.deleteMessage(conversationId: widget.conversationId, messageId: messageId, email: email);
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == messageId);
        if (idx >= 0) {
          _messages[idx]['is_deleted'] = true;
          _messages[idx]['content'] = 'This message was deleted';
        }
      });
    } catch (_) {}
  }

  Future<void> _reactToMessage(String messageId, String emoji) async {
    final email = Session.email.trim();
    try {
      final result = await _api.addReaction(
        conversationId: widget.conversationId,
        messageId: messageId,
        email: email,
        emoji: emoji,
      );
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == messageId);
        if (idx >= 0) {
          _messages[idx]['reactions'] = result['reactions'];
        }
      });
    } catch (_) {}
  }

  void _setReply(String messageId, String content, String sender) {
    setState(() {
      _replyTo = messageId;
      _replyContent = content;
      _replySender = sender;
    });
    _messageController.clear();
    FocusScope.of(context).requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyTo = null;
      _replyContent = '';
      _replySender = '';
    });
  }

  void _showEmojiPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('React', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _quickEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _reactToMessage(messageId, emoji);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> msg) {
    final isMe = (msg['sender_email'] ?? '').toString().toLowerCase() == Session.email.toLowerCase().trim();
    final isDeleted = msg['is_deleted'] == true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDeleted)
              ListTile(
                leading: const Icon(Icons.reply, color: accent),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _setReply(
                    msg['id'],
                    (msg['content'] ?? '').toString(),
                    (msg['sender_name'] ?? '').toString(),
                  );
                },
              ),
            if (!isDeleted)
              ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined, color: accent),
                title: const Text('React'),
                onTap: () {
                  Navigator.pop(context);
                  _showEmojiPicker(msg['id']);
                },
              ),
            if (isMe && !isDeleted)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msg['id']);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.grey),
              title: const Text('Copy'),
              onTap: () {
                final content = (msg['content'] ?? '').toString();
                if (content.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied')));
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final date = DateTime.parse(isoTime);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatDateHeader(String isoTime) {
    if (isoTime.isEmpty) return '';
    try {
      final date = DateTime.parse(isoTime);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDate = DateTime(date.year, date.month, date.day);
      final diff = today.difference(msgDate).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Yesterday';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;
    final currentTime = (_messages[index]['timestamp'] ?? '').toString();
    final previousTime = (_messages[index - 1]['timestamp'] ?? '').toString();
    if (currentTime.isEmpty || previousTime.isEmpty) return false;
    try {
      final currentDate = DateTime.parse(currentTime);
      final previousDate = DateTime.parse(previousTime);
      return currentDate.day != previousDate.day || currentDate.month != previousDate.month || currentDate.year != previousDate.year;
    } catch (_) {
      return false;
    }
  }

  bool _shouldShowReadReceipt(int index) {
    if (index != _messages.length - 1) return false;
    final msg = _messages[index];
    final isMe = (msg['sender_email'] ?? '').toString().toLowerCase() == Session.email.toLowerCase().trim();
    return isMe;
  }

  Widget _buildReadReceipt() {
    final readBy = _messages.isNotEmpty ? (_messages.last['read_by'] ?? []) : [];
    final isRead = readBy.length > 1;
    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 16,
      color: isRead ? Colors.blue : Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final currentEmail = Session.email.toLowerCase().trim();

    return Scaffold(
      backgroundColor: themeProvider.background,
      appBar: AppBar(
        backgroundColor: themeProvider.surface,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.chatType == 'group'
                  ? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3E3A9))
                  : const Color(0xFF6F8574),
              child: widget.chatType == 'group'
                  ? Icon(Icons.group, size: 20, color: themeProvider.textPrimary)
                  : Text(
                      widget.chatName.isNotEmpty ? widget.chatName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chatName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: themeProvider.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (_otherTyping)
                    Text('typing...', style: TextStyle(fontSize: 12, color: Colors.green[600], fontStyle: FontStyle.italic))
                  else if (widget.chatType != 'group' && _otherOnline)
                    Text('Online', style: TextStyle(fontSize: 12, color: Colors.green[600]))
                  else if (widget.handle.isNotEmpty)
                    Text(widget.handle, style: TextStyle(fontSize: 12, color: themeProvider.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: themeProvider.textPrimary),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'search', child: Text('Search in Chat')),
              if (widget.chatType != 'group')
                PopupMenuItem(value: 'block', child: Text(_isBlocked ? 'Unblock User' : 'Block User')),
              PopupMenuItem(value: 'mute', child: Text(_isMuted ? 'Unmute Notifications' : 'Mute Notifications')),
              PopupMenuItem(value: 'pin', child: Text(_isPinned ? 'Unpin Conversation' : 'Pin Conversation')),
            ],
            onSelected: (value) async {
              final email = Session.email.trim();
              if (value == 'mute') {
                try {
                  final result = await _api.toggleMute(conversationId: widget.conversationId, email: email);
                  if (!mounted) return;
                  setState(() => _isMuted = result['is_muted'] == true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_isMuted ? 'Notifications muted' : 'Notifications unmuted')),
                  );
                } catch (_) {}
              } else if (value == 'pin') {
                try {
                  final result = await _api.togglePin(conversationId: widget.conversationId, email: email);
                  if (!mounted) return;
                  setState(() => _isPinned = result['is_pinned'] == true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_isPinned ? 'Conversation pinned' : 'Conversation unpinned')),
                  );
                } catch (_) {}
              } else if (value == 'block' && widget.otherEmail.isNotEmpty) {
                try {
                  final result = await _api.toggleBlock(email: email, blockedEmail: widget.otherEmail);
                  if (!mounted) return;
                  setState(() => _isBlocked = result['blocked'] == true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_isBlocked ? 'User blocked' : 'User unblocked')),
                  );
                } catch (_) {}
              } else if (value == 'search') {
                _showSearchDialog();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: const Color(0xFF6F8574)))
                : _messages.isEmpty
                    ? _buildEmptyChat(themeProvider)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(18),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = (msg['sender_email'] ?? '').toString().toLowerCase() == currentEmail;
                          final showDate = _shouldShowDateHeader(index);
                          final showRead = _shouldShowReadReceipt(index);

                          return Column(
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(_formatDateHeader((msg['timestamp'] ?? '').toString()), style: TextStyle(color: themeProvider.textSecondary, fontSize: 12)),
                                  ),
                                ),
                              _buildMessageBubble(msg, isMe, themeProvider),
                              if (showRead) _buildReadReceipt(),
                            ],
                          );
                        },
                      ),
          ),
          if (_replyTo != null) _buildReplyBar(themeProvider),
          _buildInputArea(themeProvider),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: isDark ? Colors.white24 : Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No messages yet', style: TextStyle(color: themeProvider.textSecondary, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Say hello!', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildReplyBar(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
        border: Border(top: BorderSide(color: themeProvider.divider)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 36, color: const Color(0xFF6F8574)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_replySender, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: accent)),
                Text(_replyContent, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.surface,
        boxShadow: [BoxShadow(color: isDark ? Colors.black38 : Colors.black12, offset: const Offset(0, -2), blurRadius: 6)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF6F8574)),
              onPressed: _showAttachmentOptions,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: themeProvider.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: themeProvider.textSecondary),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _sending ? Colors.grey : const Color(0xFF6F8574),
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    final content = (msg['content'] ?? '').toString();
    final time = _formatTime((msg['timestamp'] ?? '').toString());
    final isDeleted = msg['is_deleted'] == true;
    final messageType = (msg['message_type'] ?? 'text').toString();
    final reactions = msg['reactions'] as List<dynamic>? ?? [];
    final replyContent = (msg['reply_content'] ?? '').toString();
    final replySender = (msg['reply_sender'] ?? '').toString();
    final senderName = (msg['sender_name'] ?? '').toString();

    return GestureDetector(
      onLongPress: () => _showMessageOptions(msg),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF6F8574)
                : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
            boxShadow: [BoxShadow(color: isDark ? Colors.black38 : Colors.black12, offset: const Offset(0, 1), blurRadius: 3)],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (widget.chatType == 'group' && !isMe && senderName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(senderName, style: const TextStyle(color: Color(0xFF6F8574), fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              if (replyContent.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white.withOpacity(0.15) : (isDark ? const Color(0xFF3A3A3A) : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: isMe ? Colors.white54 : const Color(0xFF6F8574), width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(replySender, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isMe ? Colors.white70 : const Color(0xFF6F8574))),
                      Text(replyContent, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isMe ? Colors.white60 : themeProvider.textSecondary)),
                    ],
                  ),
                ),
              if (messageType == 'poll' && msg['poll'] != null)
                _buildPollWidget(msg['poll'], isMe)
              else if (messageType == 'restaurant' && msg['extra_data'] != null)
                _buildRestaurantCard(msg['extra_data'], isMe)
              else if (messageType == 'post' && msg['extra_data'] != null)
                _buildPostCard(msg['extra_data'], isMe)
              else if (messageType == 'location' && msg['extra_data'] != null)
                _buildLocationCard(msg['extra_data'], isMe)
              else if (messageType == 'image')
                _buildImageMessage(msg['extra_data'], content, isMe)
              else
                Text(
                  isDeleted ? 'This message was deleted' : content,
                  style: TextStyle(
                    color: isDeleted
                        ? (isMe ? Colors.white54 : themeProvider.textSecondary)
                        : (isMe ? Colors.white : themeProvider.textPrimary),
                    fontSize: 15,
                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time, style: TextStyle(color: isMe ? Colors.white70 : themeProvider.textSecondary, fontSize: 11)),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      (msg['read_by'] ?? []).length > 1 ? Icons.done_all : Icons.done,
                      size: 14,
                      color: (msg['read_by'] ?? []).length > 1 ? Colors.blue[200] : Colors.white54,
                    ),
                  ],
                ],
              ),
              if (reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: reactions.map<Widget>((r) {
                      return GestureDetector(
                        onTap: () => _reactToMessage(msg['id'], r['emoji']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.white.withOpacity(0.2) : (isDark ? const Color(0xFF3A3A3A) : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${r['emoji']} ${r['count']}', style: TextStyle(fontSize: 12, color: isMe ? Colors.white : themeProvider.textPrimary)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollWidget(Map<String, dynamic> poll, bool isMe) {
    final question = (poll['question'] ?? '').toString();
    final options = poll['options'] as List<dynamic>? ?? [];
    final totalVotes = (poll['total_votes'] ?? 0) as int;
    final isActive = poll['is_active'] == true;
    final email = Session.email.trim();
    final date = (poll['date'] ?? '').toString();
    final time = (poll['time'] ?? '').toString();
    final restaurant = (poll['restaurant_name'] ?? '').toString();
    final creatorEmail = (poll['creator_email'] ?? '').toString();
    final isCreator = email.toLowerCase() == creatorEmail.toLowerCase();

    // Attendance option indices
    const goingIdx = 0; // "I'm In"
    const notIdx = 1; // "Can't Make It"
    final goingOpt = options.length > goingIdx ? options[goingIdx] : null;
    final notOpt = options.length > notIdx ? options[notIdx] : null;
    final goingVotes = (goingOpt?['votes'] as List<dynamic>? ?? []);
    final notVotes = (notOpt?['votes'] as List<dynamic>? ?? []);
    final hasVoted = goingVotes.contains(email) || notVotes.contains(email);
    final isGoing = goingVotes.contains(email);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.event_available, size: 18, color: isMe ? Colors.white70 : accent),
          const SizedBox(width: 6),
          Text('Get-together', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isMe ? Colors.white70 : accent)),
        ]),
        const SizedBox(height: 6),
        Text(question, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isMe ? Colors.white : Colors.black87)),
        // Plan details
        if (restaurant.isNotEmpty || date.isNotEmpty || time.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (restaurant.isNotEmpty)
                _pollDetailChip(Icons.restaurant, restaurant, isMe),
              if (date.isNotEmpty)
                _pollDetailChip(Icons.calendar_today, date, isMe),
              if (time.isNotEmpty)
                _pollDetailChip(Icons.access_time, time, isMe),
            ],
          ),
        ],
        const SizedBox(height: 12),
        // Attendance buttons
        if (isActive) ...[
          Row(
            children: [
              Expanded(
                child: _attendanceButton(
                  label: "I'm In",
                  icon: Icons.check_circle_outline,
                  count: goingVotes.length,
                  isSelected: isGoing,
                  isMe: isMe,
                  onTap: hasVoted && isGoing ? null : () => _votePoll(poll['id'], goingIdx),
                  color: Colors.green[600]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _attendanceButton(
                  label: "Can't Make It",
                  icon: Icons.cancel_outlined,
                  count: notVotes.length,
                  isSelected: notVotes.contains(email),
                  isMe: isMe,
                  onTap: hasVoted && !isGoing ? null : () => _votePoll(poll['id'], notIdx),
                  color: Colors.red[400]!,
                ),
              ),
            ],
          ),
        ] else ...[
          // Show results when closed
          _attendanceResultRow(
            label: "I'm In",
            count: goingVotes.length,
            isMe: isMe,
            color: Colors.green[600]!,
          ),
          const SizedBox(height: 6),
          _attendanceResultRow(
            label: "Can't Make It",
            count: notVotes.length,
            isMe: isMe,
            color: Colors.red[400]!,
          ),
        ],
        // Attendee avatars
        if (goingVotes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              ...goingVotes.take(6).map((v) => CircleAvatar(
                    radius: 14,
                    backgroundColor: isMe ? Colors.white54 : accent.withOpacity(0.2),
                    child: Text((v as String)[0].toUpperCase(), style: TextStyle(fontSize: 11, color: isMe ? Colors.white : accent)),
                  )),
              if (goingVotes.length > 6)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isMe ? Colors.white24 : Colors.grey[300],
                  child: Text('+${goingVotes.length - 6}', style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey[700])),
                ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Text(
          isActive ? '${goingVotes.length} in, ${notVotes.length} out' : 'Plan confirmed · ${goingVotes.length} going',
          style: TextStyle(fontSize: 11, color: isMe ? Colors.white54 : Colors.grey[500]),
        ),
        // Confirm button for creator
        if (isCreator && isActive)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: goingVotes.isEmpty ? null : () => _confirmPoll(poll['id']),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Confirm Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMe ? Colors.white : accent,
                  foregroundColor: isMe ? accent : Colors.white,
                  disabledBackgroundColor: isMe ? Colors.white24 : Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _attendanceButton({
    required String label,
    required IconData icon,
    required int count,
    required bool isSelected,
    required bool isMe,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(isMe ? 0.3 : 0.15)
              : isMe ? Colors.white.withOpacity(0.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color.withOpacity(isMe ? 0.8 : 1.0) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: isSelected ? color : (isMe ? Colors.white70 : Colors.grey[600])),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : (isMe ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$count', style: TextStyle(fontSize: 12, color: isMe ? Colors.white54 : Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _attendanceResultRow({
    required String label,
    required int count,
    required bool isMe,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.12) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))),
          Text('$count', style: TextStyle(color: isMe ? Colors.white54 : Colors.grey[600], fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _pollDetailChip(IconData icon, String label, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isMe ? Colors.white70 : accent),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _confirmPoll(String pollId) async {
    try {
      final result = await _api.confirmPoll(pollId: pollId, email: Session.email.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Plan confirmed!')),
      );
      // Refresh messages to show closed poll
      _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _votePoll(String pollId, int optionIndex) async {
    final email = Session.email.trim();
    try {
      final result = await _api.votePoll(pollId: pollId, email: email, optionIndex: optionIndex);
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['poll']?['id'] == pollId);
        if (idx >= 0) {
          _messages[idx]['poll']['options'] = result['options'];
          _messages[idx]['poll']['total_votes'] = result['total_votes'];
        }
      });
    } catch (_) {}
  }

  Widget _buildRestaurantCard(Map<String, dynamic> extra, bool isMe) {
    final name = (extra['name'] ?? '').toString();
    final cuisine = (extra['cuisine'] ?? '').toString();
    final rating = extra['rating'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.15) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.restaurant, size: 18, color: isMe ? Colors.white70 : accent),
            const SizedBox(width: 6),
            Text('Restaurant', style: TextStyle(fontSize: 11, color: isMe ? Colors.white54 : Colors.grey)),
          ]),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isMe ? Colors.white : Colors.black87)),
          if (cuisine.isNotEmpty)
            Text(cuisine, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey[600])),
          if (rating > 0)
            Row(children: [
              Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(rating.toString(), style: TextStyle(color: isMe ? Colors.white70 : Colors.black87)),
            ]),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> extra, bool isMe) {
    final restaurantName = (extra['restaurant_name'] ?? '').toString();
    final description = (extra['description'] ?? '').toString();
    final rating = extra['rating'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.15) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.post_add, size: 18, color: isMe ? Colors.white70 : accent),
            const SizedBox(width: 6),
            Text('Review', style: TextStyle(fontSize: 11, color: isMe ? Colors.white54 : Colors.grey)),
          ]),
          const SizedBox(height: 6),
          Text(restaurantName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isMe ? Colors.white : Colors.black87)),
          if (description.isNotEmpty)
            Text(description, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey[600])),
          if (rating > 0)
            Row(children: List.generate(5, (i) => Icon(Icons.star, size: 12, color: i < rating ? Colors.amber : Colors.grey[300]))),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> extra, bool isMe) {
    final name = (extra['name'] ?? 'Location').toString();
    final address = (extra['address'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.15) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.location_on, size: 18, color: isMe ? Colors.white70 : Colors.red),
            const SizedBox(width: 6),
            Text('Location', style: TextStyle(fontSize: 11, color: isMe ? Colors.white54 : Colors.grey)),
          ]),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: isMe ? Colors.white : Colors.black87)),
          if (address.isNotEmpty)
            Text(address, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildImageMessage(Map<String, dynamic>? extra, String content, bool isMe) {
    final imageUrl = extra?['image_url']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SmartImage(
              imageUrl: imageUrl,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorWidget: Container(
                width: 200, height: 150,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.image, color: Colors.grey)),
              ),
            ),
          ),
        if (content.isNotEmpty && content != 'Photo')
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(content, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
          ),
      ],
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentButton(Icons.poll, 'Poll', () {
                  Navigator.pop(context);
                  _showCreatePollDialog();
                }),
                _attachmentButton(Icons.restaurant, 'Restaurant', () {
                  Navigator.pop(context);
                  _showShareRestaurantDialog();
                }),
                _attachmentButton(Icons.post_add, 'Post', () {
                  Navigator.pop(context);
                  _showSharePostDialog();
                }),
                _attachmentButton(Icons.location_on, 'Location', () {
                  Navigator.pop(context);
                  _sendLocation();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardYellow, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showCreatePollDialog() {
    final questionController = TextEditingController();
    final restaurantController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Plan a Get-together'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(hintText: 'What are we planning?', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: restaurantController,
                  decoration: const InputDecoration(hintText: 'Restaurant / Place name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedDate != null ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}' : 'Date',
                                  style: TextStyle(color: selectedDate != null ? Colors.black87 : Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedTime != null ? selectedTime!.format(context) : 'Time',
                                  style: TextStyle(color: selectedTime != null ? Colors.black87 : Colors.grey[600]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Members will respond with "I\'m In" or "Can\'t Make It". You can confirm the plan once everyone is in.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final question = questionController.text.trim();
                if (question.isEmpty) return;

                final email = Session.email.trim();
                final dateStr = selectedDate != null ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}' : null;
                final timeStr = selectedTime != null ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}' : null;
                try {
                  final result = await _api.createPoll(
                    conversationId: widget.conversationId,
                    senderEmail: email,
                    question: question,
                    options: ["I'm In", "Can't Make It"],
                    date: dateStr,
                    time: timeStr,
                    restaurantName: restaurantController.text.trim().isNotEmpty ? restaurantController.text.trim() : null,
                  );
                  if (!mounted) return;
                  setState(() {
                    _messages.add(result['message']);
                  });
                  _scrollToBottom();
                  Navigator.pop(context);
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Send', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareRestaurantDialog() async {
    try {
      final restaurants = await _api.getRestaurants(limit: 20);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Share Restaurant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final r = restaurants[index];
                    final cuisine = (r['cuisine'] ?? '').toString();
                    final name = (r['name'] ?? '').toString();
                    final types = r['types'] as List<dynamic>?;
                    final typeColor = getRestaurantTypeColor(types, cuisine, name: name);
                    final typeIcon = getRestaurantTypeIcon(types, cuisine, name: name);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: typeColor.withOpacity(0.15),
                        child: Icon(typeIcon, color: typeColor),
                      ),
                      title: Text((r['name'] ?? '').toString()),
                      subtitle: Text(cuisine.isNotEmpty ? cuisine : 'Restaurant'),
                      onTap: () async {
                        Navigator.pop(context);
                        final email = Session.email.trim();
                        final result = await _api.sendMessage(
                          conversationId: widget.conversationId,
                          senderEmail: email,
                          content: (r['name'] ?? '').toString(),
                          messageType: 'restaurant',
                          extraData: {
                            'id': r['id'],
                            'name': r['name'],
                            'cuisine': r['cuisine'],
                            'rating': r['rating'],
                            'address': r['address'],
                          },
                        );
                        if (!mounted) return;
                        setState(() {
                          _messages.add(result['message']);
                        });
                        _scrollToBottom();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {}
  }

  void _showSharePostDialog() async {
    try {
      final posts = await _api.getPosts(limit: 20);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Share Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final p = posts[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: cardYellow, child: const Icon(Icons.post_add, color: Colors.black87)),
                      title: Text((p['restaurant_name'] ?? '').toString()),
                      subtitle: Text((p['description'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () async {
                        Navigator.pop(context);
                        final email = Session.email.trim();
                        final result = await _api.sendMessage(
                          conversationId: widget.conversationId,
                          senderEmail: email,
                          content: (p['restaurant_name'] ?? '').toString(),
                          messageType: 'post',
                          extraData: {
                            'id': p['id'],
                            'restaurant_name': p['restaurant_name'],
                            'description': p['description'],
                            'rating': p['rating'],
                          },
                        );
                        if (!mounted) return;
                        setState(() {
                          _messages.add(result['message']);
                        });
                        _scrollToBottom();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {}
  }

  void _sendLocation() async {
    final email = Session.email.trim();
    final result = await _api.sendMessage(
      conversationId: widget.conversationId,
      senderEmail: email,
      content: 'Shared a location',
      messageType: 'location',
      extraData: {
        'name': 'My Location',
        'address': 'Current location',
        'lat': 0.0,
        'lng': 0.0,
      },
    );
    if (!mounted) return;
    setState(() {
      _messages.add(result['message']);
    });
    _scrollToBottom();
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search in Chat'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final query = searchController.text.trim();
              if (query.isEmpty) return;
              final email = Session.email.trim();
              try {
                final results = await _api.searchMessages(
                  conversationId: widget.conversationId,
                  email: email,
                  query: query,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Found ${results.length} messages')),
                  );
                }
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            child: const Text('Search', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _wsSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}