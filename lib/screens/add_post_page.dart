import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../services/theme_provider.dart';
import '../widgets/map_marker.dart';

class AddPostPage extends StatefulWidget {
  final String? homeName;
  final String? restaurantId;
  final String? restaurantName;
  
  const AddPostPage({super.key, this.homeName, this.restaurantId, this.restaurantName});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  XFile? _selectedImage;
  final TextEditingController _restaurantSearchController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  int _rating = 0;
  double _priceAed = 100.0;
  
  List<dynamic> _restaurants = [];
  List<dynamic> _filteredRestaurants = [];
  dynamic _selectedRestaurant;
  bool _loading = false;
  bool _loadingRestaurants = false;
  String? _error;
  bool _showDropdown = false;
  final FocusNode _restaurantFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.restaurantName != null) {
      _restaurantSearchController.text = widget.restaurantName!;
    }
    _loadRestaurants();
    _restaurantFocusNode.addListener(() {
      if (!_restaurantFocusNode.hasFocus) {
        setState(() => _showDropdown = false);
      }
    });
  }

  Future<void> _loadRestaurants() async {
    setState(() => _loadingRestaurants = true);
    try {
      final data = await _api.getRestaurants(limit: 100);
      if (!mounted) return;
      setState(() {
        _restaurants = data;
        _filteredRestaurants = data;
        _loadingRestaurants = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRestaurants = false;
      });
    }
  }

  void _filterRestaurants(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRestaurants = _restaurants;
        _selectedRestaurant = null;
      } else {
        _filteredRestaurants = _restaurants.where((r) {
          final name = (r["name"] ?? "").toString().toLowerCase();
          final cuisine = (r["cuisine"] ?? "").toString().toLowerCase();
          return name.contains(query.toLowerCase()) || cuisine.contains(query.toLowerCase());
        }).toList();
        _selectedRestaurant = null;
      }
      _showDropdown = query.isNotEmpty && _filteredRestaurants.isNotEmpty;
    });
  }

  void _selectRestaurant(dynamic restaurant) {
    setState(() {
      _selectedRestaurant = restaurant;
      _restaurantSearchController.text = restaurant["name"] ?? "";
      _showDropdown = false;
    });
    _restaurantFocusNode.unfocus();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Image Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imageSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _imageSourceButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF3E3A9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _submitPost() async {
    final restaurantName = _restaurantSearchController.text.trim();
    if (restaurantName.isEmpty && _selectedRestaurant == null) {
      setState(() => _error = "Please select or enter a restaurant name");
      return;
    }

    if (_rating == 0) {
      setState(() => _error = "Please select a rating");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? base64Image;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      final selectedId = _selectedRestaurant?["id"]?.toString() ?? "";
      String fsqId = "";
      if (selectedId.isNotEmpty) {
        try {
          final r = _restaurants.firstWhere((r) => r["id"]?.toString() == selectedId);
          fsqId = (r["fsq_id"] ?? "").toString();
        } catch (_) {}
      }

      final postData = {
        "user_email": Session.email,
        "restaurant_name": _selectedRestaurant?["name"] ?? restaurantName,
        "restaurant_id": selectedId,
        "fsq_id": fsqId,
        "description": _descriptionController.text.trim(),
        "rating": _rating,
        "price_range": _priceAed >= 1000 ? "No Limit" : "${_priceAed.round()} AED",
        "is_review": widget.restaurantId != null || widget.restaurantName != null,
        if (base64Image != null) "image_base64": base64Image,
      };

      final res = await http.post(
        Uri.parse("${ApiService.baseUrl}/posts"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(postData),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Post created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh home page
      } else {
        final body = jsonDecode(res.body);
        setState(() {
          _error = body["detail"] ?? "Failed to create post";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: ${e.toString()}";
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
        leading: IconButton(
          icon: Icon(Icons.close, color: themeProvider.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Post',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: themeProvider.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _loading ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F8574),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error message
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),

            // Image picker
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: themeProvider.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black26, width: 2),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: isDark ? Colors.white24 : Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to add photo',
                            style: TextStyle(color: themeProvider.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Restaurant selection - Searchable Dropdown
            Text('Restaurant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: themeProvider.textPrimary)),
            const SizedBox(height: 8),
            
            if (_loadingRestaurants)
              Center(child: CircularProgressIndicator(color: const Color(0xFF6F8574)))
            else
              Container(
                decoration: BoxDecoration(
                  color: themeProvider.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                ),
                child: TextField(
                  controller: _restaurantSearchController,
                  focusNode: _restaurantFocusNode,
                  style: TextStyle(color: themeProvider.textPrimary),
                  onChanged: _filterRestaurants,
                  onTap: () {
                    if (_restaurantSearchController.text.isNotEmpty) {
                      setState(() => _showDropdown = _filteredRestaurants.isNotEmpty);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search restaurant...',
                    hintStyle: TextStyle(color: themeProvider.textSecondary),
                    prefixIcon: Icon(Icons.search, color: themeProvider.textSecondary),
                    suffixIcon: _selectedRestaurant != null
                        ? IconButton(
                            icon: Icon(Icons.clear, color: themeProvider.textSecondary),
                            onPressed: () {
                              _restaurantSearchController.clear();
                              setState(() {
                                _selectedRestaurant = null;
                                _filteredRestaurants = _restaurants;
                                _showDropdown = false;
                              });
                            },
                          )
                        : Icon(Icons.arrow_drop_down, color: themeProvider.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
                  
                  // Dropdown list
                  if (_showDropdown && _filteredRestaurants.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: themeProvider.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black38 : Colors.black12,
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _filteredRestaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = _filteredRestaurants[index];
                          final name = (restaurant["name"] ?? "").toString();
                          final cuisine = (restaurant["cuisine"] ?? "").toString();
                          final types = restaurant["types"] as List<dynamic>?;
                          final typeColor = getRestaurantTypeColor(types, cuisine, name: name);
                          final typeIcon = getRestaurantTypeIcon(types, cuisine, name: name);
                          final imageUrl = (restaurant["imageUrl"] ?? restaurant["thumbnail"] ?? "").toString();

                          return InkWell(
                            onTap: () => _selectRestaurant(restaurant),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  // Restaurant icon/image
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: imageUrl.isNotEmpty ? Colors.grey[200] : typeColor.withOpacity(0.12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(typeIcon, color: typeColor, size: 20),
                                            )
                                          : Icon(typeIcon, color: typeColor, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Restaurant info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: themeProvider.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (cuisine.isNotEmpty)
                                          Text(
                                            cuisine,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: themeProvider.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

            const SizedBox(height: 16),

            // Description
            Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: themeProvider.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: TextStyle(color: themeProvider.textPrimary),
              decoration: InputDecoration(
                hintText: 'Write about your experience...',
                hintStyle: TextStyle(color: themeProvider.textSecondary),
                filled: true,
                fillColor: themeProvider.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26)),
              ),
            ),

            const SizedBox(height: 24),

            // Rating
            Text('Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: themeProvider.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40,
                      color: Colors.amber,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Price Range (AED Slider)
            Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: themeProvider.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _priceAed >= 1000 ? 'No Limit 🤑' : 'Up to ${_priceAed.round()} AED',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF6F8574)),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const sliderPadding = 14.0;
                      final trackWidth = constraints.maxWidth - sliderPadding * 2;
                      final fraction = (_priceAed - 1) / 999;
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
                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Text(
                                _priceAed >= 1000 ? '∞' : '${_priceAed.round()}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
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
                              value: _priceAed,
                              min: 1,
                              max: 1000,
                              divisions: 999,
                              onChanged: (value) => setState(() => _priceAed = value),
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
                        Text('1', style: TextStyle(fontSize: 12, color: themeProvider.textSecondary, fontWeight: FontWeight.w600)),
                        const Text('∞', style: TextStyle(fontSize: 18, color: Color(0xFF6F8574), fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _restaurantSearchController.dispose();
    _descriptionController.dispose();
    _restaurantFocusNode.dispose();
    super.dispose();
  }
}
