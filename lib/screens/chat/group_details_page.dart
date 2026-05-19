import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/session.dart';

class GroupMember {
  final String email;
  final String name;
  final String handle;

  GroupMember({required this.email, required this.name, this.handle = ''});
}

class GroupDetailsPage extends StatefulWidget {
  final List<GroupMember> selectedMembers;

  const GroupDetailsPage({super.key, required this.selectedMembers});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  static const Color background = Color(0xFFFEF9EE);
  static const Color accent = Color(0xFF6F8574);

  final _api = ApiService();
  final TextEditingController _groupNameController = TextEditingController();

  late List<GroupMember> _members;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.selectedMembers);
  }

  void _removeMember(String email) {
    setState(() {
      _members.removeWhere((m) => m.email == email);
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }
    if (_members.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group must have at least 2 members')),
      );
      return;
    }

    final creatorEmail = Session.email.trim();
    if (creatorEmail.isEmpty) return;

    setState(() => _creating = true);
    try {
      final memberEmails = _members.map((m) => m.email).toList();
      final result = await _api.createGroupConversation(
        creatorEmail: creatorEmail,
        groupName: groupName,
        memberEmails: memberEmails,
      );
      if (!mounted) return;

      final conv = result['conversation'];
      Navigator.pop(context, {
        'conversation_id': conv['id'],
        'name': groupName,
        'is_group': true,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Group',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 28, color: Colors.black),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: 'Group name',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.black26, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.black26, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: accent, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, thickness: 1, color: Colors.grey[300]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Members (${_members.length})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _members.isEmpty
                ? Center(
                    child: Text('No members selected', style: TextStyle(color: Colors.grey[500])),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isLast = index == _members.length - 1;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: accent,
                                  child: Text(
                                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(member.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      if (member.handle.isNotEmpty)
                                        Text(member.handle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _removeMember(member.email),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      border: Border.all(color: Colors.red[300]!, width: 1.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(Icons.close, color: Colors.red[600], size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) Divider(height: 1, thickness: 1, color: Colors.grey[200], indent: 72),
                        ],
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _members.length < 2 || _creating ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _members.length < 2 || _creating ? Colors.grey : accent,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _creating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Create Group',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }
}