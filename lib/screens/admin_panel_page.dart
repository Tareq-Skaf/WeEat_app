import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> with SingleTickerProviderStateMixin {
  static const Color accent = Color(0xFF6F8574);
  static const Color cardYellow = Color(0xFFF3E3A9);

  final _api = ApiService();
  late TabController _tabController;

  List<dynamic> _users = [];
  List<dynamic> _bannedUsers = [];
  List<dynamic> _menus = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final email = Session.email.trim();
    setState(() => _loading = true);
    try {
      final users = await _api.getAdminUsers(adminEmail: email);
      final banned = await _api.getBannedUsers(adminEmail: email);
      final menus = await _api.getAdminMenus(adminEmail: email);
      if (!mounted) return;
      setState(() {
        _users = users;
        _bannedUsers = banned;
        _menus = menus;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _banUser(String email) async {
    final adminEmail = Session.email.trim();
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ban $email?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason (optional)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ban', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.banUser(adminEmail: adminEmail, targetEmail: email, reason: reasonController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$email banned')));
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _unbanUser(String email) async {
    final adminEmail = Session.email.trim();
    try {
      await _api.unbanUser(adminEmail: adminEmail, targetEmail: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$email unbanned')));
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  void _showAddRestaurantDialog() {
    final nameController = TextEditingController();
    final cuisineController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final imageController = TextEditingController();
    final hoursController = TextEditingController();
    String priceRange = '\$\$';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Restaurant'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: cuisineController, decoration: const InputDecoration(labelText: 'Cuisine', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: hoursController, decoration: const InputDecoration(labelText: 'Opening Hours', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priceRange,
                  decoration: const InputDecoration(labelText: 'Price Range', border: OutlineInputBorder()),
                  items: ['\$', '\$\$', '\$\$\$', '\$\$\$\$'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setDialogState(() => priceRange = v ?? '\$\$'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final adminEmail = Session.email.trim();
                try {
                  await _api.addRestaurant(
                    adminEmail: adminEmail,
                    name: nameController.text.trim(),
                    cuisine: cuisineController.text.trim(),
                    address: addressController.text.trim(),
                    phone: phoneController.text.trim(),
                    imageUrl: imageController.text.trim(),
                    openingHours: hoursController.text.trim(),
                    priceRange: priceRange,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant added')));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Admin Panel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: accent,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Banned'),
            Tab(text: 'Restaurants'),
            Tab(text: 'Menus'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildBannedTab(),
                _buildRestaurantsTab(),
                _buildMenusTab(),
              ],
            ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _tabController.index == 2
            ? FloatingActionButton(
                key: const ValueKey('add_restaurant'),
                onPressed: _showAddRestaurantDialog,
                backgroundColor: accent,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : _tabController.index == 3
                ? FloatingActionButton(
                    key: const ValueKey('add_menu'),
                    onPressed: _showAddMenuDialog,
                    backgroundColor: accent,
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
      ),
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final email = (user['email'] ?? '').toString();
        final name = (user['display_name'] ?? '').toString();
        final handle = (user['handle'] ?? '').toString();
        final isAdmin = user['is_admin'] == true;
        final isBanned = user['is_banned'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isBanned ? Border.all(color: Colors.red, width: 1.5) : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isAdmin ? cardYellow : Colors.grey[300],
                child: Icon(isAdmin ? Icons.shield : Icons.person, color: isAdmin ? Colors.black87 : Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: cardYellow, borderRadius: BorderRadius.circular(4)),
                            child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ],
                        if (isBanned) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                            child: Text('BANNED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red[700])),
                          ),
                        ],
                      ],
                    ),
                    Text(handle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(email, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              if (!isAdmin)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (!isBanned)
                      const PopupMenuItem(value: 'ban', child: Text('Ban User', style: TextStyle(color: Colors.red)))
                    else
                      const PopupMenuItem(value: 'unban', child: Text('Unban User')),
                  ],
                  onSelected: (value) {
                    if (value == 'ban') _banUser(email);
                    if (value == 'unban') _unbanUser(email);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannedTab() {
    if (_bannedUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 60, color: Colors.green[300]),
            const SizedBox(height: 12),
            const Text('No banned users', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bannedUsers.length,
      itemBuilder: (context, index) {
        final user = _bannedUsers[index];
        final email = (user['email'] ?? '').toString();
        final name = (user['user_name'] ?? '').toString();
        final reason = (user['reason'] ?? '').toString();
        final bannedBy = (user['banned_by'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: Colors.red[100], child: Icon(Icons.block, color: Colors.red[700])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isNotEmpty ? name : email, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (reason.isNotEmpty) Text('Reason: $reason', style: TextStyle(color: Colors.red[600], fontSize: 12)),
                    Text('Banned by: $bannedBy', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _unbanUser(email),
                child: const Text('Unban', style: TextStyle(color: accent)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Tap + to add a restaurant', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenusTab() {
    if (_menus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('No menus yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 4),
            const Text('Tap + to add a chain menu', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menus.length,
      itemBuilder: (context, index) {
        final menu = _menus[index];
        final chain = (menu['chain_name'] ?? '').toString();
        final totalItems = (menu['total_items'] ?? 0) as int;
        final updatedAt = (menu['updated_at'] ?? '').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cardYellow,
                child: Text(chain.isNotEmpty ? chain[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chain, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('$totalItems items', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    if (updatedAt.isNotEmpty)
                      Text(
                        'Updated ${_formatDate(updatedAt)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
                onPressed: () => _showEditMenuDialog(chain),
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 20, color: Colors.red[300]),
                onPressed: () => _deleteMenu(chain),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String iso) {
    try {
      final date = DateTime.parse(iso);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _deleteMenu(String chainName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $chainName menu?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red[700]))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteAdminMenu(adminEmail: Session.email.trim(), chainName: chainName);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$chainName menu deleted')));
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  void _showAddMenuDialog() => _showMenuEditorDialog(chainName: '');
  void _showEditMenuDialog(String chainName) => _showMenuEditorDialog(chainName: chainName);

  void _showMenuEditorDialog({required String chainName}) {
    final isEditing = chainName.isNotEmpty;
    final chainController = TextEditingController(text: chainName);
    // Simple JSON editor for categories
    final jsonController = TextEditingController();

    if (isEditing) {
      _api.getAdminMenu(adminEmail: Session.email.trim(), chainName: chainName).then((data) {
        final categories = data['categories'] ?? [];
        jsonController.text = const JsonEncoder.withIndent('  ').convert(categories);
      }).catchError((e) {
        jsonController.text = '[]';
      });
    } else {
      jsonController.text = '''[
  {
    "name": "Category Name",
    "items": [
      {
        "name": "Item Name",
        "description": "Description",
        "price": 25.0,
        "image_url": "",
        "is_vegetarian": false,
        "is_spicy": false,
        "calories": 500
      }
    ]
  }
]''';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit $chainName Menu' : 'Add Chain Menu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEditing) ...[
                TextField(
                  controller: chainController,
                  decoration: const InputDecoration(labelText: 'Chain Name (e.g. KFC)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
              ],
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Categories JSON', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: jsonController,
                  maxLines: 16,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                    hintText: 'Paste categories JSON here...',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final adminEmail = Session.email.trim();
              final targetChain = chainController.text.trim();
              if (targetChain.isEmpty) return;
              try {
                final categories = jsonDecode(jsonController.text.trim()) as List<dynamic>;
                final mapped = categories.map((c) => Map<String, dynamic>.from(c as Map)).toList();
                await _api.upsertAdminMenu(adminEmail: adminEmail, chainName: targetChain, categories: mapped);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${isEditing ? "Updated" : "Added"} $targetChain menu')));
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            child: Text(isEditing ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}