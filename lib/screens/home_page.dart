import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/image_viewer.dart';
import '../widgets/smart_image.dart';
import '../widgets/animations.dart';
import '../widgets/empty_states.dart';
import '../widgets/map_marker.dart';
import '../widgets/restaurant_logo_image.dart';
import '../utils/restaurant_logos.dart';
import 'restaurant_page.dart';
import 'userprofile/friend_profile_page.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../services/theme_provider.dart';
import 'comments_page.dart';
import 'notifications_page.dart';
import '../widgets/ai_chat_panel.dart';

class HomePage extends StatefulWidget {
  final String name;
  const HomePage({super.key, required this.name});

  @override
  State<HomePage> createState() => _HomePageState();

  static const Color background = Color(0xFFFEF9EE);
  static const Color cardYellow = Color(0xFFF3E3A9);
  static const Color accent = Color(0xFF6F8574);
}

class _HomePageState extends State<HomePage> {
  final _api = ApiService();
  final ScrollController _scrollController = ScrollController();

  bool _loadingRestaurants = true;
  String? _restaurantsError;
  List<dynamic> _restaurants = [];
  bool _hasTasteHistory = false;

  bool _loadingPosts = true;
  String? _postsError;
  List<dynamic> _posts = [];
  int _postsSkip = 0;
  bool _loadingMorePosts = false;
  bool _hasMorePosts = true;

  bool _loadingSuggestions = true;
  List<dynamic> _suggestedUsers = [];

  int _unreadNotifications = 0;

  Map<String, bool> _likedPosts = {};
  Map<String, int> _likesCount = {};
  Map<String, bool> _bookmarkedPosts = {};

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _loadPosts();
    _loadSuggestedUsers();
    _loadUnreadCount();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMorePosts && _hasMorePosts) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _loadingRestaurants = true;
      _restaurantsError = null;
    });

    try {
      final email = Session.email.trim();
      List<dynamic> results;
      if (email.isEmpty) {
        // Fallback generic search
        results = await _api.searchRestaurantsFoursquare(
          query: 'restaurant',
          limit: 20,
        );
        _hasTasteHistory = false;
      } else {
        // Get AI-powered personalized recommendations
        final data = await _api.getPersonalizedRecommendations(
          email: email,
          limit: 20,
        );
        results = data['restaurants'] ?? [];
        _hasTasteHistory = data['has_history'] == true;
      }

      if (!mounted) return;
      setState(() {
        _restaurants = results;
        _loadingRestaurants = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _restaurantsError = e.toString().replaceFirst("Exception: ", "");
        _loadingRestaurants = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loadingPosts = true;
      _postsError = null;
      _postsSkip = 0;
      _hasMorePosts = true;
    });

    try {
      final data = await _api.getPosts(limit: 10, includeReviews: false);
      if (!mounted) return;

      final currentEmail = Session.email.toLowerCase().trim();
      for (var post in data) {
        final postId = post["id"]?.toString() ?? "";
        final likes = post["likes"] as List<dynamic>? ?? [];
        _likesCount[postId] = likes.length;
        _likedPosts[postId] = likes.contains(currentEmail);
      }

      setState(() {
        _posts = data;
        _postsSkip = data.length;
        _loadingPosts = false;
        if (data.length < 10) _hasMorePosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _postsError = e.toString().replaceFirst("Exception: ", "");
        _loadingPosts = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMorePosts) return;
    setState(() => _loadingMorePosts = true);

    try {
      final data = await _api.getPosts(limit: 10, includeReviews: false, skip: _postsSkip);
      if (!mounted) return;

      if (data.isEmpty) {
        setState(() {
          _hasMorePosts = false;
          _loadingMorePosts = false;
        });
        return;
      }

      final currentEmail = Session.email.toLowerCase().trim();
      for (var post in data) {
        final postId = post["id"]?.toString() ?? "";
        final likes = post["likes"] as List<dynamic>? ?? [];
        _likesCount[postId] = likes.length;
        _likedPosts[postId] = likes.contains(currentEmail);
      }

      setState(() {
        _posts.addAll(data);
        _postsSkip += data.length;
        _loadingMorePosts = false;
        if (data.length < 10) _hasMorePosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMorePosts = false);
    }
  }

  Future<void> _loadSuggestedUsers() async {
    final email = Session.email.trim();
    if (email.isEmpty) {
      setState(() => _loadingSuggestions = false);
      return;
    }

    try {
      final data = await _api.getSuggestedUsers(email: email, limit: 10);
      if (!mounted) return;
      setState(() {
        _suggestedUsers = data;
        _loadingSuggestions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingSuggestions = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;
    try {
      final count = await _api.getUnreadNotificationCount(email: email);
      if (!mounted) return;
      setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  Future<void> _toggleLike(String postId) async {
    final email = Session.email.trim();
    if (email.isEmpty) return;

    HapticFeedback.lightImpact();

    try {
      final result = await _api.likePost(postId: postId, email: email);
      if (!mounted) return;
      setState(() {
        _likedPosts[postId] = !_likedPosts[postId]!;
        _likesCount[postId] = result["likes_count"] ?? (_likesCount[postId] ?? 0);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  Future<void> _toggleBookmark(String postId) async {
    final email = Session.email.trim();
    if (email.isEmpty) return;

    try {
      final result = await _api.toggleBookmark(email: email, postId: postId);
      if (!mounted) return;
      setState(() {
        _bookmarkedPosts[postId] = result["bookmarked"] == true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_bookmarkedPosts[postId]! ? 'Bookmarked' : 'Removed bookmark')),
      );
    } catch (_) {}
  }

  Future<void> _deletePost(String postId) async {
    final email = Session.email.trim();
    try {
      await _api.deletePost(postId: postId, email: email);
      if (!mounted) return;
      setState(() {
        _posts.removeWhere((p) => p["id"] == postId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  void _showPostOptions(Map<String, dynamic> post) {
    final postId = (post["id"] ?? "").toString();
    final authorEmail = (post["user_email"] ?? "").toString().toLowerCase();
    final isMine = authorEmail == Session.email.toLowerCase().trim();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(_bookmarkedPosts[postId] == true ? Icons.bookmark : Icons.bookmark_outline, color: HomePage.accent),
              title: Text(_bookmarkedPosts[postId] == true ? 'Remove Bookmark' : 'Bookmark'),
              onTap: () {
                Navigator.pop(context);
                _toggleBookmark(postId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: HomePage.accent),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                final restaurantName = (post["restaurant_name"] ?? "").toString();
                final description = (post["description"] ?? "").toString();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share: $restaurantName - $description')),
                );
              },
            ),
            if (isMine) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: HomePage.accent),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditPostDialog(post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(postId);
                },
              ),
            ],
            if (!isMine)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(postId);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditPostDialog(Map<String, dynamic> post) {
    final descController = TextEditingController(text: (post["description"] ?? "").toString());
    int rating = (post["rating"] ?? 0) as int;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => rating = i + 1),
                      child: Icon(
                        Icons.star_rounded,
                        size: 36,
                        color: i < rating ? Colors.amber : Colors.grey[300],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final email = Session.email.trim();
                try {
                  await _api.editPost(
                    postId: post["id"],
                    email: email,
                    description: descController.text.trim(),
                    rating: rating,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _loadPosts();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post updated')));
                  }
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(backgroundColor: HomePage.accent),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(String postId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Reason for report', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final email = Session.email.trim();
              try {
                await _api.reportContent(
                  reporterEmail: email,
                  reportedType: 'post',
                  reportedId: postId,
                  reason: reasonController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
                }
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return "${diff.inDays}d ago";
      if (diff.inHours > 0) return "${diff.inHours}h ago";
      if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
      return "Just now";
    } catch (e) {
      return "Recently";
    }
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget peopleCard(dynamic user) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final personName = (user["name"] ?? "User").toString();
    final handle = (user["handle"] ?? "@user").toString();
    final email = (user["email"] ?? "").toString();
    final avatarUrl = (user["avatar_url"] ?? "").toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => FriendProfilePage(userName: personName, handle: handle, email: email)));
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: themeProvider.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: isDark ? Colors.black38 : Colors.black12, offset: const Offset(2, 6), blurRadius: 8)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 30,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[350],
              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty ? Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey) : null,
            ),
            const SizedBox(height: 10),
            Text(personName, style: TextStyle(fontWeight: FontWeight.w700, color: themeProvider.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(handle, style: TextStyle(color: themeProvider.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final myEmail = Session.email.trim();
                    if (myEmail.isEmpty) return;
                    try {
                      await _api.sendFriendRequest(fromEmail: myEmail, toEmail: email);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Follow request sent!')));
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))));
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF7E489),
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Follow'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget restaurantCard(dynamic r) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final String id = (r["id"] ?? r["fsq_id"] ?? "").toString();
    final String name = (r["name"] ?? "Restaurant").toString();
    final String address = (r["address"] ?? "Location").toString();
    final String cuisine = (r["cuisine"] ?? r["type"] ?? r["category_name"] ?? "").toString();
    final String? logoUrl = getRestaurantCardImageUrl(name, cuisine);
    final String iconUrl = (r["icon_url"] ?? "").toString();
    final types = r['types'] as List<dynamic>?;
    final double rating = (r["rating"] is num) ? (r["rating"] as num).toDouble() : 0.0;
    final typeColor = getRestaurantTypeColor(types, cuisine, name: name);
    final typeIcon = getRestaurantTypeIcon(types, cuisine, name: name);
    final bool isTasteMatch = _hasTasteHistory && r['taste_matched'] == true;

    return GestureDetector(
      onTap: () {
        final restaurantId = id.isNotEmpty ? id : name.replaceAll(' ', '_').toLowerCase();
        Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantPage(restaurantId: restaurantId, restaurantName: name, foursquareData: r)));
      },
      child: Container(
        width: 190,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: themeProvider.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: isDark ? Colors.black38 : Colors.black12, offset: const Offset(0, 4), blurRadius: 8),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              clipBehavior: Clip.hardEdge,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: RestaurantLogoImage(
                  url: logoUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fallback: Center(
                    child: iconUrl.isNotEmpty
                        ? Image.network(iconUrl, width: 40, height: 40, errorBuilder: (_, __, ___) => Icon(typeIcon, color: typeColor, size: 32))
                        : Icon(typeIcon, color: typeColor, size: 32),
                  ),
                  padding: const EdgeInsets.all(18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: themeProvider.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (isTasteMatch) ...[
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 170),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6F8574).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Based on your taste',
                        style: TextStyle(fontSize: 10, color: Color(0xFF6F8574), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place, size: 14, color: themeProvider.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(address, style: TextStyle(color: themeProvider.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  if (rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: TextStyle(color: themeProvider.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget postItem(dynamic post) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final postId = (post["id"] ?? "").toString();
    final author = (post["user_name"] ?? post["user_email"] ?? "User").toString();
    final handle = (post["user_handle"] ?? "@user").toString();
    final restaurantName = (post["restaurant_name"] ?? "Restaurant").toString();
    final description = (post["description"] ?? "").toString();
    final rating = (post["rating"] is num) ? (post["rating"] as num).toInt() : 0;
    final imageUrl = (post["image_url"] ?? "").toString();
    final timeAgo = (post["created_at"] ?? "").toString();
    final likesCount = _likesCount[postId] ?? (post["likes_count"] ?? 0);
    final isLiked = _likedPosts[postId] ?? false;
    final isBookmarked = _bookmarkedPosts[postId] ?? false;
    final authorEmail = (post["user_email"] ?? "").toString();

    final isMine = authorEmail.toLowerCase() == Session.email.toLowerCase().trim();

    String timeDisplay = timeAgo.isNotEmpty ? _formatTimeAgo(timeAgo) : "Recently";

    Widget postContent = GestureDetector(
      onLongPress: () => _showPostOptions(post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(radius: 20, backgroundColor: isDark ? Colors.grey[700] : Colors.grey[350], child: Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(author, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: themeProvider.textPrimary)),
                        const SizedBox(width: 8),
                        ...List.generate(5, (i) => Icon(Icons.star_rounded, color: i < rating ? Colors.amber : (isDark ? Colors.grey[700] : Colors.grey[300]), size: 14)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(handle, style: TextStyle(color: themeProvider.textSecondary, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text(timeDisplay, style: TextStyle(color: themeProvider.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: themeProvider.textSecondary, size: 20),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'bookmark', child: Text(isBookmarked ? 'Remove Bookmark' : 'Bookmark')),
                  const PopupMenuItem(value: 'share', child: Text('Share')),
                ],
                onSelected: (value) {
                  if (value == 'bookmark') _toggleBookmark(postId);
                  if (value == 'share') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Share: $restaurantName')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(restaurantName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: themeProvider.textPrimary)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(height: 1.4, fontSize: 14, color: themeProvider.textPrimary)),
          const SizedBox(height: 8),
          if (imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewerPage(imageUrl: imageUrl))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: isDark ? Colors.grey[800] : Colors.grey[200]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SmartImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: Center(child: Icon(Icons.image, color: themeProvider.textSecondary, size: 48)),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleLike(postId),
                child: Row(
                  children: [
                    Icon(isLiked ? Icons.favorite : Icons.favorite_outline, size: 22, color: isLiked ? Colors.red : themeProvider.textSecondary),
                    const SizedBox(width: 4),
                    Text(likesCount.toString(), style: TextStyle(fontSize: 14, color: isLiked ? Colors.red : themeProvider.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CommentsPage(postId: postId, restaurantName: restaurantName)));
                },
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 20, color: themeProvider.textSecondary),
                    const SizedBox(width: 4),
                    Text('Comment', style: TextStyle(fontSize: 14, color: themeProvider.textSecondary)),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _toggleBookmark(postId),
                child: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline, size: 22, color: isBookmarked ? HomePage.accent : themeProvider.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: themeProvider.divider),
        ],
      ),
    );

    if (isMine) {
      return Dismissible(
        key: Key(postId),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 28),
              SizedBox(height: 4),
              Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Post'),
              content: const Text('Are you sure you want to delete this post?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) => _deletePost(postId),
        child: postContent,
      );
    }

    return postContent;
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
        toolbarHeight: 80,
        title: Text(
          'Welcome\n${widget.name}',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: themeProvider.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 12),
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AiChatPanel(),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF3E3A9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy, color: Color(0xFF6F8574), size: 22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18.0, top: 12),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                _loadUnreadCount();
              },
              child: Stack(
                children: [
                  Icon(Icons.notifications, color: HomePage.accent, size: 28),
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          _unreadNotifications > 9 ? '9+' : _unreadNotifications.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - (AppBar().preferredSize.height + MediaQuery.of(context).padding.top),
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadRestaurants();
                await _loadPosts();
                await _loadUnreadCount();
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12).copyWith(bottom: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),

                    // People you may know
                    if (_loadingSuggestions)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          itemBuilder: (_, __) => const PersonCardSkeleton(),
                        ),
                      )
                    else if (_suggestedUsers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF2A2A2A) : HomePage.cardYellow, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('People you may know', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: themeProvider.textPrimary)),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: _suggestedUsers.map((user) => peopleCard(user)).toList()),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 18),

                    // Restaurants
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _hasTasteHistory ? 'Recommended for you 💚' : 'Popular near you 🔥',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: themeProvider.textPrimary),
                        ),
                        TextButton(onPressed: _loadRestaurants, child: const Text('Refresh')),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_loadingRestaurants)
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          itemBuilder: (_, __) => const RestaurantCardSkeleton(),
                        ),
                      )
                    else if (_restaurantsError != null)
                      _buildErrorWidget(_restaurantsError!, _loadRestaurants)
                    else if (_restaurants.isEmpty)
                      const EmptyRestaurantsWidget()
                    else
                      SizedBox(
                        height: 200,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _restaurants.map((r) => restaurantCard(r)).toList(),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // Posts
                    Text('Posts - Updates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: themeProvider.textPrimary)),
                    const SizedBox(height: 6),
                    Text('The latest from your friends and the community', style: TextStyle(color: themeProvider.textSecondary)),
                    const SizedBox(height: 12),

                    if (_loadingPosts)
                      ...List.generate(3, (_) => const PostSkeleton())
                    else if (_postsError != null)
                      _buildErrorWidget(_postsError!, _loadPosts)
                    else if (_posts.isEmpty)
                      const EmptyPostsWidget()
                    else
                      ..._posts.map((post) => postItem(post)),

                    if (_loadingMorePosts)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: FloatingNavBar(
              currentIndex: 0,
              homeName: widget.name,
              onTap: (i) {},
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}