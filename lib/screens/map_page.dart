import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/theme_provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final _api = ApiService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<dynamic> _searchResults = [];
  bool _showSearchResults = false;
  bool _loadingSearch = false;

  dynamic _selectedPlace;
  String? _photoUrl;
  bool _loadingPhoto = false;

  LatLng? _userLocation;
  bool _loadingLocation = true;

  // Route state
  List<LatLng> _routePoints = [];
  String _travelTime = '';
  String _travelDistance = '';
  String _travelMode = 'driving';
  bool _loadingRoute = false;
  bool _showRoutePanel = false;

  static const LatLng _defaultCenter = LatLng(25.2048, 55.2708);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (!mounted) return;
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _loadingLocation = false;
        });
        _mapController.move(_userLocation!, 14);
        return;
      }
    } catch (_) {}

    // Fallback to IP location
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json/?fields=lat,lon'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lat = (data['lat'] ?? 0) as num;
        final lng = (data['lon'] ?? 0) as num;
        if (lat != 0 && lng != 0) {
          if (!mounted) return;
          setState(() {
            _userLocation = LatLng(lat.toDouble(), lng.toDouble());
            _loadingLocation = false;
          });
          _mapController.move(_userLocation!, 14);
          return;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loadingLocation = false);
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _loadingSearch = true;
      _showSearchResults = true;
    });

    try {
      final results = await _api.searchRestaurantsFoursquare(
        query: query,
      );

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _loadingSearch = false;
      });

      _fitMapToSearchResults();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _loadingSearch = false;
      });
    }
  }

  void _fitMapToSearchResults() {
    final points = <LatLng>[];
    if (_userLocation != null) points.add(_userLocation!);
    for (final place in _searchResults) {
      final lat = (place['lat'] ?? 0) as num;
      final lng = (place['lng'] ?? 0) as num;
      if (lat != 0 && lng != 0) {
        points.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }
    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)));
    } else if (points.length == 1) {
      _mapController.move(points.first, 15);
    }
  }

  void _selectPlace(dynamic place) async {
    final fsqId = (place['fsq_id'] ?? '').toString();
    final name = (place['name'] ?? '').toString();

    setState(() {
      _selectedPlace = place;
      _showSearchResults = false;
      _searchController.text = name;
      _loadingPhoto = true;
      _photoUrl = null;
      _showRoutePanel = false;
      _routePoints = [];
      _travelTime = '';
      _travelDistance = '';
    });
    _searchFocus.unfocus();

    final lat = (place['lat'] ?? 0) as num;
    final lng = (place['lng'] ?? 0) as num;

    if (lat != 0 && lng != 0) {
      _mapController.move(LatLng(lat.toDouble(), lng.toDouble()), 16);
    }

    // Fetch photo from Foursquare immediately
    if (fsqId.isNotEmpty) {
      try {
        final photos = await _api.getFoursquarePhotos(fsqId: fsqId, limit: 1);
        if (!mounted) return;
        if (photos.isNotEmpty) {
          final prefix = (photos[0]['url'] ?? '').toString();
          if (prefix.isNotEmpty) {
            setState(() {
              _photoUrl = prefix;
              _loadingPhoto = false;
            });
          } else {
            setState(() => _loadingPhoto = false);
          }
        } else {
          setState(() => _loadingPhoto = false);
        }
      } catch (_) {
        if (!mounted) return;
        setState(() => _loadingPhoto = false);
      }
    } else {
      setState(() => _loadingPhoto = false);
    }
  }

  // Calculate distance between two points in km
  double _calculateDistance(LatLng p1, LatLng p2) {
    const R = 6371.0;
    final dLat = (p2.latitude - p1.latitude) * pi / 180;
    final dLon = (p2.longitude - p1.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180) * cos(p2.latitude * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // Calculate time based on mode
  String _calculateTime(double distanceKm, String mode) {
    double speedKmh;
    switch (mode) {
      case 'walking':
        speedKmh = 5.0;
        break;
      case 'transit':
        speedKmh = 20.0;
        break;
      default:
        speedKmh = 40.0;
    }
    final hours = distanceKm / speedKmh;
    final minutes = (hours * 60).round();
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}min';
  }

  // Get arrival time string
  String _getArrivalTime(double distanceKm, String mode) {
    double speedKmh;
    switch (mode) {
      case 'walking':
        speedKmh = 5.0;
        break;
      case 'transit':
        speedKmh = 20.0;
        break;
      default:
        speedKmh = 40.0;
    }
    final hours = distanceKm / speedKmh;
    final arrival = DateTime.now().add(Duration(minutes: (hours * 60).round()));
    final hour = arrival.hour.toString().padLeft(2, '0');
    final min = arrival.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Future<void> _getRoute(LatLng destination) async {
    if (_userLocation == null) return;

    setState(() {
      _loadingRoute = true;
      _routePoints = [];
      _travelTime = '';
      _travelDistance = '';
      _showRoutePanel = true;
    });

    // Calculate straight-line distance
    final distanceKm = _calculateDistance(_userLocation!, destination);

    try {
      // Use OSRM for route
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${_userLocation!.longitude},${_userLocation!.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List;

        if (routes.isNotEmpty) {
          final route = routes[0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;
          final osrmDistance = (route['distance'] ?? 0) / 1000.0; // meters to km

          List<LatLng> points = [];
          for (var coord in coordinates) {
            points.add(LatLng(coord[1].toDouble(), coord[0].toDouble()));
          }

          setState(() {
            _routePoints = points;
            _travelDistance = '${osrmDistance.toStringAsFixed(1)} km';
            _travelTime = _calculateTime(osrmDistance, _travelMode);
            _loadingRoute = false;
          });

          // Fit map to show route
          final bounds = LatLngBounds.fromPoints([_userLocation!, destination]);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)));
          return;
        }
      }
    } catch (_) {}

    // Fallback: use straight-line distance
    setState(() {
      _routePoints = [_userLocation!, destination];
      _travelDistance = '${distanceKm.toStringAsFixed(1)} km';
      _travelTime = _calculateTime(distanceKm, _travelMode);
      _loadingRoute = false;
    });

    final bounds = LatLngBounds.fromPoints([_userLocation!, destination]);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)));
  }

  void _clearRoute() {
    setState(() {
      _routePoints = [];
      _travelTime = '';
      _travelDistance = '';
      _selectedPlace = null;
      _photoUrl = null;
      _showRoutePanel = false;
      _searchController.clear();
    });
  }

  void _openNativeNavigation() async {
    if (_selectedPlace == null) return;
    final lat = (_selectedPlace['lat'] ?? 0) as num;
    final lng = (_selectedPlace['lng'] ?? 0) as num;
    if (lat == 0 || lng == 0) return;

    String modeChar;
    switch (_travelMode) {
      case 'walking':
        modeChar = 'w';
        break;
      case 'transit':
        modeChar = 'r';
        break;
      default:
        modeChar = 'd';
    }

    // Try Google Maps on Android
    final googleUrl = 'google.navigation:q=$lat,$lng&mode=$modeChar';
    try {
      final uri = Uri.parse(googleUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Try Apple Maps on iOS
    String dirflg;
    switch (_travelMode) {
      case 'walking':
        dirflg = 'w';
        break;
      case 'transit':
        dirflg = 'r';
        break;
      default:
        dirflg = 'd';
    }
    final appleUrl = 'maps://maps.apple.com/?daddr=$lat,$lng&dirflg=$dirflg';
    try {
      final uri = Uri.parse(appleUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback to Google Maps web
    final webUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=$_travelMode&dir_action=navigate';
    try {
      final uri = Uri.parse(webUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _callRestaurant() async {
    if (_selectedPlace == null) return;
    final tel = (_selectedPlace['tel'] ?? '').toString();
    if (tel.isEmpty) return;

    final url = 'tel:$tel';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Color _getRouteColor() {
    switch (_travelMode) {
      case 'walking':
        return Colors.green;
      case 'transit':
        return Colors.orange;
      default:
        return const Color(0xFF4285F4); // Google blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: themeProvider.background,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? _defaultCenter,
              initialZoom: _userLocation != null ? 14 : 12,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.weeat.app',
              ),
              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: _getRouteColor(),
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: _floatingButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
              themeProvider: themeProvider,
            ),
          ),

          // My location button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: _floatingButton(
              icon: Icons.my_location,
              iconColor: Colors.blue,
              onTap: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 14);
                }
              },
              themeProvider: themeProvider,
            ),
          ),

          // Search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 60,
            right: 60,
            child: Container(
              decoration: BoxDecoration(
                color: themeProvider.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black26, offset: const Offset(0, 2), blurRadius: 8)],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: TextStyle(color: themeProvider.textPrimary),
                onChanged: _searchPlaces,
                decoration: InputDecoration(
                  hintText: 'Search restaurants...',
                  hintStyle: TextStyle(color: themeProvider.textSecondary),
                  prefixIcon: Icon(Icons.search, color: themeProvider.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: themeProvider.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _clearRoute();
                            setState(() {
                              _searchResults = [];
                              _showSearchResults = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Search results dropdown
          if (_showSearchResults)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                decoration: BoxDecoration(
                  color: themeProvider.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black26, offset: const Offset(0, 4), blurRadius: 12)],
                ),
                child: _loadingSearch
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: const Color(0xFF6F8574)),
                              const SizedBox(height: 12),
                              Text('Searching all UAE branches...', style: TextStyle(color: themeProvider.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text('No restaurants found', style: TextStyle(color: themeProvider.textSecondary)),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Result count header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6F8574).withOpacity(0.1),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: const Color(0xFF6F8574)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_searchResults.length} branches found across UAE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: const Color(0xFF6F8574),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Results list
                              Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final place = _searchResults[index];
                                    final name = (place['name'] ?? '').toString();
                                    final address = (place['address'] ?? '').toString();
                                    final categoryName = (place['category_name'] ?? '').toString();
                                    final iconUrl = (place['icon_url'] ?? '').toString().replaceAll('64', '88');

                                    return ListTile(
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6F8574).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: iconUrl.isNotEmpty
                                            ? Image.network(
                                                iconUrl,
                                                width: 24,
                                                height: 24,
                                                errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: Color(0xFF6F8574), size: 20),
                                              )
                                            : const Icon(Icons.restaurant, color: Color(0xFF6F8574), size: 20),
                                      ),
                                      title: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: themeProvider.textPrimary)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (address.isNotEmpty)
                                            Text(address, style: TextStyle(color: themeProvider.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          if (categoryName.isNotEmpty)
                                            Text(categoryName, style: TextStyle(color: const Color(0xFF6F8574), fontSize: 10)),
                                        ],
                                      ),
                                      onTap: () => _selectPlace(place),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
              ),
            ),

          // Branch counter badge on map
          if (_searchResults.isNotEmpty && !_showSearchResults)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F8574),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black26, offset: const Offset(0, 2), blurRadius: 6)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Showing ${_searchResults.length} branches',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Loading route indicator
          if (_loadingRoute)
            Positioned(
              bottom: _showRoutePanel ? 280 : (_selectedPlace != null ? 220 : 80),
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: themeProvider.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black26, offset: const Offset(0, 2), blurRadius: 6)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFF6F8574))),
                      const SizedBox(width: 10),
                      Text('Calculating route...', style: TextStyle(fontSize: 13, color: themeProvider.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),

          // Route panel (Google Maps style)
          if (_showRoutePanel && _travelTime.isNotEmpty && !_loadingRoute)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildRoutePanel(themeProvider),
            )
          // Restaurant card (when no route panel)
          else if (_selectedPlace != null && !_showRoutePanel)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildRestaurantCard(themeProvider),
            ),

          // Location loading
          if (_loadingLocation)
            Positioned(
              bottom: _selectedPlace != null ? 220 : 80,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: themeProvider.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black26, offset: const Offset(0, 2), blurRadius: 6)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: themeProvider.textPrimary)),
                    const SizedBox(width: 8),
                    Text('Finding you...', style: TextStyle(fontSize: 13, color: themeProvider.textPrimary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // User location (pulsing blue dot)
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10, spreadRadius: 3)],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Search result markers
    for (final place in _searchResults) {
      final lat = (place['lat'] ?? 0) as num;
      final lng = (place['lng'] ?? 0) as num;
      if (lat == 0 || lng == 0) continue;

      final isSelected = _selectedPlace != null &&
          (_selectedPlace['fsq_id'] ?? '').toString() == (place['fsq_id'] ?? '').toString();

      // Dim other pins when route is showing
      final isDimmed = _showRoutePanel && !isSelected;

      // Get icon URL - use 88px size
      String iconUrl = (place['icon_url'] ?? '').toString();
      if (iconUrl.contains('64')) {
        iconUrl = iconUrl.replaceAll('64', '88');
      }

      final name = (place['name'] ?? '').toString();
      final categoryColor = _getCategoryColor(place['category_name'] ?? '');

      markers.add(
        Marker(
          point: LatLng(lat.toDouble(), lng.toDouble()),
          width: isSelected ? 60 : 48,
          height: isSelected ? 80 : 65,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _selectPlace(place),
            child: Opacity(
              opacity: isDimmed ? 0.4 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isSelected ? 50 : 40,
                    height: isSelected ? 50 : 40,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withOpacity(isSelected ? 0.6 : 0.3),
                          blurRadius: isSelected ? 14 : 8,
                          spreadRadius: isSelected ? 3 : 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: iconUrl.isNotEmpty
                          ? Image.network(
                              iconUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.restaurant, color: Colors.white, size: isSelected ? 24 : 20),
                            )
                          : Icon(Icons.restaurant, color: Colors.white, size: isSelected ? 24 : 20),
                    ),
                  ),
                  // Triangle pointer
                  CustomPaint(
                    size: Size(isSelected ? 16 : 12, isSelected ? 10 : 8),
                    painter: _TrianglePainter(color: categoryColor),
                  ),
                  // Name label
                  if (!isDimmed)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 80),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Color _getCategoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('cafe') || lower.contains('coffee')) return const Color(0xFF8D6E63);
    if (lower.contains('pizza')) return const Color(0xFFE64A19);
    if (lower.contains('burger') || lower.contains('american')) return const Color(0xFFFBC02D);
    if (lower.contains('sushi') || lower.contains('japanese')) return const Color(0xFF00897B);
    if (lower.contains('italian')) return const Color(0xFF43A047);
    if (lower.contains('mexican')) return const Color(0xFFFF7043);
    if (lower.contains('indian')) return const Color(0xFFFF5722);
    if (lower.contains('seafood')) return const Color(0xFF039BE5);
    if (lower.contains('ice cream') || lower.contains('dessert')) return const Color(0xFFEC407A);
    if (lower.contains('fast food') || lower.contains('fried chicken')) return const Color(0xFFFFC107);
    if (lower.contains('bakery')) return const Color(0xFFFFA726);
    if (lower.contains('bar')) return const Color(0xFF7B1FA2);
    return const Color(0xFF6F8574);
  }

  Widget _buildRestaurantCard(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    final name = (_selectedPlace?['name'] ?? '').toString();
    final address = (_selectedPlace?['address'] ?? '').toString();
    final tel = (_selectedPlace?['tel'] ?? '').toString();
    final website = (_selectedPlace?['website'] ?? '').toString();
    final categoryName = (_selectedPlace?['category_name'] ?? '').toString();
    final iconUrl = (_selectedPlace?['icon_url'] ?? '').toString().replaceAll('64', '88');
    final instagram = (_selectedPlace?['social_media']?['instagram'] ?? '').toString();
    final twitter = (_selectedPlace?['social_media']?['twitter'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black26, offset: const Offset(0, 4), blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo banner at TOP
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _loadingPhoto
                ? Container(
                    height: 150,
                    width: double.infinity,
                    color: _getCategoryColor(categoryName).withOpacity(0.1),
                    child: Center(child: CircularProgressIndicator(color: const Color(0xFF6F8574))),
                  )
                : _photoUrl != null && _photoUrl!.isNotEmpty
                    ? Image.network(
                        _photoUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPhotoFallback(iconUrl, categoryName),
                      )
                    : _buildPhotoFallback(iconUrl, categoryName),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: themeProvider.textPrimary),
                ),

                if (categoryName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    categoryName,
                    style: TextStyle(color: const Color(0xFF6F8574), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],

                const SizedBox(height: 8),

                // Address
                if (address.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: themeProvider.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(address, style: TextStyle(color: themeProvider.textSecondary, fontSize: 13)),
                      ),
                    ],
                  ),

                // Phone
                if (tel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: themeProvider.textSecondary),
                      const SizedBox(width: 8),
                      Text(tel, style: TextStyle(color: themeProvider.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],

                // Website
                if (website.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.language, size: 16, color: themeProvider.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(website, style: TextStyle(color: const Color(0xFF6F8574), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],

                // Social media
                if (instagram.isNotEmpty || twitter.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (instagram.isNotEmpty) ...[
                        Icon(Icons.camera_alt, size: 16, color: themeProvider.textSecondary),
                        const SizedBox(width: 4),
                        Text('@$instagram', style: TextStyle(color: themeProvider.textSecondary, fontSize: 12)),
                      ],
                      if (instagram.isNotEmpty && twitter.isNotEmpty) const SizedBox(width: 16),
                      if (twitter.isNotEmpty) ...[
                        Icon(Icons.chat, size: 16, color: themeProvider.textSecondary),
                        const SizedBox(width: 4),
                        Text('@$twitter', style: TextStyle(color: themeProvider.textSecondary, fontSize: 12)),
                      ],
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    // Directions button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final lat = (_selectedPlace?['lat'] ?? 0) as num;
                          final lng = (_selectedPlace?['lng'] ?? 0) as num;
                          if (lat != 0 && lng != 0 && _userLocation != null) {
                            _getRoute(LatLng(lat.toDouble(), lng.toDouble()));
                          }
                        },
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F8574),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Call button
                    if (tel.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _callRestaurant,
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    if (tel.isNotEmpty) const SizedBox(width: 8),
                    // Close button
                    GestureDetector(
                      onTap: _clearRoute,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.close, size: 20, color: themeProvider.textPrimary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoFallback(String iconUrl, String categoryName) {
    final categoryColor = _getCategoryColor(categoryName);
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.15),
      ),
      child: Center(
        child: Container(
          width: 70,
          height: 70,
        decoration: BoxDecoration(
          color: categoryColor,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: iconUrl.isNotEmpty
              ? Image.network(
                  iconUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: Colors.white, size: 36),
                )
              : const Icon(Icons.restaurant, color: Colors.white, size: 36),
        ),
        ),
      ),
    );
  }

  // Google Maps style route panel
  Widget _buildRoutePanel(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    final distanceKm = _calculateDistance(
      _userLocation!,
      LatLng(
        (_selectedPlace?['lat'] ?? 0).toDouble(),
        (_selectedPlace?['lng'] ?? 0).toDouble(),
      ),
    );
    final arrivalTime = _getArrivalTime(distanceKm, _travelMode);

    String modeLabel;
    IconData modeIcon;
    switch (_travelMode) {
      case 'walking':
        modeLabel = 'Walk';
        modeIcon = Icons.directions_walk;
        break;
      case 'transit':
        modeLabel = 'Transit';
        modeIcon = Icons.directions_bus;
        break;
      default:
        modeLabel = 'Drive';
        modeIcon = Icons.directions_car;
    }

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black26, offset: const Offset(0, 4), blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Travel mode tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                _buildTravelTab(Icons.directions_car, 'Car', 'driving'),
                const SizedBox(width: 8),
                _buildTravelTab(Icons.directions_bus, 'Transit', 'transit'),
                const SizedBox(width: 8),
                _buildTravelTab(Icons.directions_walk, 'Walk', 'walking'),
              ],
            ),
          ),

          // Route details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(modeIcon, color: _getRouteColor(), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$modeLabel • $_travelTime • $_travelDistance',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                      Text(
                        'Arrive at $arrivalTime',
                        style: TextStyle(
                          fontSize: 13,
                          color: themeProvider.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // X button to cancel
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showRoutePanel = false;
                      _routePoints = [];
                      _travelTime = '';
                      _travelDistance = '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18, color: themeProvider.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          // Start button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openNativeNavigation,
                icon: const Icon(Icons.navigation, size: 20),
                label: const Text('Start', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853), // Google green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelTab(IconData icon, String label, String mode) {
    final isSelected = _travelMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _travelMode = mode);
          if (_selectedPlace != null) {
            final lat = (_selectedPlace['lat'] ?? 0) as num;
            final lng = (_selectedPlace['lng'] ?? 0) as num;
            if (lat != 0 && lng != 0 && _userLocation != null) {
              _getRoute(LatLng(lat.toDouble(), lng.toDouble()));
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _getRouteColor() : (isDark ? Colors.grey[800] : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _getRouteColor() : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700])),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingButton({required IconData icon, required VoidCallback onTap, Color? iconColor, required ThemeProvider themeProvider}) {
    final isDark = themeProvider.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: themeProvider.surface,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black26, offset: const Offset(0, 2), blurRadius: 6)],
        ),
        child: Icon(icon, color: iconColor ?? themeProvider.textPrimary, size: 22),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
