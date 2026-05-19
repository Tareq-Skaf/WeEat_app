import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../widgets/map_marker.dart';
import 'restaurant_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const Color accent = Color(0xFF6F8574);
  static const Color cardYellow = Color(0xFFF3E3A9);

  final _api = ApiService();
  List<dynamic> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;

    try {
      final liked = await _api.getLiked(email: email);
      final wishlist = await _api.getWishlist(email: email);
      if (!mounted) return;

      // Combine and deduplicate
      final allFavorites = <String, dynamic>{};
      for (var r in liked) {
        final id = (r['id'] ?? '').toString();
        if (id.isNotEmpty) {
          r['source'] = 'liked';
          allFavorites[id] = r;
        }
      }
      for (var r in wishlist) {
        final id = (r['id'] ?? '').toString();
        if (id.isNotEmpty && !allFavorites.containsKey(id)) {
          r['source'] = 'wishlist';
          allFavorites[id] = r;
        }
      }

      setState(() {
        _favorites = allFavorites.values.toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _removeFavorite(String restaurantId, String source) async {
    final email = Session.email.trim();
    try {
      if (source == 'liked') {
        await _api.toggleLiked(email: email, restaurantId: restaurantId);
      } else {
        await _api.toggleWishlist(email: email, restaurantId: restaurantId);
      }
      if (!mounted) return;
      setState(() {
        _favorites.removeWhere((r) => (r['id'] ?? '').toString() == restaurantId);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Favorites', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No favorites yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Like or wishlist restaurants to see them here', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final r = _favorites[index];
                      return _buildFavoriteCard(r);
                    },
                  ),
                ),
    );
  }

  Widget _buildFavoriteCard(dynamic restaurant) {
    final id = (restaurant['id'] ?? '').toString();
    final name = (restaurant['name'] ?? 'Restaurant').toString();
    final cuisine = (restaurant['cuisine'] ?? '').toString();
    final address = (restaurant['address'] ?? '').toString();
    final rating = (restaurant['rating'] ?? 0) as num;
    final imageUrl = (restaurant['imageUrl'] ?? '').toString();
    final source = (restaurant['source'] ?? '').toString();
    final types = restaurant['types'] as List<dynamic>?;
    final typeColor = getRestaurantTypeColor(types, cuisine, name: name);
    final typeIcon = getRestaurantTypeIcon(types, cuisine, name: name);

    return GestureDetector(
      onTap: () {
        if (id.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantPage(restaurantId: id, restaurantName: name)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, offset: const Offset(0, 2), blurRadius: 6)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 70,
                height: 70,
                color: imageUrl.isNotEmpty ? Colors.grey[200] : typeColor.withOpacity(0.12),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(typeIcon, color: typeColor, size: 28)))
                    : Center(child: Icon(typeIcon, color: typeColor, size: 28)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  if (cuisine.isNotEmpty) Text(cuisine, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      if (address.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Expanded(child: Text(address, style: TextStyle(color: Colors.grey[500], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: source == 'liked' ? Colors.red[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      source == 'liked' ? 'Liked' : 'Wishlist',
                      style: TextStyle(fontSize: 10, color: source == 'liked' ? Colors.red : Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.favorite, color: Colors.red[400], size: 20),
              onPressed: () => _removeFavorite(id, source),
            ),
          ],
        ),
      ),
    );
  }
}