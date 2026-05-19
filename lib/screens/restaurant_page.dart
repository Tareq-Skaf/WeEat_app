import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../widgets/smart_image.dart';
import '../widgets/map_marker.dart';
import '../widgets/restaurant_logo_image.dart';
import '../utils/restaurant_logos.dart';
import 'add_post_page.dart';

class RestaurantPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final Map<String, dynamic>? foursquareData;

  const RestaurantPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.foursquareData,
  });

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  static const Color background = Color(0xFFFEF9EE);
  static const Color accent = Color(0xFF6F8574);
  static const Color cardYellow = Color(0xFFF3E3A9);

  final ApiService api = ApiService();
  Map<String, dynamic>? _restaurant;
  bool _loading = true;
  String? _error;
  List<dynamic> _reviews = [];
  bool _loadingReviews = true;
  bool _isLiked = false;
  bool _isDisliked = false;
  Map<String, dynamic>? _menu;
  bool _loadingMenu = true;
  String _selectedSection = 'menu'; // 'menu' | 'reviews'
  int _selectedCategoryIndex = 0;
  String? _detectedChain;

  @override
  void initState() {
    super.initState();
    if (widget.foursquareData != null) {
      // Use passed Foursquare data directly — no database fetch needed
      _restaurant = _normalizeFoursquareData(widget.foursquareData!);
      _loading = false;
      _loadFoursquarePhotos();
    } else {
      _loadRestaurant();
    }
    _loadReviews();
    _checkLikeStatus();
    _loadMenu();
  }

  /// Normalize Foursquare raw fields into the structure this page expects
  Map<String, dynamic> _normalizeFoursquareData(Map<String, dynamic> raw) {
    return {
      "id": raw["fsq_id"] ?? raw["id"] ?? widget.restaurantId,
      "name": raw["name"] ?? widget.restaurantName,
      "address": raw["address"] ?? "",
      "phone": raw["tel"] ?? "",
      "lat": raw["lat"] ?? 0.0,
      "lng": raw["lng"] ?? 0.0,
      "imageUrl": raw["photo"] ?? raw["imageUrl"] ?? "",
      "rating": raw["rating"] ?? 0.0,
      "opening_hours": raw["hours"] ?? raw["opening_hours"] ?? "Open now",
      "price_range": raw["price_range"] ?? "",
      "types": raw["types"] ?? (raw["category_name"] != null ? [raw["category_name"]] : []),
      "cuisine": raw["category_name"] ?? raw["cuisine"] ?? raw["type"] ?? "",
      "fsq_id": raw["fsq_id"] ?? raw["id"] ?? "",
    };
  }

  Future<void> _loadFoursquarePhotos() async {
    final fsqId = (_restaurant?['fsq_id'] ?? '').toString();
    if (fsqId.isEmpty) return;
    try {
      final photos = await api.getFoursquarePhotos(fsqId: fsqId, limit: 5);
      if (!mounted) return;
      if (photos.isNotEmpty) {
        // Build photo URL: prefix + "400x200" + suffix
        final first = photos[0] as Map<String, dynamic>;
        final prefix = (first['prefix'] ?? '').toString();
        final suffix = (first['suffix'] ?? '').toString();
        if (prefix.isNotEmpty && suffix.isNotEmpty) {
          setState(() {
            _restaurant?['imageUrl'] = '${prefix}400x200$suffix';
          });
        }
      }
    } catch (_) {
      // Photos are non-critical; silently ignore failures
    }
  }

  Future<void> _loadMenu() async {
    try {
      final data = await api.getRestaurantMenu(restaurantName: widget.restaurantName);
      if (!mounted) return;
      setState(() {
        _menu = data;
        _detectedChain = data['detected_chain'];
        _loadingMenu = false;
        final categories = (_menu?['categories'] as List<dynamic>?);
        if (categories != null && categories.isNotEmpty) {
          _selectedCategoryIndex = 0;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMenu = false);
    }
  }

  Future<void> _loadRestaurant() async {
    try {
      final data = await api.getRestaurantById(widget.restaurantId);
      if (!mounted) return;
      setState(() {
        _restaurant = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _shareRestaurantToFriend() async {
    final email = Session.email.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to share')));
      return;
    }

    try {
      final friends = await api.getFriends(email: email);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Share ${_restaurant?["name"] ?? widget.restaurantName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: friends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text('No friends yet', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final friendName = (friend['friend_name'] ?? 'Unknown').toString();
                          final friendEmail = (friend['friend_email'] ?? '').toString();
                          final friendHandle = (friend['friend_handle'] ?? '').toString();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: accent,
                              child: Text(friendName.isNotEmpty ? friendName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(friendName),
                            subtitle: Text(friendHandle),
                            onTap: () async {
                              Navigator.pop(context);
                              await _sendToFriend(friendEmail, friendName);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _sendToFriend(String friendEmail, String friendName) async {
    final myEmail = Session.email.trim();
    final name = _restaurant?["name"] ?? widget.restaurantName;
    final cuisine = _restaurant?["cuisine"] ?? "";
    final address = _restaurant?["address"] ?? "";
    final rating = _restaurant?["rating"] ?? 0;
    final imageUrl = _restaurant?["imageUrl"] ?? "";

    try {
      final convResult = await api.createConversation(fromEmail: myEmail, toEmail: friendEmail);
      final convId = convResult['conversation']['id'];

      await api.sendMessage(
        conversationId: convId,
        senderEmail: myEmail,
        content: name,
        messageType: 'restaurant',
        extraData: {
          'id': widget.restaurantId,
          'name': name,
          'cuisine': cuisine,
          'address': address,
          'rating': rating,
          'imageUrl': imageUrl,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shared $name with $friendName')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _loadReviews() async {
    try {
      final fsqId = (_restaurant?['fsq_id'] ?? '').toString();
      final name = (_restaurant?['name'] ?? '').toString();
      final reviews = await api.getReviewsByRestaurant(
        fsqId: fsqId.isNotEmpty ? fsqId : null,
        restaurantName: fsqId.isEmpty ? name : null,
      );
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _loadingReviews = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _checkLikeStatus() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;
    try {
      final liked = await api.getLiked(email: email);
      final disliked = await api.getDisliked(email: email);
      if (!mounted) return;
      setState(() {
        _isLiked = liked.any((r) => (r['id'] ?? '').toString() == widget.restaurantId);
        _isDisliked = disliked.any((r) => (r['id'] ?? '').toString() == widget.restaurantId);
      });
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;
    HapticFeedback.lightImpact();
    try {
      await api.toggleLiked(email: email, restaurantId: widget.restaurantId);
      if (!mounted) return;
      setState(() => _isLiked = !_isLiked);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isLiked ? 'Liked' : 'Removed like')));
    } catch (_) {}
  }

  Future<void> _toggleDislike() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;
    HapticFeedback.lightImpact();
    try {
      await api.toggleDisliked(email: email, restaurantId: widget.restaurantId);
      if (!mounted) return;
      setState(() => _isDisliked = !_isDisliked);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isDisliked ? 'Disliked' : 'Removed dislike')));
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    final email = Session.email.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in.")),
      );
      return;
    }

    try {
      final res = await api.toggleWishlist(
        email: email,
        restaurantId: widget.restaurantId,
      );

      final inWishlist = (res["in_wishlist"] == true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(inWishlist ? "Added to wishlist ✅" : "Removed from wishlist ❌"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
        ),
      );
    }
  }

  Widget _buildRestaurantHeaderImage() {
    final imageUrl = (_restaurant?["imageUrl"] ?? "").toString();
    final name = (_restaurant?["name"] ?? "").toString();
    final cuisine = (_restaurant?["cuisine"] ?? "").toString();
    final types = _restaurant?['types'] as List<dynamic>?;
    final typeColor = getRestaurantTypeColor(types, cuisine, name: name);
    final typeIcon = getRestaurantTypeIcon(types, cuisine, name: name);
    final logoUrl = findLogoUrl(name);

    return Container(
      height: 250,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: logoUrl != null || imageUrl.isNotEmpty ? Colors.grey[100] : typeColor.withOpacity(0.12),
        gradient: logoUrl != null || imageUrl.isNotEmpty
            ? null
            : LinearGradient(
                colors: [typeColor.withOpacity(0.08), typeColor.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: logoUrl != null && logoUrl.isNotEmpty
            ? RestaurantLogoImage(
                url: logoUrl,
                width: double.infinity,
                height: double.infinity,
                fallback: imageUrl.isNotEmpty
                    ? SmartImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: Center(child: Icon(typeIcon, color: typeColor, size: 64)),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(typeIcon, color: typeColor, size: 64),
                            const SizedBox(height: 8),
                            Text(
                              cuisine.isNotEmpty ? cuisine : 'Restaurant',
                              style: TextStyle(color: typeColor, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                padding: const EdgeInsets.all(24),
              )
            : imageUrl.isNotEmpty
                ? SmartImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: Center(child: Icon(typeIcon, color: typeColor, size: 64)),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(typeIcon, color: typeColor, size: 64),
                        const SizedBox(height: 8),
                        Text(
                          cuisine.isNotEmpty ? cuisine : 'Restaurant',
                          style: TextStyle(color: typeColor, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _loading = true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Back + Plus)
            Stack(
              children: [
                Container(height: 80, width: double.infinity, color: background),
                Positioned(
                  top: 40,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => _showOptionsDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.black, size: 24),
                    ),
                  ),
                ),
              ],
            ),

            // Restaurant Image
            GestureDetector(
              onTap: () {
                final imageUrl = (_restaurant?["imageUrl"] ?? "").toString();
                if (imageUrl.isEmpty) return;
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: InteractiveViewer(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 64)),
                      ),
                    ),
                  ),
                );
              },
              child: _buildRestaurantHeaderImage(),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + location + hours (name now dynamic)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurantName,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                _restaurant?["address"] ?? "Loading...",
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cardYellow,
                          border: Border.all(color: Colors.black26, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Hours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              _restaurant?["opening_hours"] ?? "Open now",
                              style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Stars
                  Row(
                    children: List.generate(5, (index) {
                      final rating = (_restaurant?["rating"] ?? 0) as num;
                      final fullStars = rating.floor();
                      final hasHalf = (rating - fullStars) >= 0.5;
                      
                      if (index < fullStars) {
                        return const Icon(Icons.star_rounded, color: Colors.amber, size: 24);
                      } else if (index == fullStars && hasHalf) {
                        return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 24);
                      } else {
                        return Icon(Icons.star_outline_rounded, color: Colors.grey[300], size: 24);
                      }
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final phone = _restaurant?["phone"] ?? "";
                            if (phone.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Call: $phone')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number available')));
                            }
                          },
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Number'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: cardYellow,
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black26, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final lat = _restaurant?["lat"] ?? 0;
                            final lng = _restaurant?["lng"] ?? 0;
                            if (lat != 0 && lng != 0) {
                              final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving&dir_action=navigate';
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not available')));
                            }
                          },
                          icon: const Icon(Icons.location_on, size: 18),
                          label: const Text('Direction'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: cardYellow,
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black26, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareRestaurantToFriend(),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: cardYellow,
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black26, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Mini Map
                  if (_restaurant?["lat"] != null && _restaurant?["lng"] != null)
                    GestureDetector(
                      onTap: () {
                        // Open full map centered on this restaurant
                        final lat = (_restaurant!["lat"] as num).toDouble();
                        final lng = (_restaurant!["lng"] as num).toDouble();
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: SizedBox(
                              height: 400,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(lat, lng),
                                  initialZoom: 15,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.weeat.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(lat, lng),
                                        width: 40,
                                        height: 40,
                                        child: MapPinMarker(
                                          types: _restaurant?['types'] as List<dynamic>?,
                                          cuisine: (_restaurant?['cuisine'] ?? '').toString(),
                                          name: (_restaurant?['name'] ?? '').toString(),
                                          size: 38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                (_restaurant!["lat"] as num).toDouble(),
                                (_restaurant!["lng"] as num).toDouble(),
                              ),
                              initialZoom: 14,
                              interactiveFlags: InteractiveFlag.none,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.weeat.app',
                              ),
                               MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      (_restaurant!["lat"] as num).toDouble(),
                                      (_restaurant!["lng"] as num).toDouble(),
                                    ),
                                    width: 36,
                                    height: 44,
                                    alignment: Alignment.topCenter,
                                    child: MapPinMarker(
                                      types: _restaurant?['types'] as List<dynamic>?,
                                      cuisine: (_restaurant?['cuisine'] ?? '').toString(),
                                      name: (_restaurant?['name'] ?? '').toString(),
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Tab Toggle: Menu | Reviews
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSection = 'menu'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedSection == 'menu' ? accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Menu',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _selectedSection == 'menu' ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedSection = 'reviews'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _selectedSection == 'reviews' ? accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Reviews',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _selectedSection == 'reviews' ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Content area based on selected tab
                  if (_selectedSection == 'menu') ...[
                    if (_loadingMenu)
                      const Center(child: CircularProgressIndicator())
                    else if (_menu == null || (_menu!['categories'] as List<dynamic>?)?.isEmpty == true)
                      _buildMenuComingSoon()
                    else
                      _buildMenuContent(),
                  ] else ...[
                    // Reviews section
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddPostPage(
                                homeName: Session.displayName,
                                restaurantId: widget.restaurantId,
                                restaurantName: _restaurant?["name"] ?? widget.restaurantName,
                              ),
                            ),
                          ).then((_) => _loadReviews());
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: accent,
                          side: const BorderSide(color: accent, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Add Review',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loadingReviews)
                      const Center(child: CircularProgressIndicator())
                    else if (_reviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text('No reviews yet', style: TextStyle(color: Colors.grey[500])),
                              const SizedBox(height: 4),
                              Text('Be the first to review!', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._reviews.map((review) => _buildReviewCard(review)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),

              _optionButton(
                icon: Icons.thumb_up_rounded,
                label: 'Like',
                onPressed: () async {
                  Navigator.pop(context);
                  await _toggleLike();
                },
              ),
              const SizedBox(height: 12),

              _optionButton(
                icon: Icons.thumb_down_rounded,
                label: 'Dislike',
                onPressed: () async {
                  Navigator.pop(context);
                  await _toggleDislike();
                },
              ),
              const SizedBox(height: 12),

              _optionButton(
                icon: Icons.favorite_rounded,
                label: 'Add to Wishlist',
                onPressed: () async {
                  Navigator.pop(context);
                  await _toggleWishlist();
                },
              ),
              const SizedBox(height: 12),

              _optionButton(
                icon: Icons.rate_review_rounded,
                label: 'Add Review',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPostPage(
                        homeName: Session.displayName,
                        restaurantId: widget.restaurantId,
                        restaurantName: _restaurant?["name"] ?? widget.restaurantName,
                      ),
                    ),
                  ).then((_) => _loadReviews());
                },
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black26, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          backgroundColor: cardYellow,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black26, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMenuComingSoon() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Menu coming soon 🍽️',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'We are working with this restaurant\nto bring you their full menu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuContent() {
    final categories = (_menu?['categories'] as List<dynamic>?) ?? [];
    if (categories.isEmpty) return _buildMenuComingSoon();

    final selectedCategory = categories[_selectedCategoryIndex];
    final items = (selectedCategory['items'] ?? []) as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chain label
        if (_detectedChain != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '$_detectedChain Menu',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
        // Horizontal category tabs
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final catName = (categories[index]['name'] ?? '').toString();
              final isSelected = index == _selectedCategoryIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategoryIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? accent : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected ? accent : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    catName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Items for selected category
        ...items.map((item) => _buildMenuItemCard(item)),
      ],
    );
  }

  Widget _buildMenuItemCard(dynamic item) {
    final name = (item['name'] ?? '').toString();
    final description = (item['description'] ?? '').toString();
    final price = (item['price'] ?? 0) as num;
    final imageUrl = (item['image_url'] ?? '').toString();
    final isVegetarian = item['is_vegetarian'] == true;
    final isSpicy = item['is_spicy'] == true;
    final calories = item['calories'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), offset: const Offset(0, 3), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item image or placeholder
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
              image: imageUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: imageUrl.isEmpty
                ? Icon(Icons.fastfood_outlined, color: Colors.grey[400], size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    if (isVegetarian)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.eco, color: Colors.green[600], size: 16),
                      ),
                    if (isSpicy)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(Icons.local_fire_department, color: Colors.red[400], size: 16),
                      ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cardYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 1)} AED',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    if (calories != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.local_fire_department_outlined, size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(
                        '$calories kcal',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final author = (review['user_name'] ?? review['user_email'] ?? 'User').toString();
    final handle = (review['user_handle'] ?? '').toString();
    final description = (review['description'] ?? '').toString();
    final rating = (review['rating'] ?? 0) as int;
    final timeAgo = (review['created_at'] ?? '').toString();

    String timeDisplay = 'Recently';
    try {
      final date = DateTime.parse(timeAgo);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) timeDisplay = '${diff.inDays}d ago';
      else if (diff.inHours > 0) timeDisplay = '${diff.inHours}h ago';
      else if (diff.inMinutes > 0) timeDisplay = '${diff.inMinutes}m ago';
      else timeDisplay = 'Just now';
    } catch (_) {}

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
              CircleAvatar(radius: 16, backgroundColor: Colors.grey[300], child: const Icon(Icons.person, size: 16, color: Colors.grey)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    if (handle.isNotEmpty) Text(handle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Text(timeDisplay, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, color: i < rating ? Colors.amber : Colors.grey[300], size: 16))),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}