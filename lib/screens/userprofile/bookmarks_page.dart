import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/session.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  static const Color accent = Color(0xFF6F8574);

  final _api = ApiService();
  List<dynamic> _bookmarks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;

    try {
      final data = await _api.getBookmarks(email: email);
      if (!mounted) return;
      setState(() {
        _bookmarks = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Bookmarks', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_outline, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No bookmarks yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Save posts to read later', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final post = _bookmarks[index];
                    final restaurantName = (post['restaurant_name'] ?? '').toString();
                    final description = (post['description'] ?? '').toString();
                    final rating = (post['rating'] ?? 0) as int;

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
                            children: [
                              const Icon(Icons.bookmark, color: accent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(restaurantName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                              Row(
                                children: List.generate(5, (i) => Icon(Icons.star_rounded, color: i < rating ? Colors.amber : Colors.grey[300], size: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}