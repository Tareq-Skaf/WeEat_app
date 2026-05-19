import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/add_post_page.dart';
import '../screens/home_page.dart';
import '../screens/chat_page.dart';
import '../screens/userprofile/profile_page.dart';
import '../screens/search_page.dart';
import '../services/theme_provider.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final String? homeName;
  final ValueChanged<int>? onTap;
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    this.homeName,
    this.onTap,
  });

  void _handleTap(BuildContext context, int i) {
    if (onTap != null) onTap!(i);

    switch (i) {
      case 0:
        final targetName = homeName ?? '';
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(name: targetName)),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SearchPage(homeName: homeName)),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddPostPage(homeName: homeName)),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatPage(homeName: homeName)),
        );
        break;
      case 4:
        final targetName = homeName ?? '';
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ProfilePage(userName: targetName)),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final barColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFF6F8574);
    final fabColor = isDark ? const Color(0xFF3A3A3A) : Colors.white;
    final iconColor = isDark ? Colors.white70 : Colors.white;
    final fabIconColor = isDark ? const Color(0xFF6F8574) : const Color(0xFF6F8574);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 74,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black26, offset: const Offset(0, 8), blurRadius: 12)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(onPressed: () => _handleTap(context, 0), icon: Icon(Icons.home, color: iconColor)),
                  IconButton(onPressed: () => _handleTap(context, 1), icon: Icon(Icons.search, color: iconColor)),
                  const SizedBox(width: 48),
                  IconButton(onPressed: () => _handleTap(context, 3), icon: Icon(Icons.chat_bubble_outline, color: iconColor)),
                  IconButton(onPressed: () => _handleTap(context, 4), icon: Icon(Icons.person_outline, color: iconColor)),
                ],
              ),
            ),
            Positioned(
              child: GestureDetector(
                onTap: () => _handleTap(context, 2),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: fabColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: isDark ? Colors.black54 : Colors.black26, offset: const Offset(0, 8), blurRadius: 12)],
                  ),
                  child: Center(child: Icon(Icons.add, size: 30, color: fabIconColor)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
