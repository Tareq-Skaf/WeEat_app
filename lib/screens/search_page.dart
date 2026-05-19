import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/smart_image.dart';
import '../widgets/map_marker.dart';
import '../widgets/restaurant_logo_image.dart';
import '../utils/restaurant_logos.dart';

import '../services/api_service.dart';
import '../services/session.dart';
import '../services/theme_provider.dart';
import 'restaurant_page.dart';
import 'map_page.dart';

class SearchPage extends StatefulWidget {
  final String? homeName;
  
  const SearchPage({super.key, this.homeName});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _api = ApiService();
  final TextEditingController searchController = TextEditingController();
  
  String? selectedMood;
  double _maxBudget = 200.0;

  List<dynamic> _searchResults = [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _error;
  List<dynamic> _recentSearches = [];
  List<dynamic> _aiRecommendations = [];
  bool _loadingAi = true;

  // AI taste profile
  List<String> _tasteKeywords = [];
  bool _hasTasteHistory = false;
  bool _loadingTaste = true;

  final List<String> _moods = ['Casual', 'Fast', 'Coffee', 'Healthy', 'Happy/Celebrating'];
  final Map<String, String> _moodToCategory = {
    'Casual': 'Casual',
    'Fast': 'Fast',
    'Coffee': 'Coffee',
    'Healthy': 'Healthy',
    'Happy/Celebrating': 'Fine Dining',
  };

  double? _userLat;
  double? _userLng;
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadUserLocation();
    _loadTasteKeywords();
    _loadAiRecommendations();
  }

  Future<void> _loadTasteKeywords() async {
    final email = Session.email.trim();
    if (email.isEmpty) {
      setState(() => _loadingTaste = false);
      return;
    }
    try {
      final data = await _api.getTasteKeywords(email: email);
      if (!mounted) return;
      setState(() {
        _tasteKeywords = List<String>.from(data['keywords'] ?? []);
        _hasTasteHistory = data['has_history'] == true;
        _loadingTaste = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTaste = false);
    }
  }

  Future<void> _loadAiRecommendations() async {
    final email = Session.email.trim();
    if (email.isEmpty) {
      setState(() => _loadingAi = false);
      return;
    }
    try {
      final data = await _api.getPersonalizedRecommendations(email: email, limit: 10);
      if (!mounted) return;
      var recs = data['restaurants'] ?? [];
      if (!mounted) return;
      setState(() {
        _aiRecommendations = recs;
        _loadingAi = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAi = false);
    }
  }

  List<dynamic> _sortByTaste(List<dynamic> results) {
    if (_tasteKeywords.isEmpty) return results;
    final keywords = _tasteKeywords.map((k) => k.toLowerCase()).toList();
    return List<dynamic>.from(results)..sort((a, b) {
      final aCat = (a['category_name'] ?? '').toString().toLowerCase();
      final bCat = (b['category_name'] ?? '').toString().toLowerCase();
      final aMatch = keywords.any((k) => aCat.contains(k)) ? 1 : 0;
      final bMatch = keywords.any((k) => bCat.contains(k)) ? 1 : 0;
      if (aMatch != bMatch) return bMatch - aMatch;
      // Tie-break by rating
      final aRating = (a['rating'] ?? 0) as num;
      final bRating = (b['rating'] ?? 0) as num;
      return bRating.compareTo(aRating);
    });
  }

  Future<void> _loadUserLocation() async {
    try {
      final location = await _api.getUserLocationFromIP();
      if (!mounted) return;
      setState(() {
        _userLat = (location['lat'] ?? 0) as double;
        _userLng = (location['lng'] ?? 0) as double;
        _locationLoaded = true;
      });
    } catch (_) {
      // Default to Dubai if IP location fails
      setState(() {
        _userLat = 25.2048;
        _userLng = 55.2708;
        _locationLoaded = true;
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;
    try {
      final data = await _api.getRecentSearches(email: email);
      if (!mounted) return;
      setState(() => _recentSearches = data);
    } catch (_) {}
  }

  Future<void> _saveSearch(String query) async {
    final email = Session.email.trim();
    if (email.isEmpty || query.isEmpty) return;
    try {
      await _api.saveSearch(email: email, query: query);
      _loadRecentSearches();
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;
    try {
      await _api.clearRecentSearches(email: email);
      if (!mounted) return;
      setState(() => _recentSearches = []);
    } catch (_) {}
  }

  Future<void> _performSearch() async {
    final query = searchController.text.trim();
    if (query.isNotEmpty) _saveSearch(query);

    setState(() {
      _loading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      // Always search via Foursquare with filters applied server-side
      String searchQuery = query.isNotEmpty ? query : 'restaurant';
      String? moodFilter;
      if (selectedMood != null && selectedMood!.isNotEmpty) {
        moodFilter = _moodToCategory[selectedMood];
      }

      var results = await _api.searchRestaurantsFoursquare(
        query: searchQuery,
        maxBudget: _maxBudget >= 1000 ? null : _maxBudget.round(),
        mood: moodFilter,
      );

      // Sort by taste profile (matching categories go to top)
      if (query.isNotEmpty) {
        results = _sortByTaste(results);
      }

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst("Exception: ", "");
        _loading = false;
      });
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
        toolbarHeight: 80,
        title: Text(
          'Search',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: themeProvider.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage())),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3E3A9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                ),
                child: Icon(Icons.map, color: themeProvider.textPrimary, size: 24),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12).copyWith(bottom: 100),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: searchController,
                  onSubmitted: (_) => _performSearch(),
                  style: TextStyle(color: themeProvider.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search or leave empty for nearby...',
                    hintStyle: TextStyle(color: themeProvider.textSecondary),
                    prefixIcon: Icon(Icons.search, color: themeProvider.textSecondary),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: themeProvider.textSecondary),
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
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
                  ),
                ),

                const SizedBox(height: 16),

                // Filter Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showMoodDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedMood != null
                                ? const Color(0xFF6F8574)
                                : isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3E3A9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mood, size: 18, color: selectedMood != null ? Colors.white : themeProvider.textPrimary),
                              const SizedBox(width: 6),
                              Text(
                                selectedMood ?? 'Mood',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: selectedMood != null ? Colors.white : themeProvider.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showBudgetDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _maxBudget >= 1000
                                ? const Color(0xFF6F8574)
                                : isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3E3A9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet, size: 18, color: _maxBudget >= 1000 ? Colors.white : themeProvider.textPrimary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _maxBudget >= 1000 ? 'No Limit' : 'Up to ${_maxBudget.round()} AED',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _maxBudget >= 1000 ? Colors.white : themeProvider.textPrimary,
                                  ),
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

                // Active filters display
                if (selectedMood != null || _maxBudget < 1000) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (selectedMood != null)
                        _filterChip(selectedMood!, () {
                          setState(() => selectedMood = null);
                          if (searchController.text.isNotEmpty || _hasSearched) _performSearch();
                        }),
                      if (_maxBudget < 1000)
                        _filterChip('Up to ${_maxBudget.round()} AED', () {
                          setState(() => _maxBudget = 200.0);
                          if (searchController.text.isNotEmpty || _hasSearched) _performSearch();
                        }),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Search button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _performSearch,
                    icon: Icon(searchController.text.isEmpty ? Icons.near_me : Icons.search, size: 20),
                    label: Text(
                      searchController.text.isEmpty ? 'Nearby Restaurants' : 'Search Restaurants',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F8574),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Results
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFF6F8574)))
                else if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  )
                else if (!_hasSearched)
                  Column(
                    children: [
                      if (_recentSearches.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Recent Searches', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: themeProvider.textPrimary)),
                              TextButton(
                                onPressed: _clearRecentSearches,
                                child: Text('Clear', style: TextStyle(color: themeProvider.textSecondary)),
                              ),
                            ],
                          ),
                        ),
                        ..._recentSearches.map((search) {
                          final query = (search['query'] ?? '').toString();
                          return ListTile(
                            leading: Icon(Icons.history, color: themeProvider.textSecondary),
                            title: Text(query, style: TextStyle(color: themeProvider.textPrimary)),
                            onTap: () {
                              searchController.text = query;
                              _performSearch();
                            },
                          );
                        }),
                        Divider(color: themeProvider.divider),
                      ],
                      // AI recommendations
                      if (_loadingAi)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: Color(0xFF6F8574)),
                        ))
                      else if (_aiRecommendations.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              'You might like these 💚',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: themeProvider.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _aiRecommendations.map((r) => _horizontalRestaurantCard(r, themeProvider)).toList(),
                          ),
                        ),
                      ]
                      else
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Icon(Icons.near_me, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Tap "Nearby Restaurants" to discover places near you',
                                style: TextStyle(color: themeProvider.textSecondary, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                else if (_searchResults.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.search_off, size: 80, color: isDark ? Colors.white24 : Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No restaurants found',
                          style: TextStyle(color: themeProvider.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try different filters or search terms',
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Result count header
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF6F8574)),
                      const SizedBox(width: 8),
                      Text(
                        '${_searchResults.length} branches found',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF6F8574),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final restaurant = _searchResults[index];
                      return _restaurantListItem(restaurant, themeProvider);
                    },
                  ),
                ],
              ],
            ),
            ),
          ),
          // Floating navigation bar - always at bottom
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: FloatingNavBar(
              currentIndex: 1,
              homeName: widget.homeName ?? 'User',
              onTap: (i) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6F8574).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6F8574)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6F8574), fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: Color(0xFF6F8574)),
          ),
        ],
      ),
    );
  }

  Widget _restaurantListItem(dynamic restaurant, ThemeProvider themeProvider) {
    final String id = (restaurant["id"] ?? restaurant["fsq_id"] ?? "").toString();
    final String name = (restaurant["name"] ?? "Restaurant").toString();
    final String address = (restaurant["address"] ?? "Location").toString();
    final String cuisine = (restaurant["category_name"] ?? restaurant["cuisine"] ?? restaurant["type"] ?? "").toString();
    final String? logoUrl = getRestaurantCardImageUrl(name, cuisine);
    final double rating = (restaurant["rating"] is num) ? (restaurant["rating"] as num).toDouble() : 0.0;
    final double? distanceKm = restaurant["distance_km"] is num ? (restaurant["distance_km"] as num).toDouble() : null;
    final types = restaurant['types'] as List<dynamic>?;
    final typeColor = getRestaurantTypeColor(types, cuisine, name: name);
    final typeIcon = getRestaurantTypeIcon(types, cuisine, name: name);
    final isDark = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: () {
        // For API restaurants without ID, create a temporary one
        final restaurantId = id.isNotEmpty ? id : name.replaceAll(' ', '_').toLowerCase();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantPage(
              restaurantId: restaurantId,
              restaurantName: name,
              foursquareData: restaurant,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: isDark ? Colors.black38 : Colors.black12, offset: const Offset(0, 4), blurRadius: 8),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            // Logo or styled type icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                border: Border.all(color: Colors.grey[200]!),
              ),
              clipBehavior: Clip.hardEdge,
              child: RestaurantLogoImage(
                url: logoUrl,
                width: 80,
                height: 80,
                fallback: Center(child: Icon(typeIcon, color: typeColor, size: 32)),
                padding: const EdgeInsets.all(10),
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
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: themeProvider.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (cuisine.isNotEmpty)
                        Text(
                          cuisine,
                          style: TextStyle(color: themeProvider.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (_isTasteMatch(restaurant))
                        Container(
                          constraints: const BoxConstraints(maxWidth: 130),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6F8574).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Based on your taste 💚',
                            style: TextStyle(fontSize: 10, color: Color(0xFF6F8574), fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: themeProvider.textSecondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(color: themeProvider.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (rating > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.w600, color: themeProvider.textPrimary)),
                        if (distanceKm != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.directions_walk, size: 14, color: themeProvider.textSecondary),
                          const SizedBox(width: 2),
                          Text('${distanceKm.toStringAsFixed(1)} km', style: TextStyle(color: themeProvider.textSecondary, fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: themeProvider.textSecondary),
          ],
        ),
      ),
    );
  }

  bool _isTasteMatch(dynamic restaurant) {
    if (_tasteKeywords.isEmpty) return false;
    final cat = (restaurant['category_name'] ?? '').toString().toLowerCase();
    return _tasteKeywords.any((k) => cat.contains(k.toLowerCase()));
  }

  Widget _horizontalRestaurantCard(dynamic r, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    final String name = (r["name"] ?? "Restaurant").toString();
    final String address = (r["address"] ?? "Location").toString();
    final String cuisine = (r["category_name"] ?? r["cuisine"] ?? "").toString();
    final String? logoUrl = getRestaurantCardImageUrl(name, cuisine);
    final double rating = (r["rating"] is num) ? (r["rating"] as num).toDouble() : 0.0;
    final String id = (r["fsq_id"] ?? "").toString();
    final bool isTasteMatch = _isTasteMatch(r);

    return GestureDetector(
      onTap: () {
        final restaurantId = id.isNotEmpty ? id : name.replaceAll(' ', '_').toLowerCase();
        Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantPage(restaurantId: restaurantId, restaurantName: name, foursquareData: r)));
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: themeProvider.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: isDark ? Colors.black38 : Colors.black12, offset: const Offset(0, 4), blurRadius: 8)],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
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
                  fallback: const Center(child: Icon(Icons.restaurant, color: Color(0xFF6F8574), size: 32)),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: themeProvider.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (isTasteMatch)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxWidth: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6F8574).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Based on your taste',
                        style: TextStyle(fontSize: 9, color: Color(0xFF6F8574), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(address, style: TextStyle(color: themeProvider.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (rating > 0)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: themeProvider.textPrimary)),
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

  void _showMoodDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: themeProvider.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mood', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: themeProvider.textPrimary)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: themeProvider.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _moods.map((m) => _selectableChip(m, selectedMood == m, () {
                  setState(() => selectedMood = selectedMood == m ? null : m);
                  Navigator.pop(context);
                  _performSearch();
                }, themeProvider)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    double tempBudget = _maxBudget;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final String valueText = tempBudget >= 1000
              ? "No Limit 🤑"
              : "Up to ${tempBudget.round()} AED";

          return Dialog(
            backgroundColor: themeProvider.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Max Budget (AED)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: themeProvider.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Live value display
                  Text(
                    valueText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6F8574),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Slider with floating bubble
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const sliderPadding = 14.0;
                      final trackWidth = constraints.maxWidth - sliderPadding * 2;
                      final fraction = (tempBudget - 1) / 999;
                      final bubbleLeft = sliderPadding + trackWidth * fraction - 28;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Bubble above thumb
                          Positioned(
                            left: bubbleLeft.clamp(0, constraints.maxWidth - 56),
                            top: -30,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6F8574),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                tempBudget >= 1000 ? "∞" : "${tempBudget.round()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          // Slider
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 8,
                              activeTrackColor: const Color(0xFF6F8574),
                              inactiveTrackColor: const Color(0xFFF3E3A9),
                              thumbColor: const Color(0xFF6F8574),
                              overlayColor: const Color(0xFF6F8574).withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                            ),
                            child: Slider(
                              value: tempBudget,
                              min: 1,
                              max: 1000,
                              divisions: 999,
                              onChanged: (value) {
                                setDialogState(() => tempBudget = value);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  // Min / Max labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeProvider.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          '∞',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF6F8574),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _maxBudget = tempBudget);
                        Navigator.pop(context);
                        _performSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F8574),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectableChip(String label, bool isSelected, VoidCallback onTap, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6F8574)
              : isDark ? const Color(0xFF3A3A3A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : themeProvider.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
