import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/session.dart';
import '../../widgets/smart_image.dart';
import '../../widgets/map_marker.dart';
import '../restaurant_page.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  static const Color background = Color(0xFFFEF9EE);
  static const Color cardYellow = Color(0xFFF3E3A9);

  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final email = Session.email.trim(); // IMPORTANT: raw email (no encoding)

    if (email.isEmpty) {
      setState(() {
        _loading = false;
        _error = "You are not logged in (email is empty).";
        _items = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.getWishlist(email: email);
      // Ensure list of map
      final list = data.map((e) => Map<String, dynamic>.from(e)).toList();

      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
        _items = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error ?? "Failed to load wishlist")),
      );
    }
  }

  Future<void> _removeFromWishlist(String restaurantId) async {
    final email = Session.email.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are not logged in.")),
      );
      return;
    }

    try {
      final res = await _api.toggleWishlist(
        email: email,
        restaurantId: restaurantId,
      );

      final inWishlist = (res["in_wishlist"] == true);

      // If toggle returns true, it means it is still in wishlist; we want it removed.
      if (inWishlist) {
        // It got added back (unexpected UX), so toggle again to remove
        await _api.toggleWishlist(email: email, restaurantId: restaurantId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from wishlist ✅")),
      );

      await _loadWishlist();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Remove failed: ${e.toString().replaceFirst("Exception: ", "")}",
          ),
        ),
      );
    }
  }

  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
    }

  @override
  Widget build(BuildContext context) {
    final email = Session.email.trim();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Wishlist",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadWishlist,
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWishlist,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            if (email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "Logged in as: $email",
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(
                  child: Text(
                    "No items in your wishlist",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ..._items.map((r) {
                final id = (r["id"] ?? "").toString();
                final name = (r["name"] ?? "Restaurant").toString();
                final address = (r["address"] ?? "Location").toString();
                final rating = _asDouble(r["rating"], fallback: 0);
                final imageUrl = (r["imageUrl"] ?? "").toString();
                final cuisine = (r["cuisine"] ?? "").toString();
                final types = r['types'] as List<dynamic>?;
                final typeColor = getRestaurantTypeColor(types, cuisine, name: name);
                final typeIcon = getRestaurantTypeIcon(types, cuisine, name: name);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      if (id.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantPage(
                              restaurantId: id,
                              restaurantName: name,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Image or type icon
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 70,
                              height: 70,
                              color: imageUrl.isNotEmpty ? Colors.grey[200] : typeColor.withOpacity(0.12),
                              child: imageUrl.isNotEmpty
                                  ? SmartImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: Center(child: Icon(typeIcon, color: typeColor, size: 28)),
                                    )
                                  : Center(child: Icon(typeIcon, color: typeColor, size: 28)),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating == 0 ? "—" : rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Remove
                          GestureDetector(
                            onTap: () => _removeFromWishlist(id),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}