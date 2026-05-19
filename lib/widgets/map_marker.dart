import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Chain restaurant brand colors and icons
class ChainRestaurant {
  final String name;
  final Color color;
  final IconData icon;
  final String? logoUrl;

  const ChainRestaurant({
    required this.name,
    required this.color,
    required this.icon,
    this.logoUrl,
  });
}

/// Known chain restaurants with their brand colors
const List<ChainRestaurant> knownChains = [
  // Fast Food
  ChainRestaurant(name: 'KFC', color: Color(0xFFE4002B), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/8/8b/KFC_logo.svg'),
  ChainRestaurant(name: "McDonald's", color: Color(0xFFFFC72C), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/36/McDonald%27s_Golden_Arches.svg'),
  ChainRestaurant(name: 'Burger King', color: Color(0xFFD6232A), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/69/Burger_King_2020.svg'),
  ChainRestaurant(name: 'Subway', color: Color(0xFF008C15), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/05/Subway_2020.svg'),
  ChainRestaurant(name: 'Wendys', color: Color(0xFFE21C2B), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/39/Wendys_2012_logo.svg'),
  ChainRestaurant(name: 'Chick-fil-A', color: Color(0xFFDD0031), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/a/a2/Chick-fil-A_logo.svg'),
  ChainRestaurant(name: 'Five Guys', color: Color(0xFFC41230), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/5/52/Five_Guys_logo.svg'),
  ChainRestaurant(name: 'Shake Shack', color: Color(0xFF008C15), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/41/Shake_Shack_logo.svg'),
  ChainRestaurant(name: 'In-N-Out', color: Color(0xFFE4002B), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/34/In-N-Out_Logo.svg'),
  ChainRestaurant(name: 'Popeyes', color: Color(0xFFE4002B), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/5/5a/Popeyes_logo.svg'),
  ChainRestaurant(name: 'Jack in the Box', color: Color(0xFFE4002B), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/36/Jack_in_the_Box_2018_logo.svg'),
  ChainRestaurant(name: 'Carl\s Jr', color: Color(0xFFE4002B), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/5/5a/Carl%27s_Jr._logo.svg'),
  ChainRestaurant(name: 'Hardees', color: Color(0xFFE4002B), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/5/5a/Hardee%27s_logo.svg'),
  ChainRestaurant(name: 'Whataburger', color: Color(0xFFE4002B), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/6/60/Whataburger_logo.svg'),
  ChainRestaurant(name: 'Sonic', color: Color(0xFFE4002B), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/34/Sonic_Drive-In_logo.svg'),
  
  // Pizza
  ChainRestaurant(name: 'Pizza Hut', color: Color(0xFFE73C00), icon: Icons.local_pizza, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/d/d0/Pizza_Hut_logo.svg'),
  ChainRestaurant(name: "Domino's", color: Color(0xFF006491), icon: Icons.local_pizza, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/2e/Dominos_pizza_logo.svg'),
  ChainRestaurant(name: "Papa John's", color: Color(0xFFCC0000), icon: Icons.local_pizza, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/7/7e/Papa_John%27s_logo.svg'),
  ChainRestaurant(name: 'Little Caesars', color: Color(0xFFE4002B), icon: Icons.local_pizza, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4a/Little_Caesars_logo.svg'),
  ChainRestaurant(name: 'Papa Murphy\s', color: Color(0xFFE4002B), icon: Icons.local_pizza, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/2e/Papa_Murphy%27s_logo.svg'),
  
  // Coffee & Drinks
  ChainRestaurant(name: 'Starbucks', color: Color(0xFF00704A), icon: Icons.coffee, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/9/99/Starbucks_Corporation_Logo_2011.svg'),
  ChainRestaurant(name: 'Tim Hortons', color: Color(0xFFC41230), icon: Icons.coffee, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/8/8a/Tim_Hortons_logo.svg'),
  ChainRestaurant(name: 'Dunkin', color: Color(0xFFFF671F), icon: Icons.coffee, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/10/Dunkin_Donuts_2018.svg'),
  ChainRestaurant(name: 'Costa Coffee', color: Color(0xFF6F3E2B), icon: Icons.coffee, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/46/Costa_Coffee_logo.svg'),
  ChainRestaurant(name: 'Peet\s Coffee', color: Color(0xFF6F3E2B), icon: Icons.coffee, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3a/Peet%27s_Coffee_logo.svg'),
  ChainRestaurant(name: 'Caribou Coffee', color: Color(0xFF2E5A4E), icon: Icons.coffee, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/2e/Caribou_Coffee_logo.svg'),
  ChainRestaurant(name: 'Gloria Jeans', color: Color(0xFF8B0000), icon: Icons.coffee, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/2e/Gloria_Jean%27s_Coffees_logo.svg'),
  
  // Ice Cream & Desserts
  ChainRestaurant(name: 'Baskin Robbins', color: Color(0xFFE31E53), icon: Icons.icecream, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/8/88/Baskin-Robbins_Logo.svg'),
  ChainRestaurant(name: 'Dairy Queen', color: Color(0xFF0072CE), icon: Icons.icecream, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/2/28/Dairy_Queen_Logo.svg'),
  ChainRestaurant(name: 'Cold Stone', color: Color(0xFFE4002B), icon: Icons.icecream, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4a/Cold_Stone_Creamery_logo.svg'),
  ChainRestaurant(name: 'Ben & Jerry\s', color: Color(0xFFE4002B), icon: Icons.icecream, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4a/Ben_%26_Jerry%27s_logo.svg'),
  ChainRestaurant(name: 'Haagen-Dazs', color: Color(0xFFE4002B), icon: Icons.icecream, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4a/Haagen-Dazs_logo.svg'),
  
  // Mexican
  ChainRestaurant(name: 'Taco Bell', color: Color(0xFF702082), icon: Icons.local_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/04/Taco_Bell_2016.svg'),
  ChainRestaurant(name: 'Chipotle', color: Color(0xFFA02422), icon: Icons.local_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3a/Chipotle_Mexican_Grill_logo.svg'),
  ChainRestaurant(name: 'Qdoba', color: Color(0xFFE4002B), icon: Icons.local_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3a/Qdoba_logo.svg'),
  ChainRestaurant(name: 'Moe\s Southwest', color: Color(0xFFE4002B), icon: Icons.local_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3a/Moe%27s_Southwest_Grill_logo.svg'),
  ChainRestaurant(name: 'Del Taco', color: Color(0xFFE4002B), icon: Icons.local_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/3/3a/Del_Taco_logo.svg'),
  
  // Asian
  ChainRestaurant(name: 'Panda Express', color: Color(0xFFD2232A), icon: Icons.ramen_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Panda_Express_logo.svg'),
  ChainRestaurant(name: 'P.F. Changs', color: Color(0xFFC41230), icon: Icons.ramen_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/P._F._Chang%27s_logo.svg'),
  ChainRestaurant(name: 'Wagamama', color: Color(0xFFE31837), icon: Icons.ramen_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Wagamama_logo.svg'),
  ChainRestaurant(name: 'Noodles & Company', color: Color(0xFFE4002B), icon: Icons.ramen_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Noodles_%26_Company_logo.svg'),
  
  // Casual Dining
  ChainRestaurant(name: 'Nandos', color: Color(0xFFCC0000), icon: Icons.local_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/8/83/Nando%27s_logo.svg'),
  ChainRestaurant(name: "TGI Friday's", color: Color(0xFFC41230), icon: Icons.restaurant, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/9/9f/TGI_Fridays_logo.svg'),
  ChainRestaurant(name: 'Chili\s', color: Color(0xFFC41230), icon: Icons.restaurant, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Chili%27s_logo.svg'),
  ChainRestaurant(name: 'Applebee\s', color: Color(0xFFE4002B), icon: Icons.restaurant, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Applebee%27s_logo.svg'),
  ChainRestaurant(name: 'Olive Garden', color: Color(0xFFE4002B), icon: Icons.restaurant, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Olive_Garden_logo.svg'),
  ChainRestaurant(name: 'Red Lobster', color: Color(0xFFE4002B), icon: Icons.restaurant, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Red_Lobster_logo.svg'),
  ChainRestaurant(name: 'Outback', color: Color(0xFFE4002B), icon: Icons.restaurant, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Outback_Steakhouse_logo.svg'),
  ChainRestaurant(name: 'Cheesecake Factory', color: Color(0xFF8B4513), icon: Icons.restaurant, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/The_Cheesecake_Factory_logo.svg'),
  ChainRestaurant(name: 'Buffalo Wild Wings', color: Color(0xFFE4002B), icon: Icons.restaurant, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Buffalo_Wild_Wings_logo.svg'),
  ChainRestaurant(name: 'Hooters', color: Color(0xFFE4002B), icon: Icons.restaurant, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Hooters_logo.svg'),
  
  // Middle Eastern
  ChainRestaurant(name: 'Al Baik', color: Color(0xFFE4002B), icon: Icons.fastfood, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Al_Baik_logo.svg'),
  ChainRestaurant(name: 'Shawarma', color: Color(0xFFE4002B), icon: Icons.local_dining, logoUrl: null),
  ChainRestaurant(name: 'Falafel', color: Color(0xFFE4002B), icon: Icons.local_dining, logoUrl: null),
  
  // Bakery & Breakfast
  ChainRestaurant(name: 'Cinnabon', color: Color(0xFFE4002B), icon: Icons.bakery_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Cinnabon_logo.svg'),
  ChainRestaurant(name: 'Krispy Kreme', color: Color(0xFFE4002B), icon: Icons.bakery_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Krispy_Kreme_logo.svg'),
  ChainRestaurant(name: 'Dunkin Donuts', color: Color(0xFFFF671F), icon: Icons.bakery_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/10/Dunkin_Donuts_2018.svg'),
  ChainRestaurant(name: 'Panera', color: Color(0xFFE4002B), icon: Icons.bakery_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Panera_Bread_logo.svg'),
  ChainRestaurant(name: 'Einstein Bros', color: Color(0xFFE4002B), icon: Icons.bakery_dining, logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Einstein_Bros_logo.svg'),
];

/// Get chain restaurant info by name matching
ChainRestaurant? getChainRestaurant(String? name) {
  if (name == null || name.isEmpty) return null;
  final lower = name.toLowerCase();
  for (final chain in knownChains) {
    if (lower.contains(chain.name.toLowerCase())) {
      return chain;
    }
  }
  return null;
}

/// Maps restaurant/cuisine types to Material icons
IconData getRestaurantTypeIcon(List<dynamic>? types, String? cuisine, {String? name}) {
  // Check for chain restaurants first
  final chain = getChainRestaurant(name);
  if (chain != null) return chain.icon;

  final t = (types ?? []).map((e) => e.toString().toLowerCase()).toList();
  final c = (cuisine ?? "").toLowerCase();

  if (t.contains('cafe') || t.contains('coffee_shop') || c.contains('coffee') || c.contains('cafe')) {
    return Icons.coffee;
  }
  if (t.contains('bakery') || c.contains('bakery')) {
    return Icons.bakery_dining;
  }
  if (t.contains('bar') || t.contains('night_club') || c.contains('bar')) {
    return Icons.local_bar;
  }
  if (c.contains('pizza') || t.contains('pizza_restaurant')) {
    return Icons.local_pizza;
  }
  if (c.contains('burger') || c.contains('american') || t.contains('hamburger_restaurant')) {
    return Icons.fastfood;
  }
  if (c.contains('sushi') || c.contains('japanese') || c.contains('asian')) {
    return Icons.ramen_dining;
  }
  if (c.contains('italian') || c.contains('pasta')) {
    return Icons.dinner_dining;
  }
  if (c.contains('mexican') || c.contains('taco')) {
    return Icons.local_dining;
  }
  if (c.contains('indian') || c.contains('curry')) {
    return Icons.restaurant_menu;
  }
  if (c.contains('seafood') || c.contains('fish')) {
    return Icons.set_meal;
  }
  if (c.contains('ice cream') || c.contains('dessert') || t.contains('ice_cream_shop')) {
    return Icons.icecream;
  }
  if (t.contains('fast_food')) {
    return Icons.fastfood;
  }
  return Icons.restaurant;
}

/// Maps types/cuisine to a brand color
Color getRestaurantTypeColor(List<dynamic>? types, String? cuisine, {String? name}) {
  // Check for chain restaurants first
  final chain = getChainRestaurant(name);
  if (chain != null) return chain.color;

  final t = (types ?? []).map((e) => e.toString().toLowerCase()).toList();
  final c = (cuisine ?? "").toLowerCase();

  if (t.contains('cafe') || t.contains('coffee_shop') || c.contains('coffee') || c.contains('cafe')) {
    return const Color(0xFF8D6E63); // coffee brown
  }
  if (t.contains('bakery') || c.contains('bakery')) {
    return const Color(0xFFFFA726); // bakery orange
  }
  if (t.contains('bar') || t.contains('night_club') || c.contains('bar')) {
    return const Color(0xFF7B1FA2); // bar purple
  }
  if (c.contains('pizza') || t.contains('pizza_restaurant')) {
    return const Color(0xFFE64A19); // pizza red-orange
  }
  if (c.contains('burger') || c.contains('american') || t.contains('hamburger_restaurant')) {
    return const Color(0xFFFBC02D); // burger yellow
  }
  if (c.contains('sushi') || c.contains('japanese') || c.contains('asian')) {
    return const Color(0xFF00897B); // sushi teal
  }
  if (c.contains('italian') || c.contains('pasta')) {
    return const Color(0xFF43A047); // italian green
  }
  if (c.contains('mexican') || c.contains('taco')) {
    return const Color(0xFFFF7043); // mexican orange
  }
  if (c.contains('indian') || c.contains('curry')) {
    return const Color(0xFFFF5722); // indian deep orange
  }
  if (c.contains('seafood') || c.contains('fish')) {
    return const Color(0xFF039BE5); // seafood blue
  }
  if (c.contains('ice cream') || c.contains('dessert') || t.contains('ice_cream_shop')) {
    return const Color(0xFFEC407A); // dessert pink
  }
  if (t.contains('fast_food')) {
    return const Color(0xFFFFC107); // fast food amber
  }
  return const Color(0xFF6F8574); // default sage green
}

/// A beautiful map pin marker widget
class MapPinMarker extends StatelessWidget {
  final String? imageUrl;
  final List<dynamic>? types;
  final String? cuisine;
  final String? name;
  final bool isSelected;
  final double size;

  const MapPinMarker({
    super.key,
    this.imageUrl,
    this.types,
    this.cuisine,
    this.name,
    this.isSelected = false,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final color = getRestaurantTypeColor(types, cuisine, name: name);
    final icon = getRestaurantTypeIcon(types, cuisine, name: name);
    final actualSize = isSelected ? size * 1.15 : size;
    final pinWidth = actualSize;
    final pinHeight = actualSize * 1.25;
    final circleSize = actualSize * 0.72;

    return SizedBox(
      width: pinWidth,
      height: pinHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Shadow
          Positioned(
            top: pinHeight * 0.15,
            child: Container(
              width: circleSize * 0.8,
              height: circleSize * 0.4,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(circleSize),
              ),
            ),
          ),
          // Pin body (circle + triangle)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: isSelected ? 3.5 : 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: isSelected ? 14 : 10,
                      spreadRadius: isSelected ? 3 : 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildInnerContent(icon, color, circleSize),
                ),
              ),
              // Triangle pointer
              CustomPaint(
                size: Size(actualSize * 0.34, actualSize * 0.22),
                painter: _TrianglePainter(color: color),
              ),
            ],
          ),
          // Selected indicator ring
          if (isSelected)
            Positioned(
              top: 0,
              child: Container(
                width: circleSize + 8,
                height: circleSize + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInnerContent(IconData icon, Color color, double circleSize) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (hasImage) {
      // Try to load image, fallback to icon
      if (imageUrl!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          width: circleSize,
          height: circleSize,
          placeholder: (_, __) => _iconPlaceholder(icon, color, circleSize),
          errorWidget: (_, __, ___) => _iconPlaceholder(icon, color, circleSize),
        );
      }
      return _iconPlaceholder(icon, color, circleSize);
    }

    return _iconPlaceholder(icon, color, circleSize);
  }

  Widget _iconPlaceholder(IconData icon, Color color, double circleSize) {
    return Container(
      width: circleSize,
      height: circleSize,
      color: color,
      child: Icon(icon, color: Colors.white, size: circleSize * 0.45),
    );
  }
}

/// User location marker with accuracy ring
class UserLocationMarker extends StatelessWidget {
  final double size;
  const UserLocationMarker({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ),
          // Middle ring
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
          ),
          // Core dot
          Container(
            width: size * 0.42,
            height: size * 0.42,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 10, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.navigation, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }
}

/// Triangle painter for the pin pointer
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Search result avatar with type-based styling
class RestaurantSearchAvatar extends StatelessWidget {
  final String? imageUrl;
  final List<dynamic>? types;
  final String? cuisine;
  final String name;
  final double size;

  const RestaurantSearchAvatar({
    super.key,
    this.imageUrl,
    this.types,
    this.cuisine,
    required this.name,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final chain = getChainRestaurant(name);
    final color = getRestaurantTypeColor(types, cuisine, name: name);
    final icon = getRestaurantTypeIcon(types, cuisine, name: name);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final hasChainLogo = chain?.logoUrl != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        color: hasImage || hasChainLogo ? Colors.grey[200] : color.withOpacity(0.12),
        child: hasChainLogo && chain?.logoUrl != null
            ? CachedNetworkImage(
                imageUrl: chain!.logoUrl!,
                fit: BoxFit.contain,
                width: size * 0.8,
                height: size * 0.8,
                placeholder: (_, __) => _fallback(icon, color),
                errorWidget: (_, __, ___) => _fallback(icon, color),
              )
            : hasImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    placeholder: (_, __) => _fallback(icon, color),
                    errorWidget: (_, __, ___) => _fallback(icon, color),
                  )
                : _fallback(icon, color),
      ),
    );
  }

  Widget _fallback(IconData icon, Color color) {
    return Center(
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
