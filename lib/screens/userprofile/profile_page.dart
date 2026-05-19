import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/navigation_bar.dart';
import 'wishlist_page.dart';
import 'liked_page.dart';
import 'disliked_page.dart';
import 'plans_page.dart';
import '../welcome_page.dart';
import '../admin_panel_page.dart';
import '../settings_page.dart';
import '../../services/api_service.dart';
import '../../services/session.dart';
import '../../services/theme_provider.dart';
import 'followers_page.dart';
import 'following_page.dart';
import 'edit_profile_page.dart';
import 'bookmarks_page.dart';

class ProfilePage extends StatefulWidget {
  final String userName;

  const ProfilePage({super.key, required this.userName});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _api = ApiService();

  bool _loadingStats = true;
  String? _statsError;
  int _wishlistCount = 0;
  int _likedCount = 0;
  int _dislikedCount = 0;
  int _plansCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final email = Session.email.trim();
    if (email.isEmpty) return;
    try {
      final isAdmin = await _api.checkAdmin(email: email);
      if (!mounted) return;
      setState(() => _isAdmin = isAdmin);
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    final email = Session.email.trim();
    if (email.isEmpty) {
      setState(() {
        _loadingStats = false;
        _statsError = "Not logged in";
      });
      return;
    }

    setState(() {
      _loadingStats = true;
      _statsError = null;
    });

    try {
      final stats = await _api.getUserStats(email: email);
      if (!mounted) return;
      setState(() {
        _wishlistCount = (stats["wishlist_count"] ?? 0) as int;
        _likedCount = (stats["liked_count"] ?? 0) as int;
        _dislikedCount = (stats["disliked_count"] ?? 0) as int;
        _plansCount = (stats["plans_count"] ?? 0) as int;
        _followersCount = (stats["followers_count"] ?? 0) as int;
        _followingCount = (stats["following_count"] ?? 0) as int;
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e.toString().replaceFirst("Exception: ", "");
        _loadingStats = false;
      });
    }
  }

  String _profileTitle() {
    final handle = (Session.handle ?? "").trim();
    if (handle.isNotEmpty) return handle;

    final dn = (Session.displayName ?? "").trim();
    if (dn.isNotEmpty) return dn;

    return widget.userName;
  }

  String get _userEmail => Session.email.trim();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final email = _userEmail;

    return Scaffold(
      backgroundColor: themeProvider.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24)
                  .copyWith(bottom: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                    backgroundImage: Session.avatarUrl.isNotEmpty ? NetworkImage(Session.avatarUrl) : null,
                    child: Session.avatarUrl.isEmpty ? Icon(Icons.person, size: 60, color: isDark ? Colors.white54 : Colors.grey) : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
                      if (result == true) _loadStats();
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6F8574),
                      side: const BorderSide(color: Color(0xFF6F8574)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (_isAdmin) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelPage()));
                      },
                      icon: const Icon(Icons.shield, size: 16),
                      label: const Text('Admin Panel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Text(
                    _profileTitle(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: themeProvider.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),

                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Stats from backend
                  if (_loadingStats)
                    const CircularProgressIndicator(color: Color(0xFF6F8574))
                  else if (_statsError != null)
                    Text(
                      _statsError!,
                      style: TextStyle(color: Colors.red[400], fontSize: 12),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statColumn('${_wishlistCount + _likedCount + _dislikedCount}', 'Places', themeProvider),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FollowersPage())),
                          child: _statColumn('$_followersCount', 'Followers', themeProvider),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FollowingPage())),
                          child: _statColumn('$_followingCount', 'Following', themeProvider),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                  Divider(height: 1, thickness: 1, color: themeProvider.divider),
                  const SizedBox(height: 24),

                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WishlistPage(),
                                  ),
                                ).then((_) => _loadStats());
                              },
                              child: _statCard('$_wishlistCount', 'Wishlist', Icons.checklist, themeProvider),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PlansPage(),
                                  ),
                                ).then((_) => _loadStats());
                              },
                              child: _statCard('$_plansCount', 'Plans', Icons.calendar_today, themeProvider),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LikedPage(),
                                  ),
                                ).then((_) => _loadStats());
                              },
                              child: _statCard('$_likedCount', 'Liked', Icons.thumb_up, themeProvider),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DislikedPage(),
                                  ),
                                ).then((_) => _loadStats());
                              },
                              child: _statCard('$_dislikedCount', 'Disliked', Icons.thumb_down, themeProvider),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _menuItem(
                    icon: Icons.history,
                    label: 'Post Review History',
                    themeProvider: themeProvider,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Review history coming soon')),
                      );
                    },
                  ),
                  _menuItem(
                    icon: Icons.share,
                    label: 'Share Profile',
                    themeProvider: themeProvider,
                    onTap: () {
                      final handle = Session.handle.isNotEmpty ? Session.handle : Session.displayName;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Share: $handle')),
                      );
                    },
                  ),
                  _menuItem(
                    icon: Icons.edit,
                    label: 'Edit Profile',
                    themeProvider: themeProvider,
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
                      if (result == true) _loadStats();
                    },
                  ),
                  _menuItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    themeProvider: themeProvider,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(themeProvider: themeProvider)));
                    },
                  ),
                  _menuItem(
                    icon: Icons.logout,
                    label: 'Log Out',
                    isLogOut: true,
                    themeProvider: themeProvider,
                    onTap: _showLogOutDialog,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: FloatingNavBar(
              currentIndex: 4,
              onTap: (i) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String number, String label, ThemeProvider themeProvider) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: themeProvider.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: themeProvider.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String count, String label, IconData icon, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF3E3A9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: themeProvider.textPrimary),
          const SizedBox(height: 16),
          _loadingStats
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: themeProvider.textPrimary),
                )
              : Text(
                  count,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: themeProvider.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: themeProvider.textPrimary,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
    bool isLogOut = false,
  }) {
    final isDark = themeProvider.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isLogOut ? Colors.green[600] : themeProvider.textPrimary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isLogOut ? Colors.green[600] : themeProvider.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isLogOut ? Colors.green[600] : themeProvider.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogOutDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.surface,
        title: Text('Log Out', style: TextStyle(color: themeProvider.textPrimary)),
        content: Text('Are you sure you want to log out?', style: TextStyle(color: themeProvider.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await Session.clear();

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomePage()),
                (route) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
