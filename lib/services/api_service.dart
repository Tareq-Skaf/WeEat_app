import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000";
  static const String wsUrl = "ws://10.0.2.2:8000";

  // ===================== AUTH =====================

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? username,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
        if (username != null && username.trim().isNotEmpty) "username": username.trim(),
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Register failed");
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Login failed");
  }

  Future<Map<String, dynamic>> getMe({required String email}) async {
    final uri = Uri.parse("$baseUrl/users/me").replace(queryParameters: {"email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to load profile");
  }

  Future<Map<String, dynamic>> resetPassword({required String email, required String newPassword}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/reset-password"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "new_password": newPassword}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Reset failed");
  }

  // ===================== RESTAURANTS =====================

  Future<void> seedRestaurants() async {
    final res = await http.post(Uri.parse("$baseUrl/restaurants/seed"), headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to seed restaurants");
  }

  Future<List<dynamic>> getRestaurants({int limit = 20}) async {
    final uri = Uri.parse("$baseUrl/restaurants").replace(queryParameters: {"limit": limit.toString()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load restaurants");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getRestaurantById(String id) async {
    final res = await http.get(Uri.parse("$baseUrl/restaurants/$id"), headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load restaurant");
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> searchRestaurants({String? q, String? cuisine}) async {
    final qp = <String, String>{};
    if (q != null && q.isNotEmpty) qp["q"] = q;
    if (cuisine != null && cuisine.isNotEmpty) qp["cuisine"] = cuisine;
    final uri = Uri.parse("$baseUrl/restaurants/search").replace(queryParameters: qp);
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Search failed");
    return jsonDecode(res.body);
  }

  // ===================== WISHLIST =====================

  Future<Map<String, dynamic>> toggleWishlist({required String email, required String restaurantId}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/wishlist/toggle"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "restaurant_id": restaurantId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Wishlist toggle failed");
  }

  Future<List<dynamic>> getWishlist({required String email}) async {
    final uri = Uri.parse("$baseUrl/wishlist").replace(queryParameters: {"email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load wishlist");
    return jsonDecode(res.body);
  }

  // ===================== POSTS =====================

  Future<List<dynamic>> getPosts({int limit = 20, int skip = 0, bool includeReviews = false}) async {
    final uri = Uri.parse("$baseUrl/posts").replace(queryParameters: {
      "limit": limit.toString(),
      "skip": skip.toString(),
      "include_reviews": includeReviews.toString(),
    });
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load posts");
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getReviewsByRestaurant({String? restaurantName, String? fsqId}) async {
    final query = <String, String>{};
    if (restaurantName != null && restaurantName.isNotEmpty) query["restaurant_name"] = restaurantName;
    if (fsqId != null && fsqId.isNotEmpty) query["fsq_id"] = fsqId;
    final uri = Uri.parse("$baseUrl/posts/reviews").replace(queryParameters: query);
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load reviews");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createPost({
    required String userEmail,
    required String restaurantName,
    String? restaurantId,
    String? fsqId,
    required String description,
    required int rating,
    required String priceRange,
    String? imageBase64,
    bool isReview = false,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/posts"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({
        "user_email": userEmail,
        "restaurant_name": restaurantName,
        "restaurant_id": restaurantId ?? "",
        "fsq_id": fsqId ?? "",
        "description": description,
        "rating": rating,
        "price_range": priceRange,
        "is_review": isReview,
        if (imageBase64 != null) "image_base64": imageBase64,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body;
    throw Exception(body["detail"] ?? "Failed to create post");
  }

  Future<Map<String, dynamic>> likePost({required String postId, required String email}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/posts/$postId/like?email=$email"),
      headers: {"Accept": "application/json"},
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to like post");
  }

  // ===================== LIKED / DISLIKED =====================

  Future<Map<String, dynamic>> toggleLiked({required String email, required String restaurantId}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/liked/toggle"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "restaurant_id": restaurantId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to toggle liked");
  }

  Future<List<dynamic>> getLiked({required String email}) async {
    final uri = Uri.parse("$baseUrl/liked").replace(queryParameters: {"email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load liked");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> toggleDisliked({required String email, required String restaurantId}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/disliked/toggle"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "restaurant_id": restaurantId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to toggle disliked");
  }

  Future<List<dynamic>> getDisliked({required String email}) async {
    final uri = Uri.parse("$baseUrl/disliked").replace(queryParameters: {"email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load disliked");
    return jsonDecode(res.body);
  }

  // ===================== PLANS =====================

  Future<Map<String, dynamic>> createPlan({
    required String email,
    required String title,
    String? restaurantId,
    String? restaurantName,
    required String date,
    required String time,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/plans"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({
        "email": email,
        "title": title,
        if (restaurantId != null) "restaurant_id": restaurantId,
        if (restaurantName != null) "restaurant_name": restaurantName,
        "date": date,
        "time": time,
        if (notes != null) "notes": notes,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body;
    throw Exception(body["detail"] ?? "Failed to create plan");
  }

  Future<List<dynamic>> getPlans({required String email}) async {
    final uri = Uri.parse("$baseUrl/plans").replace(queryParameters: {"email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load plans");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updatePlan({
    required String planId,
    String? title,
    String? restaurantId,
    String? restaurantName,
    String? date,
    String? time,
    String? notes,
  }) async {
    final res = await http.put(
      Uri.parse("$baseUrl/plans/$planId"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({
        if (title != null) "title": title,
        if (restaurantId != null) "restaurant_id": restaurantId,
        if (restaurantName != null) "restaurant_name": restaurantName,
        if (date != null) "date": date,
        if (time != null) "time": time,
        if (notes != null) "notes": notes,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to update plan");
  }

  Future<void> deletePlan({required String planId}) async {
    final res = await http.delete(Uri.parse("$baseUrl/plans/$planId"), headers: {"Accept": "application/json"});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "Failed to delete plan");
    }
  }

  // ===================== USER STATS =====================

  Future<Map<String, dynamic>> getUserStats({required String email}) async {
    final uri = Uri.parse("$baseUrl/users/stats").replace(queryParameters: {"email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load user stats");
    return jsonDecode(res.body);
  }

  // ===================== COMMENTS =====================

  Future<List<dynamic>> getComments({required String postId}) async {
    final res = await http.get(Uri.parse("$baseUrl/comments/post/$postId"), headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load comments");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> addComment({required String postId, required String userEmail, required String content}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/comments/post/$postId"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"user_email": userEmail, "content": content}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) return body;
    throw Exception(body["detail"] ?? "Failed to add comment");
  }

  Future<int> getCommentCount({required String postId}) async {
    final res = await http.get(Uri.parse("$baseUrl/comments/post/$postId/count"), headers: {"Accept": "application/json"});
    if (res.statusCode != 200) return 0;
    final data = jsonDecode(res.body);
    return (data["count"] ?? 0) as int;
  }

  // ===================== FRIENDS =====================

  Future<Map<String, dynamic>> sendFriendRequest({required String fromEmail, required String toEmail}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/friends/request"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"from_email": fromEmail, "to_email": toEmail}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to send friend request");
  }

  Future<Map<String, dynamic>> acceptFriendRequest({required String fromEmail, required String toEmail}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/friends/accept"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"from_email": fromEmail, "to_email": toEmail}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to accept friend request");
  }

  Future<List<dynamic>> getPendingRequests({required String email}) async {
    final uri = Uri.parse("$baseUrl/friends/requests").replace(queryParameters: {"email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load pending requests");
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getFriends({required String email}) async {
    final uri = Uri.parse("$baseUrl/friends").replace(queryParameters: {"email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load friends");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getFriendshipStatus({required String email, required String otherEmail}) async {
    final uri = Uri.parse("$baseUrl/friends/status").replace(queryParameters: {"email": email.trim(), "other_email": otherEmail.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to get friendship status");
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getSuggestedUsers({required String email, int limit = 10}) async {
    final uri = Uri.parse("$baseUrl/friends/suggestions").replace(queryParameters: {"email": email.trim(), "limit": limit.toString()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load suggested users");
    return jsonDecode(res.body);
  }

  Future<void> removeFriend({required String email, required String friendEmail}) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/friends"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "friend_email": friendEmail}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "Failed to remove friend");
    }
  }

  // ===================== USER SEARCH =====================

  Future<List<dynamic>> searchUsers({required String query, int limit = 20}) async {
    final uri = Uri.parse("$baseUrl/users/search").replace(queryParameters: {"q": query.trim(), "limit": limit.toString()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to search users");
    return jsonDecode(res.body);
  }

  // ===================== DIRECTIONS =====================

  Future<Map<String, dynamic>> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String mode = 'driving',
  }) async {
    final uri = Uri.parse("$baseUrl/directions").replace(queryParameters: {
      "origin_lat": originLat.toString(),
      "origin_lng": originLng.toString(),
      "dest_lat": destLat.toString(),
      "dest_lng": destLng.toString(),
      "mode": mode,
    });
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to get directions");
    return jsonDecode(res.body);
  }

  // ===================== IP LOCATION =====================

  Future<Map<String, dynamic>> getUserLocationFromIP() async {
    final res = await http.get(Uri.parse("$baseUrl/user/location"), headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to get location");
    return jsonDecode(res.body);
  }

  // ===================== WAZE TRAFFIC =====================

  Future<Map<String, dynamic>> getTraffic({required double lat, required double lng, double radiusKm = 5}) async {
    final uri = Uri.parse("$baseUrl/waze/traffic").replace(queryParameters: {
      "lat": lat.toString(),
      "lng": lng.toString(),
      "radius_km": radiusKm.toString(),
    });
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load traffic");
    return jsonDecode(res.body);
  }

  // ===================== GOOGLE MAPS =====================

  Future<List<dynamic>> searchPlacesGoogle({required String query, double? lat, double? lng}) async {
    final qp = <String, String>{"q": query};
    if (lat != null) qp["lat"] = lat.toString();
    if (lng != null) qp["lng"] = lng.toString();
    final uri = Uri.parse("$baseUrl/google/search").replace(queryParameters: qp);
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Google Maps unavailable");
    final data = jsonDecode(res.body);
    return data["places"] ?? [];
  }

  Future<Map<String, dynamic>> getPlaceDetails({required String placeId}) async {
    final uri = Uri.parse("$baseUrl/google/place-details").replace(queryParameters: {"place_id": placeId});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to get place details");
    return jsonDecode(res.body);
  }

  // ===================== SERPAPI =====================

  Future<List<dynamic>> searchRestaurantsSerpApi({
    required String query,
    double? lat,
    double? lng,
  }) async {
    final qp = <String, String>{"q": query};
    if (lat != null) qp["lat"] = lat.toString();
    if (lng != null) qp["lng"] = lng.toString();
    final uri = Uri.parse("$baseUrl/serpapi/restaurants").replace(queryParameters: qp);
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("SerpApi unavailable");
    final data = jsonDecode(res.body);
    return data["restaurants"] ?? [];
  }

  // ===================== FOURSQUARE =====================

  Future<List<dynamic>> searchRestaurantsFoursquare({
    required String query,
    String? near,
    int? maxBudget,
    String? mood,
    int limit = 50,
  }) async {
    final qp = <String, String>{
      "q": query,
      "limit": limit.toString(),
    };
    if (near != null && near.isNotEmpty) qp["near"] = near;
    if (maxBudget != null) qp["max_budget"] = maxBudget.toString();
    if (mood != null && mood.isNotEmpty) qp["mood"] = mood;
    final uri = Uri.parse("$baseUrl/foursquare/search").replace(queryParameters: qp);
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Foursquare search failed");
    final data = jsonDecode(res.body);
    return data["restaurants"] ?? [];
  }

  // ===================== AI RECOMMENDATIONS =====================

  Future<Map<String, dynamic>> getPersonalizedRecommendations({required String email, int limit = 10}) async {
    final uri = Uri.parse("$baseUrl/recommendations").replace(queryParameters: {
      "email": email.trim(),
      "limit": limit.toString(),
    });
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load recommendations");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getTasteKeywords({required String email}) async {
    final uri = Uri.parse("$baseUrl/recommendations/taste-keywords").replace(queryParameters: {
      "email": email.trim(),
    });
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) return {"ok": true, "keywords": [], "has_history": false};
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getFoursquarePhotos({required String fsqId, int limit = 5}) async {
    final qp = <String, String>{
      "fsq_id": fsqId,
      "limit": limit.toString(),
    };
    final uri = Uri.parse("$baseUrl/foursquare/photos").replace(queryParameters: qp);
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load photos");
    final data = jsonDecode(res.body);
    return data["photos"] ?? [];
  }

  Future<Map<String, dynamic>> getFoursquareDetails({required String fsqId}) async {
    final uri = Uri.parse("$baseUrl/foursquare/details").replace(queryParameters: {"fsq_id": fsqId});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load details");
    return jsonDecode(res.body);
  }

  // ===================== CHAT =====================

  WebSocketChannel connectWebSocket(String email) {
    return WebSocketChannel.connect(Uri.parse("$wsUrl/ws/${email.trim()}"));
  }

  Future<List<dynamic>> getConversations({required String email}) async {
    final uri = Uri.parse("$baseUrl/conversations").replace(queryParameters: {"email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load conversations");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createConversation({required String fromEmail, required String toEmail}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/conversations"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"from_email": fromEmail, "to_email": toEmail}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to create conversation");
  }

  Future<Map<String, dynamic>> createGroupConversation({
    required String creatorEmail,
    required String groupName,
    required List<String> memberEmails,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/conversations/group"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"creator_email": creatorEmail, "group_name": groupName, "member_emails": memberEmails}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to create group");
  }

  Future<Map<String, dynamic>> getConversation({required String conversationId, required String email}) async {
    final uri = Uri.parse("$baseUrl/conversations/$conversationId").replace(queryParameters: {"email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load conversation");
    return jsonDecode(res.body);
  }

  Future<void> renameGroup({required String conversationId, required String email, required String name}) async {
    final res = await http.put(
      Uri.parse("$baseUrl/conversations/$conversationId/rename"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "name": name}),
    );
    if (res.statusCode != 200) throw Exception("Failed to rename group");
  }

  Future<List<dynamic>> getMessages({required String conversationId, required String email, int limit = 50, String? before}) async {
    final qp = {"email": email.trim(), "limit": limit.toString()};
    if (before != null) qp["before"] = before;
    final uri = Uri.parse("$baseUrl/conversations/$conversationId/messages").replace(queryParameters: qp);
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load messages");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderEmail,
    required String content,
    String messageType = "text",
    String? replyTo,
    Map<String, dynamic>? extraData,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/conversations/$conversationId/messages"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({
        "sender_email": senderEmail,
        "content": content,
        "message_type": messageType,
        if (replyTo != null) "reply_to": replyTo,
        if (extraData != null) "extra_data": extraData,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to send message");
  }

  Future<void> deleteMessage({required String conversationId, required String messageId, required String email}) async {
    final res = await http.put(
      Uri.parse("$baseUrl/conversations/$conversationId/messages/$messageId"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email}),
    );
    if (res.statusCode != 200) throw Exception("Failed to delete message");
  }

  Future<Map<String, dynamic>> addReaction({required String conversationId, required String messageId, required String email, required String emoji}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/conversations/$conversationId/messages/$messageId/reactions"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "emoji": emoji}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to add reaction");
  }

  Future<void> markConversationRead({required String conversationId, required String email}) async {
    final res = await http.put(
      Uri.parse("$baseUrl/conversations/$conversationId/read"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email.trim()}),
    );
    if (res.statusCode != 200) throw Exception("Failed to mark as read");
  }

  Future<Map<String, dynamic>> togglePin({required String conversationId, required String email}) async {
    final res = await http.put(
      Uri.parse("$baseUrl/conversations/$conversationId/pin"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to toggle pin");
  }

  Future<Map<String, dynamic>> toggleMute({required String conversationId, required String email}) async {
    final res = await http.put(
      Uri.parse("$baseUrl/conversations/$conversationId/mute"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to toggle mute");
  }

  Future<Map<String, dynamic>> toggleBlock({required String email, required String blockedEmail}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/block"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "blocked_email": blockedEmail}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to toggle block");
  }

  Future<Map<String, dynamic>> addGroupMember({required String conversationId, required String email, required String memberEmail}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/conversations/$conversationId/members"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "member_email": memberEmail}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to add member");
  }

  Future<void> removeGroupMember({required String conversationId, required String memberEmail, required String email}) async {
    final uri = Uri.parse("$baseUrl/conversations/$conversationId/members/$memberEmail").replace(queryParameters: {"email": email.trim()});
    final res = await http.delete(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "Failed to remove member");
    }
  }

  Future<Map<String, dynamic>> createPoll({
    required String conversationId,
    required String senderEmail,
    required String question,
    required List<String> options,
    String? date,
    String? time,
    String? restaurantName,
  }) async {
    final bodyMap = <String, dynamic>{
      "sender_email": senderEmail,
      "question": question,
      "options": options,
    };
    if (date != null) bodyMap["date"] = date;
    if (time != null) bodyMap["time"] = time;
    if (restaurantName != null) bodyMap["restaurant_name"] = restaurantName;
    final res = await http.post(
      Uri.parse("$baseUrl/conversations/$conversationId/polls"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode(bodyMap),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to create poll");
  }

  Future<Map<String, dynamic>> votePoll({required String pollId, required String email, required int optionIndex}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/polls/$pollId/vote"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "option_index": optionIndex}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to vote");
  }

  Future<void> closePoll({required String pollId, required String email}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/polls/$pollId/close"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email}),
    );
    if (res.statusCode != 200) throw Exception("Failed to close poll");
  }

  Future<Map<String, dynamic>> confirmPoll({required String pollId, required String email}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/polls/$pollId/confirm"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "Failed to confirm poll");
    }
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> searchMessages({required String conversationId, required String email, required String query}) async {
    final uri = Uri.parse("$baseUrl/conversations/$conversationId/search").replace(queryParameters: {"q": query.trim(), "email": email.trim()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to search messages");
    return jsonDecode(res.body);
  }

  // ===================== NOTIFICATIONS =====================

  Future<List<dynamic>> getNotifications({required String email, int limit = 20}) async {
    final uri = Uri.parse("$baseUrl/notifications").replace(queryParameters: {"email": email, "limit": limit.toString()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load notifications");
    return jsonDecode(res.body);
  }

  Future<int> getUnreadNotificationCount({required String email}) async {
    final uri = Uri.parse("$baseUrl/notifications/unread-count").replace(queryParameters: {"email": email});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) return 0;
    final data = jsonDecode(res.body);
    return data["count"] ?? 0;
  }

  Future<void> markNotificationRead({required String notificationId}) async {
    final res = await http.put(Uri.parse("$baseUrl/notifications/$notificationId/read"), headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to mark as read");
  }

  Future<void> markAllNotificationsRead({required String email}) async {
    final uri = Uri.parse("$baseUrl/notifications/read-all").replace(queryParameters: {"email": email});
    final res = await http.put(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to mark all as read");
  }

  // ===================== BOOKMARKS =====================

  Future<Map<String, dynamic>> toggleBookmark({required String email, required String postId}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/bookmarks/toggle"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "post_id": postId}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to toggle bookmark");
  }

  Future<List<dynamic>> getBookmarks({required String email}) async {
    final uri = Uri.parse("$baseUrl/bookmarks").replace(queryParameters: {"email": email});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load bookmarks");
    return jsonDecode(res.body);
  }

  // ===================== POSTS EDIT/DELETE =====================

  Future<Map<String, dynamic>> editPost({required String postId, required String email, String? description, int? rating, String? priceRange}) async {
    final uri = Uri.parse("$baseUrl/posts/$postId").replace(queryParameters: {"email": email});
    final res = await http.put(
      uri,
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({
        if (description != null) "description": description,
        if (rating != null) "rating": rating,
        if (priceRange != null) "price_range": priceRange,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to edit post");
  }

  Future<void> deletePost({required String postId, required String email}) async {
    final uri = Uri.parse("$baseUrl/posts/$postId").replace(queryParameters: {"email": email});
    final res = await http.delete(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "Failed to delete post");
    }
  }

  // ===================== REPORT =====================

  Future<void> reportContent({required String reporterEmail, required String reportedType, required String reportedId, required String reason}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/reports"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"reporter_email": reporterEmail, "reported_type": reportedType, "reported_id": reportedId, "reason": reason}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "Failed to report");
    }
  }

  // ===================== RESTAURANT MENU (chain-based) =====================

  /// Extract canonical chain name from a raw restaurant name (mirrors backend logic)
  static String? extractChainName(String? restaurantName) {
    if (restaurantName == null || restaurantName.trim().isEmpty) return null;
    String name = restaurantName.toLowerCase();

    // Strip parenthetical / bracket content
    name = name.replaceAll(RegExp(r"\s*[\(\[].*?[\)\]]\s*"), " ");
    // Strip dash-separated suffixes
    name = name.replaceAll(RegExp(r"\s*[-–—]\s*.*$"), "");
    // Strip common location words
    final locationWords = [
      "dubai", "abu dhabi", "sharjah", "ajman", "fujairah",
      "ras al khaimah", "umm al quwain", "al ain", "deira",
      "bur dubai", "jbr", "jlt", "downtown", "marina", "mall",
      "center", "centre", "street", "road", "avenue",
    ];
    for (final word in locationWords) {
      name = name.replaceAll(RegExp(r"\s+" + RegExp.escape(word) + r"\s*$"), "");
      name = name.replaceAll(RegExp(r"^" + RegExp.escape(word) + r"\s+"), "");
    }
    name = name.trim();

    final chains = {
      "KFC": RegExp(r"\bkfc\b"),
      "McDonalds": RegExp(r"\bmcdonald'?s?\b"),
      "Burger King": RegExp(r"\bburger king\b"),
      "Tim Hortons": RegExp(r"\btim hortons\b"),
      "Nandos": RegExp(r"\bnando'?s?\b"),
      "Pizza Hut": RegExp(r"\bpizza hut\b"),
      "Subway": RegExp(r"\bsubway\b"),
      "Krispy Kreme": RegExp(r"\bkrispy kreme\b"),
      "Starbucks": RegExp(r"\bstarbucks\b"),
      "Costa Coffee": RegExp(r"\bcosta coffee\b"),
      "Shake Shack": RegExp(r"\bshake shack\b"),
      "Popeyes": RegExp(r"\bpopeyes?\b"),
      "Taco Bell": RegExp(r"\btaco bell\b"),
      "Domino's": RegExp(r"\bdomino'?s?\b"),
      "Five Guys": RegExp(r"\bfive guys\b"),
    };
    for (final entry in chains.entries) {
      if (entry.value.hasMatch(name)) return entry.key;
    }
    return null;
  }

  Future<Map<String, dynamic>> getRestaurantMenu({required String restaurantName}) async {
    final qp = {"restaurant_name": restaurantName.trim()};
    final uri = Uri.parse("$baseUrl/menus/by-restaurant").replace(queryParameters: qp);
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load menu");
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getNearbyRestaurants({required double lat, required double lng, double radiusKm = 10, int limit = 20}) async {
    final uri = Uri.parse("$baseUrl/restaurants/nearby").replace(queryParameters: {
      "lat": lat.toString(), "lng": lng.toString(), "radius_km": radiusKm.toString(), "limit": limit.toString(),
    });
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load nearby");
    return jsonDecode(res.body);
  }

  // ===================== RECENT SEARCHES =====================

  Future<void> saveSearch({required String email, required String query, String searchType = "restaurant"}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/searches"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"email": email, "query": query, "search_type": searchType}),
    );
    if (res.statusCode != 200) throw Exception("Failed to save search");
  }

  Future<List<dynamic>> getRecentSearches({required String email, String searchType = "restaurant"}) async {
    final uri = Uri.parse("$baseUrl/searches").replace(queryParameters: {"email": email, "search_type": searchType});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load searches");
    return jsonDecode(res.body);
  }

  Future<void> clearRecentSearches({required String email}) async {
    final uri = Uri.parse("$baseUrl/searches").replace(queryParameters: {"email": email});
    final res = await http.delete(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to clear searches");
  }

  // ===================== PROFILE =====================

  Future<Map<String, dynamic>> updateProfile({required String email, String? firstName, String? lastName, String? bio, String? avatarUrl}) async {
    final res = await http.put(
      Uri.parse("$baseUrl/users/profile"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({
        "email": email,
        if (firstName != null) "first_name": firstName,
        if (lastName != null) "last_name": lastName,
        if (bio != null) "bio": bio,
        if (avatarUrl != null) "avatar_url": avatarUrl,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to update profile");
  }

  Future<Map<String, dynamic>> getUserProfile({required String email}) async {
    final res = await http.get(Uri.parse("$baseUrl/users/$email/profile"), headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load profile");
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getFollowers({required String email, int limit = 50}) async {
    final uri = Uri.parse("$baseUrl/users/$email/followers").replace(queryParameters: {"limit": limit.toString()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load followers");
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getFollowing({required String email, int limit = 50}) async {
    final uri = Uri.parse("$baseUrl/users/$email/following").replace(queryParameters: {"limit": limit.toString()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load following");
    return jsonDecode(res.body);
  }

  // ===================== ADMIN =====================

  Future<bool> checkAdmin({required String email}) async {
    final uri = Uri.parse("$baseUrl/admin/check").replace(queryParameters: {"email": email});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body);
    return data["is_admin"] == true;
  }

  Future<List<dynamic>> getAdminUsers({required String adminEmail, int limit = 50}) async {
    final uri = Uri.parse("$baseUrl/admin/users").replace(queryParameters: {"admin_email": adminEmail, "limit": limit.toString()});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load users");
    return jsonDecode(res.body);
  }

  Future<void> banUser({required String adminEmail, required String targetEmail, String reason = ""}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/admin/ban"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"admin_email": adminEmail, "target_email": targetEmail, "reason": reason}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "Failed to ban user");
    }
  }

  Future<void> unbanUser({required String adminEmail, required String targetEmail}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/admin/unban"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"admin_email": adminEmail, "target_email": targetEmail}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "Failed to unban user");
    }
  }

  Future<List<dynamic>> getBannedUsers({required String adminEmail}) async {
    final uri = Uri.parse("$baseUrl/admin/banned").replace(queryParameters: {"admin_email": adminEmail});
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load banned users");
    return jsonDecode(res.body);
  }

  // ===================== ADMIN MENU MANAGEMENT =====================

  Future<List<dynamic>> getAdminMenus({required String adminEmail, int limit = 50}) async {
    final uri = Uri.parse("$baseUrl/admin/menus").replace(queryParameters: {
      "admin_email": adminEmail,
      "limit": limit.toString(),
    });
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load menus");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getAdminMenu({required String adminEmail, required String chainName}) async {
    final uri = Uri.parse("$baseUrl/admin/menus/$chainName").replace(queryParameters: {
      "admin_email": adminEmail,
    });
    final res = await http.get(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) throw Exception("Failed to load menu");
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> upsertAdminMenu({
    required String adminEmail,
    required String chainName,
    required List<Map<String, dynamic>> categories,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/admin/menus"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({
        "admin_email": adminEmail,
        "chain_name": chainName,
        "categories": categories,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to save menu");
  }

  Future<void> deleteAdminMenu({required String adminEmail, required String chainName}) async {
    final uri = Uri.parse("$baseUrl/admin/menus/$chainName").replace(queryParameters: {
      "admin_email": adminEmail,
    });
    final res = await http.delete(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "Failed to delete menu");
    }
  }

  Future<Map<String, dynamic>> addRestaurant({
    required String adminEmail,
    required String name,
    required String cuisine,
    required String address,
    String phone = "",
    double lat = 0.0,
    double lng = 0.0,
    String imageUrl = "",
    double rating = 0.0,
    String openingHours = "",
    String priceRange = "",
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/admin/restaurants"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({
        "admin_email": adminEmail, "name": name, "cuisine": cuisine, "address": address,
        "phone": phone, "lat": lat, "lng": lng, "image_url": imageUrl,
        "rating": rating, "opening_hours": openingHours, "price_range": priceRange,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode == 200) return body;
    throw Exception(body["detail"] ?? "Failed to add restaurant");
  }

  Future<void> deleteRestaurant({required String adminEmail, required String restaurantId}) async {
    final uri = Uri.parse("$baseUrl/admin/restaurants/$restaurantId").replace(queryParameters: {"admin_email": adminEmail});
    final res = await http.delete(uri, headers: {"Accept": "application/json"});
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body["detail"] ?? "Failed to delete restaurant");
    }
  }

  // ===================== AI CHATBOT =====================

  Future<String> askChatbot({required List<Map<String, dynamic>> messages}) async {
    final res = await http.post(
      Uri.parse("$baseUrl/chatbot/ask"),
      headers: {"Content-Type": "application/json", "Accept": "application/json"},
      body: jsonEncode({"messages": messages}),
    );
    if (res.statusCode != 200) throw Exception("Chatbot unavailable");
    final data = jsonDecode(res.body);
    return data["reply"] ?? "Sorry, I could not understand that. 🙏";
  }
}