// lib/utils/restaurant_logos.dart
/// Hard-coded official brand logos for restaurant chains.
/// Falls back to category food photos, then Foursquare icons.

const Map<String, String> restaurantLogos = {
  // FAST FOOD - CHICKEN
  "kfc": "https://upload.wikimedia.org/wikipedia/en/b/bf/KFC_logo.svg",
  "popeyes": "https://upload.wikimedia.org/wikipedia/commons/6/67/Popeyes_logo.svg",
  "chicking": "https://upload.wikimedia.org/wikipedia/commons/6/6b/ChicKing_logo.png",
  "raising cane": "https://upload.wikimedia.org/wikipedia/commons/8/8e/Raising_Cane%27s_logo.svg",
  "wingstop": "https://upload.wikimedia.org/wikipedia/commons/b/b5/Wingstop_logo.svg",
  "albaik": "https://upload.wikimedia.org/wikipedia/commons/6/6b/AlBaik_Logo.png",
  "texas chicken": "https://upload.wikimedia.org/wikipedia/commons/4/4e/Texas_Chicken_logo.svg",
  "church chicken": "https://upload.wikimedia.org/wikipedia/commons/4/4e/Texas_Chicken_logo.svg",

  // FAST FOOD - BURGERS
  "mcdonald": "https://upload.wikimedia.org/wikipedia/commons/3/36/McDonald%27s_Golden_Arches.svg",
  "burger king": "https://upload.wikimedia.org/wikipedia/commons/8/85/Burger_King_logo_%281999%29.svg",
  "hardee": "https://upload.wikimedia.org/wikipedia/commons/a/a8/Hardee%27s_Logo.svg",
  "five guys": "https://upload.wikimedia.org/wikipedia/commons/4/44/Five_Guys_logo.svg",
  "shake shack": "https://upload.wikimedia.org/wikipedia/commons/9/9d/Shake_Shack_logo.svg",
  "wendy": "https://upload.wikimedia.org/wikipedia/commons/a/a1/Wendy%27s_full_logo_2012.svg",
  "smashburger": "https://upload.wikimedia.org/wikipedia/commons/2/2e/Smashburger_Logo.svg",
  "wimpy": "https://upload.wikimedia.org/wikipedia/commons/f/f6/Wimpy_logo.svg",
  "fatburger": "https://upload.wikimedia.org/wikipedia/commons/7/7b/Fatburger_logo.svg",
  "white castle": "https://upload.wikimedia.org/wikipedia/commons/8/84/White_Castle_logo.svg",
  "carl jr": "https://upload.wikimedia.org/wikipedia/commons/1/1c/Carl%27s_Jr._logo.svg",
  "in n out": "https://upload.wikimedia.org/wikipedia/commons/0/04/In-N-Out_Burger_logo.svg",

  // PIZZA
  "pizza hut": "https://upload.wikimedia.org/wikipedia/en/d/d2/Pizza_Hut_logo.svg",
  "domino": "https://upload.wikimedia.org/wikipedia/commons/3/3e/Domino%27s_pizza_logo.svg",
  "papa john": "https://upload.wikimedia.org/wikipedia/commons/a/a5/Papa_John%27s_logo.svg",
  "little caesar": "https://upload.wikimedia.org/wikipedia/commons/e/ea/Little_Caesars_logo.svg",
  "california pizza": "https://upload.wikimedia.org/wikipedia/commons/b/bc/California_Pizza_Kitchen_logo.svg",
  "pizza express": "https://upload.wikimedia.org/wikipedia/commons/8/82/PizzaExpress_logo.svg",

  // SANDWICHES & WRAPS
  "subway": "https://upload.wikimedia.org/wikipedia/commons/5/5c/Subway_2016_logo.svg",
  "quiznos": "https://upload.wikimedia.org/wikipedia/commons/c/c5/Quiznos_Logo.svg",
  "potbelly": "https://upload.wikimedia.org/wikipedia/commons/8/83/Potbelly_logo.svg",
  "schlotzsky": "https://upload.wikimedia.org/wikipedia/commons/3/3d/Schlotzsky%27s_Logo.svg",

  // COFFEE & CAFE
  "starbucks": "https://upload.wikimedia.org/wikipedia/en/d/d3/Starbucks_Corporation_Logo_2011.svg",
  "tim horton": "https://upload.wikimedia.org/wikipedia/commons/3/32/Tim_Hortons_logo.svg",
  "dunkin": "https://upload.wikimedia.org/wikipedia/commons/f/f6/Dunkin%27_Donuts_logo.svg",
  "costa": "https://upload.wikimedia.org/wikipedia/en/c/c7/Costa_Coffee_logo.svg",
  "caribou": "https://upload.wikimedia.org/wikipedia/en/0/08/Caribou_Coffee_Logo.svg",
  "peet": "https://upload.wikimedia.org/wikipedia/commons/6/6b/Peet%27s_Coffee_logo.svg",
  "mcafe": "https://upload.wikimedia.org/wikipedia/commons/1/10/McCafe_Logo.svg",
  "second cup": "https://upload.wikimedia.org/wikipedia/commons/f/f3/Second_Cup_logo.svg",
  "coffee bean": "https://upload.wikimedia.org/wikipedia/commons/9/9e/The_Coffee_Bean_%26_Tea_Leaf_logo.svg",
  "gloria jean": "https://upload.wikimedia.org/wikipedia/commons/b/b5/Gloria_Jean%27s_Coffees_logo.svg",
  "paul": "https://upload.wikimedia.org/wikipedia/commons/0/09/Paul_boulangerie_logo.svg",
  "nero": "https://upload.wikimedia.org/wikipedia/commons/4/4c/Caffe_Nero_logo.svg",
  "italian caffe": "https://upload.wikimedia.org/wikipedia/commons/4/4c/Caffe_Nero_logo.svg",

  // DONUTS & DESSERTS
  "krispy kreme": "https://upload.wikimedia.org/wikipedia/commons/8/87/Krispy_Kreme_doughnuts_logo.svg",
  "baskin robbins": "https://upload.wikimedia.org/wikipedia/commons/3/34/Baskin-Robbins_logo.svg",
  "cinnabon": "https://upload.wikimedia.org/wikipedia/commons/b/b6/Cinnabon_Logo.svg",
  "cold stone": "https://upload.wikimedia.org/wikipedia/commons/5/51/Cold_Stone_Creamery_logo.svg",
  "dairy queen": "https://upload.wikimedia.org/wikipedia/commons/b/b3/Dairy_Queen_logo.svg",
  "haagen dazs": "https://upload.wikimedia.org/wikipedia/commons/6/6e/H%C3%A4agen-Dazs_logo.svg",
  "ben jerry": "https://upload.wikimedia.org/wikipedia/commons/3/35/Ben_%26_Jerry%27s_logo.svg",
  "magnolia": "https://upload.wikimedia.org/wikipedia/commons/e/e8/Magnolia_Bakery_logo.png",
  "auntie anne": "https://upload.wikimedia.org/wikipedia/commons/c/c3/Auntie_Anne%27s_logo.svg",
  "wetzel pretzel": "https://upload.wikimedia.org/wikipedia/commons/5/55/Wetzel%27s_Pretzels_logo.svg",

  // CASUAL DINING
  "applebee": "https://upload.wikimedia.org/wikipedia/en/5/56/Applebee%27s_logo.svg",
  "chili": "https://upload.wikimedia.org/wikipedia/en/8/81/Chilis_Logo.svg",
  "tgi friday": "https://upload.wikimedia.org/wikipedia/commons/0/0a/TGI_Fridays_logo.svg",
  "cheesecake factory": "https://upload.wikimedia.org/wikipedia/commons/5/54/The_Cheesecake_Factory_Logo.svg",
  "hard rock": "https://upload.wikimedia.org/wikipedia/commons/2/27/Hard_Rock_logo.svg",
  "friday": "https://upload.wikimedia.org/wikipedia/commons/0/0a/TGI_Fridays_logo.svg",
  "outback": "https://upload.wikimedia.org/wikipedia/commons/1/18/Outback_Steakhouse_Logo.svg",
  "ihop": "https://upload.wikimedia.org/wikipedia/commons/a/a9/IHOP_logo.svg",
  "denny": "https://upload.wikimedia.org/wikipedia/commons/a/af/Denny%27s_logo.svg",
  "tony roma": "https://upload.wikimedia.org/wikipedia/commons/f/f8/Tony_Roma%27s_logo.png",
  "texas roadhouse": "https://upload.wikimedia.org/wikipedia/commons/1/17/Texas_Roadhouse_logo.svg",
  "olive garden": "https://upload.wikimedia.org/wikipedia/commons/b/b4/Olive_Garden_Logo.svg",
  "red lobster": "https://upload.wikimedia.org/wikipedia/commons/4/4f/Red_Lobster_logo.svg",
  "ruby tuesday": "https://upload.wikimedia.org/wikipedia/commons/c/c3/Ruby_Tuesday_logo.svg",

  // NANDO'S
  "nando": "https://upload.wikimedia.org/wikipedia/en/7/7d/Nandos-logo.svg",

  // ASIAN
  "panda express": "https://upload.wikimedia.org/wikipedia/commons/6/63/Panda_Express_logo.svg",
  "din tai fung": "https://upload.wikimedia.org/wikipedia/commons/e/e2/Din_Tai_Fung_logo.png",
  "p.f. chang": "https://upload.wikimedia.org/wikipedia/commons/c/c7/PF_Changs_logo.svg",
  "yo sushi": "https://upload.wikimedia.org/wikipedia/commons/6/63/YO_Sushi_logo.svg",
  "wagamama": "https://upload.wikimedia.org/wikipedia/commons/5/5a/Wagamama_logo.svg",

  // BAKERIES
  "paul bakery": "https://upload.wikimedia.org/wikipedia/commons/0/09/Paul_boulangerie_logo.svg",
  "le pain quotidien": "https://upload.wikimedia.org/wikipedia/commons/e/e9/Le_Pain_Quotidien_logo.svg",

  // JUICE & HEALTHY
  "jamba juice": "https://upload.wikimedia.org/wikipedia/commons/3/3b/Jamba_logo.svg",
  "smoothie king": "https://upload.wikimedia.org/wikipedia/commons/f/f0/Smoothie_King_Logo.svg",
  "booster juice": "https://upload.wikimedia.org/wikipedia/commons/7/77/Booster_Juice_logo.svg",

  // STEAKHOUSE
  "outback steakhouse": "https://upload.wikimedia.org/wikipedia/commons/1/18/Outback_Steakhouse_Logo.svg",
  "ruth chris": "https://upload.wikimedia.org/wikipedia/commons/8/84/Ruth%27s_Chris_Steak_House_logo.svg",

  // DESSERTS AGAIN
  "laduree": "https://upload.wikimedia.org/wikipedia/commons/4/48/Laduree_logo.svg",
  "eataly": "https://upload.wikimedia.org/wikipedia/commons/e/e7/Eataly_logo.svg",
  "vapiano": "https://upload.wikimedia.org/wikipedia/commons/5/5e/Vapiano_Logo.svg",
};

const Map<String, String> categoryImages = {
  "shawarma": "https://images.unsplash.com/photo-1561050501-a90e09d5d95a?w=200",
  "seafood": "https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=200",
  "coffee": "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=200",
  "cafe": "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=200",
  "pizza": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200",
  "burger": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200",
  "chicken": "https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=200",
  "indian": "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=200",
  "sushi": "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=200",
  "arabic": "https://images.unsplash.com/photo-1561050501-a90e09d5d95a?w=200",
  "italian": "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200",
  "steak": "https://images.unsplash.com/photo-1544025162-d76694265947?w=200",
  "sandwich": "https://images.unsplash.com/photo-1553909489-cd47e0907980?w=200",
  "dessert": "https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=200",
  "bakery": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200",
  "juice": "https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=200",
  "healthy": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200",
  "breakfast": "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=200",
  "default": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200",
};

/// Look up the official logo URL for a given restaurant name.
/// Returns null if no match is found.
String? findLogoUrl(String restaurantName) {
  if (restaurantName.trim().isEmpty) return null;
  final lower = restaurantName.toLowerCase();
  for (final entry in restaurantLogos.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return null;
}

/// Look up the fallback category photo URL based on cuisine/type keywords.
String? findCategoryImageUrl(String? cuisineOrType) {
  if (cuisineOrType == null || cuisineOrType.trim().isEmpty) return null;
  final lower = cuisineOrType.toLowerCase();
  for (final entry in categoryImages.entries) {
    if (entry.key == "default") continue;
    if (lower.contains(entry.key)) return entry.value;
  }
  return categoryImages["default"];
}

/// Return the best image URL for a restaurant card.
/// Priority: 1. Official logo, 2. Category food photo, 3. null (caller uses icon fallback).
String? getRestaurantCardImageUrl(String restaurantName, String? cuisineOrType) {
  return findLogoUrl(restaurantName) ?? findCategoryImageUrl(cuisineOrType);
}
